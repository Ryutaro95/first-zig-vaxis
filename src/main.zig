const std = @import("std");
const vaxis = @import("vaxis");

pub fn main(_: std.process.Init) !void {
    std.debug.print("List viewer\n", .{});

    _ = vaxis.Key;
}
