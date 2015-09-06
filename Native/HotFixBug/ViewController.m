//
//  ViewController.m
//  HotFixBug
//
//  Created by __huji on 6/9/15.
//  Copyright (c) 2015 huji. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self jsSel];
    [self localSel];
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
