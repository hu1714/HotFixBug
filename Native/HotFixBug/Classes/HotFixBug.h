//
//  HotFixBug.h
//  TestDemo
//
//  Created by huji on 8/8/15.
//  Copyright (c) 2015 xiaojukeji. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HotFixBug : NSObject

@property (nonatomic,copy) NSString *serverUrlString;
@property (nonatomic,copy) NSString *pwd;

-(void)evaluateScriptInMainBundleForName:(NSString*)name type:(NSString*)type;

-(void)excute:(dispatch_block_t)didDownloadPatch;

@end
