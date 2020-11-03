//
//  DownloadModel.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadTask.h"

@interface DownloadTask ()

@end

@implementation DownloadTask

- (instancetype)initWithItem:(id<DownloadableItem>)item {
    self = [super init];
    if (self) {
        self.downloadItem = item;
        self.taskPriority = DownloadTaskPriroityLow;
    }
    return self;
}

- (instancetype)initWithItem:(id<DownloadableItem>)item andPriority:(DownloadTaskPriroity)priority {
    self = [super init];
    if (self) {
        self.downloadItem = item;
        self.taskPriority = priority;
    }
    return self;
}

@end
