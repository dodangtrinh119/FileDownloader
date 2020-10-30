//
//  NSSessionDownloader.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "NSSessionDownloader.h"
#import "AppDelegate.h"
#import "Utils.h"
#import "CompletionDownloadModel.h"
#import "NSError+DownloadManager.h"
#import "DownloadStatistics.h"

@interface NSSessionDownloader () <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, strong) NSMutableDictionary *activeDownload;
@property (nonatomic, strong) dispatch_queue_t downloaderQueue;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, strong) NSURL *storedPath;
@property (nonatomic, assign) NSInteger maximumDownload;
@property (nonatomic, assign) NSInteger currentDownload;
@property (nonatomic, strong) DownloadStatistics *downloadStatistics;

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
        self.downloadStatistics = [[DownloadStatistics alloc] init];
        self.maximumDownload = 1;
        self.currentDownload = 0;
        
        self.highPriorityDownloadItems = [[NSMutableArray alloc] init];
        self.mediumPriorityDownloadItems = [[NSMutableArray alloc] init];
        self.lowPriorityDownloadItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)cancelDownloadItem:(id<DownloadableItem>)item {
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
        
        // Cancel download task, update status.
        weakSelf.currentDownload --;
        downloadTask.downloadStatus = DownloadCanceled;
        [downloadTask.task cancel];
        [weakSelf downloadItemInWaitingQueue];
    });
}

- (void)pauseDownloadItem:(id<DownloadableItem>)item {
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

- (void)resumeDownloadItem:(id<DownloadableItem>)item
         returnToQueue:(dispatch_queue_t)queue completion:(downloadTaskCompletion)completionHandler {
    // if validate -> check is download have resume data.
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        
        // Get download model in active download and check download status.
        DownloadTask *downloadTask = [self.activeDownload objectForKey:[item.downloadURL absoluteString]];
        
        // Check if same time run maximum -> add to waiting queue.
        // if not continue process download.
        if (![weakSelf canStartDownloadItem] && downloadTask) {
            [weakSelf addTaskToPendingList:downloadTask];
            return;
        }
        
        if (!downloadTask && completionHandler) {
            [weakSelf returnForAllTask:item.downloadURL storedLocation:nil response:nil error:DownloadErrorByCode(UnexpectedError)];
            return;
        }
        weakSelf.currentDownload ++;

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

- (void)startDownloadItem:(id<DownloadableItem>)item
         withPriority:(DownloadTaskPriroity)priority
        returnToQueue:(dispatch_queue_t)queue
           completion:(downloadTaskCompletion)completion {
    
    NSURL *url = item.downloadURL;
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        
        // Check if same time run maximum -> add to waiting queue.
        // if not continue process download.
        // get download task in active download
        NSString *keyForItem = [item.downloadURL absoluteString];
        DownloadTask *downloadTask = [weakSelf.activeDownload objectForKey:keyForItem];
        
        if (!downloadTask) {
            downloadTask = [[DownloadTask alloc] initWithItem:item andPriority:priority];
            [weakSelf.activeDownload setObject:downloadTask forKey:keyForItem];
        }
        
        if (![weakSelf isValidUrl:url]) {
            [weakSelf returnForAllTask:downloadTask.downloadItem.downloadURL storedLocation:nil response:nil error:DownloadErrorByCode(DownloadInvalidUrl)];
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
        
        // Check if already have a task download this file -> wait for that task finished and return for all.
        // if not -> run it.
        if (![weakSelf canStartDownloadItem]) {
            [weakSelf addTaskToPendingList:downloadTask];
            return;
        }
        
        weakSelf.currentDownload++;
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
    
    // Create a dispatch_group to notfy when return to all observer -> remove it.
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_async(dispatchGroup, self.downloaderQueue, ^{
        
        // Validate check already have a task waiting for completion.
        if (weakSelf.observers.count == 0) {
            return;
        }
        
        // Loop for all observer in queue -> check if task waiting for result form download with source url -> return result for all of this.
        NSMutableArray *listObserverForItem = [weakSelf.observers objectForKey:keyOfTask];
        if (listObserverForItem && listObserverForItem.count > 0) {
            for (NSInteger index = 0; index < listObserverForItem.count; index++) {
                CompletionDownloadModel *completionModel = [listObserverForItem objectAtIndex:index];
                downloadTaskCompletion block = completionModel.completionHandler;
                dispatch_queue_t queue = completionModel.returnQueue ? completionModel.returnQueue : dispatch_get_main_queue();
                if (block) {
                    dispatch_group_async(dispatchGroup, queue, ^{
                        block(location, response, error);
                    });
                }
            }
        }
    });
    
    // When return completion completed -> remove that observer in queue.
    dispatch_group_notify(dispatchGroup, self.downloaderQueue, ^{
        [weakSelf.observers removeObjectForKey:keyOfTask];
    });
    
}

- (void)pauseAllDownloadingItem {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        for (NSString *key in weakSelf.activeDownload.allKeys) {
            
            // When network status changed from available -> not available.
            // Pausing all task downloading, and store resume data for resume.
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

- (void)resumeAllPausingItem {
    // When network change from unavailable -> available:
    // Resume all task pending by system before.
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        for (NSString *key in weakSelf.activeDownload.allKeys) {
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

- (BOOL)canStartDownloadItem {
    return self.currentDownload < self.maximumDownload;
}

- (void)addTaskToPendingList:(DownloadTask *)task {
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

- (DownloadTask *)pickAvailableTaskForDownload {
    
    // Check if first time download -> get highest priority to download.
    DownloadTask *downloadTask = nil;
    if (self.downloadStatistics.totalTaskDownloaded == 0) {
        return [self getHighestPriorityDownloadTask];
    }
    
    // Calculate different form current proportion of each priority with expectation (high: 60%, medium: 30%, low: 10%)
    float highPriorityProportionToExpect = 0.6 - [self.downloadStatistics currentHighPriorityTaskProportion];
    float mediumPriorityProportionToExpect = 0.3 - [self.downloadStatistics currentMeidumPriorityTaskProportion];
    float lowPriorityProportionToExpect = 0.1 - [self.downloadStatistics currentLowPriorityTaskProportion];
    
    // Find which priority have maximum different with expectation -> choose it priority.
    float highestProportionToExpect = MAX(highPriorityProportionToExpect, MAX(mediumPriorityProportionToExpect, lowPriorityProportionToExpect));
    
    if (highPriorityProportionToExpect == highestProportionToExpect) {
        downloadTask = [self.highPriorityDownloadItems firstObject];
        if (downloadTask) {
            [self.highPriorityDownloadItems removeObjectAtIndex:0];
            self.downloadStatistics.countHighPriorityTaskDownloaded++;
        }
    } else if (mediumPriorityProportionToExpect == highestProportionToExpect) {
        downloadTask = [self.mediumPriorityDownloadItems firstObject];
        if (downloadTask) {
            self.downloadStatistics.countMediumPriorityTaskDownloaded++;
            [self.mediumPriorityDownloadItems removeObjectAtIndex:0];
        }
    } else if (lowPriorityProportionToExpect == highestProportionToExpect) {
        downloadTask = [self.lowPriorityDownloadItems firstObject];
        if (downloadTask) {
            self.downloadStatistics.countLowPriorityTaskDownloaded++;
            [self.lowPriorityDownloadItems removeObjectAtIndex:0];
        }
    }
    
    // If that priority selected doesn't have any item -> get highest priority available.
    if (!downloadTask) {
        downloadTask = [self getHighestPriorityDownloadTask];
    }
    return downloadTask;
    
}

- (DownloadTask*)getHighestPriorityDownloadTask {
    
    DownloadTask *highestPriorityDownloadItem = nil;
    
    highestPriorityDownloadItem = [self.highPriorityDownloadItems firstObject];
    if (highestPriorityDownloadItem) {
        self.downloadStatistics.countHighPriorityTaskDownloaded++;
        [self.highPriorityDownloadItems removeObject:highestPriorityDownloadItem];
        return highestPriorityDownloadItem;
    }
    
    highestPriorityDownloadItem = [self.mediumPriorityDownloadItems firstObject];
    if (highestPriorityDownloadItem) {
        self.downloadStatistics.countMediumPriorityTaskDownloaded++;
        [self.mediumPriorityDownloadItems removeObject:highestPriorityDownloadItem];
        return highestPriorityDownloadItem;
    }
    
    highestPriorityDownloadItem = [self.lowPriorityDownloadItems firstObject];
    if (highestPriorityDownloadItem) {
        self.downloadStatistics.countLowPriorityTaskDownloaded++;
        [self.lowPriorityDownloadItems removeObject:highestPriorityDownloadItem];
        return highestPriorityDownloadItem;
    }
    return nil;
}

- (void)downloadItemInWaitingQueue {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        if (![weakSelf canStartDownloadItem]) {
            return;
        }
        DownloadTask *downloadTask = [weakSelf pickAvailableTaskForDownload];
        if (downloadTask) {
            NSString *keyForTask = [downloadTask.downloadItem.downloadURL absoluteString];
            NSMutableArray *listObserverForTask = [weakSelf.observers objectForKey:keyForTask];
            for (CompletionDownloadModel *completionModel in listObserverForTask) {
                DownloadStatus downloadStatus = downloadTask.downloadStatus;
                if (downloadStatus == DownloadPending) {
                    [weakSelf resumeDownloadItem:downloadTask.downloadItem returnToQueue:completionModel.returnQueue completion:completionModel.completionHandler];
                } else {
                    weakSelf.currentDownload++;
                    downloadTask.downloadStatus = DownloadStatusDownloading;
                    downloadTask.task = [weakSelf.downloadSession downloadTaskWithURL:downloadTask.downloadItem.downloadURL];
                    [downloadTask.task resume];
                }
            }
        }
    });
}

- (NSURL*)localFilePathOfUrl:(NSURL *)url {
    return [self.storedPath URLByAppendingPathComponent:url.lastPathComponent];
}

#pragma mark - NSURLSessionDelegate:

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSURL *sourceUrl = downloadTask.currentRequest.URL ? downloadTask.currentRequest.URL : downloadTask.originalRequest.URL;
    
    if (!sourceUrl) {
        return;
    }
    self.currentDownload--;
    self.downloadStatistics.totalTaskDownloaded++;

    [self downloadItemInWaitingQueue];
    
    // When fisnished download -> copy file from temp folder to destination folder -> return completion for all task waiting this.
    if (location) {
        NSString *keyOfTask = [sourceUrl absoluteString];
        
        DownloadTask *downloadTask = [self.activeDownload objectForKey:keyOfTask];
        if (downloadTask) {
            downloadTask.downloadStatus = DownloadFinished;
        }
        NSURL* destinationUrl = [self localFilePathOfUrl:sourceUrl];
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
    // Handle when app go background
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
    
    // Get source download url
    NSURL *sourceUrl = downloadTask.currentRequest.URL ? downloadTask.currentRequest.URL : downloadTask.originalRequest.URL;
    
    // Check if still nil -> return
    if (!sourceUrl) {
        return;
    }
    
    // Get download task in active -> update progress for that task.
    NSString *key = [sourceUrl absoluteString];
    DownloadTask *task = [self.activeDownload objectForKey:key];
    if (self.updateProgressAtIndex && task) {
        self.updateProgressAtIndex(task.downloadItem, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

@end




//- (NSData *)correctRequestData:(NSData *)data {
//    if (!data) {
//        return nil;
//    }
//    if ([NSKeyedUnarchiver unarchiveObjectWithData:data]) {
//        return data;
//    }
//
//    NSMutableDictionary *archive = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
//    if (!archive) {
//        return nil;
//    }
//    int k = 0;
//    while ([[archive[@"$objects"] objectAtIndex:1] objectForKey:[NSString stringWithFormat:@"$%d", k]]) {
//        k += 1;
//    }
//
//    int i = 0;
//    while ([[archive[@"$objects"] objectAtIndex:1] objectForKey:[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]]) {
//        NSMutableArray *arr = archive[@"$objects"];
//        NSMutableDictionary *dic = [arr objectAtIndex:1];
//        id obj;
//        if (dic) {
//            obj = [dic objectForKey:[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]];
//            if (obj) {
//                [dic setObject:obj forKey:[NSString stringWithFormat:@"$%d",i + k]];
//                [dic removeObjectForKey:[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]];
//                arr[1] = dic;
//                archive[@"$objects"] = arr;
//            }
//        }
//        i += 1;
//    }
//    if ([[archive[@"$objects"] objectAtIndex:1] objectForKey:@"__nsurlrequest_proto_props"]) {
//        NSMutableArray *arr = archive[@"$objects"];
//        NSMutableDictionary *dic = [arr objectAtIndex:1];
//        if (dic) {
//            id obj;
//            obj = [dic objectForKey:@"__nsurlrequest_proto_props"];
//            if (obj) {
//                [dic setObject:obj forKey:[NSString stringWithFormat:@"$%d",i + k]];
//                [dic removeObjectForKey:@"__nsurlrequest_proto_props"];
//                arr[1] = dic;
//                archive[@"$objects"] = arr;
//            }
//        }
//    }
//
//    id obj = [archive[@"$top"] objectForKey:@"NSKeyedArchiveRootObjectKey"];
//    if (obj) {
//        [archive[@"$top"] setObject:obj forKey:NSKeyedArchiveRootObjectKey];
//        [archive[@"$top"] removeObjectForKey:@"NSKeyedArchiveRootObjectKey"];
//    }
//    NSData *result = [NSPropertyListSerialization dataWithPropertyList:archive format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
//    return result;
//}
//
//- (NSMutableDictionary *)getResumDictionary:(NSData *)data
//{
//    NSMutableDictionary *iresumeDictionary;
//    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion >= 10) {
//        NSMutableDictionary *root;
//        NSKeyedUnarchiver *keyedUnarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
//        NSError *error = nil;
//        root = [keyedUnarchiver decodeTopLevelObjectForKey:@"NSKeyedArchiveRootObjectKey" error:&error];
//        if (!root) {
//            root = [keyedUnarchiver decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:&error];
//        }
//        [keyedUnarchiver finishDecoding];
//        iresumeDictionary = root;
//    }
//
//    if (!iresumeDictionary) {
//        iresumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];
//    }
//    return iresumeDictionary;
//}
//
//static NSString * kResumeCurrentRequest = @"NSURLSessionResumeCurrentRequest";
//static NSString * kResumeOriginalRequest = @"NSURLSessionResumeOriginalRequest";
//
//- (NSData *)correctResumData:(NSData *)data
//{
//    NSMutableDictionary *resumeDictionary = [self getResumDictionary:data];
//    if (!data || !resumeDictionary) {
//        return nil;
//    }
//
//    resumeDictionary[kResumeCurrentRequest] = [self correctRequestData:[resumeDictionary objectForKey:kResumeCurrentRequest]];
//    resumeDictionary[kResumeOriginalRequest] = [self correctRequestData:[resumeDictionary objectForKey:kResumeOriginalRequest]];
//
//    NSData *result = [NSPropertyListSerialization dataWithPropertyList:resumeDictionary format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
//    return result;
//}


//- (BOOL)__isValidResumeData:(NSData *)data{
//    if (!data || [data length] < 1) return NO;
//       NSError *error;
//       NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:kCFPropertyListMutableContainersAndLeaves format:nil error:&error];
//       if (!resumeDictionary || error) return NO;
//
//       NSString *resumeDataFileName = resumeDictionary[@"NSURLSessionResumeInfoTempFileName"];
//       NSString *newTempPath = NSTemporaryDirectory();
//       NSString *newResumeDataPath = [newTempPath stringByAppendingPathComponent:resumeDataFileName];
//       [resumeDictionary setValue:newResumeDataPath forKey:@"NSURLSessionResumeInfoLocalPath"];
//
//
//       NSString *localTmpFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
//       if ([localTmpFilePath length] < 1) return NO;
//
//       BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:localTmpFilePath];
//
//       if (!result) {
//           NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
//           NSString *localName = [localTmpFilePath lastPathComponent];
//           NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//           NSString *cachesDir = [paths objectAtIndex:0];
//           NSString *localCachePath = [[[cachesDir stringByAppendingPathComponent:@"com.apple.nsurlsessiond/Downloads"]stringByAppendingPathComponent:bundleIdentifier]stringByAppendingPathComponent:localName];
//           result = [[NSFileManager defaultManager] moveItemAtPath:localCachePath toPath:localTmpFilePath error:nil];
//       }
//       return result;
//}


//- (NSData *)turnValidResumeData:(NSData *)data
//
//{
//
//    if (!data || [data length] < 1) return nil;
//
//    NSError *error;
//
//    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:NULL error:&error];
//
//    if (!resumeDictionary || error) return nil;
//
//    NSString *localTmpFilePath;
//
//    int download_version = [[resumeDictionary objectForKey:@"NSURLSessionResumeInfoVersion"] intValue];
//
//    if(download_version==1)
//
//    {
//
//        localTmpFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
//
//        if ([localTmpFilePath length] < 1) return nil;
//
//    }
//
//    else if(download_version==2)
//
//    {
//
//        localTmpFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoTempFileName"];
//
//        if ([localTmpFilePath length] < 1) return nil;
//
//    }
//
//    NSString *localCachePath;
//
//    NSString *localLastName = [localTmpFilePath lastPathComponent];
//
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//
//    NSString *cachesDir = [paths objectAtIndex:0];
//
//    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
//
//    if(version>=9.0)
//
//    {
//
//        return data;
//
//    }
//
//    else if(version>=8.0&&version<9.0)
//
//    {
//
//        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
//
//        NSString * _localCachePath = [[[cachesDir stringByAppendingPathComponent:@"com.apple.nsurlsessiond/Downloads"]stringByAppendingPathComponent:bundleIdentifier]stringByAppendingPathComponent:localLastName];
//
//        if([[NSFileManager defaultManager] fileExistsAtPath:_localCachePath])
//
//            localCachePath = _localCachePath;
//
//        NSString *temp = NSTemporaryDirectory();
//
//        temp = [temp stringByAppendingPathComponent:localLastName];
//
//        if([[NSFileManager defaultManager] fileExistsAtPath:temp])
//
//            localCachePath = localLastName;
//
//    }
//
//    else
//
//    {
//
//        localCachePath = [[cachesDir stringByAppendingPathComponent:@"com.apple.nsnetworkd"]stringByAppendingPathComponent:localLastName];
//
//    }
//
//    [resumeDictionary setValue:localCachePath forKey:@"NSURLSessionResumeInfoLocalPath"];
//
//    data = [NSPropertyListSerialization dataWithPropertyList:resumeDictionary format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
//
//    return data;
//
//}
