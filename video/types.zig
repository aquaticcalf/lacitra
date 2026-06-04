const std = @import("std");

pub const Protocol = enum {
    hls,
    dash,
};

pub const Probe = struct {
    width: u32,
    height: u32,
    duration_ms: u64,
    video_bitrate_bps: u64,
    format_bitrate_bps: u64,
};

pub const Rendition = struct {
    name: []const u8,
    width: u16,
    height: u16,
    target_bitrate_bps: u32,
    max_bitrate_bps: u32,
    buffer_size_bps: u32,
};

pub const Ladder = struct {
    renditions: []Rendition,

    pub fn deinit(self: Ladder, allocator: std.mem.Allocator) void {
        allocator.free(self.renditions);
    }
};

pub const Options = struct {
    protocol: Protocol = .hls,
    segment_seconds: u8 = 4,
    ffmpeg_path: []const u8 = "ffmpeg",
    ffprobe_path: []const u8 = "ffprobe",
    audio_bitrate: []const u8 = "128k",
    preset: []const u8 = "veryfast",
    crf: u8 = 23,
};

pub const RunOutput = struct {
    stdout: []u8,
    stderr: []u8,

    pub fn deinit(self: RunOutput, allocator: std.mem.Allocator) void {
        allocator.free(self.stdout);
        allocator.free(self.stderr);
    }
};

pub const base_renditions = [_]Rendition{
    .{ .name = "240p", .width = 426, .height = 240, .target_bitrate_bps = 350_000, .max_bitrate_bps = 430_000, .buffer_size_bps = 700_000 },
    .{ .name = "360p", .width = 640, .height = 360, .target_bitrate_bps = 700_000, .max_bitrate_bps = 850_000, .buffer_size_bps = 1_400_000 },
    .{ .name = "480p", .width = 854, .height = 480, .target_bitrate_bps = 1_200_000, .max_bitrate_bps = 1_450_000, .buffer_size_bps = 2_400_000 },
    .{ .name = "720p", .width = 1280, .height = 720, .target_bitrate_bps = 2_500_000, .max_bitrate_bps = 3_000_000, .buffer_size_bps = 5_000_000 },
    .{ .name = "1080p", .width = 1920, .height = 1080, .target_bitrate_bps = 5_000_000, .max_bitrate_bps = 6_000_000, .buffer_size_bps = 10_000_000 },
    .{ .name = "1440p", .width = 2560, .height = 1440, .target_bitrate_bps = 10_000_000, .max_bitrate_bps = 12_000_000, .buffer_size_bps = 20_000_000 },
    .{ .name = "2160p", .width = 3840, .height = 2160, .target_bitrate_bps = 18_000_000, .max_bitrate_bps = 22_000_000, .buffer_size_bps = 36_000_000 },
};
