const std = @import("std");
const assert = std.debug.assert;
const db = @import("db");
const sqlite = @import("sqlite");
const video = @import("video");
const types = @import("types.zig");

pub const VideoDraftInput = types.VideoDraftInput;
pub const RawUploadRecord = types.RawUploadRecord;
pub const EncodingJobRecord = types.EncodingJobRecord;

pub fn prepare_database(database: *sqlite.Db) !void {
    try db.migrate(database);
}

pub fn create_video_draft(database: *sqlite.Db, input: VideoDraftInput) !void {
    assert(input.id.len > 0);
    assert(input.channel_id.len > 0);
    assert(input.title.len > 0);
    assert(input.slug.len > 0);

    try sqlite.insert(database, db.videos, .{
        .id = input.id,
        .channel_id = input.channel_id,
        .title = input.title,
        .slug = input.slug,
        .description = input.description,
        .visibility = input.visibility,
        .status = "draft",
    });
}

pub fn record_raw_upload(database: *sqlite.Db, input: RawUploadRecord) !void {
    assert(input.id.len > 0);
    assert(input.video_id.len > 0);
    assert(input.bucket.len > 0);
    assert(input.object_key.len > 0);

    try sqlite.insert(database, db.video_uploads, .{
        .id = input.id,
        .video_id = input.video_id,
        .bucket = input.bucket,
        .object_key = input.object_key,
        .original_filename = input.original_filename,
        .content_type = input.content_type,
        .size_bytes = input.size_bytes,
        .status = "uploaded",
    });
}

pub fn record_video_probe(database: *sqlite.Db, video_id: []const u8, probe: video.Probe) !void {
    assert(video_id.len > 0);
    assert(probe.duration_ms > 0);
    assert(probe.width > 0);
    assert(probe.height > 0);

    try sqlite.update(database, db.videos, .{
        .status = "'processing'",
        .duration_ms = "?",
        .width = "?",
        .height = "?",
        .source_bitrate_bps = "?",
        .updated_at = "unixepoch()",
    }, "id = ?", .{
        checked_i64(probe.duration_ms),
        checked_i64(probe.width),
        checked_i64(probe.height),
        checked_i64(if (probe.video_bitrate_bps > 0) probe.video_bitrate_bps else probe.format_bitrate_bps),
        video_id,
    });
}

pub fn record_encoding_plan(
    allocator: std.mem.Allocator,
    database: *sqlite.Db,
    video_id: []const u8,
    profile_id: []const u8,
    ladder: video.Ladder,
) !void {
    assert(video_id.len > 0);
    assert(profile_id.len > 0);
    assert(ladder.renditions.len > 0);

    for (ladder.renditions) |rendition| {
        const variant_id = try std.fmt.allocPrint(allocator, "{s}-{d}p-h264", .{ video_id, rendition.height });
        defer allocator.free(variant_id);

        try sqlite.insert_or_replace(database, db.video_variants, .{
            .id = variant_id,
            .video_id = video_id,
            .profile_id = profile_id,
            .width = checked_i64(rendition.width),
            .height = checked_i64(rendition.height),
            .target_bitrate_bps = checked_i64(rendition.target_bitrate_bps),
            .max_bitrate_bps = checked_i64(rendition.max_bitrate_bps),
            .buffer_size_bps = checked_i64(rendition.buffer_size_bps),
            .codec = "h264",
            .status = "queued",
        });
    }
}

pub fn queue_encoding_job(database: *sqlite.Db, input: EncodingJobRecord) !void {
    assert(input.id.len > 0);
    assert(input.video_id.len > 0);

    try sqlite.insert(database, db.encoding_jobs, .{
        .id = input.id,
        .video_id = input.video_id,
        .upload_id = input.upload_id,
        .priority = input.priority,
        .ffmpeg_args_json = input.ffmpeg_args_json,
        .status = "queued",
    });
}

pub fn mark_video_ready(database: *sqlite.Db, video_id: []const u8) !void {
    assert(video_id.len > 0);

    try sqlite.update(database, db.videos, .{
        .status = "'ready'",
        .published_at = "COALESCE(published_at, unixepoch())",
        .updated_at = "unixepoch()",
    }, "id = ?", .{video_id});
}

fn checked_i64(value: anytype) i64 {
    const casted = std.math.cast(i64, value);
    assert(casted != null);

    return casted orelse unreachable;
}

test "core database lifecycle helpers are callable" {
    var database = try sqlite.Db.init(.{ .write = true, .create = true });
    defer database.deinit();

    try db.migrate(&database);

    try sqlite.insert(&database, db.users, .{
        .id = "user_123",
        .handle = "creator",
        .display_name = "Creator",
        .role = "creator",
        .status = "active",
    });
    try sqlite.insert(&database, db.channels, .{
        .id = "chan_123",
        .owner_user_id = "user_123",
        .slug = "example",
        .title = "Example Channel",
    });
    try create_video_draft(&database, .{
        .id = "vid_123",
        .channel_id = "chan_123",
        .title = "Example",
        .slug = "example",
    });
    try record_raw_upload(&database, .{
        .id = "upl_123",
        .video_id = "vid_123",
        .bucket = "raw",
        .object_key = "raw/vid_123/upl_123.mp4",
        .original_filename = "example.mp4",
        .content_type = "video/mp4",
        .size_bytes = 1024,
    });
    try record_video_probe(&database, "vid_123", .{
        .width = 1920,
        .height = 1080,
        .duration_ms = 90_000,
        .video_bitrate_bps = 4_000_000,
        .format_bitrate_bps = 4_200_000,
    });
    try queue_encoding_job(&database, .{
        .id = "job_123",
        .video_id = "vid_123",
        .upload_id = "upl_123",
    });
    try mark_video_ready(&database, "vid_123");
}
