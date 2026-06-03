const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zli_mod = b.dependency("zli", .{
        .target = target,
        .optimize = optimize,
    }).module("zli");

    const zap_mod = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
        .openssl = false,
    }).module("zap");

    const core = b.addModule("core", .{
        .root_source_file = b.path("core/core.zig"),
        .target = target,
    });

    const server = b.addModule("server", .{
        .root_source_file = b.path("server/index.zig"),
        .target = target,
    });
    server.addImport("zap", zap_mod);

    const cli = b.addModule("cli", .{
        .root_source_file = b.path("app/cli/index.zig"),
        .target = target,
    });
    cli.addImport("zli", zli_mod);
    cli.addImport("core", core);
    cli.addImport("server", server);

    const exe = b.addExecutable(.{
        .name = "lacitra",
        .root_module = b.createModule(.{
            .root_source_file = b.path("app/index.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "cli", .module = cli },
                .{ .name = "core", .module = core },
                .{ .name = "server", .module = server },
                .{ .name = "zli", .module = zli_mod },
            },
        }),
    });
    exe.root_module.addImport("zap", zap_mod);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
