//
//  DownloaderProtocol.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadableItem.h"
#import "DownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^downloadTaskCompletion)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error);

typedef void(^progressUpdateBlock)(id<DownloadableItem> item, int64_t byteWritten, int64_t totalByte);

typedef void(^resultBlock)(BOOL isSuccess);

@protocol DownloaderProtocol <NSObject>

@property (nonatomic, copy) void (^updateProgressAtIndex)(id<DownloadableItem>, int64_t byteWritten, int64_t totalByte);

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

- (void)resumeDownloadAll;

- (NSURL*)localFilePath:(NSURL *)url;

- (DownloadStatus)getStatusOfItem:(id<DownloadableItem>)item;

@end

NS_ASSUME_NONNULL_END
