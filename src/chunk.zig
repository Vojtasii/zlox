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

    /// Adds a constant to the chunk and returns its index.
    /// Maximal number of constants is 2^24.
    pub fn addConstant(self: *Chunk, value: Value) !u24 {
        try self.constants.append(value);
        return @intCast(self.constants.items.len - 1);
    }

    pub fn writeConstant(self: *Chunk, constant: u24, pos: Position) !void {
        const offset = self.code.items.len;

        const slice: []const u8 = if (constant < 256) &.{
            @intFromEnum(OpCode.Constant),
            @intCast(constant),
        } else &.{
            @intFromEnum(OpCode.ConstantLong),
            // Split the constant into 3 bytes.
            @truncate(constant >> 16),
            @truncate(constant >> 8),
            @truncate(constant),
        };
        try self.code.appendSlice(slice);

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
            OpCode.ConstantLong => {
                const constant: u24 =
                    @as(u24, chunk.code.items[offset + 1]) << 16 |
                    @as(u24, chunk.code.items[offset + 2]) << 8 |
                    @as(u24, chunk.code.items[offset + 3]);
                const value: Value = chunk.constants.items[constant];
                std.debug.print("{s:>16} {d:>4} {d:>4}\n", .{ "ConstantLong", constant, value });
                return offset + 4;
            },
        };
    }
};

pub const OpCode = enum(u8) {
    Return,
    Constant,
    ConstantLong,
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
    const index: u24 = try chunk.addConstant(value);
    try std.testing.expectEqual(chunk.constants.items[index], value);
}
