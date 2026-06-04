const std = @import("std");
const assert = std.debug.assert;
const s3 = @import("s3");
const video = @import("video");

pub const LocalIngestOptions = struct {
    buckets: s3.Buckets = .{},
    work_root: []const u8 = "var/lacitra/transcode",
    raw_extension: []const u8 = "mp4",
    raw_content_type: []const u8 = "video/mp4",
    transcode: video.Options = .{},
    ensure_buckets: bool = true,
    upload_renditions: bool = true,
};

pub const PlannedVideo = struct {
    probe: video.Probe,
    ladder: video.Ladder,

    pub fn deinit(self: PlannedVideo, allocator: std.mem.Allocator) void {
        self.ladder.deinit(allocator);
    }
};

pub const TranscodedVideo = struct {
    probe: video.Probe,
    ladder: video.Ladder,
    output_dir: []const u8,
    rendition_prefix: []const u8,
    protocol: video.Protocol,

    pub fn deinit(self: TranscodedVideo, allocator: std.mem.Allocator) void {
        assert(self.output_dir.len > 0);
        assert(self.rendition_prefix.len > 0);
        self.ladder.deinit(allocator);
        allocator.free(self.output_dir);
        allocator.free(self.rendition_prefix);
    }
};

pub const IngestedVideo = struct {
    raw_upload: s3.UploadResult,
    probe: video.Probe,
    ladder: video.Ladder,
    output_dir: []const u8,
    rendition_bucket: []const u8,
    rendition_prefix: []const u8,
    protocol: video.Protocol,

    pub fn deinit(self: IngestedVideo, allocator: std.mem.Allocator) void {
        assert(self.output_dir.len > 0);
        assert(self.rendition_bucket.len > 0);
        assert(self.rendition_prefix.len > 0);
        self.raw_upload.deinit(allocator);
        self.ladder.deinit(allocator);
        allocator.free(self.output_dir);
        allocator.free(self.rendition_prefix);
    }
};

pub const VideoDraftInput = struct {
    id: []const u8,
    channel_id: []const u8,
    title: []const u8,
    slug: []const u8,
    description: []const u8 = "",
    visibility: []const u8 = "public",
};

pub const RawUploadRecord = struct {
    id: []const u8,
    video_id: []const u8,
    bucket: []const u8,
    object_key: []const u8,
    original_filename: []const u8,
    content_type: []const u8,
    size_bytes: i64 = 0,
};

pub const EncodingJobRecord = struct {
    id: []const u8,
    video_id: []const u8,
    upload_id: ?[]const u8 = null,
    priority: i64 = 0,
    ffmpeg_args_json: []const u8 = "[]",
};
