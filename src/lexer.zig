const std = @import("std");
const token_module = @import("token.zig");
const Token = token_module.Token;

pub const Lexer = struct {
    buffer: []const u8,
    position: usize,

    fn parseNumber(self: *Lexer) !Token {
        const start = self.position;

        if (self.positionValue() == '-' or self.positionValue() == '+') {
            self.position += 1;
        }

        while (self.position < self.buffer.len and std.ascii.isDigit(self.positionValue())) {
            self.position += 1;
        }

        var is_float = false;

        if (self.position < self.buffer.len and self.positionValue() == '.') {
            is_float = true;
            self.position += 1;
            while (self.position < self.buffer.len and std.ascii.isDigit(self.positionValue())) {
                self.position += 1;
            }
        }

        if (self.position < self.buffer.len and (self.positionValue() == 'e' or self.positionValue() == 'E')) {
            is_float = true;
            self.position += 1;

            if (self.position < self.buffer.len and (self.positionValue() == '+' or self.positionValue() == '-')) {
                self.position += 1;
            }
            while (self.position < self.buffer.len and std.ascii.isDigit(self.positionValue())) {
                self.position += 1;
            }
        }

        const number_text = self.buffer[start..self.position];
        if (is_float) {
            return Token{ .FloatLiteral = try std.fmt.parseFloat(f64, number_text) };
        } else {
            return Token{ .IntegerLiteral = try std.fmt.parseInt(i64, number_text, 10) };
        }
    }

    pub fn nextToken(self: *Lexer) !Token {
        while (self.position < self.buffer.len and std.ascii.isWhitespace(self.positionValue())) {
            self.position += 1;
        }

        if (self.position >= self.buffer.len) {
            return Token{ .EndOfFile = {} };
        }

        const char = self.buffer[self.position];

        return switch (char) {
            '#' => {
                self.position += 1;
                const start = self.position;

                while (self.position < self.buffer.len and std.ascii.isDigit(self.buffer[self.position])) {
                    self.position += 1;
                }
                const number_text = self.buffer[start..self.position];
                const id_value = try std.fmt.parseInt(u32, number_text, 10);
                return Token{ .Id = id_value };
            },
            'A'...'Z' => {
                const start = self.position;

                while (self.position < self.buffer.len and (std.ascii.isAlphanumeric(self.buffer[self.position]) or self.buffer[self.position] == '_')) {
                    self.position += 1;
                }
                const text = self.buffer[start..self.position];
                return Token{ .TypeName = text };
            },
            '0'...'9', '-', '+' => {
                const next_position = self.position + 1;
                if (char == '-' and (next_position >= self.buffer.len or !std.ascii.isDigit(self.buffer[next_position]))) {
                    self.position += 1;
                    return Token{ .Dash = {} };
                }

                return self.parseNumber();
            },
            '.' => {
                self.position += 1;
                return Token{ .Dot = {} };
            },
            '*' => {
                self.position += 1;
                return Token{ .Asterisk = {} };
            },
            '\'' => {
                self.position += 1;
                const start = self.position;

                while (self.position < self.buffer.len and self.positionValue() != '\'') {
                    self.position += 1;
                }
                if (self.position > self.buffer.len) {
                    return error.UnterminatedString;
                }
                const text = self.buffer[start..self.position];
                self.position += 1;
                return Token{ .StringLiteral = text };
            },
            ',' => {
                self.position += 1;
                return Token{ .Comma = {} };
            },
            '=' => {
                self.position += 1;
                return Token{ .Equals = {} };
            },
            '$' => {
                self.position += 1;
                return Token{ .Dollar = {} };
            },
            ';' => {
                self.position += 1;
                return Token{ .Semicolon = {} };
            },
            ')' => {
                self.position += 1;
                return Token{ .RParen = {} };
            },
            '(' => {
                self.position += 1;
                return Token{ .LParen = {} };
            },
            else => {
                std.log.err("Unknown character: '{c}'", .{char});
                return error.UnknownCharacter;
            },
        };
    }

    pub fn positionValue(self: *Lexer) u8 {
        return self.buffer[self.position];
    }
};
