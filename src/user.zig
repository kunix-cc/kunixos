const SYS_PUTCHAR = 1;
const SYS_GETCHAR = 2;
const SYS_EXIT = 3;

pub export fn syscall(sysno: isize, arg0: isize, arg1: isize, arg2: isize) isize {
    return asm volatile ("ecall"
        : [ret] "={a0}" (-> isize),
        : [arg0] "{a0}" (arg0),
          [arg1] "{a1}" (arg1),
          [arg2] "{a2}" (arg2),
          [sysno] "{a3}" (sysno),
        : .{ .memory = true });
}

pub export fn putchar(ch: u8) void {
    _ = syscall(SYS_PUTCHAR, ch, 0, 0);
}

pub export fn getchar() isize {
    return syscall(SYS_GETCHAR, 0, 0, 0);
}

pub export fn exit() noreturn {
    _ = syscall(SYS_EXIT, 0, 0, 0);
    while (true) {}
}

pub export fn start() linksection(".text.start") callconv(.naked) noreturn {
    asm volatile (
        \\la sp, __stack_top
        \\call main
        \\call exit
    );
}
