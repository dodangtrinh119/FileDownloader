//
//  Utils.m
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (NSArray<MusicItem *> *)createHardCodeData {
    
    MusicItem *model1 = [[MusicItem alloc] initWithSongName:@"Attention" andArtist:@"Charlie Puth" downloadUrl:[[NSURL alloc] initWithString:@"https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/08/2b/a9/082ba99a-9495-b187-efdd-3061821464a0/mzaf_8028553167942858532.plus.aac.p.m4a"]];
    MusicItem *model2 = [[MusicItem alloc] initWithSongName:@"Almost Here" andArtist:@"The Academy Is" downloadUrl:[[NSURL alloc] initWithString:@"https://audio-ssl.itunes.apple.com/itunes-assets/Music/e6/05/b4/mzm.otycijju.aac.p.m4a"]];
    
    MusicItem *model3 = [[MusicItem alloc] initWithSongName:@"Starboy" andArtist:@"The Weeknd" downloadUrl:[[NSURL alloc] initWithString:@"https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview118/v4/90/e6/c0/90e6c08c-70b5-e21f-c653-79fa9312c139/mzaf_3252298645127756073.plus.aac.p.m4a"]];
    MusicItem *model4 = [[MusicItem alloc] initWithSongName:@"Test big file" andArtist:@"The Weeknd" downloadUrl:[[NSURL alloc] initWithString:@"http://ipv4.download.thinkbroadband.com/100MB.zip"]];
    MusicItem *model5 = [[MusicItem alloc] initWithSongName:@"Big image" andArtist:@"ADD" downloadUrl:[[NSURL alloc] initWithString:@"https://upload.wikimedia.org/wikipedia/commons/e/e6/Clocktower_Panorama_20080622_20mb.jpg"]];

    
    NSArray *result = @[model1, model2, model3, model4, model5];
    
    return result;
}

@end
