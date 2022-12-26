//
//  syscall_tracer.c
//  syscall-tracer
//
//  Created by Stevie Graham on 15/05/2018.
//  Copyright © 2018 Teller. All rights reserved.
//

#include <stdio.h>

#import <mach/mach.h>
#import <mach/exc.h>
#import <pthread.h>
#import <Foundation/Foundation.h>

semaphore_t semaphore;
pthread_t worker_thread;

void exception_server_loop(mach_port_t port);

void log_syscall(thread_t victim);

void log_exception_ports(const char * mode, kern_return_t kr, mach_msg_type_number_t count, exception_mask_array_t masks, exception_handler_array_t handlers, exception_behavior_array_t behaviours, exception_flavor_array_t flavours) {
    if(kr != KERN_SUCCESS) {
        NSLog(@"%s_exception_ports failed: %d", mode, kr);
        return;
    } else {
        NSLog(@"%s_exception_ports OK (%u syscall handler(s))", mode, count);
        
        for (mach_msg_type_number_t i = 0; i < count; i++) {
            NSLog(@"ports[%u]: mask=0x%08x handler=0x%08x behaviour=0x%08x flavour=0x%08x", i, masks[i], handlers[i], behaviours[i], flavours[i]);
        }
    }
}

void init_syscall_exception_handler_thread(void * arg) {
    mach_port_t            exception_port = MACH_PORT_NULL;
    mach_msg_type_number_t count = 0;
    exception_mask_t       masks[EXC_TYPES_COUNT];
    mach_port_t            handlers[EXC_TYPES_COUNT];
    exception_behavior_t   behaviours[EXC_TYPES_COUNT];
    thread_state_flavor_t  flavours[EXC_TYPES_COUNT];
    kern_return_t          kr;
    thread_port_t          thread;
    
    NSLog(@"Setting up syscall exception handler");
    NSLog(@"Creating exception port");
    
    mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &exception_port);
    mach_port_insert_right(mach_task_self(), exception_port, exception_port, MACH_MSG_TYPE_MAKE_SEND);
    
    NSLog(@"Swapping task exception ports");
    
    kr = task_get_exception_ports(mach_task_self(), (EXC_MASK_SYSCALL | EXC_MASK_MACH_SYSCALL), masks, &count, handlers, behaviours, flavours);
    
    log_exception_ports("task_get", kr, count, masks, handlers, behaviours, flavours);
    
    kr = task_set_exception_ports(mach_task_self(), (EXC_MASK_SYSCALL | EXC_MASK_MACH_SYSCALL), exception_port, (EXCEPTION_DEFAULT | MACH_EXCEPTION_CODES), THREAD_STATE_NONE);
    
    if(count > 0) {
        NSLog(@"Setting thread syscall handlers to default task syscall handlers");
        
        thread = mach_thread_self();
        
        NSLog(@"syscall handler thread port: 0x%08x", thread);
        NSLog(@"exception: 0x%08x", exception_port);
        
        for (mach_msg_type_number_t i = 0; i < count; i++) {
            kr = thread_set_exception_ports(thread, masks[i], handlers[i], (EXCEPTION_DEFAULT | MACH_EXCEPTION_CODES), THREAD_STATE_NONE);
            if(kr != KERN_SUCCESS) break;
        }
        
        if(kr != KERN_SUCCESS) {
            NSLog(@"Failed to set thread syscall handlers");
        } else {
            kr = thread_get_exception_ports(thread, (EXC_MASK_SYSCALL | EXC_MASK_MACH_SYSCALL), masks, &count, handlers, behaviours, flavours);
            log_exception_ports("thread_get", kr, count, masks, handlers, behaviours, flavours);
        }
    } else {
        NSLog(@"Task didn't have syscall handlers. Nothing to install on thread.");
    }
    
    count = 0;
    kr = task_get_exception_ports(mach_task_self(), (EXC_MASK_SYSCALL | EXC_MASK_MACH_SYSCALL), masks, &count, handlers, behaviours, flavours);
    
    log_exception_ports("task_get", kr, count, masks, handlers, behaviours, flavours);
    
    semaphore_signal(semaphore);
    
    exception_server_loop(exception_port);
}

void exception_server_loop(mach_port_t port) {
    __Request__exception_raise_t * request;
    __Reply__exception_raise_t reply;
    mach_msg_return_t res;
    
    size_t request_size = round_page(sizeof(*request));
    vm_allocate(mach_task_self(), (vm_address_t*)&request, request_size, VM_FLAGS_ANYWHERE);
    
    while (true) {
        request->Head.msgh_local_port = port;
        request->Head.msgh_size = (mach_msg_size_t)request_size;
        
        NSLog(@"Waiting for exception message...");
        
        res = mach_msg(&request->Head, MACH_RCV_MSG | MACH_RCV_LARGE, 0, request->Head.msgh_size, port, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
        
        switch (res) {
            case MACH_MSG_SUCCESS:
                NSLog(@"Received exception: 0x%08x", request->exception);
                
                 log_syscall(request->thread.name);
                
                memset(&reply, 0, sizeof(reply));
                
                reply.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(request->Head.msgh_bits), 0);
                reply.Head.msgh_local_port = MACH_PORT_NULL;
                reply.Head.msgh_remote_port = request->Head.msgh_remote_port;
                reply.Head.msgh_size = sizeof(reply);
                reply.NDR = NDR_record;
                reply.RetCode = KERN_FAILURE; // Fall through to default behaviour;
                reply.Head.msgh_id = request->Head.msgh_id + 100;
                
                mach_msg(&reply.Head, MACH_SEND_MSG, reply.Head.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
                break;
            default:
                NSLog(@"mach_msg error: %d", res);
                break;
        }
    }
}

void log_syscall(thread_t victim) {
    arm_thread_state64_t   state;
    mach_msg_type_number_t count = ARM_THREAD_STATE_COUNT;
    
    memset(&state, 0, sizeof(state));
    thread_get_state(victim, ARM_THREAD_STATE64, (thread_state_t)&state, &count);
    
    NSLog(@"syscall: %llu,", state.__x[16]);
}


void exxeption_log(){
    
    struct ios_execp_info {
        exception_mask_t masks[EXC_TYPES_COUNT];
        mach_port_t ports[EXC_TYPES_COUNT];
        exception_behavior_t behaviors[EXC_TYPES_COUNT];
        thread_state_flavor_t flavors[EXC_TYPES_COUNT];
        mach_msg_type_number_t count;
    };
    struct ios_execp_info *info = malloc(sizeof(struct ios_execp_info));
    kern_return_t kr = task_get_exception_ports(mach_task_self(), EXC_MASK_ALL, info->masks, &info->count, info->ports, info->behaviors, info->flavors);
    for (int i = 0; i < info->count; i++) {
        if (info->ports[i] !=0 || info->flavors[i] == THREAD_STATE_NONE) {
            NSLog(@"Being debugged... task_get_exception_ports");
        }else{
            NSLog(@"task_get_exception_ports bypassed");
        }
    }
    
}

__attribute__((constructor (-1))) static void register_syscall_handler(void) {
    pthread_attr_t         worker_thread_attr;
    mach_msg_type_number_t count;
    exception_mask_t       masks[EXC_TYPES_COUNT];
    mach_port_t            handlers[EXC_TYPES_COUNT];
    exception_behavior_t   behaviours[EXC_TYPES_COUNT];
    thread_state_flavor_t  flavours[EXC_TYPES_COUNT];
    kern_return_t          kr;
    
    
    exxeption_log();

    kr = task_get_exception_ports(mach_task_self(), (EXC_MASK_SYSCALL | EXC_MASK_MACH_SYSCALL), masks, &count, handlers, behaviours, flavours);

    log_exception_ports("task_get", kr, count, masks, handlers, behaviours, flavours);

    kr = thread_get_exception_ports(mach_thread_self(), (EXC_MASK_SYSCALL | EXC_MASK_MACH_SYSCALL), masks, &count, handlers, behaviours, flavours);

    log_exception_ports("thread_get", kr, count, masks, handlers, behaviours, flavours);

    pthread_attr_init(&worker_thread_attr);
    pthread_attr_setdetachstate(&worker_thread_attr, PTHREAD_CREATE_DETACHED);

    semaphore_create(mach_task_self(), &semaphore, SYNC_POLICY_FIFO, 0);

    pthread_create(&worker_thread, &worker_thread_attr, (void *)init_syscall_exception_handler_thread, NULL);

    NSLog(@"waiting for handler setup");

    semaphore_wait(semaphore);

    NSLog(@"initializer done");

    semaphore_destroy(mach_task_self(), semaphore);

    pthread_attr_destroy(&worker_thread_attr);
    
    
}
