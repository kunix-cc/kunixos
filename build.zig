const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv32,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .baseline,
        .cpu_features_sub = std.Target.riscv.featureSet(&.{ .f, .d }),
    });

    const user = b.addObject(.{ .name = "user", .root_module = b.createModule(.{
        .root_source_file = b.path("src/user.zig"),
        .target = target,
        .optimize = .ReleaseSmall,
    }) });

    const common = b.addObject(.{ .name = "common", .root_module = b.createModule(.{
        .root_source_file = b.path("src/common.zig"),
        .target = target,
        .optimize = .ReleaseSmall,
    }) });

    const cflags = &.{
        "-std=c11",
        "-O2",
        "-g3",
        "-Wall",
        "-Wextra",
        "-fno-stack-protector",
    };

    const shell = b.addExecutable(.{
        .name = "shell",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = .ReleaseSmall,
        }),
    });

    shell.entry = .{ .symbol_name = "start" };
    shell.setLinkerScript(b.path("user.ld"));
    shell.root_module.addCSourceFiles(.{
        .files = &.{
            "src/shell.c",
            "src/user.c",
        },
        .flags = cflags,
    });
    shell.root_module.addObject(common);
    shell.root_module.addObject(user);

    const shell_elf = shell.getEmittedBin();

    const binary = b.addSystemCommand(&.{
        "/usr/bin/llvm-objcopy",
        "--set-section-flags",
        ".bss=alloc,contents",
        "-O",
        "binary",
    });
    binary.addFileArg(shell_elf);
    const shell_bin = binary.addOutputFileArg("shell.bin");

    const files = b.addWriteFiles();
    _ = files.addCopyFile(shell_bin, "shell.bin");

    const embed = b.addSystemCommand(&.{
        "/usr/bin/llvm-objcopy",
        "-I",
        "binary",
        "-O",
        "elf32-littleriscv",
        "shell.bin",
    });
    embed.setCwd(files.getDirectory());
    const shell_obj = embed.addOutputFileArg("shell.bin.o");

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = .ReleaseSmall,
        }),
    });
    kernel.entry = .{ .symbol_name = "boot" };
    kernel.setLinkerScript(b.path("kernel.ld"));

    kernel.root_module.addCSourceFiles(.{
        .files = &.{
            "src/kernel.c",
        },
        .flags = cflags,
    });
    kernel.root_module.addObject(common);
    kernel.root_module.addObjectFile(shell_obj);

    const kernel_elf = kernel.getEmittedBin();

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
