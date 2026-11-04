const std = @import("std");
const vaxis = @import("vaxis");

const Event = union(enum) {
    key_press: vaxis.Key,
};

pub fn main(init: std.process.Init) !void {
    var buffer: [1024]u8 = undefined;

    var tty = try vaxis.Tty.init(init.io, &buffer);
    defer tty.deinit();

    const alloc = init.gpa;

    var vx = try vaxis.init(init.io, alloc, init.environ_map, .{});
    defer vx.deinit(alloc, tty.writer());

    try vx.enterAltScreen(tty.writer());

    const size = try tty.getWinsize();

    try vx.resize(alloc, tty.writer(), size);

    const win = vx.window();
    win.clear();

    const fruits = [_][]const u8{
        "りんごりんごりんごりんごりんごりんごりんごりんご",
        "みかんオレンジ",
        "ぶどう",
        "機能面で大きな修正はありません。直しておくなら、次の2点です。",
    };

    for (fruits, 1..) |fruit, index| {
        const row: u16 = @intCast(index);
        _ = win.printSegment(
            .{ .text = fruit },
            .{ .row_offset = row, .col_offset = 2, .wrap = .none },
        );
    }
    try vx.render(tty.writer());

    var loop: vaxis.Loop(Event) = .init(init.io, &tty, &vx);
    try loop.start();
    defer loop.stop();

    while (true) {
        const event = try loop.nextEvent();

        switch (event) {
            .key_press => |key| {
                if (key.matches('q', .{})) break;
            },
        }
    }
}
