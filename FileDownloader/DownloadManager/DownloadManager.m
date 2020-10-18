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

- (void)resumeDownload:(id<DownloadItem>)item returnToQueue:(nonnull dispatch_queue_t)queue completion:(nonnull downloadTaskCompletion)completionHandler {
    [self.downloader resumeDownload:item returnToQueue:queue completion:completionHandler];
}

- (void)startDownload:(id<DownloadItem>)item returnToQueue:(nonnull dispatch_queue_t)queue completion:(nonnull downloadTaskCompletion)completionHandler {
    [self.downloader startDownload:item returnToQueue:queue completion:completionHandler];
}

- (void)configDownloader {
    [self.downloader configDownloader];
}

- (void)pauseAllDownloading {
    [self.downloader pauseAllDownloading];
}

@end
