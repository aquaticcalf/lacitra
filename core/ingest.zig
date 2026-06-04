const std = @import("std");
const assert = std.debug.assert;
const s3 = @import("s3");
const video = @import("video");
const types = @import("types.zig");

pub const TranscodedVideo = types.TranscodedVideo;
pub const IngestedVideo = types.IngestedVideo;
pub const PlannedVideo = types.PlannedVideo;
pub const LocalIngestOptions = types.LocalIngestOptions;

pub fn plan_local_video(
    allocator: std.mem.Allocator,
    io: std.Io,
    source_path: []const u8,
    options: video.Options,
) !PlannedVideo {
    assert(source_path.len > 0);

    const probe = try video.analyze(allocator, io, source_path, options);
    const ladder = try video.plan_ladder(allocator, probe);
    return .{
        .probe = probe,
        .ladder = ladder,
    };
}

pub fn transcode_local_video(
    allocator: std.mem.Allocator,
    io: std.Io,
    video_id: []const u8,
    source_path: []const u8,
    options: LocalIngestOptions,
) !TranscodedVideo {
    assert(video_id.len > 0);
    assert(source_path.len > 0);

    const planned = try plan_local_video(allocator, io, source_path, options.transcode);
    errdefer planned.deinit(allocator);

    const output_dir = try output_dir_for_video(allocator, options.work_root, video_id, options.transcode.protocol);
    errdefer allocator.free(output_dir);
    try std.fs.cwd().makePath(output_dir);

    var run_output = try video.transcode_adaptive(allocator, io, source_path, output_dir, planned.ladder, options.transcode);
    defer run_output.deinit(allocator);

    const prefix = try rendition_prefix(allocator, video_id, options.transcode.protocol);
    errdefer allocator.free(prefix);

    return .{
        .probe = planned.probe,
        .ladder = planned.ladder,
        .output_dir = output_dir,
        .rendition_prefix = prefix,
        .protocol = options.transcode.protocol,
    };
}

pub fn upload_raw_source(
    client: *s3.Client,
    allocator: std.mem.Allocator,
    video_id: []const u8,
    upload_id: []const u8,
    source_path: []const u8,
    options: LocalIngestOptions,
) !s3.UploadResult {
    assert(video_id.len > 0);
    assert(upload_id.len > 0);
    assert(source_path.len > 0);

    if (options.ensure_buckets) {
        try s3.ensure_buckets(client, options.buckets);
    }

    return try s3.upload_raw_video(
        client,
        allocator,
        options.buckets,
        video_id,
        upload_id,
        source_path,
        options.raw_extension,
        options.raw_content_type,
    );
}

pub fn upload_transcoded_video(
    client: *s3.Client,
    allocator: std.mem.Allocator,
    transcoded: TranscodedVideo,
    buckets: s3.Buckets,
) !void {
    assert(transcoded.output_dir.len > 0);
    assert(transcoded.rendition_prefix.len > 0);

    try s3.upload_rendition_directory(
        client,
        allocator,
        buckets.renditions,
        transcoded.output_dir,
        transcoded.rendition_prefix,
    );
}

pub fn ingest_local_video(
    client: *s3.Client,
    allocator: std.mem.Allocator,
    io: std.Io,
    video_id: []const u8,
    upload_id: []const u8,
    source_path: []const u8,
    options: LocalIngestOptions,
) !IngestedVideo {
    assert(video_id.len > 0);
    assert(upload_id.len > 0);
    assert(source_path.len > 0);

    const raw = try upload_raw_source(client, allocator, video_id, upload_id, source_path, options);
    errdefer raw.deinit(allocator);

    const transcoded = try transcode_local_video(allocator, io, video_id, source_path, options);
    errdefer transcoded.deinit(allocator);

    if (options.upload_renditions) {
        try upload_transcoded_video(client, allocator, transcoded, options.buckets);
    }

    return .{
        .raw_upload = raw,
        .probe = transcoded.probe,
        .ladder = transcoded.ladder,
        .output_dir = transcoded.output_dir,
        .rendition_bucket = options.buckets.renditions,
        .rendition_prefix = transcoded.rendition_prefix,
        .protocol = transcoded.protocol,
    };
}

pub fn output_dir_for_video(
    allocator: std.mem.Allocator,
    work_root: []const u8,
    video_id: []const u8,
    protocol: video.Protocol,
) ![]u8 {
    assert(work_root.len > 0);
    assert(video_id.len > 0);

    return std.fs.path.join(allocator, &.{
        work_root,
        video_id,
        protocol_dir(protocol),
    });
}

pub fn rendition_prefix(
    allocator: std.mem.Allocator,
    video_id: []const u8,
    protocol: video.Protocol,
) ![]u8 {
    assert(video_id.len > 0);

    return std.fmt.allocPrint(allocator, "videos/{s}/{s}", .{ video_id, protocol_dir(protocol) });
}

fn protocol_dir(protocol: video.Protocol) []const u8 {
    return switch (protocol) {
        .hls => "hls",
        .dash => "dash",
    };
}

test "core derives stable work paths and object prefixes" {
    const allocator = std.testing.allocator;

    const output_dir = try output_dir_for_video(allocator, "work", "vid_123", .hls);
    defer allocator.free(output_dir);
    try std.testing.expectEqualStrings("work/vid_123/hls", output_dir);

    const prefix = try rendition_prefix(allocator, "vid_123", .dash);
    defer allocator.free(prefix);
    try std.testing.expectEqualStrings("videos/vid_123/dash", prefix);
}
