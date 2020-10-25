//
//  MusicModel.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadableItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface MusicItem : NSObject <DownloadableItem>

@property (nonatomic, copy) NSString *songName;
@property (nonatomic, copy) NSString *artistName;

- (instancetype)initWithSongName:(NSString *)name
                       andArtist:(NSString *)artist
                     downloadUrl:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
