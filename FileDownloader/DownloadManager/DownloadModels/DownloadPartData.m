//
//  DownloadPartData.m
//  FileDownloader
//
//  Created by LAP13976 on 11/12/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "DownloadPartData.h"

@implementation DownloadPartData

- (instancetype)initWithTask:(NSURLSessionDownloadTask *)downloadTask name:(NSString *)name {
    if (self = [super init]) {
        self.task = downloadTask;
        self.nameOfPart = name;
        self.currentByteDownloaded = 0;
        self.lastOffsetInFile = -1;
        self.partSize = 0;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.nameOfPart forKey:@"partName"];
    [coder encodeObject:self.resumeData forKey:@"resumeData"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.nameOfPart = [coder decodeObjectForKey:@"partName"];
        self.resumeData = [coder decodeObjectForKey:@"resumeData"];
    }
    return self;
}

@end
