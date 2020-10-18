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
    
    self.downloadButton = [UIButton new];
    [self.contentView addSubview:self.downloadButton];
    [self.downloadButton setTitle:@"Download" forState:UIControlStateNormal];
    [self.downloadButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [self.downloadButton addTarget:self action:@selector(startDownload:) forControlEvents:UIControlEventTouchUpInside];

    
    self.cancelButton = [UIButton new];
    [self.contentView addSubview:self.cancelButton];
    
    self.pauseButton = [UIButton new];
    [self.contentView addSubview:self.pauseButton];
    
    self.downloadProgressView = [UIProgressView new];
    [self.contentView addSubview:self.downloadProgressView];
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
    
    [self.downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView.mas_trailing).offset(-12);
        make.width.offset(120);
        make.height.offset(60);
    }];
    
    [self.downloadProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.artistNameLabel.mas_bottom).offset(5);
        make.leading.equalTo(self.contentView).offset(12);
        make.trailing.equalTo(self.downloadButton.mas_leading).offset(-8);
    }];
}

- (void)configCellWithItem:(MusicModel*)model {
    self.musicModel = model;
    [self.songNameLabel setText:model.songName];
    [self.artistNameLabel setText:model.artistName];
}

@end
