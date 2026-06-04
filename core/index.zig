const std = @import("std");
const s3 = @import("s3");
const video = @import("video");

pub const storage = s3;
pub const media = video;

pub const types = @import("types.zig");
pub const database = @import("database.zig");
pub const ingest = @import("ingest.zig");

pub const LocalIngestOptions = types.LocalIngestOptions;
pub const PlannedVideo = types.PlannedVideo;
pub const TranscodedVideo = types.TranscodedVideo;
pub const IngestedVideo = types.IngestedVideo;
pub const VideoDraftInput = types.VideoDraftInput;
pub const RawUploadRecord = types.RawUploadRecord;
pub const EncodingJobRecord = types.EncodingJobRecord;

pub const prepare_database = database.prepare_database;
pub const create_video_draft = database.create_video_draft;
pub const record_raw_upload = database.record_raw_upload;
pub const record_video_probe = database.record_video_probe;
pub const record_encoding_plan = database.record_encoding_plan;
pub const queue_encoding_job = database.queue_encoding_job;
pub const mark_video_ready = database.mark_video_ready;

pub const plan_local_video = ingest.plan_local_video;
pub const transcode_local_video = ingest.transcode_local_video;
pub const upload_raw_source = ingest.upload_raw_source;
pub const upload_transcoded_video = ingest.upload_transcoded_video;
pub const ingest_local_video = ingest.ingest_local_video;
pub const output_dir_for_video = ingest.output_dir_for_video;
pub const rendition_prefix = ingest.rendition_prefix;

pub fn greet() []const u8 {
    return "hello from core";
}
