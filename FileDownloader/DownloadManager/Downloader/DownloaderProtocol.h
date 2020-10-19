//
//  DownloaderProtocol.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadItem.h"
#import "DownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^downloadTaskCompletion)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error);

@protocol DownloaderProtocol <NSObject>

@property (nonatomic, copy) void (^updateProgressAtIndex)(id<DownloadItem>, int64_t byteWritten, int64_t totalByte);

- (void)cancelDownload:(id<DownloadItem>)item;

- (void)pauseDownload:(id<DownloadItem>)item;

- (void)resumeDownload:(id<DownloadItem>)item returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler;

- (void)startDownload:(id<DownloadItem>)item returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler;

- (void)configDownloader;

- (void)pauseAllDownloading;

- (NSURL*)localFilePath:(NSURL *)url;

- (DownloadStatus)getStatusOfItem:(id<DownloadItem>)item;

@end

NS_ASSUME_NONNULL_END
