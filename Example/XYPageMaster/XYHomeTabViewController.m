//
//  XYHomeTabViewController.m
//  XYPageMaster_Example
//
//  Created by lizitao on 2018/8/30.
//  Copyright © 2018年 leon0206. All rights reserved.
//

#import "XYHomeTabViewController.h"

@interface XYHomeTabViewController ()

@end

@implementation XYHomeTabViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIViewController * vc1 = [[UIViewController alloc]init];
    vc1.tabBarItem.title = @"推荐";
    vc1.tabBarItem.image = [UIImage imageNamed:@"cat"];
    vc1.tabBarItem.selectedImage = [UIImage imageNamed:@"dog"];
    vc1.view.backgroundColor = [UIColor greenColor];
    [self addChildViewController:vc1];
    
    
    UIViewController * vc2 = [[UIViewController alloc]init];
    vc2.tabBarItem.title = @"关注";
    vc2.tabBarItem.image = [UIImage imageNamed:@"chicken"];
    vc2.tabBarItem.selectedImage = [UIImage imageNamed:@"butterfly"];
    vc2.view.backgroundColor = [UIColor blueColor];
    [self addChildViewController:vc2];
    
    UIViewController * vc3 = [[UIViewController alloc]init];
    vc3.tabBarItem.title = @"我";
    vc3.tabBarItem.image = [UIImage imageNamed:@"dog"];
    vc3.tabBarItem.selectedImage = [UIImage imageNamed:@"cat"];
    vc3.view.backgroundColor = [UIColor greenColor];
    [self addChildViewController:vc3];
}


@end
