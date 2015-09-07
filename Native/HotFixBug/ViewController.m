//
//  ViewController.m
//  HotFixBug
//
//  Created by __huji on 6/9/15.
//  Copyright (c) 2015 huji. All rights reserved.
//

#import "ViewController.h"

@implementation TestObject

-(void)test{
    NSLog(@"test");
}

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self jsSel];
    [self localSel];
    
    TestObject *obj = [[TestObject alloc] init];
    [obj test];
}

-(void)localSel{
    NSLog(@"localSel called.");
}

-(void)jsSel{
    NSLog(@"jsSel called.");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
