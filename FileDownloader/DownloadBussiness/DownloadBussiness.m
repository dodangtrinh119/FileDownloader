//
//  DownloadBussiness.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/18/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadBussiness.h"
#import "Reachability.h"
#import "DownloadModel.h"

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
        self.reachability = [Reachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
        
        self.reachability = [Reachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
        
        [self getListDownloaded];
        if (!self.listDownloaded) {
            self.listDownloaded = [[NSMutableArray alloc] init];
        }
        self.downloadManager = [[DownloadManager alloc] init];
    }
    return self;
}

- (void)setProgressUpdate:(void (^)(id<DownloadItem> source, int64_t byteWritten, int64_t totalByte))updateProgressAtIndex {
    [self.downloadManager setProgressUpdate:updateProgressAtIndex];
}

- (void)cancelDownload:(id<DownloadItem>)item {
    [self.downloadManager cancelDownload:item];
}

- (void)pauseDownload:(id<DownloadItem>)item {
    [self.downloadManager pauseDownload:item];
}

- (void)resumeDownloadAndStored:(id<DownloadItem>)item completion:(downloadCompletion)completionHandler {
    __weak typeof(self) weakSelf = self;
    [self.downloadManager resumeDownload:item returnToQueue:dispatch_get_main_queue() completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error ) {
            completionHandler(nil, error);
        }
        if (location) {
            item.storedLocalPath = location;
            [weakSelf.listDownloaded addObject:item.downloadURL];
            completionHandler(location, nil);
        }
    }];
}

- (NSURL *)getLocalStoredPathOfItem:(id<DownloadItem>)item {
    NSURL* downloadUrl = [[NSURL alloc] initWithString:item.downloadURL];
    return [self.downloadManager localFilePath:downloadUrl];
}

- (void)downloadAndStored:(id<DownloadItem>)item completion:(downloadCompletion)completionHandler {
    NSURL* downloadUrl = [[NSURL alloc] initWithString:item.downloadURL];
    NSURL* destinationUrl = [self.downloadManager localFilePath:downloadUrl];
    
    if ([self.listDownloaded containsObject:item.downloadURL]) {
        completionHandler(destinationUrl, nil);
        return;
    }
    
    //if not downloaded and stored -> go download and store it to disk.
    __weak typeof(self) weakSelf = self;
    [self.downloadManager startDownload:item returnToQueue:dispatch_get_main_queue() completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error ) {
            completionHandler(nil, error);
        }
        if (location) {
            item.storedLocalPath = location;
            [weakSelf.listDownloaded addObject:item.downloadURL];
            [weakSelf saveListDownloaded];
            completionHandler(location, nil);
        }
    }];
}

- (void)handleNetworkChange:(NSNotification *)notice {
    NetworkStatus remoteHostStatus = [self.reachability currentReachabilityStatus];
    
    switch (remoteHostStatus) {
        case NotReachable:
            [self.downloadManager pauseAllDownloading];
            if (self.delegate) {
                [self.delegate didPausedDownloadBySystem];
            }
            break;
        default:
            break;
    }
}

- (DownloadStatus)getStatusOfModel:(id<DownloadItem>)item {
    return [self.downloadManager getStatusOfItem:item];
}

@end
