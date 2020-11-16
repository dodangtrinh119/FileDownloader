//
//  DownloadTask.h
//  FileDownloader
//
//  Created by LAP13976 on 11/12/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadableItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, DownloadStatus) {
    DownloadFinished = 1,
    DownloadStatusDownloading = 2,
    DownloadPending = 3,
    DownloadPauseBySystem = 4,
    DownloadCanceled = 5,
    DownloadWaiting = 6,
    DownloadError = 7,
    DownloadUnknown = 8,
};

typedef NS_ENUM(NSInteger, DownloadTaskPriroity) {
    DownloadTaskPriroityLow = 1,                         // Low
    DownloadTaskPriroityMedium = 2,                      // Medium
    DownloadTaskPriroityHigh = 3,                        // High
};

typedef NS_ENUM(NSInteger, DownloadTaskType) {
    NormalDownload = 1,                         // Low
    TrunkFileDownload = 2,                      // Medium
};

@protocol DownloadTask <NSObject>

@property (nonatomic, assign) long long fileSize;
@property (nonatomic, assign) DownloadStatus downloadStatus;
@property (nonatomic, assign) DownloadTaskPriroity taskPriority;
@property (nonatomic, strong) id<DownloadableItem> downloadItem;
@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign) DownloadTaskType downloadType;

@end

NS_ASSUME_NONNULL_END
