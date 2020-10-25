//
//  NSError+ContactAdapter.m
//  ContactPicker
//
//  Created by LAP13976 on 10/6/20.
//

#import <Foundation/Foundation.h>
#import "NSError+DownloadManager.h"

@implementation NSError (DownloadManager)

+ (NSError *)errorWithErrorCode:(DownloadErrorCode)errorCode message:(NSString *)message {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(message, nil),
    };
    
    NSError *error = [NSError errorWithDomain:@"FileDownloader.DownloadError"
                                         code:errorCode userInfo:userInfo];
    return error;
}

+ (NSError *)errorWithErrorCode:(DownloadErrorCode)errorCode {
    NSString *message = nil;
    switch (errorCode) {
        case UnexpectedError:
            message = @"Có lỗi sảy ra, vui lòng thử lại!";
            break;
        case UnavailableNetwork:
            message = @"Không có kết nối đến internet!";
            break;
        case StoreLocalError:
            message = @"Không thể lưu lại file đã tải!";
            break;
        case DownloadInvalidUrl:
            message = @"Đường dẫn đến file không chính xác, vui lòng kiểu tra lại!";
        default:
            message = @"Unknown";
            break;
    }
    return [self errorWithErrorCode:errorCode message:message];
}

@end
