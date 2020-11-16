//
//  TrunkFileDownloadTask.m
//  FileDownloader
//
//  Created by LAP13976 on 11/12/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "TrunkFileDownloadTask.h"

@interface TrunkFileDownloadTask()


@end

@implementation TrunkFileDownloadTask

- (BOOL)isFinisedAllPart {
    return self.listPart.count == self.countPartDownloaded;
}

- (instancetype)initWithItem:(id<DownloadableItem>)item
                 andPriority:(DownloadTaskPriroity)priority
               andCompletion:(CompletionDownloadModel*)completion {
    self = [super init];
    if (self) {
        self.listPart = [[NSMutableArray alloc] init];
        self.downloadItem = item;
        self.countPartDownloaded = 0;
        self.taskPriority = priority;
        self.downloadType = TrunkFileDownload;
        self.observers = [[NSMutableArray alloc] init];
        [self.observers addObject:completion];
    }
    return self;
}

@synthesize downloadItem;
@synthesize downloadStatus;
@synthesize observers;
@synthesize taskPriority;
@synthesize downloadType;
@synthesize fileSize;
@synthesize progress;

@end
