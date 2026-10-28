const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = "riscv32-freestanding-none";

    const common = b.addSystemCommand(&.{
        "zig", "build-obj",
    });
    common.addFileArg(b.path("common.zig"));
    common.addArgs(&.{
        "-target",            target,
        "-mcpu=baseline-f-d", "-O",
        "ReleaseSmall",
    });
    const common_obj = common.addPrefixedOutputFileArg("-femit-bin=", "common.o");

    const cflags = [_][]const u8{
        "-std=c11",
        "-O2",
        "-g3",
        "-Wall",
        "-Wextra",
        "-target",
        target,
        "-mabi=ilp32",
        "-fno-stack-protector",
        "-nostdlib",
    };

    const shell = b.addSystemCommand(&.{ "zig", "cc" });
    shell.addArgs(&cflags);
    shell.addArgs(&.{ "-Wl,-e,start", "-T" });
    shell.addFileArg(b.path("user.ld"));
    shell.addFileArg(b.path("shell.c"));
    shell.addFileArg(b.path("user.c"));
    shell.addFileArg(b.path("common.c"));
    shell.addFileArg(common_obj);
    shell.addArg("-o");
    const shell_elf = shell.addOutputFileArg("shell.elf");

    const binary = b.addSystemCommand(&.{
        "/usr/bin/llvm-objcopy",
        "--set-section-flags",
        ".bss=alloc,contents",
        "-O",
        "binary",
    });
    binary.addFileArg(shell_elf);
    const shell_bin = binary.addOutputFileArg("shell.bin");

    const embed = b.addSystemCommand(&.{
        "bash", "-c",
        "set -eu; " ++
            "tmp=$(mktemp -d); " ++
            "trap 'rm -rf \"$tmp\"' EXIT; " ++
            "cp \"$1\" \"$tmp/shell.bin\"; " ++
            "(cd \"$tmp\" && " ++
            "llvm-objcopy -I binary " ++
            "-O elf32-littleriscv " ++
            "shell.bin shell.bin.o); " ++
            "cp \"$tmp/shell.bin.o\" \"$2\"",
        "--",
    });
    embed.addFileArg(shell_bin);
    const shell_obj = embed.addOutputFileArg("shell.bin.o");

    const kernel = b.addSystemCommand(&.{ "zig", "cc" });
    kernel.addArgs(&cflags);
    kernel.addArgs(&.{ "-Wl,-e,boot", "-T" });
    kernel.addFileArg(b.path("kernel.ld"));
    kernel.addFileArg(b.path("kernel.c"));
    kernel.addFileArg(b.path("common.c"));
    kernel.addFileArg(common_obj);
    kernel.addFileArg(shell_obj);
    kernel.addArg("-o");
    const kernel_elf = kernel.addOutputFileArg("kernel.elf");

    const install = b.addInstallFileWithDir(
        kernel_elf,
        .prefix,
        "kernel.elf",
    );
    b.getInstallStep().dependOn(&install.step);

    const qemu = b.addSystemCommand(&.{
        "qemu-system-riscv32",
        "-machine",
        "virt",
        "-bios",
        "default",
        "-nographic",
        "-serial",
        "mon:stdio",
        "--no-reboot",
        "-kernel",
    });
    qemu.addFileArg(kernel_elf);
    qemu.stdio = .inherit;

    const run_step = b.step("run", "Run OS in QEMU");
    run_step.dependOn(&qemu.step);
}
