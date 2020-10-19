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

@property (weak, nonatomic) MusicModel* musicModel;

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
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
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
    
    self.pauseButton = [UIButton new];
    [self.downloadView addSubview:self.pauseButton];
    
    self.downloadButton = [UIButton new];
    [self.downloadView addSubview:self.downloadButton];
    [self.downloadButton setTitle:@"Download" forState:UIControlStateNormal];
    [self.downloadButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [self.downloadButton addTarget:self action:@selector(startDownload:) forControlEvents:UIControlEventTouchUpInside];

    self.downloadProgressView = [UIProgressView new];
    [self.contentView addSubview:self.downloadProgressView];
    
}

- (void)setupLayout {
    [self.songNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(6);
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
        make.width.offset(125);
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
    
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView.mas_trailing).offset(-12);
        make.width.offset(60);
        make.height.offset(60);
    }];
    
    [self.pauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.cancelButton.mas_leading).offset(-5);
        make.width.offset(60);
        make.height.offset(60);
    }];
}

- (void)configCellWithItem:(MusicModel*)model downloadStatus:(DownloadStatus)downloadStatus {
    self.musicModel = model;
    [self.songNameLabel setText:model.songName];
    [self.artistNameLabel setText:model.artistName];
    if (model.storedLocalPath) {
        [self.downloadView setHidden:YES];
    } else {
        switch (downloadStatus) {
            case Downloading:
                [self.downloadButton setHidden:YES];
                [self.pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
                break;
            case Pending:
            case PauseBySystem:
                [self.pauseButton setTitle:@"Resume" forState:UIControlStateNormal];
                [self.cancelButton setHidden:NO];
            case Finished:
                [self.downloadView setHidden:YES];
            case Canceled:
                [self.downloadButton setHidden:NO];
                [self.cancelButton setHidden:YES];
                [self.pauseButton setHidden:YES];
            default:
                break;
        }
    }
}

- (void)startDownload:(UIButton *)sender {
    if (self.delegate && self.musicModel) {
        [self.delegate startDownload:self.musicModel];
    }
}

- (void)pauseDownload:(UIButton *)sender {
    if (self.delegate && self.musicModel) {
        [self.delegate pauseDownload:self.musicModel];
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
