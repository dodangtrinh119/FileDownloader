//
//  FileReader.m
//  FileDownloader
//
//  Created by Đăng Trình on 11/11/20.
//  Copyright © 2020 Dang Trinh. All rights reserved.
//

#import "FileReader.h"

@implementation FileReader
@synthesize lineDelimiter, chunkSize;

- (id) initWithFilePath:(NSString *)aPath {
    if (self = [super init]) {
        NSURL *storedPath = nil;
        NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        if (URLs && URLs.count > 0) {
            storedPath = [URLs firstObject];
        }
        NSURL *url1 = [storedPath URLByAppendingPathComponent:@"part0.tmp"];
        NSURL *url2 = [storedPath URLByAppendingPathComponent:@"part1.tmp"];
        
        fileReader = [NSFileHandle fileHandleForReadingAtPath:aPath];
        fileWriter = [NSFileHandle fileHandleForWritingAtPath:[url1 path]];

        if (fileReader == nil) {
            return nil;
        }

        lineDelimiter = @"\n";
        currentOffset = 0ULL; // ???
        chunkSize = 10;
        [fileReader seekToEndOfFile];
        [fileWriter seekToEndOfFile];
        totalFileLength = [fileReader offsetInFile];
        //we don't need to seek back, since readLine will do that.
    }
    return self;
}

- (void) dealloc {
    [fileReader closeFile];
    [fileWriter closeFile];
    currentOffset = 0ULL;
    data = nil;
}

- (instancetype) init {
    return self = [super init];
}

- (void) mergeFileAtPath:(NSString*)sourcePath toFileAtPath:(NSString*)destinationPath {
    fileReader = [NSFileHandle fileHandleForReadingAtPath:sourcePath];
    fileWriter = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
    
    [fileReader seekToEndOfFile];
    long long fileReadLength = [fileReader offsetInFile];
    [fileWriter seekToEndOfFile];
    
    currentOffset = 0;
    [fileReader seekToFileOffset:currentOffset];
 
    while (currentOffset < fileReadLength) {
        data = [[fileReader readDataOfLength:10000] copy];
        [fileWriter writeData:data];
        currentOffset += [data length];
        data = nil;
    }
    
//    [fileReader closeFile];
//    [fileWriter closeFile];
//    fileReader = nil;
//    fileWriter = nil;
}


- (NSString *) readLine {
    if (currentOffset >= totalFileLength) { return nil; }

    [fileReader seekToFileOffset:currentOffset];
    NSMutableData * currentData = [[NSMutableData alloc] init];
    BOOL shouldReadMore = YES;

    @autoreleasepool {

    while (shouldReadMore) {
        if (currentOffset >= totalFileLength) { break; }
        NSData * chunk = [fileReader readDataOfLength:20];
        [fileWriter writeData:chunk];
        [currentData appendData:chunk];
        currentOffset += [chunk length];
    }
    }

    NSString * line = [[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding];
    return line;
}

- (NSString *) readTrimmedLine {
    return [[self readLine] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL*))block {
    NSString * line = nil;
    BOOL stop = NO;
    while (stop == NO && (line = [self readLine])) {
        block(line, &stop);
    }
}
#endif

@end

