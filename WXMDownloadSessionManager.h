//
//  WXMDownloadSessionManager.h
//  TianMiMi
//
//  Created by wq on 2019/12/15.
//  Copyright © 2019 sdjgroup. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WXMDownloadSessionManager : NSObject

/** 记录是否处于暂停状态 */
@property (nonatomic, assign) BOOL isSuspend;

/** 记录是否处于下载状态 */
@property (nonatomic, assign) BOOL isDownloading;

/** 是否下载完成 */
@property (nonatomic, assign) BOOL isDownFinash;

/** 完成路径 */
@property (nonatomic, copy) NSString *downFinashPath;

/** 路径转码 */
+ (NSString *)downloadKey:(NSString *)aString;

/// 保存视频data到沙河  和下载在同一目录
/// @param data data
/// @param aString 路径
+ (void)cacheLocalVideo:(NSData *)data urlString:(NSString *)aString;

/** 继续任务 */
- (void)resume;

/** 停止下载任务 */
- (void)suspend;

/** 取消任务 */
- (void)cancel;

/** 下载方法 */
- (void)downloadFromURL:(NSString *)urlString
               progress:(void (^)(CGFloat downloadProgress))downloadProgressBlock
             complement:(void (^)(NSString *filePath, NSError *error))completeBlock;
@end

NS_ASSUME_NONNULL_END
