const sqlite = @import("sqlite");

pub const schema_migrations = sqlite.table("schema_migrations", .{
    .version = sqlite.Column("version", i64).primary_key(),
    .applied_at = sqlite.Column("applied_at", i64).not_null().default("(unixepoch())"),
});

pub const users = sqlite.table("users", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .handle = sqlite.Column("handle", []const u8).not_null().unique().collate("NOCASE"),
    .display_name = sqlite.Column("display_name", []const u8).not_null(),
    .email = sqlite.Column("email", ?[]const u8).unique().collate("NOCASE"),
    .password_hash = sqlite.Column("password_hash", ?[]const u8),
    .role = sqlite.Column("role", []const u8).not_null().default("'user'").check("role IN ('user', 'creator', 'moderator', 'admin')"),
    .status = sqlite.Column("status", []const u8).not_null().default("'active'").check("status IN ('active', 'limited', 'suspended', 'deleted')"),
    .created_at = sqlite.Column("created_at", i64).not_null().default("(unixepoch())"),
    .updated_at = sqlite.Column("updated_at", i64).not_null().default("(unixepoch())"),
    .deleted_at = sqlite.Column("deleted_at", ?i64),
});

pub const channels = sqlite.table("channels", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .owner_user_id = sqlite.Column("owner_user_id", []const u8).not_null().references("users(id) ON DELETE CASCADE"),
    .slug = sqlite.Column("slug", []const u8).not_null().unique().collate("NOCASE"),
    .title = sqlite.Column("title", []const u8).not_null(),
    .description = sqlite.Column("description", []const u8).not_null().default("''"),
    .avatar_object_key = sqlite.Column("avatar_object_key", ?[]const u8),
    .banner_object_key = sqlite.Column("banner_object_key", ?[]const u8),
    .visibility = sqlite.Column("visibility", []const u8).not_null().default("'public'").check("visibility IN ('public', 'unlisted', 'private')"),
    .created_at = sqlite.Column("created_at", i64).not_null().default("(unixepoch())"),
    .updated_at = sqlite.Column("updated_at", i64).not_null().default("(unixepoch())"),
});

pub const videos = sqlite.table("videos", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .channel_id = sqlite.Column("channel_id", []const u8).not_null().references("channels(id) ON DELETE CASCADE"),
    .title = sqlite.Column("title", []const u8).not_null(),
    .slug = sqlite.Column("slug", []const u8).not_null(),
    .description = sqlite.Column("description", []const u8).not_null().default("''"),
    .status = sqlite.Column("status", []const u8).not_null().default("'draft'").check("status IN ('draft', 'uploading', 'uploaded', 'processing', 'ready', 'failed', 'blocked', 'deleted')"),
    .visibility = sqlite.Column("visibility", []const u8).not_null().default("'public'").check("visibility IN ('public', 'unlisted', 'private')"),
    .duration_ms = sqlite.Column("duration_ms", ?i64),
    .width = sqlite.Column("width", ?i64),
    .height = sqlite.Column("height", ?i64),
    .source_bitrate_bps = sqlite.Column("source_bitrate_bps", ?i64),
    .source_size_bytes = sqlite.Column("source_size_bytes", ?i64),
    .source_sha256 = sqlite.Column("source_sha256", ?[]const u8),
    .thumbnail_object_key = sqlite.Column("thumbnail_object_key", ?[]const u8),
    .preview_sprite_object_key = sqlite.Column("preview_sprite_object_key", ?[]const u8),
    .published_at = sqlite.Column("published_at", ?i64),
    .created_at = sqlite.Column("created_at", i64).not_null().default("(unixepoch())"),
    .updated_at = sqlite.Column("updated_at", i64).not_null().default("(unixepoch())"),
    .deleted_at = sqlite.Column("deleted_at", ?i64),
});

pub const video_uploads = sqlite.table("video_uploads", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .video_id = sqlite.Column("video_id", []const u8).not_null().references("videos(id) ON DELETE CASCADE"),
    .bucket = sqlite.Column("bucket", []const u8).not_null(),
    .object_key = sqlite.Column("object_key", []const u8).not_null(),
    .original_filename = sqlite.Column("original_filename", []const u8).not_null(),
    .content_type = sqlite.Column("content_type", []const u8).not_null(),
    .size_bytes = sqlite.Column("size_bytes", i64).not_null().default("0"),
    .status = sqlite.Column("status", []const u8).not_null().default("'pending'").check("status IN ('pending', 'uploaded', 'verified', 'rejected')"),
    .created_at = sqlite.Column("created_at", i64).not_null().default("(unixepoch())"),
    .completed_at = sqlite.Column("completed_at", ?i64),
});

pub const encoding_profiles = sqlite.table("encoding_profiles", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .name = sqlite.Column("name", []const u8).not_null().unique(),
    .container = sqlite.Column("container", []const u8).not_null().check("container IN ('hls', 'dash')"),
    .video_codec = sqlite.Column("video_codec", []const u8).not_null(),
    .audio_codec = sqlite.Column("audio_codec", []const u8).not_null(),
    .segment_seconds = sqlite.Column("segment_seconds", i64).not_null().check("segment_seconds BETWEEN 2 AND 6"),
    .created_at = sqlite.Column("created_at", i64).not_null().default("(unixepoch())"),
});

pub const video_variants = sqlite.table("video_variants", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .video_id = sqlite.Column("video_id", []const u8).not_null().references("videos(id) ON DELETE CASCADE"),
    .profile_id = sqlite.Column("profile_id", []const u8).not_null().references("encoding_profiles(id)"),
    .width = sqlite.Column("width", i64).not_null(),
    .height = sqlite.Column("height", i64).not_null(),
    .target_bitrate_bps = sqlite.Column("target_bitrate_bps", i64).not_null(),
    .max_bitrate_bps = sqlite.Column("max_bitrate_bps", i64).not_null(),
    .buffer_size_bps = sqlite.Column("buffer_size_bps", i64).not_null(),
    .codec = sqlite.Column("codec", []const u8).not_null(),
    .status = sqlite.Column("status", []const u8).not_null().default("'queued'").check("status IN ('queued', 'encoding', 'ready', 'failed', 'deleted')"),
    .created_at = sqlite.Column("created_at", i64).not_null().default("(unixepoch())"),
    .updated_at = sqlite.Column("updated_at", i64).not_null().default("(unixepoch())"),
});

pub const video_renditions = sqlite.table("video_renditions", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .variant_id = sqlite.Column("variant_id", []const u8).not_null().references("video_variants(id) ON DELETE CASCADE"),
    .bucket = sqlite.Column("bucket", []const u8).not_null(),
    .playlist_key = sqlite.Column("playlist_key", []const u8).not_null(),
    .init_segment_key = sqlite.Column("init_segment_key", ?[]const u8),
    .bytes_total = sqlite.Column("bytes_total", i64).not_null().default("0"),
    .segment_count = sqlite.Column("segment_count", i64).not_null().default("0"),
    .ready_at = sqlite.Column("ready_at", ?i64),
});

pub const video_segments = sqlite.table("video_segments", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .rendition_id = sqlite.Column("rendition_id", []const u8).not_null().references("video_renditions(id) ON DELETE CASCADE"),
    .segment_index = sqlite.Column("segment_index", i64).not_null(),
    .bucket = sqlite.Column("bucket", []const u8).not_null(),
    .object_key = sqlite.Column("object_key", []const u8).not_null(),
    .duration_ms = sqlite.Column("duration_ms", i64).not_null(),
    .size_bytes = sqlite.Column("size_bytes", i64).not_null(),
    .byte_start = sqlite.Column("byte_start", ?i64),
    .byte_end = sqlite.Column("byte_end", ?i64),
});

pub const video_manifests = sqlite.table("video_manifests", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .video_id = sqlite.Column("video_id", []const u8).not_null().references("videos(id) ON DELETE CASCADE"),
    .kind = sqlite.Column("kind", []const u8).not_null().check("kind IN ('hls_master', 'dash_mpd')"),
    .bucket = sqlite.Column("bucket", []const u8).not_null(),
    .object_key = sqlite.Column("object_key", []const u8).not_null(),
    .created_at = sqlite.Column("created_at", i64).not_null().default("(unixepoch())"),
});

pub const encoding_jobs = sqlite.table("encoding_jobs", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .video_id = sqlite.Column("video_id", []const u8).not_null().references("videos(id) ON DELETE CASCADE"),
    .upload_id = sqlite.Column("upload_id", ?[]const u8).references("video_uploads(id) ON DELETE SET NULL"),
    .status = sqlite.Column("status", []const u8).not_null().default("'queued'").check("status IN ('queued', 'running', 'succeeded', 'failed', 'canceled')"),
    .priority = sqlite.Column("priority", i64).not_null().default("0"),
    .attempt_count = sqlite.Column("attempt_count", i64).not_null().default("0"),
    .ffmpeg_args_json = sqlite.Column("ffmpeg_args_json", []const u8).not_null().default("'[]'"),
    .error_message = sqlite.Column("error_message", ?[]const u8),
    .queued_at = sqlite.Column("queued_at", i64).not_null().default("(unixepoch())"),
    .started_at = sqlite.Column("started_at", ?i64),
    .finished_at = sqlite.Column("finished_at", ?i64),
});

pub const tags = sqlite.table("tags", .{
    .id = sqlite.Column("id", []const u8).primary_key(),
    .slug = sqlite.Column("slug", []const u8).not_null().unique().collate("NOCASE"),
    .title = sqlite.Column("title", []const u8).not_null(),
});

pub const video_tags = sqlite.table("video_tags", .{
    .video_id = sqlite.Column("video_id", []const u8).not_null().references("videos(id) ON DELETE CASCADE"),
    .tag_id = sqlite.Column("tag_id", []const u8).not_null().references("tags(id) ON DELETE CASCADE"),
});

pub const video_daily_metrics = sqlite.table("video_daily_metrics", .{
    .video_id = sqlite.Column("video_id", []const u8).not_null().references("videos(id) ON DELETE CASCADE"),
    .day = sqlite.Column("day", []const u8).not_null(),
    .views = sqlite.Column("views", i64).not_null().default("0"),
    .watch_ms = sqlite.Column("watch_ms", i64).not_null().default("0"),
    .bytes_served = sqlite.Column("bytes_served", i64).not_null().default("0"),
    .likes = sqlite.Column("likes", i64).not_null().default("0"),
    .dislikes = sqlite.Column("dislikes", i64).not_null().default("0"),
});
