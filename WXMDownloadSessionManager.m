//
//  WXMDownloadSessionManager.m
//  TianMiMi
//
//  Created by wq on 2019/12/15.
//  Copyright © 2019 sdjgroup. All rights reserved.
//
#include <zlib.h>
#include <CommonCrypto/CommonCrypto.h>
#import <CoreText/CoreText.h>
#import "WXMDownloadSessionManager.h"
#import "WCDownConfiguration.h"

@interface WXMDownloadSessionManager ()<NSURLSessionDataDelegate>

/**  根据文件名来存储文件的总大小 */
@property (nonatomic, strong) NSMutableDictionary *totalDictionary;

/** 下载进度 */
@property (nonatomic, assign) CGFloat downloadProgress;

/** 下载的URL地址 */
@property (nonatomic, copy) NSString *urlString;

/** 存储的文件名 */
@property (nonatomic, copy) NSString *fileName;

/** 任务 */
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

/**  会话 */
@property (nonatomic, strong) NSURLSession *session;

/** 下载流 */
@property (nonatomic, strong) NSOutputStream *stream;

/** 错误信息 */
@property (nonatomic, strong) NSError *downloadError;

/** 下载过程中调用的block */
@property (nonatomic, copy) void (^downloadProgressBlock)(CGFloat progress);

/** 下载完成后调用的block 返回路径 */
@property (nonatomic, copy) void (^completeBlock)(NSString *filePath, NSError * error);

/** 线程 */
@property (nonatomic, strong) NSOperationQueue *queue;

@end

@implementation WXMDownloadSessionManager

/** 创建缓存图片的文件夹 */
+ (void)initialize {
    BOOL isDir = NO;
    BOOL isExists = [kFileManager fileExistsAtPath:kFriendVideoPath isDirectory:&isDir];
    if (!isExists || !isDir) {
        [kFileManager createDirectoryAtPath:kFriendVideoPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSLog(@"%@",kFriendVideoPath);
}

- (void)downloadFromURL:(NSString *)urlString
               progress:(void (^)(CGFloat))downloadProgressBlock
             complement:(void (^)(NSString *, NSError *))completeBlock {
    self.urlString = urlString;
    self.fileName = [WXMDownloadSessionManager downloadKey:urlString];
    self.downloadProgressBlock = downloadProgressBlock;
    self.completeBlock = completeBlock;
}

/** 设置进度 */
- (void)setDownloadProgress:(CGFloat)downloadProgress {
    _downloadProgress = downloadProgress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.downloadProgressBlock) self.downloadProgressBlock(downloadProgress);
    });
}

/** 返回错误信息 */
- (void)setDownloadError:(NSError *)downloadError {
    _downloadError = downloadError;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completeBlock) self.completeBlock(nil, downloadError);
    });
}

/** 继续 */
- (void)resume {
    if (!self.isDownloading) {
        [self.dataTask resume];
        self.isDownloading = YES;
        self.isSuspend = NO;
    }
}

/** 暂停 */
- (void)suspend {
    if (!self.isSuspend) {
        [self.dataTask suspend];
        self.isSuspend = YES;
        self.isDownloading = NO;
    }
}

/** 取消 */
- (void)cancel {
    [self.session invalidateAndCancel];
    self.session = nil;
    self.dataTask = nil;
    if (self.completeBlock) self.completeBlock(kDownloadFilePath, nil);
}

- (NSURLSessionDataTask *)dataTask {
    if (!_dataTask) {
        NSError *error = nil;
        NSInteger alreadyLength = kAlreadyDownloadLength;
        NSLog(@"视频总长度______%@",self.totalDictionary[self.fileName]);
        
        /** 说明已经下载完毕 */
        if ([self.totalDictionary[self.fileName] integerValue] &&
            [self.totalDictionary[self.fileName] integerValue] == alreadyLength) {
            if (self.completeBlock) self.completeBlock(kDownloadFilePath, nil);
            return nil;
         
        /** 如果已经存在的文件比目标大说明下载文件错误执行删除文件重新下载 */
        } else if ([self.totalDictionary[self.fileName] integerValue] < alreadyLength) {
            [kFileManager removeItemAtPath:kDownloadFilePath error:&error];
            if (!error) {
                alreadyLength = 0;
            } else {
                NSLog(@"创建任务失败请重新开始");
                [self setDownloadError:error];
                return nil;
            }
        }
        
        /** 这里是已经下载的小于总文件大小执行继续下载操作 */
        /** 创建mutableRequest对象 */
        NSURL *urls = [NSURL URLWithString:self.urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urls];
        
        /** 设置request的请求头 */
        /** Range:bytes=xxx-xxx */
        NSString *headers = [NSString stringWithFormat:@"bytes=%zd-",alreadyLength];
        [request setValue:headers forHTTPHeaderField:@"Range"];
        _dataTask = [self.session dataTaskWithRequest:request];
        [self setDownloadProgress:0.01];
    }
    return _dataTask;
}

#pragma mark ________________________session delegate

/** 服务器响应以后调用的代理方法 开始1 */
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSHTTPURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    /** 接受到服务器响应 */
    /** 获取文件的全部长度 */
    NSInteger contentLength = [response.allHeaderFields[@"Content-Length"] integerValue];
    NSInteger totalLength = contentLength + kAlreadyDownloadLength;
    
    /** 把总长度写入plist */
    self.totalDictionary[self.fileName] = @(totalLength);
    [self.totalDictionary writeToFile:kTotalDataLengthDictionaryPath atomically:YES];
    
    /** 打开outputStream */
    [self.stream open];
    
    /** 调用block设置允许进一步访问 */
    completionHandler(NSURLSessionResponseAllow);
}

/** 接收到数据后调用的代理方法 进行2 */
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    /** 把服务器传回的数据用stream写入沙盒中 */
    [self.stream write:data.bytes maxLength:data.length];
    CGFloat totalLength = [self.totalDictionary[self.fileName] floatValue];
    self.downloadProgress = (1.0 * kAlreadyDownloadLength / totalLength);
}

/** 任务完成后调用的代理方法  结束3 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (error) {
        self.downloadError = error;
        return;
    }
    
    /** 关闭流 */
    [self.stream close];
    
    /** 清空task */
    [self.session invalidateAndCancel];
    self.dataTask = nil;
    self.session = nil;
    self.isDownFinash = YES;
    
    /** 更新总长度的字典 */
    [self.totalDictionary writeToFile:kTotalDataLengthDictionaryPath atomically:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completeBlock) self.completeBlock(kDownloadFilePath, nil);
    });
}

- (NSString *)downFinashPath {
    return kDownloadFilePath;
}

- (NSOutputStream *)stream {
    if (!_stream) {
        _stream = [[NSOutputStream alloc] initToFileAtPath:kDownloadFilePath append:YES];
    }
    return _stream;
}

- (NSMutableDictionary *)totalDictionary {
    if (!_totalDictionary) {
        NSString *path = kTotalDataLengthDictionaryPath;
        _totalDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        if (!_totalDictionary) _totalDictionary = @{}.mutableCopy;
    }
    return _totalDictionary;
}

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *confi = nil;
        confi = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:confi
                                                 delegate:self
                                            delegateQueue:self.queue];
    }
    return _session;
}

- (NSOperationQueue *)queue {
    if (!_queue) _queue = [[NSOperationQueue alloc] init];
    return _queue;
}

/// 保存视频data到沙河  和下载在同一目录
/// @param data data
/// @param aString 路径
+ (void)cacheLocalVideo:(NSData *)data urlString:(NSString *)aString {
    NSString *sessionKey = [self downloadKey:aString];
    NSString *filePath = [kFriendVideoPath stringByAppendingPathComponent:sessionKey];
    [data writeToFile:filePath atomically:YES];
    
    WXMDownloadSessionManager *manager = [WXMDownloadSessionManager new];
    manager.totalDictionary[sessionKey] = @(data.length);
    [manager.totalDictionary writeToFile:kTotalDataLengthDictionaryPath atomically:YES];
}

/** 转换保存的key */
+ (NSString *)downloadKey:(NSString *)aString {
    NSString *md5 = [self md5String:aString];
    NSString *pathExtension = aString.pathExtension;
    return [NSString stringWithFormat:@"%@.%@",md5,pathExtension];
}

/** md5加密 */
+ (NSString *)md5String:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG) data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ].lowercaseString;
}

@end
