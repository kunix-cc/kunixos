const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv32,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .baseline,
        .cpu_features_sub = std.Target.riscv.featureSet(&.{ .f, .d }),
    });

    const common = b.addObject(.{ .name = "common", .root_module = b.createModule(.{
        .root_source_file = b.path("src/common.zig"),
        .target = target,
        .optimize = .ReleaseSmall,
    }) });
    const common_obj = common.getEmittedBin();

    const cflags = [_][]const u8{
        "-std=c11",
        "-O2",
        "-g3",
        "-Wall",
        "-Wextra",
        "-target",
        "riscv32-freestanding-none",
        "-mabi=ilp32",
        "-fno-stack-protector",
        "-nostdlib",
    };

    const shell = b.addSystemCommand(&.{ "zig", "cc" });
    shell.addArgs(&cflags);
    shell.addArgs(&.{ "-Wl,-e,start", "-T" });
    shell.addFileArg(b.path("user.ld"));
    shell.addFileArg(b.path("src/shell.c"));
    shell.addFileArg(b.path("src/user.c"));
    shell.addFileArg(b.path("src/common.c"));
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
    kernel.addFileArg(b.path("src/kernel.c"));
    kernel.addFileArg(b.path("src/common.c"));
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
