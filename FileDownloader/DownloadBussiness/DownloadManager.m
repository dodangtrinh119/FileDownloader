//
//  DownloadBussiness.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/18/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadManager.h"
#import "Reachability.h"
#import "DownloadTask.h"

@interface DownloadManager()

@property (nonatomic, strong) NSMutableArray *listItemDownloaded;
@property (nonatomic, strong) Reachability* reachability;

@end

@implementation DownloadManager

+ (instancetype)sharedInstance {
    static DownloadManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DownloadManager alloc] init];
    });
    return _sharedInstance;
}

+ (NSString *)storedDataKey {
    return @"listDownloaded";
}

- (void)saveListDownloaded {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.listItemDownloaded forKey:DownloadManager.storedDataKey];
}

- (void)updateListDownloaded {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.listItemDownloaded = [[userDefaults arrayForKey:DownloadManager.storedDataKey] mutableCopy];
}

- (NSArray *)getListDownloaded {
    return self.listItemDownloaded;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Register listen network status change
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkWasChanged:) name:kReachabilityChangedNotification object:nil];
        
        self.reachability = [Reachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
        
        // Get list local stored if not init
        [self updateListDownloaded];
        if (!self.listItemDownloaded) {
            self.listItemDownloaded = [[NSMutableArray alloc] init];
        }
        self.downloadProvider = [[DownloadProvider alloc] init];
    }
    return self;
}

- (void)setDownloadProgressBlockOfItem:(void (^)(id<DownloadableItem> source, int64_t byteWritten, int64_t totalByte))updateProgressAtIndex {
    [self.downloadProvider setDownloadProgressBlockOfItem:updateProgressAtIndex];
}

- (void)cancelDownloadItem:(id<DownloadableItem>)item {
    [self.downloadProvider cancelDownloadItem:item];
}

- (void)pauseDownloadItem:(id<DownloadableItem>)item {
    [self.downloadProvider pauseDownloadItem:item];
}

- (void)resumeDownloadItem:(id<DownloadableItem>)item completion:(downloadCompletion)completionHandler {
    __weak typeof(self) weakSelf = self;
    
    // If network not alvailable return network error.
    if ([self isNetworkAvailable] == NotReachable) {
        if (completionHandler) {
            completionHandler(nil, DownloadErrorByCode(UnavailableNetwork));
        }
        return;
    }
    
    [self.downloadProvider resumeDownloadItem:item returnToQueue:dispatch_get_main_queue() completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error && completionHandler) {
            completionHandler(nil, error);
        }
        
        if (location) {
            item.storedLocalPath = [location absoluteString];
            
            if (item.storedLocalPath) {
                [weakSelf.listItemDownloaded addObject:[item.downloadURL absoluteString]];
            }
            
            if (completionHandler) {
                completionHandler(location, nil);
            }
        }
    }];
}

- (void)startDownloadItem:(id<DownloadableItem>)item withPriority:(DownloadTaskPriroity)priority completion:(downloadCompletion)completionHandler {
    NSURL* downloadUrl = item.downloadURL;
    NSURL* destinationUrl = [self.downloadProvider localFilePathOfUrl:downloadUrl];
    
    // Check if this url already downloaded -> return it from local stored
    if ([self.listItemDownloaded containsObject:[item.downloadURL absoluteString]] && completionHandler) {
        completionHandler(destinationUrl, nil);
        return;
    }
    
    // Check network status
    if ([self isNetworkAvailable] == NotReachable && completionHandler) {
        completionHandler(nil, DownloadErrorByCode(UnavailableNetwork));
        return;
    }
    
    // If not downloaded and stored -> go download and store it to disk.
    __weak typeof(self) weakSelf = self;
    [self.downloadProvider startDownloadItem:item withPriority:priority returnToQueue:dispatch_get_main_queue() completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error && completionHandler) {
            completionHandler(nil, error);
        }
        if (location) {
            item.storedLocalPath = [location absoluteString];
            [weakSelf.listItemDownloaded addObject:[item.downloadURL absoluteString]];
            [weakSelf saveListDownloaded];
            if (completionHandler) {
                completionHandler(location, nil);
            }
        }
    }];
}

- (void)networkWasChanged:(NSNotification *)notice {
    NetworkStatus remoteHostStatus = [self.reachability currentReachabilityStatus];
    
    switch (remoteHostStatus) {
        case NotReachable:
            [self.downloadProvider pauseAllDownloadingItem];
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
    return [self.downloadProvider getStatusOfItem:item];
}

- (NSString *)getLocalStoredPathOfItem:(id<DownloadableItem>)item {
    NSURL* downloadUrl = item.downloadURL;
    return [[self.downloadProvider localFilePathOfUrl:downloadUrl] absoluteString];
}

@end
