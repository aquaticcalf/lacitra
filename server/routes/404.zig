const zap = @import("zap");

pub fn handle(r: zap.Request) !void {
    r.setStatusNumeric(404);
    r.setContentType(.JSON) catch return;
    try r.sendBody("{\"message\": \"not found\", \"status\": 404}");
}
