//
//  MusicTableViewCell.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/17/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicModel.h"
#import "DownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MusicCellDelegete <NSObject>

- (void)cancelDownload:(MusicModel*)model;
- (void)pauseDownload:(MusicModel*)model;
- (void)resumeDownload:(MusicModel*)model;
- (void)startDownload:(MusicModel*)model;

@end

@interface MusicTableViewCell : UITableViewCell

+ (NSString *)cellIdentifier;
@property (strong, nonatomic) UILabel *songNameLabel;
@property (strong, nonatomic) UILabel *artistNameLabel;
@property (strong, nonatomic) UIView *downloadView;
@property (strong, nonatomic) UIButton *downloadButton;
@property (strong, nonatomic) UIButton *pauseButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIProgressView *downloadProgressView;
@property (weak, nonatomic) id<MusicCellDelegete> delegate;

- (void)configCellWithItem:(MusicModel*)model downloadStatus:(DownloadStatus)downloadStatus;

- (void)updateProgress:(float)progress total:(NSString*)totalSize;

@end

NS_ASSUME_NONNULL_END
