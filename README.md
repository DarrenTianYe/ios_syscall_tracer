# ios_syscall_tracer

1. IOS 汇编实现 open、read、write 等系统调用。 
2. 汇编调用隐藏了 svc #number 代码，在静态分析中找不到SVC 指令。 
3. 在代码中可以监听系统调用。 
