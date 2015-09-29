//
//  HotFixBug.m
//  TestDemo
//
//  Created by huji on 8/8/15.
//  Copyright (c) 2015 xiaojukeji. All rights reserved.
//

#import "HotFixBug.h"
#import <JPEngine.h>
#import <AFHTTPRequestOperationManager.h>
#import <CommonCrypto/CommonCryptor.h>

#define HFB_CurrentPatchKey @"cur_patch"
#define HFB_CleanupKey @"cleanup"
#define HFB_ConfigFileName @"config.plist"

static NSMutableDictionary *_config = nil;

@interface HotFixBug ()
+(void)synchronizeConfig;
@end

static void MyECH(NSException *exception){
    for (NSString *lib in exception.callStackSymbols) {
        if ([lib rangeOfString:@"callSelector"].length != 0) {
            [_config setObject:@"YES" forKey:HFB_CleanupKey];
            [HotFixBug synchronizeConfig];
            break;
        }
    }
}

@interface NSData (Crypto)
-(NSData*)decrypy:(NSString*)pass;
@end

@implementation NSData (Crypto)

-(NSData *)decrypy:(NSString *)pass{
    char keyPtr[kCCKeySizeAES128+1];
    bzero(keyPtr, sizeof(keyPtr));
    [pass getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}

@end

@implementation HotFixBug

+(void)load{
    _config = [NSMutableDictionary dictionaryWithContentsOfFile:[self configPath]];
    
    if (_config == nil) {
        _config = [NSMutableDictionary dictionary];
    }
    
    NSSetUncaughtExceptionHandler(&MyECH);
}

-(void)excute:(dispatch_block_t)didDownloadPatch{
#ifdef DEBUG
    NSLog(@"JsPatch Path:%@",[[self class] dirPath]);
#endif
    
    [JPEngine startEngine];
    
    NSDictionary *config = _config;
    
    [self loadPatch:config];
    
    [self requestForNewPatch:config didDownLoadPatch:didDownloadPatch];
}

-(void)loadPatch:(NSDictionary*)config{
    NSString *cuPatch = config[HFB_CurrentPatchKey];
    NSString *cleanUp = config[HFB_CleanupKey];
    
    if (cleanUp) {
         NSLog(@"Clean Up because of crash last time in js file.");
        [_config removeObjectForKey:HFB_CleanupKey];
        [_config removeObjectForKey:HFB_CurrentPatchKey];
        [[self class] synchronizeConfig];
        
    }else{
        if (cuPatch && [cuPatch hasPrefix:[self version]]) {
            NSString *pp = [[[self class] dirPath] stringByAppendingPathComponent:cuPatch];
            NSString *js = [self jsStringWithPath:pp];
            if (js) {
                [JPEngine evaluateScript:js];
            }
        }
    }
   
}

-(NSString*)jsStringWithPath:(NSString*)path{
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    NSData *deData = [data decrypy:self.pwd];
    
    if (!deData) {
        NSLog(@"decrypy data error.");
        return nil;
    }
    
    return [NSString stringWithCString:deData.bytes encoding:NSUTF8StringEncoding];
}

-(void)requestForNewPatch:(NSDictionary*)config didDownLoadPatch:(dispatch_block_t)block{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (!self.serverUrlString) {
            NSLog(@"no url string.");
            return;
        }
        
        NSString *cuPatch = config[HFB_CurrentPatchKey];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[self version] forKey:@"appversion"];
        [dict setObject:[[NSBundle mainBundle]bundleIdentifier] forKey:@"bid"];
        if (cuPatch) {
            [dict setObject:cuPatch forKey:HFB_CurrentPatchKey];
        }
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
        [manager POST:self.serverUrlString parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *response = responseObject;
#ifdef DEBUG
            NSLog(@"patch response %@",response);
#endif
            if ([response[@"errno"] isEqualToString:@"0"]) {
                
                NSString *url = response[@"patch_url"];
                NSString *name = response[@"patch_name"];
                if (url && name) {
                    [self downLoadPatch:url name:name didDownLoadPatch:block];
                }else{
                    NSLog(@"no patch.");
                }
                
            }else{
                NSLog(@"post for download patch url fail.%@",response[@"errmsg"]);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"post for download patch url fail.");
        }];
    });
}

-(void)downLoadPatch:(NSString*)patchurl name:(NSString*)name didDownLoadPatch:(dispatch_block_t)block{
    
    NSString *path = [[[self class] dirPath] stringByAppendingPathComponent:name];
    
    NSURL *url = [NSURL URLWithString:patchurl];
    NSURLRequest *requst = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:requst];
    op.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"down load patch ok.");
        
        [_config setObject:name forKey:HFB_CurrentPatchKey];
        [[self class] synchronizeConfig];
        
        if (block) {
            block();
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"fail to download patch.");
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
    
}

-(NSString*)version{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+(void)synchronizeConfig{
    [_config writeToFile:[self configPath] atomically:YES];
}

+(NSString*)dirPath{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *tmp = [paths lastObject];
    NSString *msgdir = [tmp stringByAppendingPathComponent:@"HBF"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:msgdir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:msgdir withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    return msgdir;
}

+(NSString*)configPath{
    return [[self dirPath] stringByAppendingPathComponent:HFB_ConfigFileName];
}

@end
