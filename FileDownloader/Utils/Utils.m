//
//  Utils.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (NSArray<MusicModel *> *)createHardCodeData {
    MusicModel *model1 = [[MusicModel alloc] initWithSongName:@"Attention" andArtist:@"Charlie Puth" downloadUrl:@"https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/08/2b/a9/082ba99a-9495-b187-efdd-3061821464a0/mzaf_8028553167942858532.plus.aac.p.m4a"];
    MusicModel *model2 = [[MusicModel alloc] initWithSongName:@"Almost Here" andArtist:@"The Academy Is" downloadUrl:@"https://audio-ssl.itunes.apple.com/itunes-assets/Music/e6/05/b4/mzm.otycijju.aac.p.m4a"];
    
    MusicModel *model3 = [[MusicModel alloc] initWithSongName:@"Starboy" andArtist:@"The Weeknd" downloadUrl:@"https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview118/v4/90/e6/c0/90e6c08c-70b5-e21f-c653-79fa9312c139/mzaf_3252298645127756073.plus.aac.p.m4a"];
    MusicModel *model4 = [[MusicModel alloc] initWithSongName:@"Test big file" andArtist:@"The Weeknd" downloadUrl:@"http://ipv4.download.thinkbroadband.com/20MB.zip"];
    
    
    NSArray *result = @[model1, model2, model3, model4];
    
    return result;
}

@end
