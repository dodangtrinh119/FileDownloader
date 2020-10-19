//
//  MusicListViewController.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/17/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "MusicListViewController.h"
#import "Masonry.h"
#import "MusicListViewModel.h"
#import "MusicTableViewCell.h"
#import <AVKit/AVKit.h>

@interface MusicListViewController () <UITableViewDelegate, UITableViewDataSource, MusicCellDelegete>

@property (nonatomic, strong) MusicListViewModel *viewModel;

@end

@implementation MusicListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewModel = [[MusicListViewModel alloc] init];
    [self setupView];
    [self setupLayout];
    [self setupViewModel];
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

- (void)setupViewModel {
    __weak typeof(self) weakSelf = self;
    [self.viewModel setObserverDownloadProgress];
    
    self.viewModel.reloadData = ^{
        [weakSelf.musicTableView reloadData];
    };
    
    self.viewModel.reloadRowsAtIndex = ^(NSInteger index) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.musicTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        });
    };
    
    self.viewModel.updateProgressAtIndex = ^(NSInteger index, float progress, NSString * _Nonnull totalSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MusicTableViewCell *cell = [weakSelf.musicTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            [cell updateProgress:progress total:totalSize];
        });
    };
    
    self.viewModel.showError = ^(NSError * _Nonnull error) {
        
    };
}

- (void)playMusic:(MusicModel*)model {
    if (model.storedLocalPath) {
        AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];
        [self presentViewController:playerController animated:YES completion:nil];
        AVPlayer* player = [[AVPlayer alloc] initWithURL:model.storedLocalPath];
        [playerController setPlayer:player];
        [player play];
    }
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MusicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MusicTableViewCell.cellIdentifier];
    MusicModel *model = [self.viewModel.listMusics objectAtIndex:indexPath.row];
    cell.delegate = self;
    [cell configCellWithItem:model downloadStatus:[self.viewModel getStatusOfModel:model]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90.f;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.listMusics.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MusicModel *model = [self.viewModel.listMusics objectAtIndex:indexPath.row];
    [self playMusic:model];
}

- (void)startDownload:(MusicModel *)model {
    if (!model) {
        return;
    }
    [self.viewModel startDownload:model];
}

- (void)cancelDownload:(nonnull MusicModel *)model {
    if (!model) {
        return;
    }
    [self.viewModel cancelDownload:model];
}

- (void)pauseDownload:(nonnull MusicModel *)model {
    if (!model) {
        return;
    }
    [self.viewModel pauseDownload:model];
}

- (void)resumeDownload:(nonnull MusicModel *)model {
    if (!model) {
        return;
    }
    [self.viewModel resumeDownload:model];
}

@end
