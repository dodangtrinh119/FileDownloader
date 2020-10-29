//
//  DownloadManager.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadProvider.h"
#import "NSSessionDownloader.h"

@implementation DownloadProvider

- (instancetype)init {
    self = [super init];
    if (self) {
        self.downloader = [[NSSessionDownloader alloc] init];
    }
    return self;
}

- (void)setDownloadProgressBlockOfItem:(void (^)(id<DownloadableItem> item, int64_t byteWritten, int64_t totalByte))updateProgressAtIndex {
    self.downloader.updateProgressAtIndex = updateProgressAtIndex;
}

- (NSURL *)localFilePathOfUrl:(NSURL *)url {
    return [self.downloader localFilePath:url];
}

- (void)cancelDownloadItem:(id<DownloadableItem>)item {
    [self.downloader cancelDownload:item];
}

- (void)pauseDownloadItem:(id<DownloadableItem>)item {
    [self.downloader pauseDownload:item];
}

- (void)resumeDownloadItem:(id<DownloadableItem>)item
         returnToQueue:(dispatch_queue_t)queue
            completion:(downloadTaskCompletion)completionHandler {
    [self.downloader resumeDownload:item
                      returnToQueue:queue
                         completion:completionHandler];
}

- (void)startDownloadItem:(id<DownloadableItem>)item
         withPriority:(DownloadTaskPriroity)priority
        returnToQueue:(dispatch_queue_t)queue
           completion:(downloadTaskCompletion)completionHandler {
    [self.downloader startDownload:item
                      withPriority:priority
                     returnToQueue:queue
                        completion:completionHandler];
}

- (void)configDownloader {
    [self.downloader configDownloader];
}

- (void)pauseAllDownloading {
    [self.downloader pauseAllDownloading];
}

- (void)resumeAllDownload {
    [self.downloader resumeDownloadAll];
}

- (DownloadStatus)getStatusOfItem:(id<DownloadableItem>)item {
    return [self.downloader getStatusOfItem:item];
}

@end
