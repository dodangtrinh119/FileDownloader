//
//  TrunkFileDownloadTask.h
//  FileDownloader
//
//  Created by LAP13976 on 11/12/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadTask.h"
#import "DownloadPartData.h"
#import "DownloadableItem.h"
#import "CompletionDownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TrunkFileDownloadTask : NSObject <DownloadTask>

@property (nonatomic, assign) NSInteger countPartDownloaded;
@property (nonatomic, strong) NSMutableArray<DownloadPartData *> *listPart;

- (instancetype)initWithItem:(id<DownloadableItem>)item
                 andPriority:(DownloadTaskPriroity)priority
               andCompletion:(CompletionDownloadModel*)completion;

- (BOOL)isFinisedAllPart;


@end

NS_ASSUME_NONNULL_END
