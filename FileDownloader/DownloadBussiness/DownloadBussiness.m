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

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        if (URLs && URLs.count > 0) {
            self.storedPath = [URLs firstObject];
        }
        
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

- (void)resumeDownloadAndStored:(id<DownloadItem>)item completion:(downloadCompletion)completionHandler {
    NSURL* downloadUrl = [[NSURL alloc] initWithString:item.downloadURL];
    NSURL* destinationUrl = [self localFilePath:downloadUrl];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    __weak typeof(self) weakSelf = self;
    [self.downloadManager resumeDownload:item returnToQueue:dispatch_get_main_queue() completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, DownloadErrorByCode(UnexpectedError));
        }
        if (location) {
            NSError *saveFileError = nil;
            [fileManager copyItemAtURL:location toURL:destinationUrl error:&saveFileError];
            if (saveFileError) {
                completionHandler(nil, DownloadErrorByCode(StoreLocalError));
            } else {
                item.storedLocalPath = location;
                [weakSelf.listDownloaded addObject:item.downloadURL];
                completionHandler(location, nil);
            }
        }
    }];
}

- (NSURL*)localFilePath:(NSURL *)url {
    return [self.storedPath URLByAppendingPathComponent:url.lastPathComponent];
}

- (void)downloadAndStored:(id<DownloadItem>)item completion:(downloadCompletion)completionHandler {
    //check if file already downloaded and stored -> return path file in stored.
    NSURL* downloadUrl = [[NSURL alloc] initWithString:item.downloadURL];
    NSURL* destinationUrl = [self localFilePath:downloadUrl];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    if ([self.listDownloaded containsObject:item.downloadURL]) {
        completionHandler(destinationUrl, nil);
        return;
    }
    //if not downloaded and stored -> go download and store it to disk.
    __weak typeof(self) weakSelf = self;
    [self.downloadManager startDownload:item returnToQueue:dispatch_get_main_queue() completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, DownloadErrorByCode(UnexpectedError));
        }
        if (location) {
            NSError *saveFileError = nil;
            [fileManager copyItemAtURL:location toURL:destinationUrl error:&saveFileError];
            if (saveFileError) {
                completionHandler(location, DownloadErrorByCode(StoreLocalError));
            } else {
                item.storedLocalPath = destinationUrl;
                [weakSelf.listDownloaded addObject:item.downloadURL];
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
