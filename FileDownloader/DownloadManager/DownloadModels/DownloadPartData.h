//
//  DownloadPartData.h
//  FileDownloader
//
//  Created by LAP13976 on 11/12/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadPartData : NSObject

@property (nonatomic, strong) NSURLSessionDownloadTask *task;
@property (nonatomic, strong) NSString *nameOfPart;
@property (nonatomic, assign) long long currentByteDownloaded;
@property (nonatomic, assign) float partSize;
@property (nonatomic, assign) NSURL *storedUrl;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, assign) NSInteger lastOffsetInFile;

- (instancetype) initWithTask:(NSURLSessionDownloadTask*)downloadTask name:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
