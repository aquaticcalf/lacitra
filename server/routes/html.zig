const std = @import("std");
const zap = @import("zap");

const pages = @import("../html/pages.zig");

pub fn handle(r: zap.Request) !void {
    var buf: [16384]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);

    try pages.Home.render(.{}, &w);

    r.setContentType(.HTML) catch return;
    try r.sendBody(buf[0..w.end]);
}
