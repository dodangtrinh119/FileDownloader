//
//  MusicListViewModel.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/19/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "MusicListViewModel.h"
#import "Utils.h"

@interface MusicListViewModel() <DownloaderObserverProtocol>

@property (nonatomic, readwrite) NSArray *listMusics;

@end

@implementation MusicListViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.listMusics = [Utils createHardCodeData];
        [self updateHardCodeData];
    }
    return self;
}

- (void)updateHardCodeData {
    NSArray *listDownloaded = [[DownloadManager sharedInstance] getListItemDownloaded];
    for (MusicItem *model in self.listMusics) {
        if ([listDownloaded containsObject:[model.downloadURL absoluteString]]) {
            model.storedLocalPath = [[DownloadManager sharedInstance] getLocalStoredPathOfItem:model];
        }
    }
}

- (void)subcribleWithDownloader {
    [[DownloadManager sharedInstance] addObserverForDownloader:self];
}

- (void)updateLocalPathOfModel:(NSInteger)index localStoredPath:(NSURL*)path {
    if (index >= self.listMusics.count) {
        return;
    }
    MusicItem *model = [self.listMusics objectAtIndex:index];
    if (model) {
        model.storedLocalPath = [path absoluteString];
    }
}

- (void)startDownload:(MusicItem *)model {
    NSInteger index = [self.listMusics indexOfObject:model];
    NSInteger randomPriority = RAND_FROM_TO(1, 3);
    __weak typeof(self) weakSelf = self;
    [[DownloadManager sharedInstance] startDownloadItem:model isTrunkFileDownload:YES withPriority:randomPriority downloadProgressBlock:^(id<DownloadableItem> item, int64_t byteWritten, int64_t totalByte) {
        [weakSelf updateDownloadProgressOfItem:item currentByte:byteWritten totalByte:totalByte];
    } completion:^(NSURL * _Nullable location, NSError * _Nullable error) {
        [weakSelf didFinishDownloadItem:model localStoredPath:location error:error];
    }];
    self.reloadRowsAtIndex(index);
}

- (void)cancelDownload:(nonnull MusicItem *)model {
    NSInteger index = [self.listMusics indexOfObject:model];
    [[DownloadManager sharedInstance] cancelDownloadItem:model];
    self.reloadRowsAtIndex(index);
}

- (void)pauseDownload:(nonnull MusicItem *)model {
    NSInteger index = [self.listMusics indexOfObject:model];
    [[DownloadManager sharedInstance] pauseDownloadItem:model];
    self.reloadRowsAtIndex(index);
}

- (void)resumeDownload:(nonnull MusicItem *)model {
    NSInteger index = [self.listMusics indexOfObject:model];
    __weak typeof(self) weakSelf = self;
    [[DownloadManager sharedInstance] resumeDownloadItem:model completion:^(NSURL * _Nullable location, NSError * _Nullable error) {
        [weakSelf didFinishDownloadItem:model localStoredPath:location error:error];
    }];
    self.reloadRowsAtIndex(index);
}

- (void)didFinishDownloadItem:(MusicItem*)item localStoredPath:(NSURL*)location error:(NSError*)error {
    NSUInteger index = [self.listMusics indexOfObject:item];
    if (error && error.code != MaximumDownloading) {
        self.showError(error);
    }
    
    if (location) {
        [self updateLocalPathOfModel:index localStoredPath:location];
    }
    if (index != NSNotFound) {
        self.reloadRowsAtIndex(index);
    }
}

- (void)updateDownloadProgressOfItem:(MusicItem*)model currentByte:(int64_t)totalBytesWritten totalByte:(int64_t)totalBytes {
    if (self.updateProgressAtIndex) {
        NSInteger index = [self.listMusics indexOfObject:model];
        float current = totalBytesWritten;
        float total = totalBytes;
        float progress = current / total;
        NSString *totalString = [NSByteCountFormatter stringFromByteCount:totalBytes countStyle:NSByteCountFormatterCountStyleFile];
        self.updateProgressAtIndex(index, progress, totalString);
    }
    
}

- (DownloadStatus)getStatusOfModel:(MusicItem *)model {
    return [[DownloadManager sharedInstance] getStatusOfModel:model];
}

- (void)didPausedDownload {
    self.reloadData();
}

- (void)didResumeAllDownload {
    self.reloadData();
}

- (void)hasPausingNormalDownloadTaskWith:(nonnull NSURL *)url withResumeData:(nonnull NSData *)resumeData {
    for (NSInteger i = 0; i < self.listMusics.count; i++) {
        MusicItem *item = [self.listMusics objectAtIndex:i];
        if ([[item.downloadURL absoluteString] isEqual:[url absoluteString]]) {
            __weak typeof(self) weakSelf = self;
            [[DownloadManager sharedInstance] createNormalDownloadTaskWithItem:item withResumeData:resumeData withPriority:DownloadTaskPriroityHigh downloadProgressBlock:^(id<DownloadableItem> item, int64_t byteWritten, int64_t totalByte) {
                            [weakSelf updateDownloadProgressOfItem:item currentByte:byteWritten totalByte:totalByte];
                        } completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                            [weakSelf didFinishDownloadItem:item localStoredPath:location error:error];
                        }];
            self.reloadRowsAtIndex(i);
            return;
        }
    }
}

- (void)hasPausingTrunkFileDownloadDataWithUrl:(NSURL *)url withDownloadData:(NSDictionary *)trunkFileData {
    for (NSInteger i = 0; i < self.listMusics.count; i++) {
        MusicItem *item = [self.listMusics objectAtIndex:i];
        if ([[item.downloadURL absoluteString] isEqual:[url absoluteString]]) {
            __weak typeof(self) weakSelf = self;
            [[DownloadManager sharedInstance] createTrunkFileDownloadTaskWithItem:item withData:trunkFileData withPriority:DownloadTaskPriroityHigh downloadProgressBlock:^(id<DownloadableItem>  _Nonnull item, int64_t byteWritten, int64_t totalByte) {
                [weakSelf updateDownloadProgressOfItem:item currentByte:byteWritten totalByte:totalByte];
            } completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [weakSelf didFinishDownloadItem:item localStoredPath:location error:error];
            }];
            self.reloadRowsAtIndex(i);
        }
    }
}


@end
