const std = @import("std");
const assert = std.debug.assert;
const types = @import("types.zig");

pub const Probe = types.Probe;
pub const Options = types.Options;

pub fn analyze(allocator: std.mem.Allocator, io: std.Io, input_path: []const u8, options: Options) !Probe {
    assert(input_path.len > 0);
    assert(options.ffprobe_path.len > 0);

    const argv = [_][]const u8{
        options.ffprobe_path,
        "-v",
        "error",
        "-select_streams",
        "v:0",
        "-show_entries",
        "stream=width,height,bit_rate:format=duration,bit_rate",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        input_path,
    };

    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(16 * 1024),
        .stderr_limit = .limited(16 * 1024),
    });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    switch (result.term) {
        .exited => |code| if (code != 0) return error.FfprobeFailed,
        else => return error.FfprobeFailed,
    }

    return parse_probe_output(result.stdout);
}

fn parse_probe_output(stdout: []const u8) !Probe {
    assert(stdout.len > 0);

    var it = std.mem.splitScalar(u8, stdout, '\n');
    const width = try parse_int_line(u32, it.next());
    const height = try parse_int_line(u32, it.next());
    const stream_bitrate = parse_int_line(u64, it.next()) catch 0;
    const duration_seconds = try parse_float_line(it.next());
    const format_bitrate = parse_int_line(u64, it.next()) catch 0;

    return .{
        .width = width,
        .height = height,
        .duration_ms = @intFromFloat(duration_seconds * 1000),
        .video_bitrate_bps = stream_bitrate,
        .format_bitrate_bps = format_bitrate,
    };
}

fn parse_int_line(comptime T: type, line_opt: ?[]const u8) !T {
    const line = std.mem.trim(u8, line_opt orelse return error.InvalidProbeOutput, " \r\n");
    if (line.len == 0 or std.mem.eql(u8, line, "N/A")) return error.InvalidProbeOutput;
    return std.fmt.parseInt(T, line, 10);
}

fn parse_float_line(line_opt: ?[]const u8) !f64 {
    const line = std.mem.trim(u8, line_opt orelse return error.InvalidProbeOutput, " \r\n");
    if (line.len == 0 or std.mem.eql(u8, line, "N/A")) return error.InvalidProbeOutput;
    return std.fmt.parseFloat(f64, line);
}
