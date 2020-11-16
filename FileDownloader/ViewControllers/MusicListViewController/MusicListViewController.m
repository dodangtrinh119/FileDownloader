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
#import "FileReader.h"
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel subcribleWithDownloader];
}

- (void)setupView {
    self.musicTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.musicTableView.delegate = self;
    self.musicTableView.dataSource = self;
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
    
    self.viewModel.reloadData = ^{
        [weakSelf.musicTableView reloadData];
    };
    
    self.viewModel.reloadRowsAtIndex = ^(NSInteger index) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.musicTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        });
    };
    
    self.viewModel.showError = ^(NSError * _Nonnull error) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Thông báo"
                                                                                 message:error.localizedDescription
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        //We add buttons to the alert controller by creating UIAlertActions:
        UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alertController addAction:actionOk];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alertController animated:YES completion:nil];
        });
    };
    
    self.viewModel.updateProgressAtIndex = ^(NSInteger index, float progress, NSString * _Nonnull totalSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MusicTableViewCell *cell = [weakSelf.musicTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            [cell updateProgress:progress total:totalSize];
        });
    };
    
}

- (void)playMusic:(MusicItem*)model {
    NSURL *storedPath = nil;
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    if (URLs && URLs.count > 0) {
        storedPath = [URLs firstObject];
    }
    NSLog(@"Start merge all part to 1 file");

    NSURL *url1 = [storedPath URLByAppendingPathComponent:@"part0.tmp"];

    NSFileManager *fileManager = NSFileManager.defaultManager;
    FileReader * reader = [[FileReader alloc] init];

    for (NSInteger i = 1; i < 3; i++) {
        NSString* fileName = [NSString stringWithFormat:@"part%ld.tmp",i];
        NSURL *url2 = [storedPath URLByAppendingPathComponent:fileName];
        [reader mergeFileAtPath:[url2 path] toFileAtPath:[url1 path]];
    }
    
    NSURL* destinationUrl = [storedPath URLByAppendingPathComponent:@"abc.zip"];
    NSURL* currentUrl = url1;
    NSError *saveFileError = nil;
    [fileManager copyItemAtURL:currentUrl toURL:destinationUrl error:&saveFileError];
    NSLog(@"Finished merge all part to 1 file");
    
    //[reader readLine];

    
    
    
    
    if (model.storedLocalPath) {
        AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];
        [self presentViewController:playerController animated:YES completion:nil];
        NSURL *localUrl = [[NSURL alloc] initWithString:model.storedLocalPath];
        AVPlayer* player = [[AVPlayer alloc] initWithURL:localUrl];
        [playerController setPlayer:player];
        [player play];
    }
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MusicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MusicTableViewCell.cellIdentifier];
    MusicItem *model = [self.viewModel.listMusics objectAtIndex:indexPath.row];
    cell.delegate = self;
    [cell configCellWithItem:model downloadStatus:[self.viewModel getStatusOfModel:model]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MusicItem *model = [self.viewModel.listMusics objectAtIndex:indexPath.row];
    if (model.storedLocalPath) {
        return 82.f;
    }
    return 90.f;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.listMusics.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MusicItem *model = [self.viewModel.listMusics objectAtIndex:indexPath.row];
    [self playMusic:model];
}

- (void)startDownload:(MusicItem *)model {
    if (!model) {
        return;
    }
    [self.viewModel startDownload:model];
}

- (void)cancelDownload:(nonnull MusicItem *)model {
    if (!model) {
        return;
    }
    [self.viewModel cancelDownload:model];
}

- (void)pauseDownload:(nonnull MusicItem *)model {
    if (!model) {
        return;
    }
    [self.viewModel pauseDownload:model];
}

- (void)resumeDownload:(nonnull MusicItem *)model {
    if (!model) {
        return;
    }
    [self.viewModel resumeDownload:model];
}

@end
