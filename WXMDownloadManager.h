//
//  WXMDownloadManager.h
//  TianMiMi
//
//  Created by wq on 2019/12/15.
//  Copyright © 2019 sdjgroup. All rights reserved.
//
#import "WXMDownloadProgressBar.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WXMDownloadManager : NSObject

+ (instancetype)sharedInstance;

/** 断点下载视频大文件 */
- (void)downloadFromURL:(NSString *)urlString
               progress:(void (^)(CGFloat downloadProgress))downloadProgressBlock
             complement:(void (^)(NSString *filePath, NSError *error))completeBlock;

/** 暂停某个url的下载任务 */
- (void)suspendTaskWithURL:(NSString *)urlString;

/** 暂停所有下载任务 */
- (void)suspendAllTasks;

/** 继续某个url的下载任务 */
- (void)resumeTaskWithURL:(NSString *)urlString;

/** 继续所有下载任务 */
- (void)resumeAllTasks;

/** 取消某个url的下载任务,取消以后必须重新设置任务 */
- (void)cancelTaskWithURL:(NSString *)urlString;

/** 取消所有下载任务,取消以后必须重新设置任务 */
- (void)cancelAllTasks;

@end

NS_ASSUME_NONNULL_END
