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

#define CurrentPatchKey @"cur_patch"
#define ConfigFileName @"config.plist"

@implementation HotFixBug

-(void)excute{
#ifdef DEBUG
    NSLog(@"JsPatch Path:%@",[self dirPath]);
#endif
    
    [JPEngine startEngine];
    
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[self configPath]];
    
    [self loadPatch:config];
    
    [self requestForNewPatch:config];
}

-(void)loadPatch:(NSDictionary*)config{
    NSString *cuPatch = config[CurrentPatchKey];
    if (cuPatch && [cuPatch hasPrefix:[self version]]) {
        NSString *pp = [[self dirPath] stringByAppendingPathComponent:cuPatch];
        NSString *js = [self jsStringWithPath:pp];
        if (js) {
            [JPEngine evaluateScript:js];
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

-(void)requestForNewPatch:(NSDictionary*)config{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (!self.serverUrlString) {
            NSLog(@"no url string.");
            return;
        }
        
        NSString *cuPatch = config[CurrentPatchKey];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[self version] forKey:@"appversion"];
        [dict setObject:[[NSBundle mainBundle]bundleIdentifier] forKey:@"bid"];
        if (cuPatch) {
            [dict setObject:cuPatch forKey:CurrentPatchKey];
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
                    [self downLoadPatch:url name:name];
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

-(void)downLoadPatch:(NSString*)patchurl name:(NSString*)name{
    
    NSString *path = [[self dirPath] stringByAppendingPathComponent:name];
    
    NSURL *url = [NSURL URLWithString:patchurl];
    NSURLRequest *requst = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:requst];
    op.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"down load patch ok.");
        
        NSDictionary *configdict = [NSDictionary dictionaryWithObject:name forKey:CurrentPatchKey];
        [configdict writeToFile:[self configPath] atomically:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"fail to download patch.");
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
    
}

-(NSString*)version{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

-(NSString*)dirPath{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *tmp = [paths lastObject];
    NSString *msgdir = [tmp stringByAppendingPathComponent:@"HBF"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:msgdir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:msgdir withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    return msgdir;
}

-(NSString*)configPath{
    return [[self dirPath] stringByAppendingPathComponent:ConfigFileName];
}

@end
