const std = @import("std");
const zli = @import("zli");

const server_cmd = @import("server.zig");
const hello_cmd = @import("hello.zig");

pub fn build(init_options: zli.InitOptions) !*zli.Command {
    const root = try zli.Command.init(init_options, .{
        .name = "lacitra",
        .description = "lacitra cli",
    }, showHelp);

    try root.addCommands(&.{
        try server_cmd.register(init_options),
        try hello_cmd.register(init_options),
    });

    return root;
}

fn showHelp(ctx: zli.CommandContext) !void {
    try ctx.command.printHelp();
}
