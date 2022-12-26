//
//  hidesysCall.c
//  syscall-tracer
//
//  Created by darren on 2022/12/26.
//  Copyright © 2022 Teller. All rights reserved.
//

#include "hidesysCall.h"
#import <Foundation/Foundation.h>


int my_test_get_app_dir(){
    
    NSLog(@"NSHomeDirectory:%@",NSHomeDirectory());
    NSLog(@"bundlePath:%@",[[NSBundle mainBundle] bundlePath]);
    NSLog(@"NSTemporaryDirectory:%@",NSTemporaryDirectory());

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [paths objectAtIndex:0];
    NSLog(@"docPath:%@",docPath);

    NSArray *paths1 = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libPath = [paths1 objectAtIndex:0];
    NSLog(@"libPath:%@",libPath);

    
    return 0;
}

int my_file_test()
{
    int result;
    
    NSString * docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dataFilePath = [docsdir stringByAppendingPathComponent:@"archiver"]; // 在Document目录下创建 "archiver" 文件夹

    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir = NO;

    // fileExistsAtPath 判断一个文件或目录是否有效，isDirectory判断是否一个目录
    BOOL existed = [fileManager fileExistsAtPath:dataFilePath isDirectory:&isDir];

    if (!(isDir && existed)) {
        // 在Document目录下创建一个archiver目录
        [fileManager createDirectoryAtPath:dataFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    // 在archiver下写入文件
    NSString *path = [dataFilePath stringByAppendingPathComponent:@"my.txt"];

    NSLog(@"my_file_test ===path:%@",path);
    
    
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *fileData = [handle readDataToEndOfFile];
    [handle closeFile];
    NSString *content =[ NSString stringWithCString:[fileData bytes] encoding:NSUTF8StringEncoding];
    NSLog(@"读取成功==%@", content);
    
    char *cNsHome = [path cStringUsingEncoding:NSUTF8StringEncoding];
    int retII=open(cNsHome, O_WRONLY);
    printf("my_file_test open : %d\n", retII);

    return 0;
}

int my_orig_syscall_test()
{
    int result;
    
    NSString * docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dataFilePath = [docsdir stringByAppendingPathComponent:@"archiver"]; // 在Document目录下创建 "archiver" 文件夹

    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir = NO;

    // fileExistsAtPath 判断一个文件或目录是否有效，isDirectory判断是否一个目录
    BOOL existed = [fileManager fileExistsAtPath:dataFilePath isDirectory:&isDir];

    if (!(isDir && existed)) {
        // 在Document目录下创建一个archiver目录
        [fileManager createDirectoryAtPath:dataFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    // 在archiver下写入文件
    NSString *path = [dataFilePath stringByAppendingPathComponent:@"my.txt"];

    NSLog(@"my_orig_syscall ===path:%@",path);
    
    char *cNsHome = [path cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Get pointer to address of syscall instruction inside of __mmap
    __mmap_ptr = (__mmap + (intptr_t) 4);
    
    
    
    
    
    // Tests syscall hiding (produce error)
    result = syscall_orig(SYS_open, cNsHome , O_WRONLY);
    printf("syscall my_orig_syscall_test result: %d\n", result);
    
    //write(int fildes, const void *buf, size_t nbyte);
    char tmp[1024]={"my_orig_syscall_test &&&&&&&&&&&&&&&&&&"};
    result = syscall_orig(SYS_write, result, tmp, 1024);
    printf("syscall my_orig_syscall_test write1: %d\n", result);
    
    result = syscall_orig(SYS_open, cNsHome , O_RDWR);
    printf("syscall my_orig_syscall_test result : %d\n", result);
    
    //read(int fildes, void *buf, size_t nbyte);
    char readData[1024]={"0"};
    result = syscall_orig(SYS_read, result, readData, 1024);
    printf("syscall my_orig_syscall_test read : %d, %s \n", result, readData);
    if(result < 0){
        perror("my_orig_syscall_test read STDIN_FILENO");
        NSLog(@"SYS_read error:%d, %s", errno, strerror(errno));
    }
    NSLog(@"my_orig_syscall_test end !!! \n");
    

    return EXIT_SUCCESS;
}


int my_hide_syscall_test()
{
    int result;
    
    NSString * docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dataFilePath = [docsdir stringByAppendingPathComponent:@"archiver"]; // 在Document目录下创建 "archiver" 文件夹

    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir = NO;

    // fileExistsAtPath 判断一个文件或目录是否有效，isDirectory判断是否一个目录
    BOOL existed = [fileManager fileExistsAtPath:dataFilePath isDirectory:&isDir];

    if (!(isDir && existed)) {
        // 在Document目录下创建一个archiver目录
        [fileManager createDirectoryAtPath:dataFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    // 在archiver下写入文件
    NSString *path = [dataFilePath stringByAppendingPathComponent:@"my.txt"];

    NSLog(@"syscall_hidden start ===path:%@",path);
    
    char *cNsHome = [path cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Get pointer to address of syscall instruction inside of __mmap
    __mmap_ptr = (__mmap + (intptr_t) 4);
    
    // Tests syscall hiding (produce error)
    result = syscall_hidden(SYS_open, cNsHome , O_WRONLY);
    printf("syscall hiding result: %d\n", result);

    //write(int fildes, const void *buf, size_t nbyte);
    char tmp[1024]={"darren test  syscall hide project ###########"};
    result = syscall_hidden(SYS_write, result, tmp, 1024);
    printf("syscall hiding write1: %d\n", result);

    result = syscall_hidden(SYS_open, cNsHome , O_RDWR);
    printf("syscall hiding result : %d\n", result);


    //read(int fildes, void *buf, size_t nbyte);
    char readData[1024]={"0"};
    result = syscall_hidden(SYS_read, result, readData, 1024);
    printf("syscall hiding read : %d, %s \n", result, readData);
    if(result < 0){
        perror("syscall_hidden read STDIN_FILENO");
        NSLog(@"SYS_read error:%d, %s", errno, strerror(errno));
    }
    NSLog(@"syscall_hidden end !!! \n");
    
    
    return EXIT_SUCCESS;
}

