//
//  DownloadBussiness.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/18/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadManager.h"
#import "DownloadableItem.h"
#import "DownloadTask.h"
#import "NSError+DownloadManager.h"

@protocol DownloadBussinessDelegate <NSObject>

- (void)didPausedDownload;

- (void)didResumeAllDownload;

@end

NS_ASSUME_NONNULL_BEGIN

typedef void(^downloadCompletion)(NSURL * _Nullable location, NSError * _Nullable error);

@interface DownloadBussiness : NSObject

@property (nonatomic, weak) id<DownloadBussinessDelegate> delegate;
@property (nonatomic, strong) DownloadManager *downloadManager;
@property (nonatomic, strong) NSURL *storedPath;

+ (instancetype)sharedInstance;

+ (NSString *)storedDataKey;

-(NSArray *)getListStored;

- (NSString *)getLocalStoredPathOfItem:(id<DownloadableItem>)item;

- (void)downloadAndStored:(id<DownloadableItem>)item completion:(downloadCompletion)completionHandler;

- (void)resumeDownloadAndStored:(id<DownloadableItem>)item completion:(downloadCompletion)completionHandler;

- (void)cancelDownload:(id<DownloadableItem>)item;

- (void)pauseDownload:(id<DownloadableItem>)item;

- (void)saveListDownloaded;

- (void)setProgressUpdate:(void (^)(id<DownloadableItem> source, int64_t byteWritten, int64_t totalByte))updateProgressAtIndex;

- (DownloadStatus)getStatusOfModel:(id<DownloadableItem>)item;

@end

NS_ASSUME_NONNULL_END
