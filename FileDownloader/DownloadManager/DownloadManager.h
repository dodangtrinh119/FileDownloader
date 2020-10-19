//
//  DownloadManager.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloaderProtocol.h"
#import "DownloadItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadManager : NSObject

@property (nonatomic, retain) id<DownloaderProtocol> downloader;

- (void)cancelDownload:(id<DownloadItem>)item;

- (void)pauseDownload:(id<DownloadItem>)item;

- (void)resumeDownload:(id<DownloadItem>)item returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler;

- (void)startDownload:(id<DownloadItem>)item returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler;

- (void)configDownloader;

- (void)pauseAllDownloading;

- (DownloadStatus)getStatusOfItem:(id<DownloadItem>)item;

- (NSURL*)localFilePath:(NSURL *)url;

- (void)setProgressUpdate:(void (^)(id<DownloadItem> item, int64_t byteWritten, int64_t totalByte))updateProgressAtIndex;



@end

NS_ASSUME_NONNULL_END
