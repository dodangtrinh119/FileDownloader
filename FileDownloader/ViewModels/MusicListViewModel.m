//
//  MusicListViewModel.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/19/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "MusicListViewModel.h"
#import "Utils.h"

@interface MusicListViewModel() <DownloadBussinessDelegate>

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
    NSArray *listDownloaded = [[DownloadBussiness sharedInstance] getListStored];
    for (MusicItem *model in self.listMusics) {
        if ([listDownloaded containsObject:[model.downloadURL absoluteString]]) {
            model.storedLocalPath = [[DownloadBussiness sharedInstance] getLocalStoredPathOfItem:model];
        }
    }
}

- (void)setObserverDownloadProgress {
    __weak typeof(self) weakSelf = self;
    [[DownloadBussiness sharedInstance] setProgressUpdate:^(id<DownloadableItem>  _Nonnull source, int64_t byteWritten, int64_t totalByte) {
        [weakSelf updateProgressWithSource:source currentByte:byteWritten totalByte:totalByte];
    }];
    [DownloadBussiness sharedInstance].delegate = self;
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
    __weak typeof(self) weakSelf = self;
    [[DownloadBussiness sharedInstance] downloadAndStored:model completion:^(NSURL * _Nullable location, NSError * _Nullable error) {
        if (error && error.code != MaximumDownloading) {
            weakSelf.showError(error);
        }
        if (location) {
            NSInteger index = [weakSelf.listMusics indexOfObject:model];
            [weakSelf updateLocalPathOfModel:index localStoredPath:location];
        }
        weakSelf.reloadRowsAtIndex(index);

    }];
    self.reloadRowsAtIndex(index);
}

- (void)cancelDownload:(nonnull MusicItem *)model {
    NSInteger index = [self.listMusics indexOfObject:model];
    [[DownloadBussiness sharedInstance] cancelDownload:model];
    self.reloadRowsAtIndex(index);
}

- (void)pauseDownload:(nonnull MusicItem *)model {
    NSInteger index = [self.listMusics indexOfObject:model];
    [[DownloadBussiness sharedInstance] pauseDownload:model];
    self.reloadRowsAtIndex(index);
}

- (void)resumeDownload:(nonnull MusicItem *)model {
    NSInteger index = [self.listMusics indexOfObject:model];
    __weak typeof(self) weakSelf = self;
    [[DownloadBussiness sharedInstance] resumeDownloadAndStored:model completion:^(NSURL * _Nullable location, NSError * _Nullable error) {
        if (error && error.code != MaximumDownloading) {
            weakSelf.showError(error);
        }
        
        if (location) {
            NSUInteger index = [weakSelf.listMusics indexOfObject:model];
            [weakSelf updateLocalPathOfModel:index localStoredPath:location];
        }
        
        weakSelf.reloadRowsAtIndex(index);
    }];
    self.reloadRowsAtIndex(index);

}

- (void)updateProgressWithSource:(MusicItem*)model currentByte:(int64_t)totalBytesWritten totalByte:(int64_t)totalBytes {
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
    return [[DownloadBussiness sharedInstance] getStatusOfModel:model];
}

- (void)didPausedDownload {
    self.reloadData();
}

- (void)didResumeAllDownload {
    self.reloadData();
}

@end
