//
//  MusicModel.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface MusicModel : NSObject <DownloadItem>

@property (nonatomic, strong) NSString *songName;
@property (nonatomic, strong) NSString *artistName;

- (instancetype)initWithSongName:(NSString *)name andArtist:(NSString *)artist downloadUrl:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
