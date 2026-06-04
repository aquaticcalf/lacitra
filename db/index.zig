pub const tables = @import("tables.zig");
pub const seed_mod = @import("seed.zig");
pub const connection = @import("connection.zig");
pub const migration = @import("migration.zig");

pub const schema_version = seed_mod.schema_version;

pub const schema_migrations = tables.schema_migrations;
pub const users = tables.users;
pub const channels = tables.channels;
pub const videos = tables.videos;
pub const video_uploads = tables.video_uploads;
pub const encoding_profiles = tables.encoding_profiles;
pub const video_variants = tables.video_variants;
pub const video_renditions = tables.video_renditions;
pub const video_segments = tables.video_segments;
pub const video_manifests = tables.video_manifests;
pub const encoding_jobs = tables.encoding_jobs;
pub const tags = tables.tags;
pub const video_tags = tables.video_tags;
pub const video_daily_metrics = tables.video_daily_metrics;

pub const seed = seed_mod.seed;
pub const init_db_connection = connection.init_db_connection;
pub const deinit_db_connection = connection.deinit_db_connection;
pub const migrate = migration.migrate;
