---
layout:         post
title:          OS 挑战性任务
subtitle:
# date:           2023-06-29
author:         Steel Shadow
# header-img:     img
# header-style:   text
mathjax:        true
tags:
    - OS
---
# lab4-challenge 挑战性任务实验报告

## 实现架构

### 信号的注册

首先，我在 `signal.h` 中定义了 `struct sigaction` 和 `sigset_t`，以及信号的相关宏定义，包括信号编码 `SIGKILL` 等，掩码行为 `SIG_BLOCK` 等，最大信号数量 `NSIG`。

并且，在 `env.h` 中，我在`进程控制块 PCB`中添加了 信号处理器、信号处理入口、信号的进程全局掩码、处理信号的标识、待处理信号栈等与信号相关的信息。

我将 `待处理信号栈 char sa_pending_stack[NSIG]` ， `处理中信号栈 char sig_running_stack[NSIG]`直接保存在进程控制块中(为节省内存，使用了`char`)。

`sigprocmask` 是通过系统调用，在内核态修改 PCB 的信号掩码完成的，相关处理较为简单，此处略去。

```c
struct sigaction{
    void (*sa_handler)(int);
    sigset_t sa_mask;
};

struct sigset_t{
    int sig[2]; //最多 32*2=64 种信号
};
```

### 信号的发送

`kill` 使用 `syscall_kill` 系统调用，修改接收方 PCB 的待处理信号栈。**注意信号屏蔽是延后搁置处理，但仍然是要加入待处理信号栈的。**

下面考察内核态实现 `sys_kill`。`sys_kill` 就是将接收到的信号加入到 PCB 的待处理信号处理栈中。需要注意如果栈已经存在该信号，需要调整此信号至栈顶，否则直接将新信号放在栈顶。此处能看出来使用栈的原因：保持/更新 信号传入顺序。

`指导书未明确要求的部分`当进程收到一个信号时，如果该信号还未处理完毕，而此时又接收到相同的信号，那么这个信号会被合并(`合并信号`)。事实上，在Linux中，信号被分为`实时信号`和`非实时信号`，我把本次任务的信号都当成了`非实时信号`。`实时信号`是不能合并的，可以在栈中重复存在，我的实现中，待处理的信号栈中，每个信号都是独特唯一的。

此外，指导书规定了一些默认的信号处理，其中，需要在内存缺页时，do_tlb_refill 调用的 passive_alloc 中，当 va < UTEMP 时，向自己进程发送 SIGSEGV 信号，取代原有的 panic 崩溃。

```c
#define SIGKILL 9
#define SIGSEGV 11
#define SIGTERM 15
```

### 信号的处理

此部分为该挑战性任务的重难点，涉及到用户态和内核态的反复切换，是我本次任务遇到的最大困难。

首先考虑`信号的处理时机`：我参照了 Linux 内核，将 `do_signal` 放在 `ret_from_exception` 中。这样可以保证在任何异常返回时，都执行信号检查，信号可以被及时处理。信号处理时机/异常返回出现情况：系统调用，时钟中断等。

rfe 指令的说明：
将异常程序计数器（EPC）中的值加载到程序计数器（PC）中，使程序返回到异常发生时的下一条指令，从而恢复正常的执行流程。
将异常处理程序状态寄存器（EPSR）中的值加载到状态寄存器（SR）中，以恢复之前的特权级别。

```mips
FEXPORT(ret_from_exception)
    /*lab4-challenge Linux把信号处理过程放置在进程从内核态返回到用户态前*/
    move    a0, sp
    //这里正常情况下是8，但是在我的实现中可能出问题，适当扩大即可解决
    //请看章节 `奇怪的BUG`
    addiu   sp, sp, -12 
    jal     do_signal
    addiu   sp, sp, 12

    RESTORE_SOME
    lw      k0, TF_EPC(sp)
    lw      sp, TF_REG29(sp) /* Deallocate stack */
.set noreorder
    jr      k0
    rfe
.set reorder
```

接着我们考虑 do_signal `信号处理函数`。首先明确，`do_signal` 还是处于内核态。

do_signal 遍历待处理信号栈，如果被掩码阻塞，则继续遍历，否则执行相应的信号处理函数。

信号处理有两种情况：

1. 默认处理。env_destroy(curenv) 销毁进程即可。

2. 用户提供的相应的信号处理动作的信号处理函数。
   我们可以直接在内核态执行用户态代码。这里可以参考 cow_entry 的处理，使用 signal_entry 信号处理入口，统一执行用户提供的信号处理函数。这里涉及到栈帧的传参细节。使用入口函数和压栈(共用异常处理栈)也实现了信号重入。

```c
tf->regs[4] = tf->regs[29];
tf->regs[5] = (unsigned long)curenv->sigactions[sig - 1].sa_handler;
tf->regs[6] = sig;  //$a2 = sig

tf->regs[29] -= sizeof(tf->regs[4]);  //$sp -= 4
tf->regs[29] -= sizeof(tf->regs[5]);  //$sp -= 4
tf->regs[29] -= sizeof(tf->regs[6]);  //$sp -= 4

tf->cp0_epc = (unsigned long)curenv->env_signal_entry; 
//ret_from_exception 末尾，jr 跳转到 cp0_epc，并且 rfe 恢复特权等级
//使用压栈实现信号重入
```

在信号处理时，要注意处理中信号栈(保存在进程控制块中)的维护，实现信号重入。

## 测试方法

+ 早期测试：我直接在 `init/init.c` 中创建进程`ENV_CREATE(user_myTest)`，并创建测试文件 `user/myTest.c`，修改相应Makefile。

+ shell测试：使用 shell 完成测试文件的开启。在测试进程启动前，会生成其它系统进程，文件系统、shell。这样能够增加干扰，提高测试强度。

最终，在我的成果中，在 `signal.h` 中使用了`宏开关`控制运行平台，在直接测试和shell测试中切换，并有宏开关切换正常模式和 DEBUG_MODE 输出调试信息。

`make && make run` 或者 `make && make dbg`即可。

## 改进

PCB 进程控制块中，我使用了 char 节省内存。将 struct Env 的大小 1524B -> 1140B。

但是这其实还是浪费内存了，在信号少时，会有大量的信号栈浪费。

更进一步，其实可以考虑动态分配 `待处理信号栈` `信号处理重入栈`，在信号入栈时再分配内存，但是涉及到手动操作内存分配，较为复杂。

## 奇怪的 BUG

如上面提到的，我的进程控制块很大。这导致了我的 PCB 在进程切换后，可能莫名其妙被修改了。  

修复办法：在`进程切换`的时候，也就是 `env_run` 调用 `env_pop_tf` ，后的 `ret_from_exception` 中， `do_signal` 分配的栈，将 8 字节 改为 12、16、20 等即可正确通过我构造的样例。

与同学交流，似乎是由于异常重入时，env_pop_tf 中的栈帧被 do_signal 越界修改了。具体原因仍然不清楚，限于时间问题，我尝试着扩大 do_signal 栈后即正确。

## 实验收获与反思

学习了工程多文件的 Makefile 编写方式。

实际操作了操作系统内核态和用户态的转换，对二者加深了理解。

学习了 c语言 与 汇编 的组合。

学习使用了 GXemul dbg调试器。

ChatGpt 太强大了，在本次作业中帮了我大忙。
