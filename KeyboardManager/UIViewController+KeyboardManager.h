//
//  UIViewController+Keyboard.h
//  DZHLotteryTicket
//
//  Created by Duanwwu on 13-12-12.
//  Copyright (c) 2013年 DZH. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef IOS_VERSION_7_OR_ABOVE

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
#define IOS_VERSION_7_OR_ABOVE ((floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) && [[UIDevice currentDevice].systemVersion floatValue] >= 7)
#else
#define IOS_VERSION_7_OR_ABOVE NO
#endif

#endif

/**
 * 键盘管理分类，控制键盘显示、消失时调整界面，panelView必须为UIScrollView类型,buildKeyboardManager与buildKeyboardManager:两个初始化方法2选1，务必调用destroyKeyboardManager进行释放动作。分类中实现了textFieldDidBeginEditing:和textFieldDidEndEditing:方法，进行打开关闭方法的控制，
 * 但因为使用了method swizzling，对自定义的UIViewController重写这两个方法没有影响。
 */
@interface UIViewController (KeyboardManager)<UITextFieldDelegate,UIGestureRecognizerDelegate>

/**选中的文本框*/
@property(nonatomic,assign)UITextField *selectedTextField;
/**文本框集合*/
@property(nonatomic,retain)NSMutableArray *textFields;
/**点击视图其他位置使键盘消失手势*/
@property(nonatomic,assign,readonly)UITapGestureRecognizer *disappearKeyboardGesture;
/**底层滑动面板*/
@property(nonatomic,assign) UIView *panelView;
/**键盘显示的时候，panelView是否需要进行可移动判断，如果为NO，则不进行任何需要移动panelView位置的判断*/
@property(nonatomic,assign)BOOL shouldChangeFrameWhenShowKeyboard;
/**纪录键盘显示时，panelView的偏移量 CGPoint类型*/
@property(nonatomic,retain,readonly)NSValue *origOffset;
/**是否自动计算panelView需要移动的高度,默认为YES*/
@property(nonatomic,assign)BOOL autoAdjustKeyboardHeight;

/**点击视图其他位置是否需要使键盘消失,设置为YES的时候，会初始化disappearKeyboardGesture。此属性设置最好在loadView或者viewDidLoad中设置*/
- (void)setTouchOutsideDisappearKeyboard:(BOOL)touchOutsideDisappearKeyboard;

/**
 * 快捷方法,默认使用self.view作为panelView
 */
- (void)buildKeyboardManager;

/**
 * 初始化键盘管理分类
 */
- (void)buildKeyboardManager:(UIView *)panelView;

/**
 * 销毁键盘管理分类
 */
- (void)destroyKeyboardManager;

/**
 * 添加文本框进行管理
 * @param textField 文本框
 */
- (void)addTextFieldToManager:(UITextField *)textField;

/**
 * 从管理器中移除文本框
 * @param textField 文本框
 */
- (void)removeTextFieldFromManager:(UITextField *)textField;

@end
