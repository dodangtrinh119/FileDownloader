//
//  DownloadItem.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DownloadItem <NSObject>

@property (nonatomic, strong) NSString *downloadURL;

@end

NS_ASSUME_NONNULL_END
