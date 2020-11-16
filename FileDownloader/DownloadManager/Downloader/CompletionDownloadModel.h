//
//  CompletionDownloadModel.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/17/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadableItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^downloadTaskCompletion)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error);

typedef void(^downloadProgressBlock)(id<DownloadableItem> item, int64_t byteWritten, int64_t totalByte);


@interface CompletionDownloadModel : NSObject

@property (nonatomic, strong) downloadTaskCompletion completionHandler;
@property (nonatomic, strong) dispatch_queue_t returnQueue;
@property (nonatomic, strong) NSURL* sourceUrl;
@property (nonatomic, strong) downloadProgressBlock progressBlock;


- (instancetype)initWithSourceUrl:(NSURL*)source
                       completion:(downloadTaskCompletion)completion
                   andReturnQueue:(dispatch_queue_t)queue
            downloadProgressBlock:(downloadProgressBlock)progressBlock;

@end

NS_ASSUME_NONNULL_END
