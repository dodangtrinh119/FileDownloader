//
//  DownloaderProtocol.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadableItem.h"
#import "NormalDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^downloadTaskCompletion)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error);

typedef void(^downloadProgressBlock)(id<DownloadableItem> item, int64_t byteWritten, int64_t totalByte);

typedef void(^resultBlock)(BOOL isSuccess);

typedef void(^getItemSizeBlock)(NSInteger itemSize, NSError *error);

@protocol DownloaderObserverProtocol <NSObject>

- (void)didPausedDownload;

- (void)didResumeAllDownload;

- (void)hasPausingNormalDownloadTaskWith:(NSURL*)url withResumeData:(NSData*)resumeData;

- (void)hasPausingTrunkFileDownloadDataWithUrl:(NSURL*)url withDownloadData:(NSDictionary*)trunkFileData;

@end

@protocol DownloaderProtocol <NSObject>

- (void)cancelDownloadItem:(id<DownloadableItem>)item;

- (void)pauseDownloadItem:(id<DownloadableItem>)item;

- (void)resumeDownloadItem:(id<DownloadableItem>)item
         returnToQueue:(dispatch_queue_t)queue
            completion:(downloadTaskCompletion)completionHandler;

- (void)startDownloadItem:(id<DownloadableItem>)item
      isTrunkFileDownload:(BOOL)isTrunkFile
             withPriority:(DownloadTaskPriroity)priority
            returnToQueue:(dispatch_queue_t)queue
    downloadProgressBlock:(downloadProgressBlock)progressBlock
               completion:(downloadTaskCompletion)completion;

- (void)configDownloader;

- (void)pauseAllDownloadingItem;

- (void)resumeAllPausingItem;

- (NSURL*)localFilePathOfUrl:(NSURL *)url;

- (DownloadStatus)getStatusOfItem:(id<DownloadableItem>)item;

- (void)createNormalDownloadTaskWithItem:(id<DownloadableItem>)item
               withResumeData:(NSData*)resumeData
                 withPriority:(DownloadTaskPriroity)priority
                returnToQueue:(dispatch_queue_t)queue
        downloadProgressBlock:(downloadProgressBlock)progressBlock
                   completion:(downloadTaskCompletion)completion;

- (void)createTrunkFileDownloadTaskWithItem:(id<DownloadableItem>)item
                                   withData:(NSDictionary*)taskData
                               withPriority:(DownloadTaskPriroity)priority
                              returnToQueue:(dispatch_queue_t)queue
                      downloadProgressBlock:(downloadProgressBlock)progressBlock
                                 completion:(downloadTaskCompletion)completion;

- (void)addDownloadObserver:(id<DownloaderObserverProtocol>)downloaderObserver;

@end

NS_ASSUME_NONNULL_END
