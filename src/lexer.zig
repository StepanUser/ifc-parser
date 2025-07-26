const std = @import("std");
const token_module = @import("token.zig");
const Token = token_module.Token;

pub const Lexer = struct {
    buffer: []const u8,
    position: usize,

    pub fn init(buffer: []const u8) Lexer {
        return .{ .buffer = buffer, .position = 0 };
    }
    pub fn nextToken(self: *Lexer) !Token {
        while (self.position < self.buffer.len and std.ascii.isWhitespace(self.buffer[self.position])) {
            self.position += 1;
        }

        if (self.position >= self.buffer.len) {
            return Token{ .EndOfFile = {} };
        }

        const char = self.buffer[self.position];
        if (tokenMap.get(&[_]u8{char})) |token| {
            self.position += 1;
            return token;
        }

        return switch (char) {
            '#' => self.parseId(),
            'A'...'Z' => self.parseTypeName(),
            '0'...'9', '-', '+' => {
                const next_position = self.position + 1;
                if (char == '-' and (next_position >= self.buffer.len or !std.ascii.isDigit(self.buffer[next_position]))) {
                    self.position += 1;
                    return Token{ .Dash = {} };
                }

                return self.parseNumber();
            },
            '\'' => self.parseString(),
            else => {
                std.log.err("Unknown character: '{c}'", .{char});
                return LexerError.UnknownCharacter;
            },
        };
    }

    const tokenMap = std.StaticStringMap(Token).initComptime(.{
        .{ ".", Token{ .Dot = {} } },
        .{ "*", Token{ .Asterisk = {} } },
        .{ ",", Token{ .Comma = {} } },
        .{ "=", Token{ .Equals = {} } },
        .{ "$", Token{ .Dollar = {} } },
        .{ ";", Token{ .Semicolon = {} } },
        .{ ")", Token{ .RParen = {} } },
        .{ "(", Token{ .LParen = {} } },
    });

    fn parseNumber(self: *Lexer) !Token {
        const start = self.position;
        if (self.buffer[self.position] == '-' or self.buffer[self.position] == '+') {
            self.position += 1;
        }

        if (self.position >= self.buffer.len) {
            return LexerError.InvalidNumber;
        }

        while (std.ascii.isDigit(self.buffer[self.position])) {
            self.position += 1;
            if (self.position >= self.buffer.len) break;
        }

        var is_float = false;

        if (self.position < self.buffer.len and self.buffer[self.position] == '.') {
            is_float = true;
            self.position += 1;
            if (self.position >= self.buffer.len) return LexerError.InvalidNumber;
            while (std.ascii.isDigit(self.buffer[self.position])) {
                self.position += 1;
                if (self.position >= self.buffer.len) break;
            }
        }

        if (self.position < self.buffer.len and (self.buffer[self.position] == 'e' or self.buffer[self.position] == 'E')) {
            is_float = true;
            self.position += 1;

            if (self.position < self.buffer.len and (self.buffer[self.position] == '+' or self.buffer[self.position] == '-')) {
                self.position += 1;
            }

            if (self.position >= self.buffer.len or !std.ascii.isDigit(self.buffer[self.position])) {
                return LexerError.InvalidNumber;
            }

            while (self.position < self.buffer.len and std.ascii.isDigit(self.buffer[self.position])) {
                self.position += 1;
            }
        }

        const number_text = self.buffer[start..self.position];

        if (number_text.len == 0 or (number_text.len == 1 and (number_text[0] == '-' or number_text[0] == '+'))) {
            return LexerError.InvalidNumber;
        }

        if (is_float) {
            return Token{ .FloatLiteral = try std.fmt.parseFloat(f64, number_text) };
        } else {
            return Token{ .IntegerLiteral = try std.fmt.parseInt(i64, number_text, 10) };
        }
    }

    fn parseString(self: *Lexer) !Token {
        self.position += 1;
        const start = self.position;

        while (self.position < self.buffer.len and self.buffer[self.position] != '\'') {
            self.position += 1;
        }
        if (self.position > self.buffer.len) {
            return LexerError.UnterminatedString;
        }
        const text = self.buffer[start..self.position];
        self.position += 1;
        return Token{ .StringLiteral = text };
    }

    fn parseId(self: *Lexer) !Token {
        self.position += 1;
        const start = self.position;

        while (self.position < self.buffer.len and std.ascii.isDigit(self.buffer[self.position])) {
            self.position += 1;
        }
        const id_value = try std.fmt.parseInt(u32, self.buffer[start..self.position], 10);

        return Token{ .Id = id_value };
    }

    fn parseTypeName(self: *Lexer) !Token {
        const start = self.position;
        while (self.position < self.buffer.len) {
            const char = self.buffer[self.position];
            if (!std.ascii.isAlphanumeric(char) and char != '_') break;
            self.position += 1;
        }

        return Token{ .TypeName = self.buffer[start..self.position] };
    }
};

pub const LexerError = error{
    UnterminatedString,
    InvalidNumber,
    UnknownCharacter,
};
