const std = @import("std");
const lexer_module = @import("lexer.zig");
const token_module = @import("token.zig");
const ast = @import("ast.zig");

const Lexer = lexer_module.Lexer;
const Token = token_module.Token;
const TokenTag = token_module.TokenTag;
const AllEntities = ast.AllEntities;
const GenericEntity = ast.GenericEntity;
const Value = ast.Value;

pub const Parser = struct {
    lexer: *Lexer,
    allocator: std.mem.Allocator,
    current_token: Token,

    pub fn parse(lexer: *Lexer, allocator: std.mem.Allocator) !AllEntities {
        var self = Parser{
            .lexer = lexer,
            .allocator = allocator,
            .current_token = try lexer.nextToken(),
        };

        var entities = AllEntities.init(allocator);
        errdefer {
            var it = entities.valueIterator();
            while (it.next()) |entity| {
                entity.deinit();
            }
            entities.deinit();
        }

        while (self.current_token.tag() != .EndOfFile) {
            if (self.current_token.tag() == .TypeName and std.mem.eql(u8, self.current_token.TypeName, "DATA")) {
                try self.eat(.TypeName);
                try self.eat(.Semicolon);
                break;
            }

            try self.eat(self.current_token.tag());
        }

        while (self.current_token.tag() != .EndOfFile and self.current_token.tag() != .TypeName) {
            const entity = try self.parseEntity();
            try entities.put(entity.id, entity);
        }

        return entities;
    }

    fn eat(self: *Parser, expected_tag: TokenTag) !void {
        if (self.current_token.tag() == expected_tag) {
            self.current_token = try self.lexer.nextToken();
        } else {
            std.log.err("Parsing Error: Expected token '{any}', but found '{any}'", .{ expected_tag, self.current_token });
            return error.UnexpectedToken;
        }
    }

    fn parseEntity(self: *Parser) !GenericEntity {
        const id = self.current_token.Id;
        try self.eat(.Id);
        try self.eat(.Equals);
        const type_name = self.current_token.TypeName;
        try self.eat(.TypeName);
        try self.eat(.LParen);

        const attributes = try self.parseValueList();
        try self.eat(.RParen);
        try self.eat(.Semicolon);

        return GenericEntity{ .id = id, .type_name = type_name, .attributes = attributes };
    }

    fn parseValueList(self: *Parser) anyerror!std.ArrayList(Value) {
        var list = std.ArrayList(Value).init(self.allocator);
        errdefer list.deinit();

        if (self.current_token.tag() == .RParen) {
            return list;
        }

        try list.append(try self.parseValue());
        while (self.current_token.tag() == .Comma) {
            try self.eat(.Comma);
            try list.append(try self.parseValue());
        }

        return list;
    }

    fn parseValue(self: *Parser) !Value {
        return switch (self.current_token) {
            .Id => |id| {
                try self.eat(.Id);
                return Value{ .Reference = id };
            },
            .StringLiteral => |s| {
                try self.eat(.StringLiteral);
                return Value{ .String = s };
            },
            .IntegerLiteral => |i| {
                try self.eat(.IntegerLiteral);
                return Value{ .Integer = i };
            },
            .FloatLiteral => |f| {
                try self.eat(.FloatLiteral);
                return Value{ .Float = f };
            },
            .Dollar => {
                try self.eat(.Dollar);
                return Value{ .Null = {} };
            },
            .Asterisk => {
                try self.eat(.Asterisk);
                return Value{ .Null = {} };
            },
            .LParen => {
                try self.eat(.LParen);
                const list = try self.parseValueList();
                try self.eat(.RParen);
                return Value{ .List = list };
            },
            .Dot => {
                try self.eat(.Dot);
                const enum_value = self.current_token.TypeName;
                try self.eat(.TypeName);
                try self.eat(.Dot);
                return Value{ .Enum = enum_value };
            },
            .TypeName => |type_name| {
                try self.eat(.TypeName);
                try self.eat(.LParen);

                var value_list = try self.parseValueList();
                errdefer value_list.deinit();
                try value_list.insert(0, Value{ .String = type_name });

                try self.eat(.RParen);
                return Value{ .List = value_list };
            },
            else => {
                std.log.err("Cannot parse value from token {any}", .{self.current_token});
                return error.InvalidValue;
            },
        };
    }
};
