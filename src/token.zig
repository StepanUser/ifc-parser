pub const Token = union(TokenTag) {
    Id: u32,
    TypeName: []const u8,
    StringLiteral: []const u8,
    IntegerLiteral: i64,
    FloatLiteral: f64,
    Equals: void,
    LParen: void,
    RParen: void,
    Semicolon: void,
    Comma: void,
    Dash: void,
    Dollar: void,
    Dot: void,
    Asterisk: void,
    EndOfFile: void,
    NotImplemented: void,

    pub fn tag(self: Token) TokenTag {
        return @as(TokenTag, self);
    }
};

pub const TokenTag = enum {
    Id,
    TypeName,
    StringLiteral,
    IntegerLiteral,
    FloatLiteral,
    Equals,
    LParen,
    RParen,
    Semicolon,
    Comma,
    Dash,
    Dollar,
    Dot,
    Asterisk,
    EndOfFile,
    NotImplemented,
};
