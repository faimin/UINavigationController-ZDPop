//
//  UIViewController+ZDPop.m
//  UINavigationControllerStudy
//
//  Created by 符现超 on 16/1/25.
//  Copyright © 2016年 Zero.D.Saber. All rights reserved.
//

#import "UIViewController+ZDPop.h"
#import <objc/runtime.h>

#pragma mark - key && Function
static void *OriginDelegateKey = &OriginDelegateKey;

static void ZD_SwizzlePopInstanceSelector(Class aClass, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(aClass, originalSelector);
    Method newMethod = class_getInstanceMethod(aClass, newSelector);
    
    if (class_addMethod(aClass, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(aClass, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }
    else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

#pragma mark - Implementation
@implementation UIViewController (ZDPop)
//do nothing
@end

@implementation UINavigationController (ZDPop)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZD_SwizzlePopInstanceSelector([self class], @selector(viewDidLoad), @selector(zd_viewDidLoad));
        ZD_SwizzlePopInstanceSelector([self class], @selector(navigationBar:shouldPopItem:), @selector(zd_navigationBar:shouldPopItem:));
    });
}

- (void)zd_viewDidLoad
{
    [self zd_viewDidLoad];
    
    /// 先把导航控制以前的手势代理保存起来，然后再把当前的控制器设为它的代理
    /// 当 当前控制器释放的时候还要把原来的代理赋值回导航控制器
    /// 这么做是因为iOS不支持多重代理（ps：利用消息转发机制能实现多重代理）
    objc_setAssociatedObject(self, OriginDelegateKey, self.interactivePopGestureRecognizer.delegate, OBJC_ASSOCIATION_ASSIGN);
    self.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
}

#pragma mark - (Swizz)UINavigationBarDelegate

- (BOOL)zd_navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    UIViewController *topVC = self.topViewController;
    if (item != topVC.navigationItem) {
        return YES;
    }
    
    /// 不响应协议方法的控制器，则执行系统原来的pop方法
    if ([topVC respondsToSelector:@selector(zd_navigationControllerShouldPop:)]) {
        /// 实现此协议的控制器要返回NO，这样才能替换系统原来的返回方法
        BOOL systemPop = [(id <UINavigationControllerShouldPop>)topVC zd_navigationControllerShouldPop:self];
        if (systemPop) {
            return [self zd_navigationBar:navigationBar shouldPopItem:item];
        }
        else {
            return NO;
        }
    }
    else {
        return [self zd_navigationBar:navigationBar shouldPopItem:item];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        UIViewController *topVC = self.topViewController;
        if ([topVC respondsToSelector:@selector(zd_navigationControllerShouldStarInteractivePopGestureRecognizer:)]) {
#if MergeGestureToBackMethod
            if (![(id<UINavigationControllerShouldPop>)topVC zd_navigationControllerShouldPop:self]) {
                return NO;
            }
#else
            if ([(id<UINavigationControllerShouldPop>)vc zd_navigationControllerShouldStarInteractivePopGestureRecognizer:self]) {
                return NO;
            }
#endif
        }
        id<UIGestureRecognizerDelegate> originDelegate = objc_getAssociatedObject(self, OriginDelegateKey);
        return [originDelegate gestureRecognizerShouldBegin:gestureRecognizer];
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        id<UIGestureRecognizerDelegate> originDelegeate = objc_getAssociatedObject(self, OriginDelegateKey);
        return [originDelegeate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        id<UIGestureRecognizerDelegate> originDelegeate = objc_getAssociatedObject(self, OriginDelegateKey);
        return [originDelegeate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    return YES;
}

@end





























