const std = @import("std");
const Token = @import("token.zig").Token;

pub const Program = struct {
    statements: []Statement,

    pub fn tokenLiteral(self: @This()) []const u8 {
        return if (self.statements.len > 0)
            self.statements[0].tokenLiteral()
        else
            "";
    }
};

pub const NodeTag = enum {
    program,
    statement,
    expression,
};

pub const Node = union(NodeTag) {
    program: Program,
    statement: Statement,
    expression: Expression,

    pub fn tokenLiteral(self: @This()) []const u8 {
        return switch (self) {
            .program => |val| val.tokenLiteral(),
            .statement => |statement| statement.tokenLiteral(),
            .expression => "",
        };
    }
};

pub const StatementTag = enum {
    let,
    identifier,
};

pub const Statement = union(StatementTag) {
    const Self = @This();

    let: LetStatement,
    identifier: Identifier,

    pub fn tokenLiteral(self: Self) []const u8 {
        return switch (self) {
            .let => |val| val.token.literal,
            .identifier => |val| val.token.literal,
        };
    }
};

// Statements
pub const LetStatement = struct {
    token: Token,
    name: *Identifier,
    value: Expression,
};

pub const Identifier = struct {
    token: Token,
    value: []const u8,
};

pub const ExpressionTag = enum {};
pub const Expression = union(ExpressionTag) {};
