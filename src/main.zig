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
const Mutex = std.Io.Mutex;

const CurrentMeasurement = struct {
    value: isize,
    Level: enum {
        Danger,
        Normal,
        UnderTheRate,
    },
    mutex: Mutex,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.arena.allocator();

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        // try std.posix.getrandom(std.mem.asBytes(&seed));
        io.random(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    const range = args_parser.parse(init, allocator) catch exit(1);

    print("from = {d}\n", .{range.from});
    print("to   = {d}\n", .{range.to});

    poll: {
        var current_measurement = CurrentMeasurement{
            .value = 0, 
            .Level = .Normal,
            .mutex = .init,
        };

        const income = try 
            std.Thread.spawn(
                .{}, 
                income_stream, 
                .{io, rand, range, &current_measurement}
            );
        defer income.join();

        const check = try 
            std.Thread.spawn(
                .{}, 
                electro_checker, 
                .{io, range, &current_measurement}
            );
        defer check.join();

        if (false) {
            break :poll;
        }
    }

    print("Quit...\n", .{});
}

/// Here is where the data come from.
fn income_stream(io: std.Io, rand: std.Random, range: args_parser.ArgsRange, current: *CurrentMeasurement) !void {
    while (true) {
        try current.*.mutex.lock(io);
        defer {
            current.*.mutex.unlock(io);
            io.sleep(.fromMilliseconds(650), .awake) catch undefined;
        }

        const random_number = rand.intRangeAtMost(isize, range.from - 10, range.to + 10);
        current.*.value = random_number;
        print("income_stream:   {any}\n", .{random_number});
    }
}

fn electro_checker(io: std.Io, range: args_parser.ArgsRange, current: *CurrentMeasurement) !void {
    while (true) {
        try current.*.mutex.lock(io);
        defer {
            current.*.mutex.unlock(io);
            io.sleep(.fromMilliseconds(650), .awake) catch undefined;
        }

        if (current.*.value > range.to) {
            current.*.Level = .Danger;
        } else if (current.*.value < range.from) {
            current.*.Level = .UnderTheRate;
        } else {
            current.*.Level = .Normal;
        }

        print("electro_checker: {any}\n", .{current.Level});
    }
}
