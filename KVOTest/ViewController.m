//
//  ViewController.m
//  KVOTest
//
//  Created by EBIZM2 on 2019/3/18.
//  Copyright © 2019年 EBIZM2. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+KVO.h"
#import "Person.h"
#import <objc/runtime.h>
@interface ViewController ()
@property (nonatomic, strong) Person *p1;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Person *p1 = [[Person alloc] init];
    _p1 = p1;
    id cls1 = object_getClass(p1);
    NSLog(@"添加 KVO 之前: cls1 = %@ ",cls1);
    
    [p1 yv_addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
    
    NSLog(@"++++++++++   %@",object_getClass(p1));
    
    [p1 setValue:@"222" forKey:@"name"];
    NSLog(@"%@", p1.name);
//    p1.name = @"dzb";
//    p1.name = @"111";
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@",change);
}


@end
