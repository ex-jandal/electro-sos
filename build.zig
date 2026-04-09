const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ 
        .default_target = .{ 
            .abi = .musl,
            .cpu_arch = .x86_64,
            .os_tag = .linux,
        }
    });
    const optimize = b.standardOptimizeOption(.{ 
        .preferred_optimize_mode = .ReleaseFast,
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "elctrosos",
        .root_module = mod,
        .linkage = .static,
        .version = .{
            .major = 0,
            .minor = 1,
            .patch = 0,
        }
    });

    // clap parser
    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));

    // pass version to main
    const version = b.option([]const u8, "version", "application version string") orelse "0.0.0";
    const options = b.addOptions();
    options.addOption([]const u8, "version", version);
    options.addOption([]const u8, "bin_name", exe.name);

    exe.root_module.addOptions("config", options);

    b.installArtifact(exe);

    // to make `zig build run` happen
    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    // pass the args to binary when i do `zig build run -- --args`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // this one for testing command `zig build test`
    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");

    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
