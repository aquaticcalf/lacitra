const std = @import("std");
const assert = std.debug.assert;
const S3Client = @import("z3").S3Client;
const types = @import("types.zig");

pub const Buckets = types.Buckets;
pub const ObjectKeys = types.ObjectKeys;
pub const UploadResult = types.UploadResult;

pub fn ensure_buckets(client: *S3Client, buckets: Buckets) !void {
    try ensure_bucket(client, buckets.raw);
    try ensure_bucket(client, buckets.renditions);
    try ensure_bucket(client, buckets.thumbnails);
}

pub fn upload_raw_video(
    client: *S3Client,
    allocator: std.mem.Allocator,
    buckets: Buckets,
    video_id: []const u8,
    upload_id: []const u8,
    src_path: []const u8,
    extension: []const u8,
    content_type: []const u8,
) !UploadResult {
    assert(video_id.len > 0);
    assert(upload_id.len > 0);
    assert(src_path.len > 0);
    assert(extension.len > 0);
    assert(content_type.len > 0);

    const key = try ObjectKeys.raw_upload(allocator, video_id, upload_id, extension);
    errdefer allocator.free(key);

    var response = try client.putFile(buckets.raw, key, src_path, .{ .content_type = content_type });
    defer response.deinit();
    try expect_ok(response.http_head.status);

    const etag = if (response.s3_head.etag) |value| try allocator.dupe(u8, value) else null;
    errdefer if (etag) |value| allocator.free(value);

    return .{
        .bucket = buckets.raw,
        .key = key,
        .etag = etag,
    };
}

pub fn upload_rendition_directory(
    client: *S3Client,
    allocator: std.mem.Allocator,
    bucket: []const u8,
    local_dir_path: []const u8,
    object_prefix: []const u8,
) !void {
    assert(bucket.len > 0);
    assert(local_dir_path.len > 0);
    assert(object_prefix.len > 0);

    var dir = try std.fs.cwd().openDir(local_dir_path, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;

        const key = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ object_prefix, entry.path });
        defer allocator.free(key);

        const local_path = try std.fs.path.join(allocator, &.{ local_dir_path, entry.path });
        defer allocator.free(local_path);

        var response = try client.putFile(bucket, key, local_path, .{
            .content_type = content_type_for_path(entry.path),
        });
        defer response.deinit();
        try expect_ok(response.http_head.status);
    }
}

fn ensure_bucket(client: *S3Client, bucket: []const u8) !void {
    assert(bucket.len > 0);
    var response = client.createBucket(bucket, .{}) catch |err| switch (err) {
        error.S3Error, error.RequestFailed => return,
        else => |e| return e,
    };
    defer response.deinit();
}

fn expect_ok(status: std.http.Status) !void {
    switch (status) {
        .ok, .created, .no_content => {},
        else => return error.S3UploadFailed,
    }
}

fn content_type_for_path(path: []const u8) []const u8 {
    assert(path.len > 0);
    if (std.mem.endsWith(u8, path, ".m3u8")) return "application/vnd.apple.mpegurl";
    if (std.mem.endsWith(u8, path, ".mpd")) return "application/dash+xml";
    if (std.mem.endsWith(u8, path, ".m4s")) return "video/iso.segment";
    if (std.mem.endsWith(u8, path, ".mp4")) return "video/mp4";
    if (std.mem.endsWith(u8, path, ".ts")) return "video/mp2t";
    if (std.mem.endsWith(u8, path, ".webp")) return "image/webp";
    if (std.mem.endsWith(u8, path, ".jpg") or std.mem.endsWith(u8, path, ".jpeg")) return "image/jpeg";
    if (std.mem.endsWith(u8, path, ".png")) return "image/png";
    return "application/octet-stream";
}

test "object keys are stable" {
    const allocator = std.testing.allocator;

    const key = try ObjectKeys.hls_segment(allocator, "vid_123", 720, 42);
    defer allocator.free(key);

    try std.testing.expectEqualStrings("videos/vid_123/hls/720p/seg-000042.ts", key);
}
