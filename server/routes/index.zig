const zap = @import("zap");

pub fn handle(r: zap.Request) !void {
    r.setContentType(.JSON) catch return;
    try r.sendBody("{\"message\": \"hello\", \"status\": \"ok\"}");
}
