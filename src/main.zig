const std = @import("std");
const vaxis = @import("vaxis");

pub fn main(init: std.process.Init) !void {
    var buffer: [1024]u8 = undefined;

    var tty = try vaxis.Tty.init(init.io, &buffer);
    defer tty.deinit();

    const alloc = init.gpa;

    var vx = try vaxis.init(init.io, alloc, init.environ_map, .{});
    defer vx.deinit(alloc, tty.writer());

    // `enterAltScreen()` は画面の切り替えを指示するエスケープシーケンスを端末へ送る
    // それを受け取ったGhosttyなどのターミナルが、表示する画面を切り替える
    try vx.enterAltScreen(tty.writer());

    try tty.writer().writeAll("Alternate screen: press a latter to exit.\r\n");
    try tty.writer().flush();

    var input_buffer: [1]u8 = undefined;
    // `tty.read()` は受け取った入力を input_buffer に書き込み、読み取ったバイト数を返す
    // 今回バイト数は不要なので `- =`で捨てている
    _ = try tty.read(&input_buffer);
}
