const std = @import("std");
const zsx_pkg = @import("zsx");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zsx_dep = b.dependency("zsx", .{
        .target = target,
        .optimize = optimize,
    });

    const templates = zsx_pkg.addTemplates(b, zsx_dep, &.{
        b.path("server/html/pages.zsx"),
    });

    const zli_mod = b.dependency("zli", .{
        .target = target,
        .optimize = optimize,
    }).module("zli");

    const zap_mod = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
        .openssl = false,
    }).module("zap");

    const z3_mod = b.dependency("z3", .{
        .target = target,
        .optimize = optimize,
    }).module("s3");

    const core = b.addModule("core", .{
        .root_source_file = b.path("core/index.zig"),
        .target = target,
    });

    const server = b.addModule("server", .{
        .root_source_file = b.path("server/index.zig"),
        .target = target,
    });
    server.addImport("zap", zap_mod);
    server.addImport("zsx", zsx_dep.module("zsx"));

    const cli = b.addModule("cli", .{
        .root_source_file = b.path("app/cli/index.zig"),
        .target = target,
    });
    cli.addImport("zli", zli_mod);
    cli.addImport("core", core);
    cli.addImport("server", server);

    const s3 = b.addModule("s3", .{
        .root_source_file = b.path("s3/index.zig"),
        .target = target,
    });
    s3.addImport("z3", z3_mod);

    const sqlite_mod = b.dependency("sqlite", .{
        .target = target,
        .optimize = optimize,
    }).module("sqlite");

    const db = b.addModule("db", .{
        .root_source_file = b.path("db/index.zig"),
        .target = target,
        .link_libc = true,
    });
    db.addImport("sqlite", sqlite_mod);

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
    exe.step.dependOn(templates);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "run the lacitra cli");
    run_step.dependOn(&run_cmd.step);

    const start_s3_cmd = b.addSystemCommand(&.{ "podman", "compose", "up", "-d" });
    const start_s3_step = b.step("startS3", "start minio via podman compose");
    start_s3_step.dependOn(&start_s3_cmd.step);

    const stop_s3_cmd = b.addSystemCommand(&.{ "podman", "compose", "down" });
    const stop_s3_step = b.step("stopS3", "stop minio via podman compose");
    stop_s3_step.dependOn(&stop_s3_cmd.step);
}
