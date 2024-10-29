const std = @import("std");

const Value = @import("value.zig").Value;
const ValueArray = @import("value.zig").ValueArray;

pub const Chunk = struct {
    code: std.ArrayList(u8),
    constants: ValueArray,

    pub fn init(allocator: std.mem.Allocator) Chunk {
        return Chunk{
            .code = std.ArrayList(u8).init(allocator),
            .constants = ValueArray.init(allocator),
        };
    }

    pub fn deinit(self: Chunk) void {
        self.code.deinit();
        self.constants.deinit();
    }

    pub fn addConstant(self: *Chunk, value: Value) !u8 {
        try self.constants.append(value);
        return @intCast(self.constants.items.len - 1);
    }

    pub fn writeConstant(self: *Chunk, constant: u8) !void {
        const slice = [_]u8{ @intFromEnum(OpCode.Constant), constant };
        try self.code.appendSlice(&slice);
    }

    pub fn writeReturn(self: *Chunk) !void {
        try self.code.append(@intFromEnum(OpCode.Return));
    }

    pub fn disassemble(chunk: *const Chunk, name: []const u8) void {
        std.debug.print("== {s} ==\n", .{name});
        var offset: usize = 0;
        while (offset < chunk.code.items.len) {
            offset = chunk.dissasembleInstruction(offset);
        }
    }

    fn dissasembleInstruction(chunk: *const Chunk, offset: usize) usize {
        std.debug.print("{d:0>4} ", .{offset});
        const opcode: OpCode = @enumFromInt(chunk.code.items[offset]);
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

test "init chunk" {
    var chunk = Chunk.init(std.testing.allocator);
    defer chunk.deinit();
    try chunk.writeReturn();
    try std.testing.expectEqual(chunk.code.items[0], @intFromEnum(OpCode.Return));
}

test "add constant" {
    var chunk = Chunk.init(std.testing.allocator);
    defer chunk.deinit();
    const value: Value = 1.2;
    const index: u8 = try chunk.addConstant(value);
    try std.testing.expectEqual(chunk.constants.items[index], value);
}
