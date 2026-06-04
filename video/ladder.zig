const std = @import("std");
const assert = std.debug.assert;
const types = @import("types.zig");

pub const Probe = types.Probe;
pub const Ladder = types.Ladder;
pub const Rendition = types.Rendition;
pub const base_renditions = types.base_renditions;

pub fn plan_ladder(allocator: std.mem.Allocator, probe: Probe) !Ladder {
    assert(probe.width > 0);
    assert(probe.height > 0);

    var list = std.ArrayList(Rendition).empty;
    errdefer list.deinit(allocator);

    const source_bitrate = if (probe.video_bitrate_bps > 0) probe.video_bitrate_bps else probe.format_bitrate_bps;

    for (base_renditions) |base| {
        if (base.height > probe.height) continue;

        var rendition = base;
        if (source_bitrate > 0) {
            const capped = @min(@as(u64, rendition.target_bitrate_bps), @max(@as(u64, 250_000), source_bitrate * 85 / 100));
            rendition.target_bitrate_bps = @intCast(capped);
            rendition.max_bitrate_bps = @intCast(capped * 120 / 100);
            rendition.buffer_size_bps = @intCast(capped * 2);
        }
        try list.append(allocator, rendition);
    }

    if (list.items.len == 0) {
        try list.append(allocator, base_renditions[0]);
    }

    return .{ .renditions = try list.toOwnedSlice(allocator) };
}

test "plan ladder caps variants to source height and bitrate" {
    const allocator = std.testing.allocator;
    const ladder = try plan_ladder(allocator, .{
        .width = 1280,
        .height = 720,
        .duration_ms = 60_000,
        .video_bitrate_bps = 1_500_000,
        .format_bitrate_bps = 1_800_000,
    });
    defer ladder.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 4), ladder.renditions.len);
    try std.testing.expectEqual(@as(u16, 720), ladder.renditions[3].height);
    try std.testing.expect(ladder.renditions[3].target_bitrate_bps <= 1_275_000);
}
