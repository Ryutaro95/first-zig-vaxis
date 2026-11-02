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

    // # Vaxisの画面上に文字を配置して、その内容をターミナルへ描画したい

    // ターミナルの大きさを取得する
    //
    // 現在の端末が何行・何列あるかなどを取得している
    const size = try tty.getWinsize();

    // その大きさの画面情報を用意する
    //
    // Vaxisが、各位置に表示する文字や色を保存できるように
    // 画面サイズに応じたメモリを確保する
    //
    // この処理では、端末側の表示領域のクリアなども行われる
    try vx.resize(alloc, tty.writer(), size);

    // 画面に文字を配置する
    //
    // `win` は画面全体を対象に文字などを配置するための描画領域
    // OSのウィンドウを新しく作る処理ではない
    //
    // `win.clear()` は、Vaxisがメモリ上で管理している画面を空にする
    const win = vx.window();
    win.clear();

    // `printSegment()` で指定した位置へ文字を配置する
    _ = win.printSegment(
        .{ .text = "Press q to exit" },

        // 0から数えるので、上から2行目、左から3列目へ配置する
        .{ .row_offset = 1, .col_offset = 2 },
    );

    // 配置した内容をターミナルへ反映する
    //
    // Vaxisはメモリ上の画面情報を前回の描画結果として比較し、必要な文字や制御命令をWriterへ書き込み、出力のための`flush()`も内部で実施する
    try vx.render(tty.writer());

    // 今回、重要なのは printSegment()はメモリ上の画面を書き換えて、 render()がその内容をターミナルへ反映するという役割の分担を理解すること

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
