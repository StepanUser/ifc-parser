const std = @import("std");
const lexer_module = @import("./../src/lexer.zig");
const token_module = @import("./../src/token.zig");

const Lexer = lexer_module.Lexer;
const LexerError = lexer_module.LexerError;
const Token = token_module.Token;
const testing = std.testing;

test "Lexer parses numbers" {
    var lexer = Lexer.init("123 -456 78.9 1e-10");
    try testing.expectEqual(Token{ .IntegerLiteral = 123 }, try lexer.nextToken());
    try testing.expectEqual(Token{ .IntegerLiteral = -456 }, try lexer.nextToken());
    try testing.expectEqual(Token{ .FloatLiteral = 78.9 }, try lexer.nextToken());
    try testing.expectEqual(Token{ .FloatLiteral = 1e-10 }, try lexer.nextToken());
}

test "Lexer handles invalid numbers" {
    var lexer = Lexer.init("123.456.78");
    try testing.expectError(LexerError.InvalidNumber, try lexer.nextToken());
}
