//
//  NSObject+KVO.h
//  KVOTest
//
//  Created by EBIZM2 on 2019/3/18.
//  Copyright © 2019年 EBIZM2. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (KVO)
- (void)yv_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;
@end

NS_ASSUME_NONNULL_END
