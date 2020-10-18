//
//  MusicListViewController.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/17/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "MusicListViewController.h"
#import "Masonry.h"
#import "Utils.h"
#import "MusicTableViewCell.h"
#import "DownloadBussiness.h"
#import <AVKit/AVKit.h>

@interface MusicListViewController () <UITableViewDelegate, UITableViewDataSource, MusicCellDelegete>

@property (nonatomic, strong) NSArray* listMusics;

@end

@implementation MusicListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.listMusics = [Utils createHardCodeData];
    [self setupView];
    [self setupLayout];
    [self.musicTableView reloadData];
    
}

- (void)setupView {
    self.musicTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.musicTableView.delegate = self;
    self.musicTableView.dataSource = self;
    [self.musicTableView setBackgroundColor:UIColor.blueColor];
    self.musicTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.musicTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.musicTableView registerClass:[MusicTableViewCell class] forCellReuseIdentifier:MusicTableViewCell.cellIdentifier];
  
    [self.view addSubview:self.musicTableView];
}

- (void)setupLayout {
    [self.musicTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.leading.trailing.equalTo(self.view);
    }];
}

- (void)playMusic:(MusicModel*)model {
    AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];
    [self presentViewController:playerController animated:YES completion:nil];
    NSURL *downloadUrl = [[NSURL alloc] initWithString:model.downloadURL];
    NSURL* url = [[DownloadBussiness sharedInstance] localFilePath:downloadUrl];
    AVPlayer* player = [[AVPlayer alloc] initWithURL:url];
    [playerController setPlayer:player];
    [player play];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MusicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MusicTableViewCell.cellIdentifier];
    MusicModel *model = [self.listMusics objectAtIndex:indexPath.row];
    cell.delegate = self;
    [cell configCellWithItem:model];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.f;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listMusics.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MusicModel *model = [self.listMusics objectAtIndex:indexPath.row];
    [self playMusic:model];
}

- (void)startDownload:(MusicModel *)model {
    [[DownloadBussiness sharedInstance] downloadAndStored:model completion:^(NSURL * _Nullable location, NSError * _Nullable error) {
        NSLog(@"abc");
    }];
}

- (void)cancelDownload:(nonnull MusicModel *)model {
    
}

- (void)pauseDownload:(nonnull MusicModel *)model {
    
}

- (void)resumeDownload:(nonnull MusicModel *)model {
    
}

@end
