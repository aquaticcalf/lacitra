const sqlite = @import("sqlite");

pub fn initDbConnection(path: [:0]const u8) !sqlite.Db {
    return try sqlite.Db.init(.{
        .mode = .{ .File = path },
        .open_flags = .{
            .write = true,
            .create = true,
        },
    });
}

pub fn deinitDbConnection(db: *sqlite.Db) void {
    db.deinit();
}
