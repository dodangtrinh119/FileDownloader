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
#import "NSError+DownloadError.h"
#import "TrunkFileDownloadTask.h"
#import "DownloadStatistics.h"
#import "FileReader.h"

static NSString * kResumeCurrentRequest = @"NSURLSessionResumeCurrentRequest";
static NSString * kResumeOriginalRequest = @"NSURLSessionResumeOriginalRequest";

@interface NSSessionDownloader () <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, strong) NSMutableDictionary *activeDownload;
@property (nonatomic, strong) dispatch_queue_t downloaderQueue;
@property (nonatomic, strong) NSURL *storedPath;
@property (nonatomic, assign) NSInteger maximumDownload;
@property (nonatomic, assign) NSInteger currentDownload;
@property (nonatomic, strong) DownloadStatistics *downloadStatistics;

@property (nonatomic, strong) NSMutableArray *highPriorityDownloadItems;
@property (nonatomic, strong) NSMutableArray *mediumPriorityDownloadItems;
@property (nonatomic, strong) NSMutableArray *lowPriorityDownloadItems;
@property (nonatomic, strong) NSMutableDictionary *resumeDataStored;
@property (nonatomic, strong) NSMutableArray *observers;

@end

@implementation NSSessionDownloader


float const HIGH_PRIORITY_PROPORTION_EXPECT = 0.6;
float const MEDIUM_PRIORITY_PROPORTION_EXPECT = 0.3;
float const LOW_PRIORITY_PROPORTION_EXPECT = 0.3;

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        if (URLs && URLs.count > 0) {
            self.storedPath = [URLs firstObject];
        }
        self.downloaderQueue = dispatch_queue_create("downloaderQueue", DISPATCH_QUEUE_SERIAL);
        self.activeDownload = [[NSMutableDictionary alloc] init];
        self.observers = [[NSMutableArray alloc] init];
        [self getListResumeDatas];
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
        // Firstly check is this  already add in queue and downloading.model
        NSString *keyForItem = [item.downloadURL absoluteString];
        id<DownloadTask> downloadTask = [weakSelf.activeDownload objectForKey:keyForItem];
        if (!downloadTask) {
            return;
        }
        [downloadTask.observers removeAllObjects];
        // Cancel download task, update status.
        weakSelf.currentDownload --;
        downloadTask.downloadStatus = DownloadCanceled;
        switch (downloadTask.downloadType) {
            case NormalDownload: {
                NormalDownloadTask *normalDownloadTask = (NormalDownloadTask *)downloadTask;
                [normalDownloadTask.task cancel];
                [weakSelf.resumeDataStored removeObjectForKey:keyForItem];
                [weakSelf saveListResumeData];
                break;
            }
            case TrunkFileDownload: {
                TrunkFileDownloadTask *trunkFileDownloadTask = (TrunkFileDownloadTask *)downloadTask;
                for (DownloadPartData *part in trunkFileDownloadTask.listPart) {
                    [part.task cancel];
                }
                break;
            }
        }
        [weakSelf downloadItemInWaitingQueue];
    });
}

- (void)getDownloadSize:(NSURL*)url completion:(getItemSizeBlock)completion {
    float timeoutInterval = 5.0;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:timeoutInterval];
    [request setHTTPMethod:@"HEAD"];
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        completion((NSInteger)response.expectedContentLength, error);
    }];
    [task resume];
}

- (void)pauseDownloadItem:(id<DownloadableItem>)item {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        NSString *keyOfTask = [item.downloadURL absoluteString];
        id<DownloadTask> downloadTask = [weakSelf.activeDownload objectForKey:keyOfTask];
        if (!downloadTask) {
            return;
        }
        weakSelf.currentDownload --;
        downloadTask.downloadStatus = DownloadPending;
        switch (downloadTask.downloadType) {
            case NormalDownload: {
                NormalDownloadTask *normalDownloadTask = (NormalDownloadTask *)downloadTask;
                [normalDownloadTask.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    [weakSelf downloadItemInWaitingQueue];
                    if (resumeData) {
                        normalDownloadTask.resumeData = resumeData;
                        [weakSelf.resumeDataStored setObject:resumeData forKey:keyOfTask];
                        [weakSelf saveListResumeData];
                    }
                }];
                break;
            }
            case TrunkFileDownload: {
                TrunkFileDownloadTask *trunkFileDownloadTask = (TrunkFileDownloadTask *)downloadTask;
                for (DownloadPartData *part in trunkFileDownloadTask.listPart) {
                    [part.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                        NSMutableDictionary *storedResumeDataTrunkFile = @{ @"fileSize": [NSNumber numberWithLong:trunkFileDownloadTask.fileSize],
                                                                     @"countPartDownloaded": [NSNumber numberWithInteger: trunkFileDownloadTask.countPartDownloaded],
                                                                     @"listParts": trunkFileDownloadTask.listPart};
                        if (resumeData) {
                            part.resumeData = resumeData;
                            NSDictionary *partData = @{@"partName": part.nameOfPart,
                                                       @"resumeData": part.resumeData
                            };
                            [storedResumeDataTrunkFile setObject:partData forKey:part.nameOfPart];
                            //store resume data for kill app;
                        }
                    }];
                }
            }
        }
       
    });
}

- (void)resumeDownloadItem:(id<DownloadableItem>)item
             returnToQueue:(dispatch_queue_t)queue
                completion:(downloadTaskCompletion)completionHandler {
    // If validate -> check is download have resume data.
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
//        if (true) {
//
//            return;
//        }
        NSString *keyOfTask = [item.downloadURL absoluteString];
        // Get download model in active download and check download status.
        NormalDownloadTask *downloadTask = [self.activeDownload objectForKey:keyOfTask];
        
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
            //NSDictionary* resume = [weakSelf getResumDictionary:resumeData];
            //BOOL check = [weakSelf isValidResumeData:resumeData];
            if ([weakSelf.resumeDataStored objectForKey:keyOfTask]) {
                [weakSelf.resumeDataStored removeObjectForKey:keyOfTask];
            }
            downloadTask.task = [weakSelf.downloadSession downloadTaskWithResumeData:resumeData];
        } else {
            downloadTask.task = [weakSelf.downloadSession downloadTaskWithURL:item.downloadURL];
        }
        [downloadTask.task resume];
        
    });
    
}

-(void)addResumeDownloadItem:(id<DownloadableItem>)item withResumeData:(NSData *)resumeData withPriority:(DownloadTaskPriroity)priority returnToQueue:(dispatch_queue_t)queue downloadProgressBlock:(downloadProgressBlock)progressBlock completion:(downloadTaskCompletion)completion {
    
    if (![self isValidUrl:item.downloadURL] && completion) {
        completion(nil, nil, DownloadErrorByCode(DownloadInvalidUrl));
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        
        // Check if same time run maximum -> add to waiting queue.
        // If not continue process download.
        // Get download task in active download
        NSString *keyForItem = [item.downloadURL absoluteString];
        NormalDownloadTask *downloadTask = [weakSelf.activeDownload objectForKey:keyForItem];
        CompletionDownloadModel *completionModel = [[CompletionDownloadModel alloc] initWithSourceUrl:item.downloadURL
                                                                                           completion:completion
                                                                                       andReturnQueue:queue
                                                                                downloadProgressBlock:progressBlock];
        
        // Check if already have this url downloading -> add completion to observers.
        if (!downloadTask) {
            downloadTask = [[NormalDownloadTask alloc] initWithItem:item andPriority:priority andCompletion:completionModel];
            downloadTask.resumeData = resumeData;
            [weakSelf.activeDownload setObject:downloadTask forKey:keyForItem];
        } else {
            [downloadTask.observers addObject:completionModel];
            if (downloadTask.downloadStatus != DownloadStatusDownloading) {
                [weakSelf resumeDownloadItem:item returnToQueue:queue completion:completion];
            }
            return;
        }
        downloadTask.downloadStatus = DownloadPending;
    });
    
}

- (void)saveListResumeData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.resumeDataStored forKey:@"DownloaderResumeDatas"];
}

- (void)getListResumeDatas {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.resumeDataStored = [[userDefaults dictionaryForKey:@"DownloaderResumeDatas"] mutableCopy];
    if (!self.resumeDataStored) {
        self.resumeDataStored = [[NSMutableDictionary alloc] init];
    }
}

- (void)startDownloadItem:(id<DownloadableItem>)item
             withPriority:(DownloadTaskPriroity)priority
            returnToQueue:(dispatch_queue_t)queue
    downloadProgressBlock:(downloadProgressBlock)progressBlock
               completion:(downloadTaskCompletion)completion {
    NSURL *url = item.downloadURL;
    
    // Validate url
    if (![self isValidUrl:url] && completion) {
        completion(nil, nil, DownloadErrorByCode(DownloadInvalidUrl));
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloaderQueue, ^{
        
        // Check if same time run maximum -> add to waiting queue.
        // If not continue process download.
        // Get download task in active download
        NSString *keyForItem = [item.downloadURL absoluteString];
        id<DownloadTask> downloadTask = [weakSelf.activeDownload objectForKey:keyForItem];
        CompletionDownloadModel *completionModel = [[CompletionDownloadModel alloc] initWithSourceUrl:url
                                                                                           completion:completion
                                                                                       andReturnQueue:queue
                                                                                downloadProgressBlock:progressBlock];
        
        // Check if already have this url downloading -> add completion to observers.
        if (!downloadTask) {
            downloadTask = [[TrunkFileDownloadTask alloc] initWithItem:item andPriority:priority andCompletion:completionModel];
            [weakSelf.activeDownload setObject:downloadTask forKey:keyForItem];
        } else {
            [downloadTask.observers addObject:completionModel];
            if (downloadTask.downloadStatus != DownloadStatusDownloading) {
                [weakSelf resumeDownloadItem:item returnToQueue:queue completion:completion];
            }
            return;
        }
        
        // Check if already have a task download this file -> wait for that task finished and return for all.
        // if not -> run it.
        if (![weakSelf canStartDownloadItem]) {
            [weakSelf addTaskToPendingList:downloadTask];
            return;
        }
        
        // Start download
        weakSelf.currentDownload++;
        downloadTask.downloadStatus = DownloadStatusDownloading;
        NSLog(@"Start download");
//        downloadTask.task = [weakSelf.downloadSession downloadTaskWithURL:url];
//        [downloadTask.task resume];
        [weakSelf getDownloadSize:url completion:^(long itemSize, NSError * _Nonnull error) {
            downloadTask.fileSize = itemSize;
            NSMutableArray *partSize = [[NSMutableArray alloc] init];
            NSInteger totalPart = 2;
            for (NSInteger i = 4; i > 0 ; i--) {
                if (itemSize % i == 0) {
                    totalPart = i;
                    break;
                }
            }
            NSInteger totalSize = itemSize;
            NSInteger currentIndex = 0;
            while (totalSize > 0) {

                NSInteger sizePerPart = itemSize / totalPart;
                if (totalSize - sizePerPart > 0) {
                    totalSize -= sizePerPart;
                } else {
                    sizePerPart = totalSize;
                    totalSize = 0;
                }
                NSString *string = nil;
                if (currentIndex == totalPart - 1) {
                    string = [NSString stringWithFormat:@"bytes=%ld-%ld",currentIndex*sizePerPart, (currentIndex + 1)*sizePerPart];
                } else {
                    string = [NSString stringWithFormat:@"bytes=%ld-%ld",currentIndex*sizePerPart, (currentIndex + 1)*sizePerPart - 1];
                }
                NSLog(string);
                [partSize addObject:string];
                currentIndex++;

            }
            for (NSInteger index = 0; index < totalPart; index++) {
                NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
                [req addValue:[partSize objectAtIndex:index] forHTTPHeaderField:@"Range"];
                NSURLSessionDownloadTask *task = [self.downloadSession downloadTaskWithRequest:req];
                TrunkFileDownloadTask* trunkFileDownloadTask = (TrunkFileDownloadTask *)downloadTask;
                NSString *partName = [NSString stringWithFormat:@"part%ld.tmp",index];

                DownloadPartData *partData = [[DownloadPartData alloc] initWithTask:task name:partName];
                [trunkFileDownloadTask.listPart addObject:partData];
                [task resume];
            }
        }];
       
        
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
        NormalDownloadTask *downloadTask = [weakSelf.activeDownload objectForKey:keyOfTask];
        // Validate check already have a task waiting for completion.
        if (!downloadTask) {
            return;
        }
        
        // Loop for all observer in queue -> check if task waiting for result form download with source url -> return result for all of this.
        for (NSInteger index = 0; index < downloadTask.observers.count; index++) {
            CompletionDownloadModel *completionModel = [downloadTask.observers objectAtIndex:index];
            downloadTaskCompletion block = completionModel.completionHandler;
            dispatch_queue_t queue = completionModel.returnQueue ? completionModel.returnQueue : dispatch_get_main_queue();
            if (block) {
                dispatch_group_async(dispatchGroup, queue, ^{
                    block(location, response, error);
                });
            }
        }
    });
    
    // When return completion completed -> remove that observer in queue.
    dispatch_group_notify(dispatchGroup, self.downloaderQueue, ^{
        NormalDownloadTask *downloadTask = [self.activeDownload objectForKey:keyOfTask];
        [downloadTask.observers removeAllObjects];
    });
    
}

- (void)pauseAllDownloadingItem {
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.downloaderQueue, ^{
        for (NSString *key in weakSelf.activeDownload.allKeys) {
            
            // When network status changed from available -> not available.
            // Pausing all task downloading, and store resume data for resume.
            NormalDownloadTask *model = [weakSelf.activeDownload objectForKey:key];
            if (model && model.downloadStatus == DownloadStatusDownloading) {
                weakSelf.currentDownload --;
                [model.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    if (resumeData) {
                        model.resumeData = resumeData;
                        [weakSelf.resumeDataStored setObject:resumeData forKey:key];
                        [weakSelf saveListResumeData];
                    }
                }];
                model.downloadStatus = DownloadPauseBySystem;
            }
        }
        [weakSelf notifyDidPauseAllDownload];
    });
}

- (void)resumeAllPausingItem {
    // When network change from unavailable -> available:
    // Resume all task pending by system before.
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.downloaderQueue, ^{
        for (NSString *key in weakSelf.activeDownload.allKeys) {
            NormalDownloadTask *model = [weakSelf.activeDownload objectForKey:key];
            if (model && model.downloadStatus == DownloadPauseBySystem) {
                model.downloadStatus = DownloadStatusDownloading;
                NSData *resumeData = model.resumeData;
                if (resumeData) {
                    model.task = [weakSelf.downloadSession downloadTaskWithResumeData:resumeData];
                } else {
                    model.task = [weakSelf.downloadSession downloadTaskWithURL:model.downloadItem.downloadURL];
                }
                weakSelf.currentDownload ++;
                [weakSelf.resumeDataStored removeObjectForKey:key];
                [model.task resume];
            }
        }
        [weakSelf notifyDidResumeAllDownload];
    });
}

- (BOOL)canStartDownloadItem {
    return self.currentDownload < self.maximumDownload;
}

- (void)addTaskToPendingList:(NormalDownloadTask *)task {
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
    NormalDownloadTask *downloadTask = [self.activeDownload objectForKey:keyForItem];
    if (downloadTask) {
        return downloadTask.downloadStatus;
    }
    return DownloadUnknown;
}

- (NormalDownloadTask *)pickAvailableTaskForDownload {
    
    // Check if first time download -> get highest priority to download.
    NormalDownloadTask *downloadTask = nil;
    if (self.downloadStatistics.totalTaskDownloaded == 0) {
        return [self getHighestPriorityDownloadTask];
    }
    
    // Calculate different form current proportion of each priority with expectation (high: 60%, medium: 30%, low: 10%)
    float highPriorityProportionToExpect = HIGH_PRIORITY_PROPORTION_EXPECT - [self.downloadStatistics currentHighPriorityTaskProportion];
    float mediumPriorityProportionToExpect = MEDIUM_PRIORITY_PROPORTION_EXPECT - [self.downloadStatistics currentMeidumPriorityTaskProportion];
    float lowPriorityProportionToExpect = LOW_PRIORITY_PROPORTION_EXPECT - [self.downloadStatistics currentLowPriorityTaskProportion];
    
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

- (NormalDownloadTask*)getHighestPriorityDownloadTask {
    
    NormalDownloadTask *highestPriorityDownloadItem = nil;
    
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
        NormalDownloadTask *downloadTask = [weakSelf pickAvailableTaskForDownload];
        if (downloadTask) {
            //NSString *keyForTask = [downloadTask.downloadItem.downloadURL absoluteString];
            NSMutableArray *listObserverForTask = downloadTask.observers;
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

- (NSURL*)localFileOfFileName:(NSString *)fileName {
    return [self.storedPath URLByAppendingPathComponent:fileName];
}

#pragma mark - NSURLSessionDelegate:

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSURL *sourceUrl = downloadTask.currentRequest.URL ? downloadTask.currentRequest.URL : downloadTask.originalRequest.URL;
    NSUInteger taskId = downloadTask.taskIdentifier;
    if (!sourceUrl) {
        return;
    }
    
    if (location) {
        NSString *keyOfTask = [sourceUrl absoluteString];
        NSLog(@"Finished download");
        NSFileManager *fileManager = NSFileManager.defaultManager;
        id<DownloadTask> downloadTask = [self.activeDownload objectForKey:keyOfTask];
        switch (downloadTask.downloadType) {
            case NormalDownload: {
                NormalDownloadTask *downloadTask = [self.activeDownload objectForKey:keyOfTask];
                if (downloadTask) {
                    downloadTask.downloadStatus = DownloadFinished;
                }
                NSURL* destinationUrl = [self localFilePathOfUrl:sourceUrl];
                NSFileManager *fileManager = NSFileManager.defaultManager;
                NSError *saveFileError = nil;
                
                // Copy temp file after downloaded to destination path and stored with right format of file.
                [fileManager copyItemAtURL:location toURL:destinationUrl error:&saveFileError];
                if (saveFileError) {
                    downloadTask.downloadStatus = DownloadError;
                    [self returnForAllTask:sourceUrl storedLocation:nil response:nil error:DownloadErrorByCode(StoreLocalError)];
                } else {
                    [self returnForAllTask:sourceUrl storedLocation:destinationUrl response:nil error:nil];
                }
                break;
            }
            case TrunkFileDownload: {
                if (!downloadTask) {
                    return;
                    //downloadTask.downloadStatus = DownloadFinished;
                }
                TrunkFileDownloadTask *trunkFileDownloadTask = (TrunkFileDownloadTask *)downloadTask;
                if (!trunkFileDownloadTask)
                    return;
                for (DownloadPartData *part in trunkFileDownloadTask.listPart) {
                    if (part.task.taskIdentifier == taskId) {
                        NSString *fileName = part.nameOfPart;
                        NSURL* destinationUrl = [self localFilePathOfUrl:[NSURL URLWithString:fileName]];
                        NSError *saveFileError = nil;
                        [fileManager copyItemAtURL:location toURL:destinationUrl error:&saveFileError];
                        if (!saveFileError) {
                            trunkFileDownloadTask.countPartDownloaded ++;
                            part.storedUrl = destinationUrl;
                            NSLog(@"Finished download task at part %@ and stored at %@",part.nameOfPart, [part.storedUrl path]);
                        }
                        break;
                    }
                }
                if ([trunkFileDownloadTask isFinisedAllPart]) {
                    NSLog(@"Finished downloading all part");
                    NSString *fileMergedPath = [[self localFilePathOfUrl:[trunkFileDownloadTask.listPart firstObject].nameOfPart] path];
                    for (NSInteger index = 1; index < trunkFileDownloadTask.listPart.count; index++) {
                        DownloadPartData *dataOfPart = [trunkFileDownloadTask.listPart objectAtIndex:index];
                        NSString *path = [[self localFileOfFileName:dataOfPart.nameOfPart] path];
                        [self mergeFileAtPath:path toFileAtPath:fileMergedPath];
                    }
                    NSURL* destinationUrl = [self localFilePathOfUrl:sourceUrl];
                    NSURL* currentUrl = [[NSURL alloc] initFileURLWithPath:fileMergedPath];;
                    NSError *saveFileError = nil;
                    NSLog(@"Finished merge all part to 1 file");
                    [fileManager copyItemAtURL:currentUrl toURL:destinationUrl error:&saveFileError];
                    [self returnForAllTask:sourceUrl storedLocation:destinationUrl response:nil error:nil];

                }
            }
            default:
                break;
        }
        
    }
    
    // Degree current download, and increase total downloaded item.
    self.currentDownload--;
    self.downloadStatistics.totalTaskDownloaded++;
    
    // Start download item in waiting queue.
    [self downloadItemInWaitingQueue];
    
    // When fisnished download -> copy file from temp folder to destination folder -> return completion for all task waiting this.
//    if (location) {
//        NSString *keyOfTask = [sourceUrl absoluteString];
//        NSLog(@"Finished download");
//
//        NormalDownloadTask *downloadTask = [self.activeDownload objectForKey:keyOfTask];
//        if (downloadTask) {
//            downloadTask.downloadStatus = DownloadFinished;
//        }
//        NSURL* destinationUrl = [self localFilePathOfUrl:sourceUrl];
//        NSFileManager *fileManager = NSFileManager.defaultManager;
//        NSError *saveFileError = nil;
//
//        // Copy temp file after downloaded to destination path and stored with right format of file.
//        [fileManager copyItemAtURL:location toURL:destinationUrl error:&saveFileError];
//        if (saveFileError) {
//            downloadTask.downloadStatus = DownloadError;
//            [self returnForAllTask:sourceUrl storedLocation:nil response:nil error:DownloadErrorByCode(StoreLocalError)];
//        } else {
//            [self returnForAllTask:sourceUrl storedLocation:destinationUrl response:nil error:nil];
//        }
//    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSURL *sourceUrl = task.currentRequest.URL ? task.currentRequest.URL : task.originalRequest.URL;
    if (!sourceUrl) {
        return;
    }
    
    NSString *key = [sourceUrl absoluteString];
    NormalDownloadTask *downloadTask = [self.activeDownload objectForKey:key];
    
    if (!error) {
        return;
    } else if (error.code == NSURLErrorCancelled && [error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"]) {
        if (downloadTask.downloadStatus == DownloadPending) {
            return;
        }
        //[self isValidResumeData:[error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"]];
        if (self.observers.count > 0) {
            NSData *resumeData = [error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"];
            [self.resumeDataStored setObject:resumeData forKey:key];
            [self saveListResumeData];
            [self notifyHasPausingDownloadWithResumeData:sourceUrl resumeData:resumeData];
            return;
        }
        //DownloadTask *task = [DownloadTask alloc] initWithItem:
    }
    
    
    downloadTask.downloadStatus = DownloadError;
    [self returnForAllTask:sourceUrl storedLocation:nil response:nil error:DownloadErrorByCode(UnexpectedError)];
    
    
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
    id<DownloadTask> task = [self.activeDownload objectForKey:key];
    for (CompletionDownloadModel *completionModel in task.observers) {
        if (completionModel.progressBlock) {
            switch (task.downloadType) {
                case NormalDownload: {
                    task.progress = totalBytesWritten / totalBytesExpectedToWrite;
                    completionModel.progressBlock(task.downloadItem, totalBytesWritten, totalBytesExpectedToWrite);
                    break;
                }
                case TrunkFileDownload: {
                    TrunkFileDownloadTask *trunkFileTask = (TrunkFileDownloadTask *)task;
                    long long totalPartDownloaded = 0;
                    for (DownloadPartData *part in trunkFileTask.listPart) {
                        if (part.task.taskIdentifier == downloadTask.taskIdentifier) {
                            part.currentByteDownloaded = totalBytesWritten;
                        }
                        totalPartDownloaded += part.currentByteDownloaded;
                    }
                    task.progress = totalPartDownloaded / task.fileSize;
                    completionModel.progressBlock(task.downloadItem, totalPartDownloaded, task.fileSize);
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
}

#pragma mark - Downloader notify to all observers listening

- (void)notifyHasPausingDownloadWithResumeData:(NSURL*)source resumeData:(NSData*)resumeData {
    for (id<DownloaderObserverProtocol> observer in self.observers) {
        [observer didFailedDownloadByKilledWithUrl:source withResumeData:resumeData];
    }
}

- (void)notifyDidPauseAllDownload {
    for (id<DownloaderObserverProtocol> observer in self.observers) {
        [observer didPausedDownload];
    }
}

- (void)notifyDidResumeAllDownload {
    for (id<DownloaderObserverProtocol> observer in self.observers) {
        [observer didResumeAllDownload];
    }
}

- (void)addDownloadObserver:(id<DownloaderObserverProtocol>)downloaderProtocol {
    if (downloaderProtocol) {
        [self.observers addObject:downloaderProtocol];
        for (NSString *key in self.resumeDataStored.allKeys) {
            NSURL *url = [[NSURL alloc] initWithString:key];
            NSData *resumeData = [self.resumeDataStored objectForKey:key];
            if (url && resumeData) {
                [self notifyHasPausingDownloadWithResumeData:url resumeData:resumeData];
            }
        }
    }
}

#pragma mark - fix resume data for iOS < 10.2

-(BOOL)isValidResumeData:(NSData *)data {
    if (!data || [data length] < 1) return NO;
       NSError *error;
       NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:kCFPropertyListMutableContainersAndLeaves format:nil error:&error];
       if (!resumeDictionary || error) return NO;

       NSString *resumeDataFileName = resumeDictionary[@"NSURLSessionResumeInfoTempFileName"];
       NSString *newTempPath = NSTemporaryDirectory();
       NSString *newResumeDataPath = [newTempPath stringByAppendingPathComponent:resumeDataFileName];
       [resumeDictionary setValue:newResumeDataPath forKey:@"NSURLSessionResumeInfoLocalPath"];


       NSString *localTmpFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
       if ([localTmpFilePath length] < 1) return NO;

       BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:localTmpFilePath];

       if (!result) {
           NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
           NSString *localName = [localTmpFilePath lastPathComponent];
           NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
           NSString *cachesDir = [paths objectAtIndex:0];
           NSString *localCachePath = [[[cachesDir stringByAppendingPathComponent:@"com.apple.nsurlsessiond/Downloads"]stringByAppendingPathComponent:bundleIdentifier]stringByAppendingPathComponent:localName];
           result = [[NSFileManager defaultManager] moveItemAtPath:localCachePath toPath:localTmpFilePath error:nil];
       }
       return result;
}

- (NSMutableDictionary *)getResumDictionary:(NSData *)data
{
    NSMutableDictionary *iresumeDictionary;
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion >= 10) {
        NSMutableDictionary *root;
        NSError *error = nil;
        NSKeyedUnarchiver *keyedUnarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        root = [keyedUnarchiver decodeTopLevelObjectForKey:@"NSKeyedArchiveRootObjectKey" error:&error];
        if (!root) {
            root = [keyedUnarchiver decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:&error];
        }
        [keyedUnarchiver finishDecoding];
        iresumeDictionary = root;
    }

    if (!iresumeDictionary) {
        iresumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];
    }
    return iresumeDictionary;
}

- (NSData *)correctResumData:(NSData *)data {
    NSMutableDictionary *resumeDictionary = [self getResumDictionary:data];
    if (!data || !resumeDictionary) {
        return nil;
    }

    resumeDictionary[kResumeCurrentRequest] = [self correctRequestData:[resumeDictionary objectForKey:kResumeCurrentRequest]];
    resumeDictionary[kResumeOriginalRequest] = [self correctRequestData:[resumeDictionary objectForKey:kResumeOriginalRequest]];

    NSData *result = [NSPropertyListSerialization dataWithPropertyList:resumeDictionary format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
    return result;
}

- (NSData *)correctRequestData:(NSData *)data {
    if (!data) {
        return nil;
    }
    if ([NSKeyedUnarchiver unarchiveObjectWithData:data]) {
        return data;
    }

    NSMutableDictionary *archive = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
    if (!archive) {
        return nil;
    }
    int k = 0;
    while ([[archive[@"$objects"] objectAtIndex:1] objectForKey:[NSString stringWithFormat:@"$%d", k]]) {
        k += 1;
    }

    int i = 0;
    while ([[archive[@"$objects"] objectAtIndex:1] objectForKey:[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]]) {
        NSMutableArray *arr = archive[@"$objects"];
        NSMutableDictionary *dic = [arr objectAtIndex:1];
        id obj;
        if (dic) {
            obj = [dic objectForKey:[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]];
            if (obj) {
                [dic setObject:obj forKey:[NSString stringWithFormat:@"$%d",i + k]];
                [dic removeObjectForKey:[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]];
                arr[1] = dic;
                archive[@"$objects"] = arr;
            }
        }
        i += 1;
    }
    if ([[archive[@"$objects"] objectAtIndex:1] objectForKey:@"__nsurlrequest_proto_props"]) {
        NSMutableArray *arr = archive[@"$objects"];
        NSMutableDictionary *dic = [arr objectAtIndex:1];
        if (dic) {
            id obj;
            obj = [dic objectForKey:@"__nsurlrequest_proto_props"];
            if (obj) {
                [dic setObject:obj forKey:[NSString stringWithFormat:@"$%d",i + k]];
                [dic removeObjectForKey:@"__nsurlrequest_proto_props"];
                arr[1] = dic;
                archive[@"$objects"] = arr;
            }
        }
    }

    id obj = [archive[@"$top"] objectForKey:@"NSKeyedArchiveRootObjectKey"];
    if (obj) {
        [archive[@"$top"] setObject:obj forKey:NSKeyedArchiveRootObjectKey];
        [archive[@"$top"] removeObjectForKey:@"NSKeyedArchiveRootObjectKey"];
    }
    NSData *result = [NSPropertyListSerialization dataWithPropertyList:archive format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    return result;
}

- (void) mergeFileAtPath:(NSString*)sourcePath toFileAtPath:(NSString*)destinationPath {
    NSFileHandle *fileReader = [NSFileHandle fileHandleForReadingAtPath:sourcePath];
    NSFileHandle *fileWriter = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
    
    [fileReader seekToEndOfFile];
    long long fileReadLength = [fileReader offsetInFile];
    [fileWriter seekToEndOfFile];
    
    long long currentOffset = 0;
    [fileReader seekToFileOffset:0];
 
    while (currentOffset < fileReadLength) {
        NSData *data = [[fileReader readDataOfLength:10000] copy];
        [fileWriter writeData:data];
        currentOffset += [data length];
        data = nil;
    }
    
    [fileReader closeFile];
    [fileWriter closeFile];

}

@end










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
