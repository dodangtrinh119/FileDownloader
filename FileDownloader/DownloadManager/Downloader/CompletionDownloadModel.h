//
//  CompletionDownloadModel.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/17/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloaderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface CompletionDownloadModel : NSObject

@property (nonatomic, strong) downloadTaskCompletion completionHandler;
@property (nonatomic, strong) dispatch_queue_t returnQueue;
@property (nonatomic, strong) NSURL* sourceUrl;

- (instancetype)initWithSourceUrl:(NSURL*)source completion:(downloadTaskCompletion)completion andReturnQueue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
