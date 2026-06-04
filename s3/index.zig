pub const types = @import("types.zig");
pub const connection = @import("connection.zig");
pub const upload = @import("upload.zig");

pub const Client = types.Client;
pub const Buckets = types.Buckets;
pub const ObjectKeys = types.ObjectKeys;
pub const UploadResult = types.UploadResult;

pub const init_s3_connection = connection.init_s3_connection;
pub const deinit_s3_connection = connection.deinit_s3_connection;
pub const ensure_buckets = upload.ensure_buckets;
pub const upload_raw_video = upload.upload_raw_video;
pub const upload_rendition_directory = upload.upload_rendition_directory;
