//
//  AppDelegate.m
//  syscall-tracer
//
//  Created by Stevie Graham on 13/05/2018.
//  Copyright © 2018 Teller. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSLog(@"PT_DENY_ATTACH");
    
    /* Calling ptrace with PT_DENY_ATTACH with inline assembly, because:
    /  - Want to prove the capability of interposing syscalls from inline ASM.
    /  - PT_DENY_ATTACH will immediately crash the app if launched by Xcode/lldb.
    */
    
    __asm__ __volatile__("mov x0, #31");
    __asm__ __volatile__("mov x1, #0");
    
    NSLog(@"PT_DENY_ATTACH14");
    __asm__ __volatile__("mov x2, #0");
    __asm__ __volatile__("mov x3, #0");
    
    NSLog(@"PT_DENY_ATTACH15");
    
    
    __asm__ __volatile__("mov x16, #26");
    
    NSLog(@"PT_DENY_ATTACH16");
    
    __asm__ __volatile__("svc #128");
    
    
    NSLog(@"PT_DENY_ATTACH17");
    

    return YES;
}
@end
