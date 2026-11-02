const std = @import("std");
const vaxis = @import("vaxis");

// Eventは、libvaxisから受け取る情報の型を定義している
const Event = union(enum) {
    // key_pressという種類のイベントを受け取り、その中にはvaxis.Key型のキー情報が入ると定義している
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

    try tty.writer().writeAll("Press q to exit\r\n");
    try tty.writer().flush();

    // `vaxis.Loop(Event)` Event型を受け渡すループの型を作る
    // `.init(...)` 使用する I/O・TTY・Vaxisを渡して初期化する
    var loop: vaxis.Loop(Event) = .init(init.io, &tty, &vx);

    // ユーザーからの入力の読み取りと解析をlibvaxisに任せて、解析結果を受け取る
    // 1. ユーザーのキー入力
    // 2. libvaxisがバイト列を読み取る
    // 3. libvaxisが「押されたキー」の情報へ変換する
    // 4. アプリが情報を受け取る
    // 5. アプリが「qなら終了」と判断する

    // loop.start() により入力の読み取りを開始する
    // labvaxisでは、別の入力処理タスクが開始される
    // そのタスクがターミナルからの入力を読み取り
    // 解析したイベントを、順番に受け入れるためにキューへ入れる
    try loop.start();
    defer loop.stop();

    //  libvaxis側                         main側
    //
    // 端末から入力を読む
    //     ↓
    // キー情報へ変換する
    //     ↓
    // キューへ入れる ─────────────→ nextEvent()で取り出す
    //                                   ↓
    //                              qかどうか判断する
    while (true) {
        // `loop.nextEvent()` によってアプリ側でキューから取り出す
        const event = try loop.nextEvent();

        switch (event) {
            .key_press => |key| {
                // qが入力されるとループを抜ける
                if (key.matches('q', .{})) break;
            },
        }
    }
}
