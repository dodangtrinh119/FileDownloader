//
//  CompletionDownloadModel.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/17/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "CompletionDownloadModel.h"

@implementation CompletionDownloadModel

- (instancetype)initWithCompletion:(downloadTaskCompletion)completion andReturnQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        self.completionHandler = completion;
        self.returnQueues = queue;
    }
    return self;
}

@end
