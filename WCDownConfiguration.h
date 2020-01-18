//
//  WCDownConfiguration.h
//  TianMiMi
//
//  Created by sdjim on 2019/12/19.
//  Copyright © 2019 sdjgroup. All rights reserved.
//

#ifndef WCDownConfiguration_h
#define WCDownConfiguration_h

/** 文件管理类 */
#define kFileManager [NSFileManager defaultManager]

/** Library目录 */
#define kLibraryboxPath \
NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject

/** file缓存文件夹 */
#define kFilePath \
[kLibraryboxPath stringByAppendingPathComponent:@"FILE_CACHE"]

/** file->视频文件夹 */
#define kTargetPath \
[kFilePath stringByAppendingPathComponent:@"WXMVideos"]

/**文件存放路径*/
#define kDownloadFilePath [kTargetPath stringByAppendingPathComponent:self.fileName]

/**文件总长度字典存放的路径*/
#define kTotalDataLengthDictionaryPath \
[kTargetPath stringByAppendingPathComponent:@"totalDataLengththDictionaryPath.plist"]

/**已经下载的文件长度 */
#define kAlreadyDownloadLength \
[[kFileManager attributesOfItemAtPath:kDownloadFilePath error:nil][NSFileSize] integerValue]


#endif /* WCDownConfiguration_h */
