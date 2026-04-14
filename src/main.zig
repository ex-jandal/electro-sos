const std = @import("std");
const args_parser = @import("args_parser.zig");

//                            .ssSSSSss.
//                          .ER'      `AM.
//                        .ST'          `CS.
//                       .E'  .S.    .S.  `S.
//                      .L'   SSS    SSS   `S.
//                      S'    `S'    `S'    `S
//                      S                    S
//                      S                    S
//                      S.  s.          .s   S
//                      `S. `"s.      .s"'  S'
//                       `S.  `"ss..ss"'  .S'
//                        `SS.    ~~    .SS'
//                          `SS.      .SS'
//                            `SSssssSS'
//
//  .     .   .      o       .          .       *  . .     .  .    *
//   .  *  |     .    .            .   .     .   .     * .    . .  
//       --o--   This project is just advanced stupidity!  *   |     
//    *    |     .   *  .   .      .    . *     .   .   .    --*--  .
//   .    .    *    .     .    .       . . .      .        .   |   . 

const print = std.debug.print;
const exit = std.process.exit;

const RANGE_OFFSET = 20;
var TIME_OFFSET: i64 = undefined;

const WarningLevel = enum {
    Danger,
    Normal,
    UnderTheRate,
};
const CurrentMeasurement = struct {
    value: isize,
    Level: WarningLevel,
    mutex: std.Io.Mutex,

    fn init() CurrentMeasurement {
        return .{
            .value = 0,
            .Level = .Normal,
            .mutex = .init
        };
    }
};

fn enable_raw_mode(stdin: std.Io.File) !void {
    var tcgetattr = try std.posix.tcgetattr(stdin.handle);
    tcgetattr.lflag.ECHO = false;
    tcgetattr.lflag.ICANON = false;

    try std.posix.tcsetattr(
        stdin.handle, 
        .DRAIN, 
        tcgetattr
    );
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.arena.allocator();

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        // // Old Zig (0.15.x)
        // try std.posix.getrandom(std.mem.asBytes(&seed));
        io.random(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    const args = args_parser.parse(init, allocator) catch exit(1);

    TIME_OFFSET = @intCast(args.time);

    print("\x1B[2J\x1B[H", .{});
    print(
        \\Range: {{ 
        \\  from: {d},
        \\  to:   {d}, 
        \\  time: {d},
        \\}}
        \\
        , .{args.from, args.to, args.time}
    );

    poll: {
        var current_measurement: CurrentMeasurement = .init();

        var store = io.@"async"(
                store_income, 
                .{io, args, rand, &current_measurement}
            );
        var radar_async = io.@"async"(
            radar,
            .{io, &current_measurement}
        );

        var buffer: [1024]u8 = undefined;
        var stdin = std.Io.File.stdin();

        try enable_raw_mode(stdin);
        var reader = stdin.reader(io, &buffer);
        const reader_interface = &reader.interface;

        while (true) {
            const letter = try reader_interface.takeByte();
            // 27 is Esc
            if (letter == 'q' or letter == 27) {
                // try store.@"await"(io);
                store.cancel(io) catch undefined;
                radar_async.cancel(io) catch undefined;
                break :poll;
            }
        }
    }

    print("Quit...\n", .{});
}

fn lableize_electro(
    range: args_parser.ArgValues, 
    current: *CurrentMeasurement
) void {
    if (current.*.value > range.to) {
        current.*.Level = .Danger;
    } else if (current.*.value < range.from) {
        current.*.Level = .UnderTheRate;
    } else {
        current.*.Level = .Normal;
    }
}

fn store_income(
    io: std.Io, 
    range: args_parser.ArgValues, 
    rand: std.Random, 
    current: *CurrentMeasurement
) !void {
    while (true) {
        const random_number = rand.intRangeAtMost(isize, range.from - RANGE_OFFSET, range.to + RANGE_OFFSET);

        {
            try current.*.mutex.lock(io);
            defer current.*.mutex.unlock(io);

            current.*.value = random_number;
            lableize_electro(range, current);
        }

        // print("\x1B[2J\x1B[H", .{});
        print("\x1b[7;H\x1b[J", .{});
        print("income_stream: {d}\n", .{random_number});
        try io.sleep(.fromMilliseconds(TIME_OFFSET), .awake);
    }
}

fn radar(io: std.Io, current: *CurrentMeasurement) !void {
    while (true) {
        var current_val: isize = undefined;
        var current_lvl: WarningLevel = undefined;
        
        {
            try current.*.mutex.lock(io);
            defer current.*.mutex.unlock(io);
            
            current_val = current.*.value;
            current_lvl = current.*.Level;
        }


        print(
            \\Measurement {{ 
            \\  value: {d},
            \\  Level: {s}, 
            \\}} 
            \\
            , .{ current_val, @tagName(current_lvl) });

        switch (current_lvl) {
            .Danger => print("Fahhhhh\n", .{}),
            .UnderTheRate => print("WoooooooW\n", .{}),
            .Normal => print("67\n", .{}),
        }
        print("\n", .{});

        try io.sleep(.fromMilliseconds(TIME_OFFSET), .awake);
    }
}
