const std = @import("std");
const S3Client = @import("z3").S3Client;

pub fn initS3Connection(allocator: std.mem.Allocator, config: S3Client.Config) !S3Client {
    return try S3Client.init(allocator, config, .{});
}

pub fn deinitS3Connection(client: *S3Client) void {
    client.deinit();
}
