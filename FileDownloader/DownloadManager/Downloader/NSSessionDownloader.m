//
//  NSSessionDownloader.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "NSSessionDownloader.h"
#import "CompletionDownloadModel.h"

@interface NSSessionDownloader () <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSMutableDictionary *activeDownload;
@property (nonatomic, strong) dispatch_queue_t downloaderQueue;
@property (nonatomic, strong) NSMutableArray *observers;

@end


@implementation NSSessionDownloader

- (instancetype)init {
    self = [super init];
    if (self) {
        self.downloaderQueue = dispatch_queue_create("downloaderQueue", DISPATCH_QUEUE_SERIAL);
        self.observers = [[NSMutableArray alloc] init];
        self.activeDownload = [[NSMutableDictionary alloc] init];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"dangtrinh.downloadfile"];
        self.downloadSection = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    }
    return self;
}

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

- (void)resumeDownload:(id<DownloadItem>)item returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler {
    DownloadModel *downloadModel = [self.activeDownload objectForKey:item.downloadURL];
    if (!downloadModel) {
        return;
    }
    NSData *resumeData = downloadModel.resumeData;
    if (resumeData) {
        downloadModel.task = [self.downloadSection downloadTaskWithResumeData:resumeData completionHandler:completionHandler];
    } else {
        //todo: Imp url for download item;
        NSURL *url = [[NSURL alloc] initWithString:item.downloadURL];
        downloadModel.task = [self.downloadSection downloadTaskWithURL:url completionHandler:completionHandler];
    }
    [downloadModel.task resume];
    downloadModel.downloadStatus = Downloading;
}

- (void)startDownload:(id<DownloadItem>)item returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler {
    __weak typeof(self) weakSelf = self;
    NSURL *url = [[NSURL alloc] initWithString:item.downloadURL];
    dispatch_async(self.downloaderQueue, ^{
        
        CompletionDownloadModel *completionModel = [[CompletionDownloadModel alloc] initWithSourceUrl:url completion:completionHandler andReturnQueue:queue];
        if (weakSelf.observers.count > 0 && [self.activeDownload objectForKey:item.downloadURL]) {
            [weakSelf.observers addObject:completionModel];
            return;
        } else {
            [weakSelf.observers addObject:completionModel];
        }
        
        DownloadModel *downloadModel;
        if ([weakSelf.activeDownload objectForKey:item.downloadURL]) {
            downloadModel = [self.activeDownload objectForKey:item.downloadURL];
        } else {
            downloadModel = [[DownloadModel alloc] initWithItem:item];
            [weakSelf.activeDownload setObject:downloadModel forKey:item.downloadURL];
        }
        
        downloadModel = [[DownloadModel alloc] initWithItem:item];
        downloadModel.task = [self.downloadSection downloadTaskWithURL:url];
  
        [downloadModel.task resume];
        
        downloadModel.downloadStatus = Downloading;
    });
}

- (void)returnForAllTask:(NSURL *)source storedLocation:(NSURL*)location response:(NSURLResponse *)response error:(NSError*)error {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        if (!weakSelf.observers && weakSelf.observers.count == 0) {
            return;
        }
        for (NSInteger index = 0; index < weakSelf.observers.count; index++) {
            CompletionDownloadModel *completionModel = [weakSelf.observers objectAtIndex:index];
            if (completionModel.sourceUrl == source) {
                downloadTaskCompletion block = completionModel.completionHandler;
                dispatch_queue_t queue = completionModel.returnQueues;
                if (queue && block) {
                    dispatch_async(queue, ^{
                        block(location, response, error);
                        [weakSelf.observers removeObjectAtIndex:index];
                    });
                }
            }
        }
    });
}

- (void)pauseAllDownloading {
     for (DownloadModel *model in self.activeDownload) {
         if (model.downloadStatus == Downloading) {
             [model.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                 if (resumeData) {
                     model.resumeData = resumeData;
                 }
             }];
             model.downloadStatus = PauseBySystem;
         }
     }
}

- (void)configDownloader {
   
}

- (DownloadStatus)getStatusOfItem:(id<DownloadItem>)item {
    DownloadModel *downloadModel = [self.activeDownload objectForKey:item.downloadURL];
    if (downloadModel) {
        return downloadModel.downloadStatus;
    }
    return Unknown;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error) {
        return;
    }
    NSURL *sourceUrl = task.originalRequest.URL;
    if (sourceUrl) {
        [self returnForAllTask:sourceUrl storedLocation:nil response:nil error:error];
    }
    //downloadModel.task = [self.downloadSection downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
     //     [weakSelf returnForAllTask:location response:response error:error];
      //}];
    
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSURL *sourceUrl = downloadTask.originalRequest.URL;
       if (sourceUrl) {
           [self returnForAllTask:sourceUrl storedLocation:location response:nil error:nil];
       }
}

@end


