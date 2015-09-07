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

#define CurrentPatchKey @"cuPatch"
#define ConfigFileName @"config.plist"

@implementation HotFixBug

-(void)excute{
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
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
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
                
                NSString *url = response[@"patch"];
                NSString *name = response[@"name"];
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
