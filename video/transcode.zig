const std = @import("std");
const assert = std.debug.assert;
const types = @import("types.zig");

pub const Ladder = types.Ladder;
pub const Rendition = types.Rendition;
pub const Options = types.Options;
pub const RunOutput = types.RunOutput;
pub const base_renditions = types.base_renditions;

pub fn transcode_adaptive(
    allocator: std.mem.Allocator,
    io: std.Io,
    input_path: []const u8,
    output_dir: []const u8,
    ladder: Ladder,
    options: Options,
) !RunOutput {
    assert(input_path.len > 0);
    assert(output_dir.len > 0);
    assert(ladder.renditions.len > 0);
    assert(options.segment_seconds >= 2);
    assert(options.segment_seconds <= 6);

    const argv = switch (options.protocol) {
        .hls => try build_hls_args(allocator, input_path, output_dir, ladder, options),
        .dash => try build_dash_args(allocator, input_path, output_dir, ladder, options),
    };
    defer free_argv(allocator, argv);

    const result = try std.process.run(allocator, io, .{
        .argv = argv,
        .stdout_limit = .limited(256 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    });
    errdefer allocator.free(result.stdout);
    errdefer allocator.free(result.stderr);

    switch (result.term) {
        .exited => |code| if (code != 0) return error.FfmpegFailed,
        else => return error.FfmpegFailed,
    }

    return .{ .stdout = result.stdout, .stderr = result.stderr };
}

pub fn build_hls_args(
    allocator: std.mem.Allocator,
    input_path: []const u8,
    output_dir: []const u8,
    ladder: Ladder,
    options: Options,
) ![]const []const u8 {
    assert(input_path.len > 0);
    assert(output_dir.len > 0);
    assert(ladder.renditions.len > 0);

    var args = std.ArrayList([]const u8).empty;
    errdefer free_arg_list(allocator, &args);

    try append_common_input(&args, allocator, options.ffmpeg_path, input_path);
    try append_arg(&args, allocator, "-filter_complex");
    try append_owned(&args, allocator, try build_filter_complex(allocator, ladder));

    for (ladder.renditions, 0..) |rendition, index| {
        try append_arg(&args, allocator, "-map");
        try append_owned(&args, allocator, try std.fmt.allocPrint(allocator, "[v{d}]", .{index}));
        try append_arg(&args, allocator, "-map");
        try append_arg(&args, allocator, "0:a:0?");
        try append_video_settings(&args, allocator, rendition, options, index);
    }

    try append_arg(&args, allocator, "-f");
    try append_arg(&args, allocator, "hls");
    try append_arg(&args, allocator, "-hls_time");
    try append_owned(&args, allocator, try std.fmt.allocPrint(allocator, "{d}", .{options.segment_seconds}));
    try append_arg(&args, allocator, "-hls_playlist_type");
    try append_arg(&args, allocator, "vod");
    try append_arg(&args, allocator, "-hls_flags");
    try append_arg(&args, allocator, "independent_segments");
    try append_arg(&args, allocator, "-master_pl_name");
    try append_arg(&args, allocator, "master.m3u8");
    try append_arg(&args, allocator, "-var_stream_map");
    try append_owned(&args, allocator, try hls_var_stream_map(allocator, ladder));
    try append_arg(&args, allocator, "-hls_segment_filename");
    try append_owned(&args, allocator, try std.fmt.allocPrint(allocator, "{s}/%v/seg-%06d.ts", .{output_dir}));
    try append_owned(&args, allocator, try std.fmt.allocPrint(allocator, "{s}/%v/index.m3u8", .{output_dir}));

    return try args.toOwnedSlice(allocator);
}

pub fn build_dash_args(
    allocator: std.mem.Allocator,
    input_path: []const u8,
    output_dir: []const u8,
    ladder: Ladder,
    options: Options,
) ![]const []const u8 {
    assert(input_path.len > 0);
    assert(output_dir.len > 0);
    assert(ladder.renditions.len > 0);

    var args = std.ArrayList([]const u8).empty;
    errdefer free_arg_list(allocator, &args);

    try append_common_input(&args, allocator, options.ffmpeg_path, input_path);
    try append_arg(&args, allocator, "-filter_complex");
    try append_owned(&args, allocator, try build_filter_complex(allocator, ladder));

    for (ladder.renditions, 0..) |rendition, index| {
        try append_arg(&args, allocator, "-map");
        try append_owned(&args, allocator, try std.fmt.allocPrint(allocator, "[v{d}]", .{index}));
        try append_arg(&args, allocator, "-map");
        try append_arg(&args, allocator, "0:a:0?");
        try append_video_settings(&args, allocator, rendition, options, index);
    }

    try append_arg(&args, allocator, "-f");
    try append_arg(&args, allocator, "dash");
    try append_arg(&args, allocator, "-seg_duration");
    try append_owned(&args, allocator, try std.fmt.allocPrint(allocator, "{d}", .{options.segment_seconds}));
    try append_arg(&args, allocator, "-use_template");
    try append_arg(&args, allocator, "1");
    try append_arg(&args, allocator, "-use_timeline");
    try append_arg(&args, allocator, "1");
    try append_arg(&args, allocator, "-adaptation_sets");
    try append_arg(&args, allocator, "id=0,streams=v id=1,streams=a");
    try append_owned(&args, allocator, try std.fmt.allocPrint(allocator, "{s}/manifest.mpd", .{output_dir}));

    return try args.toOwnedSlice(allocator);
}

pub fn free_argv(allocator: std.mem.Allocator, argv: []const []const u8) void {
    assert(argv.len > 0);
    for (argv) |arg| {
        allocator.free(arg);
    }
    allocator.free(argv);
}

fn append_common_input(args: *std.ArrayList([]const u8), allocator: std.mem.Allocator, ffmpeg_path: []const u8, input_path: []const u8) !void {
    assert(ffmpeg_path.len > 0);
    assert(input_path.len > 0);
    try append_arg(args, allocator, ffmpeg_path);
    try append_arg(args, allocator, "-hide_banner");
    try append_arg(args, allocator, "-y");
    try append_arg(args, allocator, "-i");
    try append_arg(args, allocator, input_path);
}

fn append_video_settings(args: *std.ArrayList([]const u8), allocator: std.mem.Allocator, rendition: Rendition, options: Options, index: usize) !void {
    assert(rendition.width > 0);
    assert(rendition.height > 0);
    assert(rendition.target_bitrate_bps > 0);

    try append_owned(args, allocator, try std.fmt.allocPrint(allocator, "-c:v:{d}", .{index}));
    try append_arg(args, allocator, "libx264");
    try append_arg(args, allocator, "-preset");
    try append_arg(args, allocator, options.preset);
    try append_arg(args, allocator, "-crf");
    try append_owned(args, allocator, try std.fmt.allocPrint(allocator, "{d}", .{options.crf}));
    try append_owned(args, allocator, try std.fmt.allocPrint(allocator, "-b:v:{d}", .{index}));
    try append_owned(args, allocator, try bitrate_arg(allocator, rendition.target_bitrate_bps));
    try append_owned(args, allocator, try std.fmt.allocPrint(allocator, "-maxrate:v:{d}", .{index}));
    try append_owned(args, allocator, try bitrate_arg(allocator, rendition.max_bitrate_bps));
    try append_owned(args, allocator, try std.fmt.allocPrint(allocator, "-bufsize:v:{d}", .{index}));
    try append_owned(args, allocator, try bitrate_arg(allocator, rendition.buffer_size_bps));
    try append_owned(args, allocator, try std.fmt.allocPrint(allocator, "-c:a:{d}", .{index}));
    try append_arg(args, allocator, "aac");
    try append_owned(args, allocator, try std.fmt.allocPrint(allocator, "-b:a:{d}", .{index}));
    try append_arg(args, allocator, options.audio_bitrate);
    try append_owned(args, allocator, try std.fmt.allocPrint(allocator, "-ac:a:{d}", .{index}));
    try append_arg(args, allocator, "2");
}

fn append_arg(args: *std.ArrayList([]const u8), allocator: std.mem.Allocator, arg: []const u8) !void {
    assert(arg.len > 0);
    const owned = try allocator.dupe(u8, arg);
    errdefer allocator.free(owned);
    try args.append(allocator, owned);
}

fn append_owned(args: *std.ArrayList([]const u8), allocator: std.mem.Allocator, arg: []u8) !void {
    errdefer allocator.free(arg);
    try args.append(allocator, arg);
}

fn free_arg_list(allocator: std.mem.Allocator, args: *std.ArrayList([]const u8)) void {
    for (args.items) |arg| allocator.free(arg);
    args.deinit(allocator);
}

fn bitrate_arg(allocator: std.mem.Allocator, bitrate_bps: u32) ![]u8 {
    assert(bitrate_bps > 0);
    return std.fmt.allocPrint(allocator, "{d}k", .{bitrate_bps / 1000});
}

fn hls_var_stream_map(allocator: std.mem.Allocator, ladder: Ladder) ![]u8 {
    assert(ladder.renditions.len > 0);

    var buf = std.ArrayList(u8).empty;
    errdefer buf.deinit(allocator);

    for (ladder.renditions, 0..) |rendition, index| {
        if (index > 0) try buf.append(allocator, ' ');
        const entry = try std.fmt.allocPrint(allocator, "v:{d},a:{d},name:{s}", .{ index, index, rendition.name });
        defer allocator.free(entry);
        try buf.appendSlice(allocator, entry);
    }

    return try buf.toOwnedSlice(allocator);
}

fn build_filter_complex(allocator: std.mem.Allocator, ladder: Ladder) ![]u8 {
    assert(ladder.renditions.len > 0);

    var buf = std.ArrayList(u8).empty;
    errdefer buf.deinit(allocator);

    try buf.appendSlice(allocator, "[0:v]split=");
    const count = try std.fmt.allocPrint(allocator, "{d}", .{ladder.renditions.len});
    defer allocator.free(count);
    try buf.appendSlice(allocator, count);

    for (ladder.renditions, 0..) |_, index| {
        const label = try std.fmt.allocPrint(allocator, "[v{d}in]", .{index});
        defer allocator.free(label);
        try buf.appendSlice(allocator, label);
    }
    try buf.append(allocator, ';');

    for (ladder.renditions, 0..) |rendition, index| {
        if (index > 0) try buf.append(allocator, ';');
        const scale = try std.fmt.allocPrint(
            allocator,
            "[v{d}in]scale=w={d}:h={d}:force_original_aspect_ratio=decrease[v{d}]",
            .{ index, rendition.width, rendition.height, index },
        );
        defer allocator.free(scale);
        try buf.appendSlice(allocator, scale);
    }

    return try buf.toOwnedSlice(allocator);
}

fn has_arg(argv: []const []const u8, expected: []const u8) bool {
    assert(expected.len > 0);
    for (argv) |arg| {
        if (std.mem.eql(u8, arg, expected)) return true;
    }
    return false;
}

test "hls args include adaptive segment settings" {
    const allocator = std.testing.allocator;
    const ladder = Ladder{ .renditions = @constCast(&[_]Rendition{base_renditions[0]}) };
    const args = try build_hls_args(allocator, "input.mp4", "/tmp/out", ladder, .{ .segment_seconds = 2 });
    defer free_argv(allocator, args);

    try std.testing.expect(has_arg(args, "-hls_time"));
    try std.testing.expect(has_arg(args, "master.m3u8"));
}
