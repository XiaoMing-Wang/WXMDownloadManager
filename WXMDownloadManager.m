//
//  WXMDownloadManager.m
//  TianMiMi
//
//  Created by wq on 2019/12/15.
//  Copyright © 2019 sdjgroup. All rights reserved.
//

#import "WXMDownloadManager.h"
#import "WXMDownloadSessionManager.h"

@interface WXMDownloadManager ()

/**存放任务session以及其对应的URL的字典*/
@property (nonatomic, strong) NSMutableDictionary *sessionDictionary;

@end

@implementation WXMDownloadManager

+ (instancetype)sharedInstance {
    static WXMDownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)downloadFromURL:(NSString *)urlString
               progress:(void(^)(CGFloat downloadProgress))downloadProgressBlock
             complement:(void(^)(NSString *filePath,NSError *error))completeBlock {
    
    WXMDownloadSessionManager *sessionMan = nil;
    NSString *sessionKey = [WXMDownloadSessionManager downloadKey:urlString];
    
    /** 创建task */
    if (![self.sessionDictionary.allKeys containsObject:sessionKey]) {
        sessionMan = [[WXMDownloadSessionManager alloc] init];
        [self.sessionDictionary setObject:sessionMan forKey:sessionKey];
        
        [sessionMan downloadFromURL:urlString
                           progress:downloadProgressBlock
                         complement:^(NSString *filePath, NSError *error)
         {
            if (!error) {
                [self.sessionDictionary removeObjectForKey:sessionKey];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completeBlock) completeBlock(filePath, nil);
                });
            }
        }];
        
        [sessionMan resume];
    } else {
        
        /** 下载完成 */
        sessionMan = [self.sessionDictionary objectForKey:sessionKey];
        if (sessionMan.isDownFinash && completeBlock) {
            completeBlock(sessionMan.downFinashPath, nil);
            
        /** 正在下载或者暂停 把block切换成最新 */
        } else if (!sessionMan.isDownFinash) {
            [sessionMan downloadFromURL:urlString
                               progress:downloadProgressBlock
                             complement:completeBlock];
            if (sessionMan.isDownloading) return;
            if (sessionMan.isSuspend) [sessionMan resume];
        }
    }
}

/** 继续 */
- (void)resumeTaskWithURL:(NSString *)urlString {
    NSString *sessionKey = [WXMDownloadSessionManager downloadKey:urlString];
    WXMDownloadSessionManager *sessionMan = self.sessionDictionary[sessionKey];
    if (!sessionMan) {
        [NSException raise:@"" format:@"Can not find the given url task"];
        return;
    }
    [sessionMan resume];
}

- (void)resumeAllTasks {
    [self.sessionDictionary enumerateKeysAndObjectsUsingBlock:^(id key,id obj,BOOL *stop) {
        WXMDownloadSessionManager *sessionMan = (WXMDownloadSessionManager *)obj;
        [sessionMan resume];
    }];
}

/** 暂停 */
- (void)suspendTaskWithURL:(NSString *)urlString {
    NSString *sessionKey = [WXMDownloadSessionManager downloadKey:urlString];
    WXMDownloadSessionManager *sessionMan = self.sessionDictionary[sessionKey];
    [sessionMan suspend];
}

- (void)suspendAllTasks{
    [self.sessionDictionary enumerateKeysAndObjectsUsingBlock:^(id key,id obj,BOOL *stop) {
        WXMDownloadSessionManager *sessionMan = (WXMDownloadSessionManager *)obj;
        [sessionMan suspend];
    }];
}

/** 取消(会删除文件) */
- (void)cancelTaskWithURL:(NSString *)urlString {
    NSString *sessionKey = [WXMDownloadSessionManager downloadKey:urlString];
    WXMDownloadSessionManager *sessionMan = self.sessionDictionary[sessionKey];
    [sessionMan cancel];
}

- (void)cancelAllTasks {
    [self.sessionDictionary enumerateKeysAndObjectsUsingBlock:^(id key,id obj,BOOL *stop) {
        WXMDownloadSessionManager *sessionMan = (WXMDownloadSessionManager *)obj;
        [sessionMan cancel];
    }];
}

- (NSMutableDictionary *)sessionDictionary {
    if (!_sessionDictionary) {
        _sessionDictionary = [NSMutableDictionary dictionary];
    }
    return _sessionDictionary;
}


@end
