const std = @import("std");
const config = @import("config");
const clap = @import("clap");

const print = std.debug.print;
const exit = std.process.exit;

pub const ArgValues = struct {
    from: isize,
    to: isize,
    time: usize = 1000,
};

const flags = 
    \\  -f, --from    <isize> from.
    \\  -t, --to      <isize> to.
    \\  -i, --time    <usize> time offset.
    \\  
    \\  -h, --help            Display this help and exit.
    \\  -v, --version         Display the app version.
    ;

pub fn parse(init: std.process.Init, allocator: std.mem.Allocator) !ArgValues {
    const params = comptime clap.parseParamsComptime(flags);

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, init.minimal.args, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();
    errdefer res.deinit();

    if (res.args.version != 0) {
        print("electro_sos v{s}\n", .{config.version});
        res.deinit();
        exit(0);
    }
    if (res.args.help != 0){
        const help_msg = try std.fmt.allocPrint(allocator, 
            \\electro_sos v{s}
            \\
            \\Description:
            \\  System that worn the user if they have high 
            \\  `static electricity` in their body throw sensor,
            \\  but with i do not have sensor, so i just guess 
            \\  the number or read it from `stdin`. :)
            \\
            \\Uasge:
            \\{s}
        , .{config.version, flags});

        print("{s}\n", .{help_msg});

        res.deinit();
        exit(0);
    }

    const range_from: isize = res.args.from orelse 10;
    const range_to:   isize = res.args.to orelse 
        if (range_from < 0) 
            @intCast(@abs(range_from))
        else 
            range_from + 5;

    if (range_from > range_to) {
        print(
            \\the start point of the range is bigger than the end point.
            \\  from = {d}
            \\  to   = {d}
            \\
            \\you can do `{s} -h` to get some help.
            \\
            , .{range_from, range_to, config.bin_name});
        return error.StupidRange;
    }

    var args: ArgValues = .{ 
        .from = range_from, 
        .to = range_to,
    };

    if (res.args.time) |t| {
        args.time = t;
    }

    return args;
}
