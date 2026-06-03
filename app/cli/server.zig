const zli = @import("zli");
const server = @import("server");

pub fn register(init_options: zli.InitOptions) !*zli.Command {
    return try zli.Command.init(init_options, .{
        .name = "server",
        .description = "start the api server",
    }, run);
}

fn run(ctx: zli.CommandContext) !void {
    _ = ctx;
    try server.start();
}
