//
//  NSSessionDownloader.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "NSSessionDownloader.h"
#import "AppDelegate.h"
#import "CompletionDownloadModel.h"
#import "NSError+DownloadManager.h"

@interface NSSessionDownloader () <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSMutableDictionary *activeDownload;
@property (nonatomic, strong) dispatch_queue_t downloaderQueue;
@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, strong) NSURL *storedPath;

@end

@implementation NSSessionDownloader

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        if (URLs && URLs.count > 0) {
            self.storedPath = [URLs firstObject];
        }
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
    downloadModel.downloadStatus = Canceled;
    [downloadModel.task cancel];
}

- (void)pauseDownload:(id<DownloadItem>)item {
    DownloadModel *downloadModel = [self.activeDownload objectForKey:item.downloadURL];
       if (!downloadModel && !downloadModel.task) {
           return;
       }
    downloadModel.downloadStatus = Pending;

    [downloadModel.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        if (resumeData) {
            downloadModel.resumeData = resumeData;
        }
    }];
}

- (void)resumeDownload:(id<DownloadItem>)item returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler {
    DownloadModel *downloadModel = [self.activeDownload objectForKey:item.downloadURL];
    NSURL *url = [[NSURL alloc] initWithString:item.downloadURL];
    if (!downloadModel) {
        [self returnForAllTask:url storedLocation:nil response:nil error:DownloadErrorByCode(UnexpectedError)];
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        CompletionDownloadModel *completionModel = [[CompletionDownloadModel alloc] initWithSourceUrl:url completion:completionHandler andReturnQueue:queue];
        if (weakSelf.observers.count > 0 && [self.activeDownload objectForKey:item.downloadURL]) {
            [weakSelf.observers addObject:completionModel];
            return;
        } else {
            [weakSelf.observers addObject:completionModel];
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
        
    });
    
}

- (void)startDownload:(id<DownloadItem>)item returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler {
    __weak typeof(self) weakSelf = self;
    NSURL *url = [[NSURL alloc] initWithString:item.downloadURL];
    DownloadModel *downloadModel;
    if ([weakSelf.activeDownload objectForKey:item.downloadURL]) {
        downloadModel = [self.activeDownload objectForKey:item.downloadURL];
    } else {
        downloadModel = [[DownloadModel alloc] initWithItem:item];
        [weakSelf.activeDownload setObject:downloadModel forKey:item.downloadURL];
    }
    downloadModel.downloadStatus = Downloading;

    dispatch_async(self.downloaderQueue, ^{
        
        CompletionDownloadModel *completionModel = [[CompletionDownloadModel alloc] initWithSourceUrl:url completion:completionHandler andReturnQueue:queue];
        if (weakSelf.observers.count > 0 && [self.activeDownload objectForKey:item.downloadURL]) {
            [weakSelf.observers addObject:completionModel];
            return;
        } else {
            [weakSelf.observers addObject:completionModel];
        }
        
        downloadModel.task = [self.downloadSection downloadTaskWithURL:url];
  
        [downloadModel.task resume];
        
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
        [self returnForAllTask:sourceUrl storedLocation:nil response:nil error:DownloadErrorByCode(UnexpectedError)];
    }
}

- (NSURL*)localFilePath:(NSURL *)url {
    return [self.storedPath URLByAppendingPathComponent:url.lastPathComponent];
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSURL *sourceUrl = downloadTask.originalRequest.URL;
    if (sourceUrl) {
        if (location) {
            NSURL* destinationUrl = [self localFilePath:sourceUrl];
            NSFileManager *fileManager = NSFileManager.defaultManager;
            NSError *saveFileError = nil;
            [fileManager copyItemAtURL:location toURL:destinationUrl error:&saveFileError];
            if (saveFileError) {
                [self returnForAllTask:sourceUrl storedLocation:location response:nil error:DownloadErrorByCode(StoreLocalError)];
            } else {
                [self returnForAllTask:sourceUrl storedLocation:destinationUrl response:nil error:nil];
            }
        }
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (appDelegate) {
            void(^completion)(void) = appDelegate.backgroundTransferCompletionHandler;
            appDelegate.backgroundTransferCompletionHandler = nil;
            completion();
        }
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSURL *sourceUrl = downloadTask.originalRequest.URL;
    NSString *key = [sourceUrl absoluteString];
    DownloadModel *downloadModel = [self.activeDownload objectForKey:key];
    if (self.updateProgressAtIndex && downloadModel) {
        self.updateProgressAtIndex(downloadModel.downloadItem, totalBytesWritten, totalBytesExpectedToWrite);
    }

}

@synthesize updateProgressAtIndex;

@end


