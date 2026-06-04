const std = @import("std");
const assert = std.debug.assert;
const S3Client = @import("z3").S3Client;

pub const Client = S3Client;

pub const Buckets = struct {
    raw: []const u8 = "lacitra-raw",
    renditions: []const u8 = "lacitra-renditions",
    thumbnails: []const u8 = "lacitra-thumbnails",
};

pub const ObjectKeys = struct {
    pub fn raw_upload(allocator: std.mem.Allocator, video_id: []const u8, upload_id: []const u8, extension: []const u8) ![]u8 {
        assert(video_id.len > 0);
        assert(upload_id.len > 0);
        assert(extension.len > 0);
        return std.fmt.allocPrint(allocator, "raw/{s}/{s}.{s}", .{ video_id, upload_id, extension });
    }

    pub fn hls_master(allocator: std.mem.Allocator, video_id: []const u8) ![]u8 {
        assert(video_id.len > 0);
        return std.fmt.allocPrint(allocator, "videos/{s}/hls/master.m3u8", .{video_id});
    }

    pub fn hls_variant_playlist(allocator: std.mem.Allocator, video_id: []const u8, height: u16) ![]u8 {
        assert(video_id.len > 0);
        assert(height > 0);
        return std.fmt.allocPrint(allocator, "videos/{s}/hls/{d}p/index.m3u8", .{ video_id, height });
    }

    pub fn hls_segment(allocator: std.mem.Allocator, video_id: []const u8, height: u16, index: u32) ![]u8 {
        assert(video_id.len > 0);
        assert(height > 0);
        return std.fmt.allocPrint(allocator, "videos/{s}/hls/{d}p/seg-{d:0>6}.ts", .{ video_id, height, index });
    }

    pub fn dash_manifest(allocator: std.mem.Allocator, video_id: []const u8) ![]u8 {
        assert(video_id.len > 0);
        return std.fmt.allocPrint(allocator, "videos/{s}/dash/manifest.mpd", .{video_id});
    }

    pub fn thumbnail(allocator: std.mem.Allocator, video_id: []const u8, index: u32, extension: []const u8) ![]u8 {
        assert(video_id.len > 0);
        assert(extension.len > 0);
        return std.fmt.allocPrint(allocator, "videos/{s}/thumbs/{d:0>3}.{s}", .{ video_id, index, extension });
    }
};

pub const UploadResult = struct {
    bucket: []const u8,
    key: []const u8,
    etag: ?[]const u8,

    pub fn deinit(self: UploadResult, allocator: std.mem.Allocator) void {
        assert(self.key.len > 0);
        allocator.free(self.key);
        if (self.etag) |etag| allocator.free(etag);
    }
};
