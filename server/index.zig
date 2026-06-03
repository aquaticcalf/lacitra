const std = @import("std");
const zap = @import("zap");

const index = @import("routes/index.zig");
const not_found = @import("routes/404.zig");
const html_route = @import("routes/html.zig");

fn onRequest(r: zap.Request) !void {
    const path = r.path orelse return;

    if (std.mem.eql(u8, path, "/")) {
        try index.handle(r);
        return;
    }

    if (std.mem.eql(u8, path, "/html/")) {
        try html_route.handle(r);
        return;
    }

    try not_found.handle(r);
}

pub fn start() !void {
    var listener = zap.HttpListener.init(.{
        .port = 8000,
        .on_request = onRequest,
        .log = true,
    });

    try listener.listen();

    std.debug.print("listening on http://localhost:8000\n", .{});
    zap.start(.{ .threads = 2, .workers = 1 });
}
