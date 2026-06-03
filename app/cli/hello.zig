const std = @import("std");
const zli = @import("zli");
const core = @import("core");

pub fn register(init_options: zli.InitOptions) !*zli.Command {
    return try zli.Command.init(init_options, .{
        .name = "hello",
        .description = "greet from core",
    }, run);
}

fn run(ctx: zli.CommandContext) !void {
    try ctx.writer.print("{s}\n", .{core.greet()});
}
