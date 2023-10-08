const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;

const prompt = ">> ";

pub fn start() !void {
    var stdin = std.io.getStdIn().reader();
    while (true) {
        std.debug.print(prompt, .{});

        var buffer: [1024]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buffer);

        try stdin.streamUntilDelimiter(fbs.writer(), '\n', 1024);
        var lexer = Lexer.init(fbs.getWritten());

        var tok = lexer.nextToken();
        while (tok.type_ != .eof) : (tok = lexer.nextToken()) {
            std.debug.print(
                "Token{{ .type_ = {any}, .literal = \"{s}\" }}\n",
                .{ tok.type_, tok.literal },
            );
        }
    }
}

pub fn main() !void {
    std.debug.print("Welcome to the Monkey Programming Language!\n", .{});

    try start();
}
