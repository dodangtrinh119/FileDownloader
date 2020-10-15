//
//  NSSessionDownloader.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "NSSessionDownloader.h"

@interface NSSessionDownloader ()

@end

@implementation NSSessionDownloader

- (void)cancelDownload:(id<DownloadItem>)item {
    //firstly check is this  already add in queue and downloading.model
    DownloadModel *downloadModel = [self.activeDownload objectForKey:item.downloadURL];
    if (!downloadModel && !downloadModel.task) {
        return;
    }
    [downloadModel.task cancel];
    
}

- (void)pauseDownload:(id<DownloadItem>)item {
    DownloadModel *downloadModel = [self.activeDownload objectForKey:item.downloadURL];
       if (!downloadModel && !downloadModel.task) {
           return;
       }
    
    [downloadModel.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        if (resumeData) {
            downloadModel.resumeData = resumeData;
        }
    }];
    downloadModel.downloadStatus = Pending;
}

//need handle to queue, multiple download...
- (void)resumeDownload:(id<DownloadItem>)item {
    DownloadModel *downloadModel = [self.activeDownload objectForKey:item.downloadURL];
    if (!downloadModel) {
        return;
    }
    NSData *resumeData = downloadModel.resumeData;
    if (resumeData) {
        
        downloadModel.task = [self.downloadSection downloadTaskWithResumeData:resumeData];
    } else {
        //todo: Imp url for download item;
        NSURL *url = [[NSURL alloc] initWithString:item.downloadURL];
        downloadModel.task = [self.downloadSection downloadTaskWithURL:url];
    }
    [downloadModel.task resume];
    downloadModel.downloadStatus = Downloading;
}

//need handle to queue, handle error of downloaded here....
// used - (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;
- (void)startDownload:(id<DownloadItem>)item {
    DownloadModel *downloadModel = [[DownloadModel alloc] initWithItem:item];
    NSURL *url = [[NSURL alloc] initWithString:item.downloadURL];
    downloadModel.task = [self.downloadSection downloadTaskWithURL:url];
    
    [downloadModel.task resume];
    downloadModel.downloadStatus = Downloading;
    [self.activeDownload setObject:downloadModel forKey:item.downloadURL];
    
}

- (void)networkStatusChanged:(NetworkStatus)status {
    switch (status) {
        case NoInternet:
            //pending all downloading, and save resumed data
            break;
        case InternetAvailable:
            //resume all downloading.
            break;
        default:
            break;
    }
}

- (void)handleError:(nonnull NSError *)error {
    //handle error here, must define error by myself.
}

- (void)configDownloader {
    
}



@end
