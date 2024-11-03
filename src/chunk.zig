const std = @import("std");

const Value = @import("value.zig").Value;
const ValueArray = @import("value.zig").ValueArray;

pub const Chunk = struct {
    code: std.ArrayList(u8),
    constants: ValueArray,
    positions: std.AutoArrayHashMap(usize, Position),

    pub fn init(allocator: std.mem.Allocator) Chunk {
        return Chunk{
            .code = std.ArrayList(u8).init(allocator),
            .constants = ValueArray.init(allocator),
            .positions = std.AutoArrayHashMap(usize, Position).init(allocator),
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.code.deinit();
        self.constants.deinit();
        self.positions.deinit();
    }

    pub fn addConstant(self: *Chunk, value: Value) !u8 {
        try self.constants.append(value);
        return @intCast(self.constants.items.len - 1);
    }

    pub fn writeConstant(self: *Chunk, constant: u8, pos: Position) !void {
        const offset = self.code.items.len;

        const slice = [_]u8{
            @intFromEnum(OpCode.Constant),
            constant,
        };
        try self.code.appendSlice(&slice);

        try self.positions.put(offset, pos);
    }

    pub fn writeReturn(self: *Chunk, pos: Position) !void {
        const offset = self.code.items.len;

        try self.code.append(
            @intFromEnum(OpCode.Return),
        );

        try self.positions.put(offset, pos);
    }

    pub fn disassemble(chunk: *const Chunk, name: []const u8) void {
        std.debug.print("== {s} ==\n", .{name});
        var offset: usize = 0;
        while (offset < chunk.code.items.len) {
            offset = chunk.dissasembleInstruction(offset);
        }
    }

    fn dissasembleInstruction(chunk: *const Chunk, offset: usize) usize {
        const opcode: OpCode = @enumFromInt(chunk.code.items[offset]);
        const pos = chunk.positions.get(offset) orelse Position{};
        std.debug.print("{d:0>4} {s:>3}", .{ offset, pos });
        return switch (opcode) {
            OpCode.Return => {
                std.debug.print("{s:>16}\n", .{"Return"});
                return offset + 1;
            },
            OpCode.Constant => {
                const constant = chunk.code.items[offset + 1];
                const value: Value = chunk.constants.items[constant];
                std.debug.print("{s:>16} {d:>4} {d:>4}\n", .{ "Constant", constant, value });
                return offset + 2;
            },
        };
    }
};

pub const OpCode = enum(u8) {
    Constant,
    Return,
};

/// Represents a position in the source code.
/// Both line a column start at 1. 0 means unknown.
pub const Position = struct {
    line: u32 = 0,
    column: u32 = 0,

    pub fn format(
        self: Position,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        // _ = options;

        if (self.line == 0) {
            try std.fmt.formatAsciiChar('?', options, writer);
        } else {
            try std.fmt.formatInt(self.line, 10, .lower, options, writer);
        }
        try writer.writeAll(":");
        var options_left = options;
        options_left.alignment = .left;
        if (self.column == 0) {
            try std.fmt.formatAsciiChar('?', options_left, writer);
        } else {
            try std.fmt.formatInt(self.column, 10, .lower, options_left, writer);
        }
    }
};

test "init chunk" {
    var chunk = Chunk.init(std.testing.allocator);
    defer chunk.deinit();
    try chunk.writeReturn(.{});
    try std.testing.expectEqual(chunk.code.items[0], @intFromEnum(OpCode.Return));
}

test "add constant" {
    var chunk = Chunk.init(std.testing.allocator);
    defer chunk.deinit();
    const value: Value = 1.2;
    const index: u8 = try chunk.addConstant(value);
    try std.testing.expectEqual(chunk.constants.items[index], value);
}
