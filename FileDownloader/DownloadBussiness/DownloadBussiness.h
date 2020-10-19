//
//  DownloadBussiness.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/18/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadManager.h"
#import "DownloadItem.h"
#import "DownloadModel.h"
#import "NSError+DownloadManager.h"

@protocol DownloadBussinessDelegate <NSObject>

- (void)didPausedDownloadBySystem;

@end

NS_ASSUME_NONNULL_BEGIN

typedef void(^downloadCompletion)(NSURL * _Nullable location, NSError * _Nullable error);


@interface DownloadBussiness : NSObject

@property (nonatomic, weak) id<DownloadBussinessDelegate> delegate;
@property (nonatomic, strong) DownloadManager *downloadManager;
@property (nonatomic, strong) NSURL *storedPath;

+ (instancetype)sharedInstance;

+ (NSString *)storedDataKey;

- (void)downloadAndStored:(id<DownloadItem>)item completion:(downloadCompletion)completionHandler;

- (void)resumeDownloadAndStored:(id<DownloadItem>)item completion:(downloadCompletion)completionHandler;

- (void)saveListDownloaded;

- (void)cancelDownload:(id<DownloadItem>)item;

- (void)pauseDownload:(id<DownloadItem>)item;

- (NSURL*)localFilePath:(NSURL *)url;

- (DownloadStatus)getStatusOfModel:(id<DownloadItem>)item;

@end

NS_ASSUME_NONNULL_END
