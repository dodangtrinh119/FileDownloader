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

- (NSURL *)localFilePathOfUrl:(NSURL *)url {
    return [self.downloader localFilePathOfUrl:url];
}

- (void)cancelDownloadItem:(id<DownloadableItem>)item {
    [self.downloader cancelDownloadItem:item];
}

- (void)pauseDownloadItem:(id<DownloadableItem>)item {
    [self.downloader pauseDownloadItem:item];
}

- (void)resumeDownloadItem:(id<DownloadableItem>)item
         returnToQueue:(dispatch_queue_t)queue
            completion:(downloadTaskCompletion)completionHandler {
    [self.downloader resumeDownloadItem:item
                      returnToQueue:queue
                         completion:completionHandler];
}

- (void)startDownloadItem:(id<DownloadableItem>)item
      isTrunkFileDownload:(BOOL)isTrunkFile
             withPriority:(DownloadTaskPriroity)priority
            returnToQueue:(dispatch_queue_t)queue
    downloadProgressBlock:(downloadProgressBlock)progressBlock
               completion:(downloadTaskCompletion)completion {
    [self.downloader startDownloadItem:item
                   isTrunkFileDownload:isTrunkFile
                          withPriority:priority
                         returnToQueue:queue
                 downloadProgressBlock:progressBlock
                            completion:completion];
}

- (void)configDownloader {
    [self.downloader configDownloader];
}

- (void)pauseAllDownloadingItem {
    [self.downloader pauseAllDownloadingItem];
}

- (void)resumeAllPausingItem {
    [self.downloader resumeAllPausingItem];
}

- (DownloadStatus)getStatusOfItem:(id<DownloadableItem>)item {
    return [self.downloader getStatusOfItem:item];
}

- (void)createNormalDownloadTaskWithItem:(id<DownloadableItem>)item withResumeData:(NSData *)resumeData withPriority:(DownloadTaskPriroity)priority returnToQueue:(dispatch_queue_t)queue downloadProgressBlock:(downloadProgressBlock)progressBlock completion:(downloadTaskCompletion)completion {
    [self.downloader createNormalDownloadTaskWithItem:item withResumeData:resumeData withPriority:priority returnToQueue:queue downloadProgressBlock:progressBlock completion:completion];
}

- (void)createTrunkFileDownloadTaskWithItem:(id<DownloadableItem>)item withData:(NSDictionary *)taskData withPriority:(DownloadTaskPriroity)priority returnToQueue:(dispatch_queue_t)queue downloadProgressBlock:(downloadProgressBlock)progressBlock completion:(downloadTaskCompletion)completion {
    [self.downloader createTrunkFileDownloadTaskWithItem:item withData:taskData withPriority:priority returnToQueue:queue downloadProgressBlock:progressBlock completion:completion];
}

- (void)addDownloadObserver:(id<DownloaderObserverProtocol>)downloaderObserver {
    [self.downloader addDownloadObserver:downloaderObserver];
}

@end
