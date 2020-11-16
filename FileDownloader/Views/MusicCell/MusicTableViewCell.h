//
//  MusicTableViewCell.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/17/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicItem.h"
#import "NormalDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MusicCellDelegete <NSObject>

- (void)cancelDownload:(MusicItem*)model;
- (void)pauseDownload:(MusicItem*)model;
- (void)resumeDownload:(MusicItem*)model;
- (void)startDownload:(MusicItem*)model;

@end

@interface MusicTableViewCell : UITableViewCell

+ (NSString *)cellIdentifier;
@property (strong, nonatomic) UILabel *downloadStatusLabel;
@property (strong, nonatomic) UILabel *songNameLabel;
@property (strong, nonatomic) UILabel *artistNameLabel;
@property (strong, nonatomic) UIView *downloadView;
@property (strong, nonatomic) UIView *bottomLine;
@property (strong, nonatomic) UIButton *downloadButton;
@property (strong, nonatomic) UIButton *pauseButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIProgressView *downloadProgressView;
@property (weak, nonatomic) id<MusicCellDelegete> delegate;

- (void)configCellWithItem:(MusicItem*)model downloadStatus:(DownloadStatus)downloadStatus;

- (void)updateProgress:(float)progress total:(NSString*)totalSize;

@end

NS_ASSUME_NONNULL_END
