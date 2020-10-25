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

#define RAND_FROM_TO(min, max) (min + arc4random_uniform(max - min + 1))


@interface NSSessionDownloader () <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSMutableDictionary *activeDownload;
@property (nonatomic, strong) dispatch_queue_t downloaderQueue;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, strong) NSURL *storedPath;
@property (nonatomic, assign) NSInteger maximumDownload;
@property (nonatomic, assign) NSInteger currentDownload;

@property (nonatomic, strong) NSMutableArray *highPriorityDownloadItems;
@property (nonatomic, strong) NSMutableArray *mediumPriorityDownloadItems;
@property (nonatomic, strong) NSMutableArray *lowPriorityDownloadItems;

@end

@implementation NSSessionDownloader

@synthesize updateProgressAtIndex;

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        if (URLs && URLs.count > 0) {
            self.storedPath = [URLs firstObject];
        }
        self.downloaderQueue = dispatch_queue_create("downloaderQueue", DISPATCH_QUEUE_SERIAL);
        self.observers = [[NSMutableDictionary alloc] init];
        self.activeDownload = [[NSMutableDictionary alloc] init];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"dangtrinh.downloadfile"];
        self.downloadSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        
        self.maximumDownload = 1;
        self.currentDownload = 0;
        
        self.highPriorityDownloadItems = [[NSMutableArray alloc] init];
        self.mediumPriorityDownloadItems = [[NSMutableArray alloc] init];
        self.lowPriorityDownloadItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)cancelDownload:(id<DownloadableItem>)item {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        //firstly check is this  already add in queue and downloading.model
        NSString *keyForItem = [item.downloadURL absoluteString];
        DownloadTask *downloadTask = [weakSelf.activeDownload objectForKey:keyForItem];
        if (!downloadTask || !downloadTask.task) {
            return;
        }
        
        NSMutableArray *listObserverForItem = [weakSelf.observers objectForKey:keyForItem];
        if (listObserverForItem && listObserverForItem.count > 0) {
            [listObserverForItem removeAllObjects];
        }
        
        // cancel download task, update status.
        weakSelf.currentDownload --;
        downloadTask.downloadStatus = DownloadCanceled;
        [downloadTask.task cancel];
        [self downloadItemInWaitingQueue];
    });
}

- (void)pauseDownload:(id<DownloadableItem>)item {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        DownloadTask *downloadTask = [weakSelf.activeDownload objectForKey:[item.downloadURL absoluteString]];
        if (!downloadTask && !downloadTask.task) {
            return;
        }
        downloadTask.downloadStatus = DownloadPending;
        weakSelf.currentDownload --;
        [downloadTask.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            [weakSelf downloadItemInWaitingQueue];
            if (resumeData) {
                downloadTask.resumeData = resumeData;
            }
        }];
    });
}

- (void)resumeDownload:(id<DownloadableItem>)item
         returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler {
    // if validate -> check is download have resume data.
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        
        // get download model in active download and check download status.
        DownloadTask *downloadTask = [self.activeDownload objectForKey:[item.downloadURL absoluteString]];
        
        //check if same time run maximum -> add to waiting queue.
        //if not continue process download.
        if (![weakSelf canStartADownloadItem] && downloadTask) {
            [weakSelf addTaskToWaitingQueue:downloadTask];
            return;
        }
        
        if (!downloadTask && completionHandler) {
            [self returnForAllTask:item.downloadURL storedLocation:nil response:nil error:DownloadErrorByCode(UnexpectedError)];
            return;
        }
        
        downloadTask.downloadStatus = DownloadStatusDownloading;
        NSData *resumeData = downloadTask.resumeData;
        if (resumeData) {
            downloadTask.task = [weakSelf.downloadSession downloadTaskWithResumeData:resumeData];
        } else {
            downloadTask.task = [weakSelf.downloadSession downloadTaskWithURL:item.downloadURL];
        }
        [downloadTask.task resume];
        
    });
    
}

- (void)startDownload:(id<DownloadableItem>)item
         withPriority:(DownloadTaskPriroity)priority
        returnToQueue:(dispatch_queue_t)queue
           completion:(downloadTaskCompletion)completion {
    
    NSURL *url = item.downloadURL;
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        
        //check if same time run maximum -> add to waiting queue.
        //if not continue process download.
        //get download task in active download
        NSString *keyForItem = [item.downloadURL absoluteString];
        DownloadTask *downloadTask = [weakSelf.activeDownload objectForKey:keyForItem];
        if (!downloadTask) {
            downloadTask = [[DownloadTask alloc] initWithItem:item];
            [weakSelf.activeDownload setObject:downloadTask forKey:keyForItem];
        }
        
        if (![self isValidUrl:url]) {
            [self returnForAllTask:downloadTask.downloadItem.downloadURL storedLocation:nil response:nil error:DownloadErrorByCode(DownloadInvalidUrl)];
            return;
        }
        
        CompletionDownloadModel *completionModel = [[CompletionDownloadModel alloc] initWithSourceUrl:url completion:completion andReturnQueue:queue];
        NSMutableArray *listObservers = [weakSelf.observers objectForKey:keyForItem];
        if (listObservers && listObservers.count > 0 && [weakSelf.activeDownload objectForKey:keyForItem] && downloadTask.downloadStatus == DownloadStatusDownloading ) {
            [listObservers addObject:completionModel];
            return;
        } else {
            listObservers = [[NSMutableArray alloc] initWithArray:@[completionModel]];
            [weakSelf.observers setObject:listObservers forKey:keyForItem];
        }
        
        //check if already have a task download this file -> wait for that task finished and return for all.
        //if not -> run it.
        if (![weakSelf canStartADownloadItem]) {
            [self addTaskToWaitingQueue:downloadTask];
            return;
        }
        
        self.currentDownload++;

        
        downloadTask.downloadStatus = DownloadStatusDownloading;
        
        downloadTask.task = [weakSelf.downloadSession downloadTaskWithURL:url];
        
        [downloadTask.task resume];
        
    });
}

- (BOOL) isValidUrl: (NSURL*)url {
    BOOL isValid = [url scheme] && [url host];
    return isValid;
}

- (void)returnForAllTask:(NSURL *)source storedLocation:(NSURL*)location response:(NSURLResponse *)response error:(NSError*)error {
    NSString *keyOfTask = [source absoluteString];
    __weak typeof(self) weakSelf = self;
    //create a dispatch_group to notfy when return to all observer -> remove it.
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_async(dispatchGroup, self.downloaderQueue, ^{
        //validate check already have a task waiting for completion.
        if (!weakSelf.observers && weakSelf.observers.count == 0) {
            return;
        }
        //loop for all observer in queue -> check if task waiting for result form download with source url -> return result for all of this.
        NSMutableArray *listObserverForItem = [weakSelf.observers objectForKey:keyOfTask];
        if (listObserverForItem && listObserverForItem.count > 0) {
            for (NSInteger index = 0; index < listObserverForItem.count; index++) {
                CompletionDownloadModel *completionModel = [listObserverForItem objectAtIndex:index];
                downloadTaskCompletion block = completionModel.completionHandler;
                dispatch_queue_t queue = completionModel.returnQueue ? completionModel.returnQueue : dispatch_get_main_queue();
                if (block) {
                    dispatch_group_async(dispatchGroup, queue, ^{
                        block(location, response, error);
                        //when return completion -> remove that observer in queue.
                    });
                }
            }
        }
    });
    
    dispatch_group_notify(dispatchGroup, self.downloaderQueue, ^{
        [weakSelf.observers removeObjectForKey:keyOfTask];
    });
    
}

- (void)pauseAllDownloading {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        for (NSString *key in weakSelf.activeDownload.allKeys) {
            //When network status changed from available -> not available.
            //Pausing all task downloading, and store resume data for resume.
            DownloadTask *model = [weakSelf.activeDownload objectForKey:key];
            if (model && model.downloadStatus == DownloadStatusDownloading) {
                [model.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    if (resumeData) {
                        model.resumeData = resumeData;
                    }
                }];
                model.downloadStatus = DownloadPauseBySystem;
            }
        }
    });
}

- (void)resumeDownloadAll {
    //when network change from unavailable -> available:
    //resume all task pending by system before.
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        for (NSString *key in self.activeDownload.allKeys) {
            DownloadTask *model = [weakSelf.activeDownload objectForKey:key];
            if (model && model.downloadStatus == DownloadPauseBySystem) {
                model.downloadStatus = DownloadStatusDownloading;
                NSData *resumeData = model.resumeData;
                if (resumeData) {
                    model.task = [weakSelf.downloadSession downloadTaskWithResumeData:resumeData];
                } else {
                    model.task = [weakSelf.downloadSession downloadTaskWithURL:model.downloadItem.downloadURL];
                }
                [model.task resume];
            }
        }
    });
}

- (BOOL)canStartADownloadItem {
    return self.currentDownload < self.maximumDownload;
}

- (void)addTaskToWaitingQueue:(DownloadTask *)task {
    switch (task.taskPriority) {
        case DownloadTaskPriroityLow:
            [self.lowPriorityDownloadItems addObject:task];
            break;
        case DownloadTaskPriroityMedium:
            [self.mediumPriorityDownloadItems addObject:task];
            break;
        case DownloadTaskPriroityHigh:
            [self.highPriorityDownloadItems addObject:task];
            break;
    }
    task.downloadStatus = DownloadWaiting;
}

- (void)configDownloader {
    
}

- (DownloadStatus)getStatusOfItem:(id<DownloadableItem>)item {
    NSString *keyForItem = [item.downloadURL absoluteString];
    DownloadTask *downloadTask = [self.activeDownload objectForKey:keyForItem];
    if (downloadTask) {
        return downloadTask.downloadStatus;
    }
    return DownloadUnknown;
}

- (DownloadTask *)getDownloadTask {
    DownloadTask *downloadTask = nil;
    NSInteger choosen = RAND_FROM_TO(1, 10);
    if (choosen <= 6 && self.highPriorityDownloadItems.count > 0) {
        downloadTask = [self.highPriorityDownloadItems firstObject];
        [self.highPriorityDownloadItems removeObjectAtIndex:0];
        return downloadTask;
    } else if (choosen <= 9 && self.mediumPriorityDownloadItems.count > 0) {
        downloadTask = [self.mediumPriorityDownloadItems firstObject];
        [self.mediumPriorityDownloadItems removeObjectAtIndex:0];
        return downloadTask;
    } else if (self.lowPriorityDownloadItems.count > 0) {
        downloadTask = [self.lowPriorityDownloadItems firstObject];
        [self.lowPriorityDownloadItems removeObjectAtIndex:0];
        return downloadTask;
    }
    return [self getHighestPriorityDownloadTask];
}

- (DownloadTask*)getHighestPriorityDownloadTask {
    
    DownloadTask *highestPriorityDownloadItem = nil;
    
    highestPriorityDownloadItem = [self.highPriorityDownloadItems firstObject];
    if (highestPriorityDownloadItem) {
        [self.highPriorityDownloadItems removeObject:highestPriorityDownloadItem];
        return highestPriorityDownloadItem;
    }
    
    highestPriorityDownloadItem = [self.mediumPriorityDownloadItems firstObject];
    if (highestPriorityDownloadItem) {
        [self.mediumPriorityDownloadItems removeObject:highestPriorityDownloadItem];
        return highestPriorityDownloadItem;
    }
    highestPriorityDownloadItem = [self.lowPriorityDownloadItems firstObject];
    if (highestPriorityDownloadItem) {
        [self.lowPriorityDownloadItems removeObject:highestPriorityDownloadItem];
        return highestPriorityDownloadItem;
    }
    return nil;
}

- (void)downloadItemInWaitingQueue {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        DownloadTask *downloadTask = [weakSelf getDownloadTask];
        if (downloadTask) {
            NSString *keyForTask = [downloadTask.downloadItem.downloadURL absoluteString];
            NSMutableArray *listObserverForTask = [weakSelf.observers objectForKey:keyForTask];
            for (CompletionDownloadModel *completionModel in listObserverForTask) {
                DownloadStatus downloadStatus = downloadTask.downloadStatus;
                if (downloadStatus == DownloadPending) {
                    [weakSelf resumeDownload:downloadTask.downloadItem returnToQueue:completionModel.returnQueue completion:completionModel.completionHandler];
                } else {
                    [weakSelf startDownload:downloadTask.downloadItem withPriority:downloadTask.taskPriority returnToQueue:completionModel.returnQueue completion:completionModel.completionHandler];
                }
            }
        }
    });
}

- (NSURL*)localFilePath:(NSURL *)url {
    return [self.storedPath URLByAppendingPathComponent:url.lastPathComponent];
}

#pragma mark - NSURLSessionDelegate:

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSURL *sourceUrl = downloadTask.currentRequest.URL ? downloadTask.currentRequest.URL : downloadTask.originalRequest.URL;
    
    if (!sourceUrl) {
        return;
    }
    self.currentDownload--;

    [self downloadItemInWaitingQueue];
    
    //when fisnished download -> copy file from temp folder to destination folder -> return completion for all task waiting this.
    if (location) {
        NSString *keyOfTask = [sourceUrl absoluteString];
        
        DownloadTask *downloadTask = [self.activeDownload objectForKey:keyOfTask];
        if (downloadTask) {
            downloadTask.downloadStatus = DownloadFinished;
        }
        NSURL* destinationUrl = [self localFilePath:sourceUrl];
        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSError *saveFileError = nil;
        [fileManager copyItemAtURL:location toURL:destinationUrl error:&saveFileError];
        if (saveFileError) {
            downloadTask.downloadStatus = DownloadError;
            [self returnForAllTask:sourceUrl storedLocation:nil response:nil error:DownloadErrorByCode(StoreLocalError)];
        } else {
            [self returnForAllTask:sourceUrl storedLocation:destinationUrl response:nil error:nil];
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error || error.code == NSURLErrorCancelled) {
        return;
    }
    
    NSURL *sourceUrl = task.currentRequest.URL ? task.currentRequest.URL : task.originalRequest.URL;
    if (!sourceUrl) {
        return;
    }
    if (sourceUrl) {
        NSString *key = [sourceUrl absoluteString];
        DownloadTask *downloadTask = [self.activeDownload objectForKey:key];
        downloadTask.downloadStatus = DownloadError;
        [self returnForAllTask:sourceUrl storedLocation:nil response:nil error:DownloadErrorByCode(UnexpectedError)];
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    //handle when app go background
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate) {
            void(^completion)(void) = appDelegate.backgroundTransferCompletionHandler;
            if (completion) {
                completion();
                appDelegate.backgroundTransferCompletionHandler = nil;
            }
        }
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    //get source download url
    NSURL *sourceUrl = downloadTask.currentRequest.URL ? downloadTask.currentRequest.URL : downloadTask.originalRequest.URL;
    
    //check if still nil -> return
    if (!sourceUrl) {
        return;
    }
    // get download task in active -> update progress for that task.
    NSString *key = [sourceUrl absoluteString];
    DownloadTask *task = [self.activeDownload objectForKey:key];
    if (self.updateProgressAtIndex && task) {
        self.updateProgressAtIndex(task.downloadItem, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

@end


