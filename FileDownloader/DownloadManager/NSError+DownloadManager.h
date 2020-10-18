//
//  NSError+ContactAdapter.h
//  ContactPicker
//
//  Created by LAP13976 on 10/6/20.
//

#import <Foundation/Foundation.h>
#import "DownloadManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Error builder macro
#define DownloadErrorByCode(errorCode)      [NSError errorWithErrorCode:errorCode]

/// Error domain
extern NSString * const DownloadErrorDomain;

/// Error code
typedef NS_ENUM (NSUInteger, DownloadErrorCode) {
    UnexpectedError = -50000,
    UnavailableNetwork = -50001,
    StoreLocalError = -5003,
};

@interface NSError (DownloadManager)

+ (NSError *)errorWithErrorCode:(DownloadErrorCode)errorCode;

+ (NSError *)errorWithErrorCode:(DownloadErrorCode)errorCode
                                message:(NSString * __nullable)message;

@end

NS_ASSUME_NONNULL_END
