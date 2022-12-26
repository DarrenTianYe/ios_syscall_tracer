//
//  ViewController.m
//  syscall-tracer
//
//  Created by Stevie Graham on 13/05/2018.
//  Copyright © 2018 Teller. All rights reserved.
//

#import "ViewController.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/syscall.h>
#include "hidesysCall.h"



@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    my_orig_syscall_test();
    my_hide_syscall_test();
    my_test_get_app_dir();
    my_file_test();
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end



