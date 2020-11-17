//
//  DownloadManager.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadableItem.h"
#import "DownloaderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadProvider : NSObject

@property (nonatomic, retain) id<DownloaderProtocol> downloader;

- (void)cancelDownloadItem:(id<DownloadableItem>)item;

- (void)pauseDownloadItem:(id<DownloadableItem>)item;

- (void)resumeDownloadItem:(id<DownloadableItem>)item
         returnToQueue:(dispatch_queue_t)queue
            completion:(downloadTaskCompletion)completion;

- (void)startDownloadItem:(id<DownloadableItem>)item
      isTrunkFileDownload:(BOOL)isTrunkFile
             withPriority:(DownloadTaskPriroity)priority
            returnToQueue:(dispatch_queue_t)queue
    downloadProgressBlock:(downloadProgressBlock)progressBlock
               completion:(downloadTaskCompletion)completion
           ;

- (void)configDownloader;

- (void)pauseAllDownloadingItem;

- (void)resumeAllPausingItem;

- (void)addDownloadObserver:(id<DownloaderObserverProtocol>)downloaderObserver;

- (DownloadStatus)getStatusOfItem:(id<DownloadableItem>)item;

- (NSURL*)localFilePathOfUrl:(NSURL *)url;

- (void)createNormalDownloadTaskWithItem:(id<DownloadableItem>)item
               withResumeData:(NSData*)resumeData
                 withPriority:(DownloadTaskPriroity)priority
                returnToQueue:(dispatch_queue_t)queue
        downloadProgressBlock:(downloadProgressBlock)progressBlock
                   completion:(downloadTaskCompletion)completion;

- (void)createTrunkFileDownloadTaskWithItem:(id<DownloadableItem>)item
                             withData:(NSData*)taskData
                               withPriority:(DownloadTaskPriroity)priority
                              returnToQueue:(dispatch_queue_t)queue
                      downloadProgressBlock:(downloadProgressBlock)progressBlock
                                 completion:(downloadTaskCompletion)completion;
@end

NS_ASSUME_NONNULL_END
