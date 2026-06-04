const std = @import("std");
const assert = std.debug.assert;
const sqlite = @import("sqlite");

pub fn init_db_connection(path: [:0]const u8) !sqlite.Db {
    assert(path.len > 0);

    return try sqlite.Db.init(.{
        .path = path,
        .write = true,
        .create = true,
    });
}

pub fn deinit_db_connection(db: *sqlite.Db) void {
    db.deinit();
}
