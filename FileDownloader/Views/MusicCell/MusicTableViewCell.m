//
//  MusicTableViewCell.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/17/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "MusicTableViewCell.h"
#import "Masonry.h"

@interface MusicTableViewCell ()

@property (weak, nonatomic) MusicItem* musicModel;
@property (nonatomic, readwrite) DownloadStatus currrentStatus;

@end

@implementation MusicTableViewCell

+ (NSString *)cellIdentifier {
    return @"MusicTableViewCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
        [self setupLayout];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

}

- (void)setupViews {
    self.artistNameLabel = [UILabel new];
    [self.contentView addSubview:self.artistNameLabel];
    
    self.songNameLabel = [UILabel new];
    [self.contentView addSubview:self.songNameLabel];
    
    self.downloadView = [UIView new];
    [self.contentView addSubview:self.downloadView];
    
    self.cancelButton = [UIButton new];
    [self.downloadView addSubview:self.cancelButton];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelDownload:) forControlEvents:UIControlEventTouchUpInside];
    
    self.pauseButton = [UIButton new];
    [self.downloadView addSubview:self.pauseButton];
    [self.pauseButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [self.pauseButton addTarget:self action:@selector(pauseDownload:) forControlEvents:UIControlEventTouchUpInside];

    self.downloadButton = [UIButton new];
    [self.downloadView addSubview:self.downloadButton];
    [self.downloadButton setTitle:@"Download" forState:UIControlStateNormal];
    [self.downloadButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [self.downloadButton addTarget:self action:@selector(startDownload:) forControlEvents:UIControlEventTouchUpInside];

    self.downloadProgressView = [UIProgressView new];
    [self.downloadProgressView setProgress:0];
    [self.contentView addSubview:self.downloadProgressView];
    
    self.downloadStatusLabel = [UILabel new];
    [self.downloadStatusLabel setTextColor:UIColor.lightGrayColor];
    [self.downloadStatusLabel setFont:[UIFont systemFontOfSize:12]];
    [self.contentView addSubview:self.downloadStatusLabel];
    
    self.bottomLine = [UIView new];
    [self.bottomLine setBackgroundColor:UIColor.lightGrayColor];
    [self.contentView addSubview:self.bottomLine];
}

- (void)setupLayout {
    [self.bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.contentView.mas_bottom);
        make.leading.equalTo(self.contentView.mas_leading).offset(12);
        make.trailing.equalTo(self.contentView.mas_trailing).offset(-12);
        make.height.offset(1);
    }];
    
    [self.songNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(10);
        make.leading.equalTo(self.contentView).offset(12);
        make.trailing.equalTo(self.downloadButton.mas_leading).offset(-8);
    }];
    
    [self.artistNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.songNameLabel.mas_bottom).offset(5);
        make.leading.equalTo(self.contentView).offset(12);
        make.trailing.equalTo(self.downloadButton.mas_leading).offset(-8);
    }];
    
    [self.downloadView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView.mas_trailing).offset(-12);
        make.width.offset(145);
        make.height.offset(60);
    }];
    
    [self.downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.leading.trailing.equalTo(self.downloadView);
    }];
    
    [self.downloadProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.artistNameLabel.mas_bottom).offset(5);
        make.leading.equalTo(self.contentView).offset(12);
        make.trailing.equalTo(self.downloadButton.mas_leading).offset(-8);
    }];
    
    [self.downloadStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.downloadProgressView.mas_bottom).offset(5);
        make.leading.equalTo(self.contentView.mas_leading).offset(12);
    }];
    
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView.mas_trailing).offset(-12);
        make.width.offset(70);
        make.height.offset(60);
    }];
    
    [self.pauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.cancelButton.mas_leading).offset(-5);
        make.width.offset(70);
        make.height.offset(60);
    }];
}

- (void)configCellWithItem:(MusicItem*)model downloadStatus:(DownloadStatus)downloadStatus {
    self.musicModel = model;
    self.currrentStatus = downloadStatus;
    [self.songNameLabel setText:model.songName];
    [self.artistNameLabel setText:model.artistName];
    [self.downloadProgressView setHidden:NO];
    if (model.storedLocalPath) {
        [self.downloadView setHidden:YES];
        [self.downloadProgressView setHidden:YES];
        [self.downloadStatusLabel setText:@"Finished."];
        [self.downloadStatusLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.artistNameLabel.mas_bottom).offset(5);
        }];
    } else {
        switch (downloadStatus) {
            case DownloadStatusDownloading:
                [self.downloadProgressView setHidden:NO];
                [self showDownload:NO];
                [self.downloadStatusLabel setText:@"Downloading.."];
                [self.pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
                break;
            case DownloadPending:
            case DownloadPauseBySystem:
                [self.pauseButton setTitle:@"Resume" forState:UIControlStateNormal];
                [self showDownload:NO];
                [self.downloadStatusLabel setText:@"Pausing."];
                break;
            case DownloadFinished: {
                [self.downloadProgressView setHidden:YES];
                [self.downloadView setHidden:YES];
                [self.downloadStatusLabel setText:@"Finished."];
                [self.downloadStatusLabel mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(self.artistNameLabel.mas_bottom).offset(5);
                }];
                break;
            }
            case DownloadCanceled:
                [self showDownload:YES];
                [self.downloadStatusLabel setText:@"Canceled."];
                break;
            case DownloadWaiting:
                [self showDownload:NO];
                [self.pauseButton setHidden:YES];
                [self.downloadStatusLabel setText:@"Wating"];
                break;
            case DownloadError:
                [self showDownload:YES];
            default:
                [self showDownload:YES];
                break;
        }
    }
}

- (void)showDownload:(BOOL)isShow {
    [self.downloadButton setHidden:!isShow];
    [self.cancelButton setHidden:isShow];
    [self.pauseButton setHidden:isShow];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.downloadProgressView setProgress:0.f];
}

- (void)updateProgress:(float)progress total:(NSString*)totalSize {
    [self.downloadProgressView setProgress:progress];
    [self.downloadStatusLabel setText:[NSString stringWithFormat:@"Downloading.. %.1f%% of %@", progress * 100, totalSize]];
}

- (void)startDownload:(UIButton *)sender {
    if (self.delegate && self.musicModel) {
        [self.delegate startDownload:self.musicModel];
    }
}

- (void)pauseDownload:(UIButton *)sender {
    if (self.delegate && self.musicModel) {
        if (self.currrentStatus == DownloadStatusDownloading) {
            [self.delegate pauseDownload:self.musicModel];
        } else {
            [self.delegate resumeDownload:self.musicModel];
        }
    }
}

- (void)resumeDownload:(UIButton *)sender {
    if (self.delegate && self.musicModel) {
        [self.delegate resumeDownload:self.musicModel];

    }
}

- (void)cancelDownload:(UIButton *)sender {
    if (self.delegate && self.musicModel) {
        [self.delegate cancelDownload:self.musicModel];
    }
}


@end
