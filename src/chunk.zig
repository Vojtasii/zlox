const std = @import("std");

pub const Chunk = struct {
    code: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) Chunk {
        return Chunk{
            .code = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: Chunk) void {
        self.code.deinit();
    }

    pub fn addReturn(self: *Chunk) !void {
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
                std.debug.print("Return\n", .{});
                return offset + 1;
            },
        };
    }
};

pub const OpCode = enum(u8) {
    Return,
};

test "init chunk" {
    var chunk = Chunk.init(std.testing.allocator);
    defer chunk.deinit();
    try chunk.addReturn();
    try std.testing.expectEqual(chunk.code.items[0], @intFromEnum(OpCode.Return));
}
