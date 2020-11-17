//
//  DownloadBussiness.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/18/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadManager.h"
#import "Reachability.h"
#import "NormalDownloadTask.h"

@interface DownloadManager()

@property (nonatomic, strong) NSMutableArray *listItemDownloaded;
@property (nonatomic, strong) Reachability* reachability;
@property (nonatomic, strong) DownloadProvider *downloadProvider;
@property (nonatomic, strong) NSURL *storedPath;

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

- (void)saveListItemDownloaded {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.listItemDownloaded forKey:DownloadManager.storedDataKey];
}

- (void)updateListDownloaded {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.listItemDownloaded = [[userDefaults arrayForKey:DownloadManager.storedDataKey] mutableCopy];
}

- (NSArray *)getListItemDownloaded {
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
    
    [self.downloadProvider resumeDownloadItem:item
                                returnToQueue:dispatch_get_main_queue()
                                   completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
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

- (void)startDownloadItem:(id<DownloadableItem>)item
      isTrunkFileDownload:(BOOL)isTrunkFile
             withPriority:(DownloadTaskPriroity)priority
    downloadProgressBlock:(downloadProgressBlock)progressBlock
               completion:(downloadCompletion)completionHandler {
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
    [self.downloadProvider startDownloadItem:item
                         isTrunkFileDownload:isTrunkFile
                                withPriority:priority
                               returnToQueue:dispatch_get_main_queue()
                       downloadProgressBlock: progressBlock
                                  completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error && completionHandler) {
            completionHandler(nil, error);
        }
        if (location) {
            item.storedLocalPath = [location absoluteString];
            [weakSelf.listItemDownloaded addObject:[item.downloadURL absoluteString]];
            [weakSelf saveListItemDownloaded];
            if (completionHandler) {
                completionHandler(location, nil);
            }
        }
    }];
}

- (void)createNormalDownloadTaskWithItem:(id<DownloadableItem>)item withResumeData:(NSData *)resumeData withPriority:(DownloadTaskPriroity)priority downloadProgressBlock:(downloadProgressBlock)progressBlock completion:(downloadTaskCompletion)completionHandler {
    [self.downloadProvider createNormalDownloadTaskWithItem:item withResumeData:resumeData withPriority:priority returnToQueue:dispatch_get_main_queue() downloadProgressBlock:progressBlock completion:completionHandler];
}

- (void)createTrunkFileDownloadTaskWithItem:(id<DownloadableItem>)item withData:(NSData *)taskData withPriority:(DownloadTaskPriroity)priority downloadProgressBlock:(downloadProgressBlock)progressBlock completion:(downloadTaskCompletion)completion {
    [self.downloadProvider createTrunkFileDownloadTaskWithItem:item withData:taskData withPriority:priority returnToQueue:dispatch_get_main_queue() downloadProgressBlock:progressBlock completion:completion];
}

- (void)networkWasChanged:(NSNotification *)notice {
    NetworkStatus remoteHostStatus = [self.reachability currentReachabilityStatus];
    
    switch (remoteHostStatus) {
        case NotReachable:
            [self.downloadProvider pauseAllDownloadingItem];
            break;
        default:
            [self.downloadProvider resumeAllPausingItem];
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

- (void)addObserverForDownloader:(id<DownloaderObserverProtocol>)downloaderObserver {
    [self.downloadProvider addDownloadObserver:downloaderObserver];
}

@end
