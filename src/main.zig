const std = @import("std");
const vaxis = @import("vaxis");

pub fn main(init: std.process.Init) !void {
    var buffer: [1024]u8 = undefined;

    var tty = try vaxis.Tty.init(init.io, &buffer);
    defer tty.deinit();

    try tty.writer().writeAll("TTY initialized\r\n");
    try tty.writer().flush();
}
