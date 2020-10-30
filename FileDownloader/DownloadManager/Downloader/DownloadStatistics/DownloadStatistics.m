//
//  DownloadStatistic.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/29/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadStatistics.h"

@implementation DownloadStatistics


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.countHighPriorityTaskDownloaded = 0;
        self.countLowPriorityTaskDownloaded = 0;
        self.countMediumPriorityTaskDownloaded = 0;
        self.totalTaskDownloaded = 0;
    }
    return self;
}

- (float)currentLowPriorityTaskProportion {
    return self.totalTaskDownloaded == 0 ? 0 : (float)self.countLowPriorityTaskDownloaded / (float)self.totalTaskDownloaded;
}

- (float)currentHighPriorityTaskProportion {
    return self.totalTaskDownloaded == 0 ? 0 : (float)self.countHighPriorityTaskDownloaded / (float)self.totalTaskDownloaded;
}

- (float)currentMeidumPriorityTaskProportion {
    return self.totalTaskDownloaded == 0 ? 0 : (float)self.countMediumPriorityTaskDownloaded / (float)self.totalTaskDownloaded;
}

@end
