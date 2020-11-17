//
//  DownloadModel.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "NormalDownloadTask.h"

@interface NormalDownloadTask () <NSCoding>

@end

@implementation NormalDownloadTask

@synthesize downloadItem;
@synthesize downloadStatus;
@synthesize observers;
@synthesize taskPriority;
@synthesize downloadType;
@synthesize fileSize;
@synthesize progress;

- (instancetype)initWithItem:(id<DownloadableItem>)item
                 andPriority:(DownloadTaskPriroity)priority
               andCompletion:(CompletionDownloadModel*)completion {
    self = [super init];
    if (self) {
        self.downloadItem = item;
        self.taskPriority = priority;
        self.fileSize = -1;
        self.observers = [[NSMutableArray alloc] init];
        [self.observers addObject:completion];
        self.downloadType = NormalDownload;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[NSNumber numberWithLongLong:fileSize] forKey:@"fileSize"];
    [coder encodeObject:self.resumeData forKey:@"resumeData"];
    [coder encodeInteger:NormalDownload forKey:@"downloadType"];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];

    if (self) {
        self.downloadType = [coder decodeIntegerForKey:@"downloadType"];
        NSNumber *fileSize = [coder decodeObjectForKey:@"fileSize"];
        self.fileSize = fileSize.longLongValue;
        self.resumeData = [coder decodeObjectForKey:@"resumeData"];
    }
    return self;
}

@end
