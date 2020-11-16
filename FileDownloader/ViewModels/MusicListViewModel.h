//
//  MusicListViewModel.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/19/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadManager.h"
#import "NormalDownloadTask.h"
#import "MusicItem.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MusicListDelegate <NSObject>

- (void)reloadRowsAtIndexPath:(NSIndexPath*)index;
- (void)reloadData;
- (void)updateProgressAtIndexPath:(NSIndexPath*)index;

@end

@interface MusicListViewModel : NSObject

@property (nonatomic, readonly) NSArray *listMusics;

@property (nonatomic, copy)void (^reloadData)(void);
@property (nonatomic, copy)void (^updateProgressAtIndex)(NSInteger index, float progress, NSString *totalSize);
@property (nonatomic, copy)void (^reloadRowsAtIndex)(NSInteger index);
@property (nonatomic, copy)void (^showError)(NSError *error);

- (DownloadStatus)getStatusOfModel:(MusicItem*)model;

- (void)startDownload:(MusicItem *)model;

- (void)pauseDownload:(MusicItem *)model;

- (void)resumeDownload:(MusicItem *)model;

- (void)cancelDownload:(MusicItem *)model;

- (void)subcribleWithDownloader;

@end


NS_ASSUME_NONNULL_END
