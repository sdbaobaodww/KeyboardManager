//
//  TestViewController.m
//  KeyboardTest
//
//  Created by Duanwwu on 13-12-14.
//  Copyright (c) 2013年 DZH. All rights reserved.
//

#import "TestViewController.h"
#import "TViewController.h"
#import "UIViewController+KeyboardManager.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (id)init
{
    if(self=[super init])
    {
        [self buildKeyboardManager];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.touchOutsideDisappearKeyboard=YES;
    UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
    button.frame=CGRectMake(100., 100., 100., 30.);
    button.backgroundColor=[UIColor redColor];
    [button setTitle:@"测试" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(test) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    self.view.backgroundColor=[UIColor whiteColor];
    UITextField *textFiled=[[UITextField alloc] initWithFrame:CGRectMake(100., 300., 100., 30.)];
    textFiled.delegate=self;
    textFiled.text=@"test1";
    [self.view addSubview:textFiled];
    [textFiled release];
}

- (void)test
{
    TViewController *tController=[[TViewController alloc] init];
    [self.navigationController pushViewController:tController animated:YES];
    [tController release];
}

- (void)didReceiveMemoryWarning
{
    [self destroyKeyboardManager];
    [super didReceiveMemoryWarning];
}

@end
