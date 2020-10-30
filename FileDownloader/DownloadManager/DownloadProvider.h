//
//  DownloadManager.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloaderProtocol.h"
#import "DownloadableItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadProvider : NSObject

@property (nonatomic, retain) id<DownloaderProtocol> downloader;

- (void)cancelDownloadItem:(id<DownloadableItem>)item;

- (void)pauseDownloadItem:(id<DownloadableItem>)item;

- (void)resumeDownloadItem:(id<DownloadableItem>)item
         returnToQueue:(dispatch_queue_t)queue
            completion:(downloadTaskCompletion)completion;

- (void)startDownloadItem:(id<DownloadableItem>)item
         withPriority:(DownloadTaskPriroity)priority
        returnToQueue:(dispatch_queue_t)queue
           completion:(downloadTaskCompletion)completionHandler;

- (void)configDownloader;

- (void)pauseAllDownloadingItem;

- (void)resumeAllPausingItem;

- (DownloadStatus)getStatusOfItem:(id<DownloadableItem>)item;

- (NSURL*)localFilePathOfUrl:(NSURL *)url;

- (void)setDownloadProgressBlockOfItem:(void (^)(id<DownloadableItem> item, int64_t byteWritten, int64_t totalByte))updateProgressAtIndex;

@end

NS_ASSUME_NONNULL_END
