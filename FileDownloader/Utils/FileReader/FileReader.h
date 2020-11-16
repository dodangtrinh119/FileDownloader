//
//  FileReader.h
//  FileDownloader
//
//  Created by Đăng Trình on 11/11/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileReader : NSObject {
    NSString * filePath;
    NSFileHandle * fileWriter;
    NSFileHandle * fileReader;
    unsigned long long currentOffset;
    unsigned long long totalFileLength;
    NSData *data;

    NSString * lineDelimiter;
    NSUInteger chunkSize;
}

@property (nonatomic, copy) NSString * lineDelimiter;
@property (nonatomic) NSUInteger chunkSize;

- (id) initWithFilePath:(NSString *)aPath;

- (NSString *) readLine;
- (NSString *) readTrimmedLine;
- (void)mergeFileAtPath:(NSString*)sourcePath toFileAtPath:(NSString*)destinationPath;

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL *))block;
#endif

@end

NS_ASSUME_NONNULL_END
