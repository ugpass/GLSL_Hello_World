//
//  ViewController.m
//  GLSL_Hello_World
//
//  Created by William on 2020/7/27.
//  Copyright © 2020 ls. All rights reserved.
//

#import "ViewController.h"
#import "CustomView.h"

@interface ViewController ()

@property (nonatomic, strong) CustomView *customView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.customView = (CustomView *)self.view;
    
    
}


@end
