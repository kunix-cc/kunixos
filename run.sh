#!/bin/bash

set -xue

QEMU=qemu-system-riscv32

CC="zig cc"

OBJCOPY=/usr/bin/llvm-objcopy
TARGET=riscv32-freestanding-none

zig build-obj common.zig -target ${TARGET} -mcpu=baseline-f-d -O ReleaseSmall

CFLAGS="-std=c11 -O2 -g3 -Wall -Wextra -target ${TARGET} -mabi=ilp32 -fno-stack-protector -ffreestanding -nostdlib"

$CC $CFLAGS -Wl,-e,start -T user.ld -o shell.elf shell.c user.c common.c common.o
$OBJCOPY --set-section-flags .bss=alloc,contents -O binary shell.elf shell.bin
$OBJCOPY -Ibinary -Oelf32-littleriscv shell.bin shell.bin.o

$CC $CFLAGS -Wl,-e,boot -T kernel.ld -o kernel.elf \
	kernel.c common.c common.o shell.bin.o

$QEMU -machine virt -bios default -nographic -serial mon:stdio --no-reboot \
	-kernel kernel.elf

