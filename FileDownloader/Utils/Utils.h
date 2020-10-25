//
//  Utils.h
//  FileDownloader
//
//  Created by Đăng Trình on 10/16/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject

+ (NSArray<MusicItem*> *)createHardCodeData;

@end

NS_ASSUME_NONNULL_END
