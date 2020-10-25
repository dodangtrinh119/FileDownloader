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

@interface DownloadManager : NSObject

@property (nonatomic, retain) id<DownloaderProtocol> downloader;

- (void)cancelDownload:(id<DownloadableItem>)item;

- (void)pauseDownload:(id<DownloadableItem>)item;

- (void)resumeDownload:(id<DownloadableItem>)item
         returnToQueue:(dispatch_queue_t)queue
            completion:(downloadTaskCompletion)completionHandler;

- (void)startDownload:(id<DownloadableItem>)item
         withPriority:(DownloadTaskPriroity)priority
        returnToQueue:(dispatch_queue_t)queue
           completion:(downloadTaskCompletion)completionHandler;

- (void)configDownloader;

- (void)pauseAllDownloading;

- (void)resumeAllDownload;

- (DownloadStatus)getStatusOfItem:(id<DownloadableItem>)item;

- (NSURL*)localFilePath:(NSURL *)url;

- (void)setProgressUpdate:(void (^)(id<DownloadableItem> item, int64_t byteWritten, int64_t totalByte))updateProgressAtIndex;

@end

NS_ASSUME_NONNULL_END
