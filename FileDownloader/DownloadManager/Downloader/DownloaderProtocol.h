//
//  DownloaderProtocol.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, NetworkStatus) {
    NoInternet = -50000,
    InternetAvailable = -50001,
};

@protocol DownloaderProtocol <NSObject>

- (void)cancelDownload:(id<DownloadItem>)item;

- (void)pauseDownload:(id<DownloadItem>)item;

- (void)resumeDownload:(id<DownloadItem>)item;

- (void)startDownload:(id<DownloadItem>)item;

- (void)networkStatusChanged:(NetworkStatus)status;

- (void)handleError:(NSError *)error;

- (void)configDownloader;

@end

NS_ASSUME_NONNULL_END
