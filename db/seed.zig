const sqlite = @import("sqlite");
const tables = @import("tables.zig");

pub const schema_version = 1;

pub fn seed(db: *sqlite.Db) !void {
    try sqlite.insert_or_ignore(db, tables.encoding_profiles, .{
        .id = "hls-h264-aac-2s",
        .name = "HLS H.264/AAC 2s segments",
        .container = "hls",
        .video_codec = "libx264",
        .audio_codec = "aac",
        .segment_seconds = @as(i64, 2),
        .created_at = @as(i64, 0),
    });
    try sqlite.insert_or_ignore(db, tables.encoding_profiles, .{
        .id = "dash-h264-aac-4s",
        .name = "MPEG-DASH H.264/AAC 4s segments",
        .container = "dash",
        .video_codec = "libx264",
        .audio_codec = "aac",
        .segment_seconds = @as(i64, 4),
        .created_at = @as(i64, 0),
    });
    try sqlite.insert_or_ignore(db, tables.schema_migrations, .{
        .version = schema_version,
        .applied_at = @as(i64, 0),
    });
}
