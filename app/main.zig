const std = @import("std");
const core = @import("core");

pub fn main() !void {
    std.debug.print("{s}\n", .{core.greet()});
}
