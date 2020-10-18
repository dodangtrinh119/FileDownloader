//
//  DownloadModel.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, DownloadStatus) {
    Finished = 1,
    Downloading,
    Pending,
    PauseBySystem,
    Canceled,
};

@interface DownloadModel : NSObject

@property (nonatomic) DownloadStatus downloadStatus;
@property (nonatomic) float progress;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSURLSessionDownloadTask *task;
@property (nonatomic, strong) id<DownloadItem> downloadItem;

- (instancetype)initWithItem:(id<DownloadItem>)item;

@end

NS_ASSUME_NONNULL_END
