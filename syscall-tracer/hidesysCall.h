//
//  hidesysCall.h
//  syscall-tracer
//
//  Created by darren on 2022/12/26.
//  Copyright © 2022 Teller. All rights reserved.
//

#ifndef hidesysCall_h
#define hidesysCall_h

#include <stdio.h>

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/syscall.h>



#if (!defined(__arm64__))
    #error "Must be arm64 XNU!"
#endif

void *__mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off);

extern void *(*__mmap_ptr)(void *addr, size_t len, int prot, int flags, int fildes, off_t off);

extern int errno_orig;

int my_orig_syscall_test();
int my_test_get_app_dir();
int my_hide_syscall_test();
int my_file_test();


// Do not use more than 4 additional arguments or bad things might happen
int syscall_orig(int number, ...);
__asm__(".balign 8\n"
        ".text\n"
        ".globl syscall_orig\n"
        "_syscall_orig:\n"
        "mov     x16, x0\n"
        "ldp     x0, x1, [sp, #0x00]\n"
        "ldp     x2, x3, [sp, #0x10]\n"
        "ldp     x4, x5, [sp, #0x20]\n"
        "ldp     x6, x7, [sp, #0x30]\n"
        "svc     #0x80\n"
        "b.lo    #0x14\n" // ret
        "adrp    x8, #_errno_orig@PAGE\n"
        "str     w0, [x8, #_errno_orig@PAGEOFF]\n"
        "movn    x0, #0\n"
        "movn    x1, #0\n"
        "ret\n"
        ".data\n"
        "_errno_orig: .zero 4");

// Do not use more than 4 additional arguments or bad things might happen
int syscall_hidden(int number, ...);
__asm__(".balign 8\n"
        ".text\n"
        ".globl syscall_hidden\n"
        "_syscall_hidden:\n"
        "mov     x16, x0\n"
        "ldp     x0, x1, [sp, #0x00]\n"
        "ldp     x2, x3, [sp, #0x10]\n"
        "ldp     x4, x5, [sp, #0x20]\n"
        "ldp     x6, x7, [sp, #0x30]\n"
        "adrp    x8, #___mmap_ptr@PAGE\n"
        "ldr     x8, [x8, #___mmap_ptr@PAGEOFF]\n"
        "br      x8\n"
        // Could probably sneak in some errno support with bl vs. br, oh well
        ".data\n"
        "___mmap_ptr: .zero 8");

#endif /* hidesysCall_h */
