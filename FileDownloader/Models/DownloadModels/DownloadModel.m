//
//  DownloadModel.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadModel.h"

@interface DownloadModel ()

@end

@implementation DownloadModel

- (instancetype)initWithItem:(id<DownloadItem>)item {
    self = [super init];
    if (self) {
        self.downloadItem = item;
    }
    return self;
}

@end
