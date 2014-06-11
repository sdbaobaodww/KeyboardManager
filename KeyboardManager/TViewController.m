//
//  TViewController.m
//  KeyboardTest
//
//  Created by Duanwwu on 13-12-14.
//  Copyright (c) 2013年 DZH. All rights reserved.
//

#import "TViewController.h"
#import "UIViewController+KeyboardManager.h"

@interface TViewController ()<UITextFieldDelegate>

@end

@implementation TViewController

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
    self.view.backgroundColor=[UIColor whiteColor];
    UITextField *textFiled=[[UITextField alloc] initWithFrame:CGRectMake(100., 100., 100., 30.)];
    textFiled.delegate=self;
    textFiled.text=@"test1";
    [self.view addSubview:textFiled];
    [textFiled release];
    
    textFiled=[[UITextField alloc] initWithFrame:CGRectMake(100., 150., 100., 30.)];
    textFiled.delegate=self;
    textFiled.text=@"test2";
    [self.view addSubview:textFiled];
    [textFiled release];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"--TViewController--");
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    NSLog(@"textFieldShouldEndEditing");
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"---textFieldDidEndEditing----");
}

- (void)dealloc
{
    [self destroyKeyboardManager];
    [super dealloc];
}

@end
