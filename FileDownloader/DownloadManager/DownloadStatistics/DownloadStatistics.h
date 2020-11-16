//
//  DownloadStatistic.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/29/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NormalDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadStatistics : NSObject

@property (nonatomic, assign) NSInteger totalTaskDownloaded;
@property (nonatomic, assign) NSInteger countHighPriorityTaskDownloaded;
@property (nonatomic, assign) NSInteger countMediumPriorityTaskDownloaded;
@property (nonatomic, assign) NSInteger countLowPriorityTaskDownloaded;

- (float)currentMeidumPriorityTaskProportion;
- (float)currentHighPriorityTaskProportion;
- (float)currentLowPriorityTaskProportion;

@end

NS_ASSUME_NONNULL_END
