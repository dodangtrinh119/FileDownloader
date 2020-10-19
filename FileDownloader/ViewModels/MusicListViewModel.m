//
//  MusicListViewModel.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/19/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "MusicListViewModel.h"
#import "Utils.h"

@interface MusicListViewModel()

@property (nonatomic, readwrite) NSArray *listMusics;

@end

@implementation MusicListViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.listMusics = [Utils createHardCodeData];
    }
    return self;
}

- (void)startDownload:(MusicModel *)model {
    __weak typeof(self) weakSelf = self;
    [[DownloadBussiness sharedInstance] downloadAndStored:model completion:^(NSURL * _Nullable location, NSError * _Nullable error) {
        if (error) {
            weakSelf.showError(error);
        }
        if (location) {
            NSInteger index = [weakSelf.listMusics indexOfObject:model];
            [weakSelf updateLocalPathOfModel:index localStoredPath:location];
            weakSelf.reloadRowsAtIndex(index);
        }
    }];
}

- (void)updateLocalPathOfModel:(NSInteger)index localStoredPath:(NSURL*)path {
    if (index >= self.listMusics.count) {
        return;
    }
    MusicModel *model = [self.listMusics objectAtIndex:index];
    if (model) {
        model.storedLocalPath = path;
    }
}

- (void)cancelDownload:(nonnull MusicModel *)model {
    [[DownloadBussiness sharedInstance] cancelDownload:model];
}

- (void)pauseDownload:(nonnull MusicModel *)model {
    [[DownloadBussiness sharedInstance] pauseDownload:model];
}

- (void)resumeDownload:(nonnull MusicModel *)model {
    __weak typeof(self) weakSelf = self;
    [[DownloadBussiness sharedInstance] resumeDownloadAndStored:model completion:^(NSURL * _Nullable location, NSError * _Nullable error) {
        if (error) {
            weakSelf.showError(error);
            return;
        }
        NSUInteger index = [weakSelf.listMusics indexOfObject:model];
        [weakSelf updateLocalPathOfModel:index localStoredPath:location];
        weakSelf.reloadRowsAtIndex(index);
    }];
}

- (DownloadStatus)getStatusOfModel:(MusicModel *)model {
    return [[DownloadBussiness sharedInstance] getStatusOfModel:model];
}

@end
