//
//  UIViewController+Keyboard.m
//  DZHLotteryTicket
//
//  Created by Duanwwu on 13-12-12.
//  Copyright (c) 2013年 DZH. All rights reserved.
//

#import "UIViewController+KeyboardManager.h"
#import <objc/runtime.h>  
#import <objc/message.h>

#define kTextFieldKeyboardSpace 10.  //文本框与键盘的间距

void methodSwizzle(Class c,SEL origSEL,IMP implementation,SEL overrideSEL,const char *types);
void swizzleTextFieldDidBeginEditing(id self, SEL _cmd, UITextField *textField);
void swizzleTextFieldDidEndEditing(id self, SEL _cmd, UITextField *textField);
BOOL swizzleShouldReceiveTouch(id self, SEL _cmd, UIGestureRecognizer *gestureRecognizer, UITouch *touch);

@implementation UIViewController (KeyboardManager)

@dynamic selectedTextField;
@dynamic textFields;
@dynamic disappearKeyboardGesture;
@dynamic panelView;
@dynamic shouldChangeFrameWhenShowKeyboard;
@dynamic origOffset;
@dynamic autoAdjustKeyboardHeight;

- (void)buildKeyboardManager
{
    [self buildKeyboardManager:self.view];
}

- (void)buildKeyboardManager:(UIView *)panelView
{
    self.panelView=panelView;
    self.shouldChangeFrameWhenShowKeyboard=YES;
    self.autoAdjustKeyboardHeight=YES;
    
    NSMutableArray *arr=[[NSMutableArray alloc] init];
    self.textFields=arr;
    [arr release];
    
    methodSwizzle([self class], @selector(textFieldDidBeginEditing:), (IMP)swizzleTextFieldDidBeginEditing, NSSelectorFromString(@"swizzleTextFieldDidBeginEditing:"),"v@:@");
    methodSwizzle([self class], @selector(textFieldDidEndEditing:), (IMP)swizzleTextFieldDidEndEditing, NSSelectorFromString(@"swizzleTextFieldDidEndEditing:"), "v@:@");
    methodSwizzle([self class], @selector(gestureRecognizer:shouldReceiveTouch:), (IMP)swizzleShouldReceiveTouch, NSSelectorFromString(@"swizzleGestureRecognizer:shouldReceiveTouch:"), "B@:@@");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hiddenKeyboardWhenBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)destroyKeyboardManager
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[[UIApplication sharedApplication] keyWindow] makeKeyAndVisible];
    self.textFields=nil;
    self.selectedTextField=nil;
    self.disappearKeyboardGesture=nil;
    self.panelView=nil;
    self.origOffset=nil;
}

-(void)setTouchOutsideDisappearKeyboard:(BOOL)touchOutsideDisappearKeyboard
{
    if(touchOutsideDisappearKeyboard)
    {
        if(self.disappearKeyboardGesture)
            return;
        
        UITapGestureRecognizer *gesture=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textFieldResignFirstResponse)];
        [gesture setEnabled:NO];
        [self.view addGestureRecognizer:gesture];
        gesture.delegate = self;
        [gesture release];
        self.disappearKeyboardGesture=gesture;
    }
    else if(self.disappearKeyboardGesture)
    {
        [self.view removeGestureRecognizer:self.disappearKeyboardGesture];
        self.disappearKeyboardGesture=nil;
    }
}

- (void)addTextFieldToManager:(UITextField *)textField
{
    [self.textFields addObject:textField];
}

- (void)removeTextFieldFromManager:(UITextField *)textField
{
    [self.textFields removeObject:textField];
}

- (void)textFieldResignFirstResponse
{
    [self.selectedTextField resignFirstResponder];
}

#pragma  mark - NSNotification

/**
 * 键盘显示、消失通知调用方法
 * @param notification 通知对象
 */
- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    if(!self.selectedTextField)
        return;
    
    if(!self.shouldChangeFrameWhenShowKeyboard)
        return;
    
    for (UITextField *textField in self.textFields)
    {
        if(self.selectedTextField==textField)
        {
            if (textField.window.isKeyWindow == NO)
            {
                // 解决xcode4.6 ios6不能输入bug
                [textField.window makeKeyAndVisible];
            }
            
            NSDictionary *info = [notification userInfo];
            CGRect beginKeyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
            CGRect endKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
            NSTimeInterval duration=[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
            UIViewAnimationCurve curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
            
            CGFloat y = self.view.frame.size.height - [textField.superview convertPoint:CGPointMake(textField.frame.origin.x, CGRectGetMaxY(textField.frame)) toView:self.view].y - kTextFieldKeyboardSpace;//判断文本框距离屏幕底部的距离，看是否有足够空间显示键盘。通过获取文本框下边在self.view中的纵坐标位置,再减去一个文本框与键盘的间距kTextFieldKeyboardSpace进行判断.
            
            CGFloat yOffset = beginKeyboardRect.origin.y-endKeyboardRect.origin.y;//用于判断键盘状态，显示、隐藏、切换
            
            CGFloat keyboardHeight = endKeyboardRect.size.height;//键盘高度
            
            CGPoint targetOffset;
            if(yOffset==0) // 键盘切换
            {
                if(y < keyboardHeight)//文本框下边距离屏幕下边界的高度少于键盘高度＋kTextFieldKeyboardSpace,此时需更改panelView的contentOffset
                {
                    CGPoint origOffset=[self.origOffset CGPointValue];
                    targetOffset=CGPointMake(origOffset.x, keyboardHeight-y);
                    [self _animationTranslatePanelViewWithOffset:targetOffset duration:duration animationCurve:curve show:YES];
                }
                else
                {
                    CGPoint origOffset=[self.panelView isKindOfClass:[UIScrollView class]] ? ((UIScrollView *)self.panelView).contentOffset : self.panelView.frame.origin;
                    self.origOffset=[NSValue valueWithCGPoint:origOffset];//纪录键盘显示时panelView的偏移位置
                }
            }
            else if(yOffset>0)//键盘显示
            {
                CGPoint origOffset=[self.panelView isKindOfClass:[UIScrollView class]] ? ((UIScrollView *)self.panelView).contentOffset : self.panelView.frame.origin;
                
                self.origOffset=[NSValue valueWithCGPoint:origOffset];//纪录键盘显示时panelView的偏移位置
                if(y<keyboardHeight)//空间不够显示键盘,需移动panelView的位置
                {
                    if(self.autoAdjustKeyboardHeight)//如果是自适应显示键盘，则键盘的上边距离文本框的下边间隔kTextFieldKeyboardSpace个像素，以紧凑显示。
                    {
                        targetOffset=CGPointMake(origOffset.x, origOffset.y + keyboardHeight-y);
                        if(IOS_VERSION_7_OR_ABOVE && ![self.panelView isKindOfClass:[UIScrollView class]])//ios7下视图的origin坐标跟ios6不一致
                        {
                            targetOffset.y-=20.;//减去状态栏高度
                            if(self.navigationController)//如果有导航栏，减去导航栏高度
                            {
                                UIInterfaceOrientation orientation=[[UIApplication sharedApplication] statusBarOrientation];
                                if(orientation==UIInterfaceOrientationPortrait || orientation==UIInterfaceOrientationPortraitUpsideDown)//竖屏幕
                                    targetOffset.y-=44.;
                                else//横屏幕
                                    targetOffset.y-=32.;
                            }
                        }
                    }
                    else//不需要自适应，则直接将panelView移动键盘高度的距离
                    {
                        targetOffset=CGPointMake(origOffset.x, keyboardHeight);
                    }
                    [self _animationTranslatePanelViewWithOffset:targetOffset duration:duration animationCurve:curve show:YES];
                }
            }
            else
            {
                self.selectedTextField=nil;
                [self _animationTranslatePanelViewWithOffset:[self.origOffset CGPointValue] duration:duration animationCurve:curve show:NO];
            }
        }
    }
}

- (void)_animationTranslatePanelViewWithOffset:(CGPoint)offset duration:(NSTimeInterval)duration animationCurve:(UIViewAnimationCurve)curve show:(BOOL)show
{
    if([self.panelView isKindOfClass:[UIScrollView class]])
    {
        [(UIScrollView *)self.panelView setContentOffset:offset animated:YES];
    }
    else
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
        CGRect frame=self.panelView.frame;
        if(show)
            frame.origin.y-=offset.y;
        else
            frame.origin.y=offset.y;
        self.panelView.frame=frame;
        [UIView commitAnimations];
    }
}

- (void)hiddenKeyboardWhenBackground:(NSNotification *)notification
{
    [self.view endEditing:YES];
    self.selectedTextField=nil;
}

#pragma  mark - Method Swizzling

void methodSwizzle(Class c,SEL origSEL,IMP implementation,SEL overrideSEL,const char *types)
{
    Method origMethod = class_getInstanceMethod(c, origSEL);//源方法
    IMP origImplementation=method_getImplementation(origMethod);//源方法实现
    if(origImplementation==implementation)//如果两个实现一样，则说明两个Selector的实现已经交换过
        return;
    Method overrideMethod = class_getInstanceMethod(c, overrideSEL);//目标方法
    if(origMethod==NULL)//源方法不存在,则将源Selector与implementation关联起来
    {
        class_addMethod(c, origSEL, implementation, types);
    }
    else if(overrideMethod==NULL)//源方法存在，目标Selector无对应实现
    {
        class_addMethod(c, overrideSEL, origImplementation, types);//目标方法使用源方法实现
        class_replaceMethod(c, origSEL, implementation, types);//源方法使用目标方法实现
    }
}

void swizzleTextFieldDidBeginEditing(id self, SEL _cmd, UITextField *textField)
{
    objc_msgSend(self,@selector(setSelectedTextField:),textField);
    
    id disappearKeyboardGesture = objc_msgSend(self,@selector(disappearKeyboardGesture));
    if(disappearKeyboardGesture)//如果手势存在，则启用
        objc_msgSend(disappearKeyboardGesture, @selector(setEnabled:),YES);
    
    SEL selector=NSSelectorFromString(@"swizzleTextFieldDidBeginEditing:");
    if([self respondsToSelector:selector])//发送消息到textFieldDidBeginEditing:方法
        objc_msgSend(self, selector,textField);
}

void swizzleTextFieldDidEndEditing(id self, SEL _cmd, UITextField *textField)
{
    id disappearKeyboardGesture = objc_msgSend(self,@selector(disappearKeyboardGesture));
    if(disappearKeyboardGesture)//如果手势存在，则禁用
        objc_msgSend(disappearKeyboardGesture, @selector(setEnabled:),NO);
    
    SEL selector=NSSelectorFromString(@"swizzleTextFieldDidEndEditing:");
    if([self respondsToSelector:selector])//发送消息到textFieldDidEndEditing:方法
        objc_msgSend(self, selector,textField);
}

BOOL swizzleShouldReceiveTouch(id self, SEL _cmd, UIGestureRecognizer *gestureRecognizer, UITouch *touch)
{
    SEL selector=NSSelectorFromString(@"swizzleGestureRecognizer:shouldReceiveTouch:");
    if([self respondsToSelector:selector])//发送消息到gestureRecognizer:shouldReceiveTouch:方法
    {
        id ret = objc_msgSend(self, selector, gestureRecognizer, touch);
        return (BOOL) ret;
    }
    
    if([touch.view isKindOfClass:[UIButton class]])
        return NO;
    return YES;
}

#pragma mark - Getter setter

-(UITextField *)selectedTextField
{
    return objc_getAssociatedObject(self, @"selectedTextField");
}

-(void)setSelectedTextField:(UITextField *)selectedTextField
{
    objc_setAssociatedObject(self, @"selectedTextField", selectedTextField, OBJC_ASSOCIATION_ASSIGN);
}

-(NSMutableArray *)textFields
{
    return objc_getAssociatedObject(self, @"textFields");
}

-(void)setTextFields:(NSMutableArray *)textFields
{
    objc_setAssociatedObject(self, @"textFields", textFields, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UITapGestureRecognizer *)disappearKeyboardGesture
{
    return objc_getAssociatedObject(self, @"disappearKeyboardGesture");
}

- (void)setDisappearKeyboardGesture:(UITapGestureRecognizer *)disappearKeyboardGesture
{
    objc_setAssociatedObject(self, @"disappearKeyboardGesture", disappearKeyboardGesture, OBJC_ASSOCIATION_ASSIGN);
}

- (UIScrollView *)panelView
{
    return objc_getAssociatedObject(self, @"panelView");
}

- (void)setPanelView:(UIScrollView *)panelView
{
    objc_setAssociatedObject(self, @"panelView", panelView, OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)shouldChangeFrameWhenShowKeyboard
{
    NSNumber *ret = objc_getAssociatedObject(self, @"shouldChangeFrameWhenShowKeyboard");
    return [ret boolValue];
}

- (void)setShouldChangeFrameWhenShowKeyboard:(BOOL)shouldChangeFrameWhenShowKeyboard
{
    objc_setAssociatedObject(self, @"shouldChangeFrameWhenShowKeyboard", @(shouldChangeFrameWhenShowKeyboard), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSValue *)origOffset
{
    return objc_getAssociatedObject(self, @"origOffset");
}

- (void)setOrigOffset:(NSValue *)origOffset
{
    objc_setAssociatedObject(self, @"origOffset", origOffset, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)autoAdjustKeyboardHeight
{
    NSNumber *value=objc_getAssociatedObject(self, @"autoAdjustKeyboardHeight");
    return [value boolValue];
}

- (void)setAutoAdjustKeyboardHeight:(BOOL)autoAdjust
{
    objc_setAssociatedObject(self, @"autoAdjustKeyboardHeight", [NSNumber numberWithBool:autoAdjust], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
