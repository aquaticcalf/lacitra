const std = @import("std");
const sqlite = @import("sqlite");
const tables = @import("tables.zig");
const seed = @import("seed.zig");

const all_tables = .{
    tables.schema_migrations,
    tables.users,
    tables.channels,
    tables.videos,
    tables.video_uploads,
    tables.encoding_profiles,
    tables.video_variants,
    tables.video_renditions,
    tables.video_segments,
    tables.video_manifests,
    tables.encoding_jobs,
    tables.tags,
    tables.video_tags,
    tables.video_daily_metrics,
};

const IndexSpec = struct {
    name: []const u8,
    table: []const u8,
    columns: []const u8,
    opts: sqlite.IndexOpts,
};

const all_index_specs = [_]IndexSpec{
    .{ .name = "idx_videos_ready_recent", .table = "videos", .columns = "status, visibility, published_at DESC", .opts = sqlite.IndexOpts{ .where = "deleted_at IS NULL" } },
    .{ .name = "idx_videos_channel_recent", .table = "videos", .columns = "channel_id, published_at DESC", .opts = sqlite.IndexOpts{ .where = "deleted_at IS NULL" } },
    .{ .name = "idx_video_uploads_video", .table = "video_uploads", .columns = "video_id", .opts = .{} },
    .{ .name = "idx_video_variants_video_status", .table = "video_variants", .columns = "video_id, status", .opts = .{} },
    .{ .name = "idx_video_segments_rendition_index", .table = "video_segments", .columns = "rendition_id, segment_index", .opts = .{} },
    .{ .name = "idx_encoding_jobs_status_priority", .table = "encoding_jobs", .columns = "status, priority DESC, queued_at ASC", .opts = .{} },
    .{ .name = "idx_video_metrics_views", .table = "video_daily_metrics", .columns = "day, views DESC", .opts = .{} },
};

pub fn migrate(db: *sqlite.Db) !void {

    try db.pragma("foreign_keys", "1");
    try db.pragma("synchronous", "NORMAL");
    try db.pragma("busy_timeout", "5000");
    inline for (all_tables) |table_meta| {
        const stmt = comptime sqlite.create_stmt(table_meta, true);
        try db.exec_multi(stmt.data[0..stmt.len]);
    }
    inline for (all_index_specs) |spec| {
        const stmt = comptime sqlite.create_index(spec.name, spec.table, spec.columns, spec.opts);
        try db.exec_multi(stmt.data[0..stmt.len]);
    }
    try seed.seed(db);
}

test "ddl generates valid SQL" {
    const generated = comptime sqlite.create_stmt(tables.videos, true);
    try std.testing.expect(generated.len > 0);
    try std.testing.expect(generated.len > 10);
}

test "schema migration creates core video tables" {
    var database = try sqlite.Db.init(.{
        .write = true,
        .create = true,
    });
    defer database.deinit();

    try migrate(&database);

    const q = comptime sqlite.count_tables_query(&.{ "videos", "video_uploads", "video_variants", "video_segments", "encoding_jobs" });
    const table_count = try database.one(usize, q.data[0..q.len], .{});

    try std.testing.expectEqual(@as(usize, 5), table_count.?);
}
