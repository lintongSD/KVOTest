//
//  NSObject+KVO.m
//  KVOTest
//
//  Created by EBIZM2 on 2019/3/18.
//  Copyright © 2019年 EBIZM2. All rights reserved.
//

#import "NSObject+KVO.h"
#import <objc/message.h>
@implementation NSObject (KVO)

static NSString *const KVOAssociatedObservers = @"KVOAssociatedObservers";
static NSString *const KVOAssociatedOldValue = @"KVOAssociatedOldValue";

//通过 runtime 动态创建子类
- (void)yv_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context{
    
    //获取当前isa指向的class
    Class cls = object_getClass(self);
    
    //生成setter方法
    SEL setterSel = NSSelectorFromString(setterForGetter(keyPath));
    if (!setterSel) return ;
    //获取父类的setter方法
    Method method = class_getInstanceMethod(cls, setterSel);
    if (!method) {
        NSString *resason = [NSString stringWithFormat:@"Object %@ does not hava a setter for key %@", cls, keyPath];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:resason userInfo:nil];
        return;
    }
    
    //指向子类
    Class sub_cls = [self registerSubClassWithSuperClass:cls];
    
    Method class_method = class_getInstanceMethod(cls, @selector(class));
    Method changeValue_method = class_getInstanceMethod(cls, @selector(didChangeValueForKey:));
    
    //子类重写class方法, 返回父类名
    class_addMethod(sub_cls, @selector(class), (IMP)kvo_class, method_getTypeEncoding(class_method));
    class_addMethod(sub_cls, @selector(didChangeValueForKey:), (IMP)didChangeValue, method_getTypeEncoding(changeValue_method));
    class_addMethod(sub_cls, setterSel, (IMP)kvo_setter, method_getTypeEncoding(method));
    
    
    //将当前对象和观察者关联起来
    objc_setAssociatedObject(self,(__bridge const void * _Nonnull)(KVOAssociatedObservers), observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    
}

- (Class)registerSubClassWithSuperClass:(Class)superClass{
    //创建子类名
    NSString *subClsName = [NSString stringWithFormat:@"NSKVONotifying_%@", superClass];
    //创建子类空间
    Class sub_cls = objc_allocateClassPair(superClass, subClsName.UTF8String, 16);
    //注册子类
    objc_registerClassPair(sub_cls);
    //将父类指针指向子类
    object_setClass(self, sub_cls);
    
    return sub_cls;
}

//重写Class方法
static Class kvo_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

//didChangeValue实现
static void didChangeValue(id self, SEL _cmd, NSString *key){
    id newValue = [self valueForKey:key];
    id observer = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(KVOAssociatedObservers));
    
    id oldValue = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)KVOAssociatedOldValue);
    
    NSMutableDictionary *change = [NSMutableDictionary dictionary];
    if (oldValue) {
        change[@"oldValue"] = oldValue;
    } else {
        change[@"oldValue"] = [NSNull null];
    }
    if (newValue) {
        change[@"newValue"] = newValue;
    } else {
        change[@"newValue"] = newValue;
    }
    
    [observer observeValueForKeyPath:key ofObject:self change:change context:NULL];
}


//设置setter方法名
static NSString * setterForGetter(NSString *getter) {
    if (getter.length <= 0) {
        return nil;
    }
    //大写第一个字母
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    
    // setName:
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, remainingLetters];
    NSLog(@"setterForGetter   %@", setter);
    return setter;
}


//自实现setter
static void kvo_setter(id self, SEL _cmd, id newValue) {
    NSString *setterName = NSStringFromSelector(_cmd);
    //通过setter获取getter方法名
    NSString *getterName = getterForSetter(setterName);
    [self willChangeValueForKey:getterName];
    
    //调用super setter方法
    struct objc_super sup_cls = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    //存储旧值
    objc_setAssociatedObject(self,(__bridge const void * _Nonnull)(KVOAssociatedOldValue),[self valueForKey:getterName], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //调用父类设置新值
    objc_msgSendSuper(&sup_cls, _cmd, newValue);
    
    [self didChangeValueForKey:getterName];
}
//通过setter获取getter方法名
static NSString * getterForSetter(NSString * setter) {
    if (setter.length <=0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    
    
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    
    return key;
}

@end
