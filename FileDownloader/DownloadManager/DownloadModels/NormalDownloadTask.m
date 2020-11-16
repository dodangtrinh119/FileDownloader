//
//  DownloadModel.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "NormalDownloadTask.h"

@interface NormalDownloadTask ()

@end

@implementation NormalDownloadTask

@synthesize downloadItem;
@synthesize downloadStatus;
@synthesize observers;
@synthesize taskPriority;
@synthesize downloadType;

- (instancetype)initWithItem:(id<DownloadableItem>)item
                 andPriority:(DownloadTaskPriroity)priority
               andCompletion:(CompletionDownloadModel*)completion {
    self = [super init];
    if (self) {
        self.downloadItem = item;
        self.taskPriority = priority;
        self.observers = [[NSMutableArray alloc] init];
        [self.observers addObject:completion];
        self.downloadType = NormalDownload;
    }
    return self;
}

@end
