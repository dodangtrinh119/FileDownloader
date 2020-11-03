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
#import "DownloadTask.h"
#import "NSError+DownloadError.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DownloadBussinessDelegate <NSObject>

- (void)didPausedDownload;

- (void)didResumeAllDownload;

@end

typedef void(^downloadCompletion)(NSURL * _Nullable location, NSError * _Nullable error);

@interface DownloadManager : NSObject

@property (nonatomic, weak) id<DownloadBussinessDelegate> delegate;
@property (nonatomic, strong) DownloadProvider *downloadProvider;
@property (nonatomic, strong) NSURL *storedPath;

+ (instancetype)sharedInstance;

+ (NSString *)storedDataKey;

- (NSArray *)getListDownloaded;

- (NSString *)getLocalStoredPathOfItem:(id<DownloadableItem>)item;

- (void)startDownloadItem:(id<DownloadableItem>)item
             withPriority:(DownloadTaskPriroity)priority
               completion:(downloadCompletion)completionHandler;

- (void)resumeDownloadItem:(id<DownloadableItem>)item
                completion:(downloadCompletion)completionHandler;

- (void)cancelDownloadItem:(id<DownloadableItem>)item;

- (void)pauseDownloadItem:(id<DownloadableItem>)item;

- (void)saveListDownloaded;

- (void)setDownloadProgressBlockOfItem:(void (^)(id<DownloadableItem> source, int64_t byteWritten, int64_t totalByte))updateProgressAtIndex;

- (DownloadStatus)getStatusOfModel:(id<DownloadableItem>)item;

@end

NS_ASSUME_NONNULL_END
