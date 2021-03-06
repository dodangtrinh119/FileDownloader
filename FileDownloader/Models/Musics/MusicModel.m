//
//  MusicModel.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "MusicModel.h"

@implementation MusicModel

@synthesize downloadURL;
@synthesize storedLocalPath;

- (instancetype)initWithSongName:(NSString *)name andArtist:(NSString *)artist downloadUrl:(NSString *)url {
    self = [super init];
    if (self) {
        self.downloadURL = url;
        self.artistName = artist;
        self.songName = name;
    }
    return self;
}



@end
