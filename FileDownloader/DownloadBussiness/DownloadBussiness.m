//
//  DownloadBussiness.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/18/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadBussiness.h"
#import "Reachability.h"
#import "DownloadTask.h"

@interface DownloadBussiness()

@property (nonatomic, strong) NSMutableArray *listDownloaded;
@property (nonatomic, strong) Reachability* reachability;

@end

@implementation DownloadBussiness

+ (instancetype)sharedInstance {
    static DownloadBussiness *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DownloadBussiness alloc] init];
    });
    return _sharedInstance;
}

+ (NSString *)storedDataKey {
    return @"listDownloaded";
}

- (void)saveListDownloaded {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.listDownloaded forKey:DownloadBussiness.storedDataKey];
}

- (void)getListDownloaded {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.listDownloaded = [[userDefaults arrayForKey:DownloadBussiness.storedDataKey] mutableCopy];
}

- (NSArray *)getListStored {
    return self.listDownloaded;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //register listen network status change
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
        
        self.reachability = [Reachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
        
        //get list local stored if not init
        [self getListDownloaded];
        if (!self.listDownloaded) {
            self.listDownloaded = [[NSMutableArray alloc] init];
        }
        self.downloadManager = [[DownloadManager alloc] init];
    }
    return self;
}

- (void)setProgressUpdate:(void (^)(id<DownloadableItem> source, int64_t byteWritten, int64_t totalByte))updateProgressAtIndex {
    [self.downloadManager setProgressUpdate:updateProgressAtIndex];
}

- (void)cancelDownload:(id<DownloadableItem>)item {
    [self.downloadManager cancelDownload:item];
}

- (void)pauseDownload:(id<DownloadableItem>)item {
    [self.downloadManager pauseDownload:item];
}

- (void)resumeDownloadAndStored:(id<DownloadableItem>)item completion:(downloadCompletion)completionHandler {
    __weak typeof(self) weakSelf = self;
    
    //if network not alvailable return network error.
    if ([self isNetworkAvailable] == NotReachable) {
        if (completionHandler) {
            completionHandler(nil, DownloadErrorByCode(UnavailableNetwork));
        }
        return;
    }
    [self.downloadManager resumeDownload:item returnToQueue:dispatch_get_main_queue() completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error && completionHandler) {
            completionHandler(nil, error);
        }
        if (location) {
            item.storedLocalPath = [location absoluteString];
            [weakSelf.listDownloaded addObject:[item.downloadURL absoluteString]];
            if (completionHandler) {
                completionHandler(location, nil);
            }
        }
    }];
}

- (void)downloadAndStored:(id<DownloadableItem>)item completion:(downloadCompletion)completionHandler {
    NSURL* downloadUrl = item.downloadURL;
    NSURL* destinationUrl = [self.downloadManager localFilePath:downloadUrl];
    // check if this url already downloaded -> return it from local stored
    if ([self.listDownloaded containsObject:[item.downloadURL absoluteString]] && completionHandler) {
        completionHandler(destinationUrl, nil);
        return;
    }
    //check network status
    if ([self isNetworkAvailable] == NotReachable && completionHandler) {
        completionHandler(nil, DownloadErrorByCode(UnavailableNetwork));
        return;
    }
    
    //if not downloaded and stored -> go download and store it to disk.
    __weak typeof(self) weakSelf = self;
    [self.downloadManager startDownload:item withPriority:DownloadTaskPriroityHigh returnToQueue:dispatch_get_main_queue() completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error && completionHandler) {
            completionHandler(nil, error);
        }
        if (location) {
            item.storedLocalPath = [location absoluteString];
            [weakSelf.listDownloaded addObject:[item.downloadURL absoluteString]];
            [weakSelf saveListDownloaded];
            if (completionHandler) {
                completionHandler(location, nil);
            }
        }
    }];
}

- (void)handleNetworkChange:(NSNotification *)notice {
    NetworkStatus remoteHostStatus = [self.reachability currentReachabilityStatus];
    
    switch (remoteHostStatus) {
        case NotReachable:
            [self.downloadManager pauseAllDownloading];
            if (self.delegate) {
                [self.delegate didPausedDownload];
            }
            break;
        default:
            break;
    }
}

- (BOOL)isNetworkAvailable {
    NetworkStatus remoteHostStatus = [self.reachability currentReachabilityStatus];
    if (remoteHostStatus == NotReachable) {
        return NO;
    }
    return YES;
}

- (DownloadStatus)getStatusOfModel:(id<DownloadableItem>)item {
    return [self.downloadManager getStatusOfItem:item];
}

- (NSString *)getLocalStoredPathOfItem:(id<DownloadableItem>)item {
    NSURL* downloadUrl = item.downloadURL;
    return [[self.downloadManager localFilePath:downloadUrl] absoluteString];
}

@end
