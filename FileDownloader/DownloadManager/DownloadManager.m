//
//  DownloadManager.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadManager.h"
#import "NSSessionDownloader.h"

@implementation DownloadManager

+ (instancetype)sharedInstance {
    static DownloadManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DownloadManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.downloader = [[NSSessionDownloader alloc] init];
    }
    return self;
}

- (void)cancelDownload:(id<DownloadItem>)item {
    [self.downloader cancelDownload:item];
}

- (void)pauseDownload:(id<DownloadItem>)item {
    [self.downloader pauseDownload:item];
}

- (void)resumeDownload:(id<DownloadItem>)item {
    [self.downloader resumeDownload:item];
}

- (void)startDownload:(id<DownloadItem>)item {
    [self.downloader startDownload:item];
}

- (void)networkStatusChanged:(NetworkStatus)status {
    [self.downloader networkStatusChanged:status];
}

- (void)handleError:(NSError *)error {
    [self.downloader handleError:error];
}

- (void)configDownloader {
    [self.downloader configDownloader];
}


@end
