//
//  DownloadModel.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "CompletionDownloadModel.h"
#import "DownloadableItem.h"
#import "DownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface NormalDownloadTask : NSObject <DownloadTask>

@property (nonatomic, strong) NSURLSessionDownloadTask *task;
@property (nonatomic, strong) NSData *resumeData;

- (instancetype)initWithItem:(id<DownloadableItem>)item
                 andPriority:(DownloadTaskPriroity)priority
               andCompletion:(CompletionDownloadModel*)completion;

@end

NS_ASSUME_NONNULL_END
