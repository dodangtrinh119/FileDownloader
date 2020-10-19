//
//  NSSessionDownloader.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadModel.h"
#import "DownloaderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSSessionDownloader : NSObject <DownloaderProtocol>

@property (nonatomic, strong) NSURLSession *downloadSection;

@end

NS_ASSUME_NONNULL_END
