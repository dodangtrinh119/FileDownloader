//
//  DownloadModel.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
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

@interface DownloadTask : NSObject

@property (nonatomic, assign) DownloadStatus downloadStatus;
@property (nonatomic, assign) DownloadTaskPriroity taskPriority;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSURLSessionDownloadTask *task; 
@property (nonatomic, strong) id<DownloadableItem> downloadItem;

- (instancetype)initWithItem:(id<DownloadableItem>)item;

- (instancetype)initWithItem:(id<DownloadableItem>)item andPriority:(DownloadTaskPriroity)priority;

@end

NS_ASSUME_NONNULL_END
