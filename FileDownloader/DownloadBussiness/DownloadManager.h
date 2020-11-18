//
//  DownloadBussiness.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/18/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadProvider.h"
#import "DownloadableItem.h"
#import "NormalDownloadTask.h"
#import "NSError+DownloadError.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^downloadCompletion)(NSURL * _Nullable location, NSError * _Nullable error);

@interface DownloadManager : NSObject

+ (instancetype)sharedInstance;

+ (NSString *)storedDataKey;

- (NSArray *)getListItemDownloaded;

- (NSString *)getLocalStoredPathOfItem:(id<DownloadableItem>)item;

- (void)startDownloadItem:(id<DownloadableItem>)item
      isTrunkFileDownload:(BOOL)isTrunkFile
             withPriority:(DownloadTaskPriroity)priority
    downloadProgressBlock:(downloadProgressBlock)progressBlock
               completion:(downloadCompletion)completionHandler;

- (void)resumeDownloadItem:(id<DownloadableItem>)item
                completion:(downloadCompletion)completionHandler;

- (void)cancelDownloadItem:(id<DownloadableItem>)item;

- (void)pauseDownloadItem:(id<DownloadableItem>)item completion:(completionBlock)completion;

- (void)saveListItemDownloaded;

- (DownloadStatus)getStatusOfModel:(id<DownloadableItem>)item;

- (void)addObserverForDownloader:(id<DownloaderObserverProtocol>)downloaderObserver;

- (void)createNormalDownloadTaskWithItem:(id<DownloadableItem>)item
               withResumeData:(NSData*)resumeData
                 withPriority:(DownloadTaskPriroity)priority
        downloadProgressBlock:(downloadProgressBlock)progressBlock
                   completion:(downloadTaskCompletion)completionHandler;

- (void)createTrunkFileDownloadTaskWithItem:(id<DownloadableItem>)item
                             withData:(NSData*)taskData
                               withPriority:(DownloadTaskPriroity)priority
                      downloadProgressBlock:(downloadProgressBlock)progressBlock
                                 completion:(downloadTaskCompletion)completion;

@end

NS_ASSUME_NONNULL_END
