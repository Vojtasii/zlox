const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    // We use a logging allocator to help us debug memory issues.
    var la = std.heap.LoggingAllocator(.debug, .err).init(gpa.allocator());

    const ally = la.allocator();

    var chunk = Chunk.init(ally);
    defer chunk.deinit();

    const constant = try chunk.addConstant(1.2);
    try chunk.writeConstant(constant, .{ .line = 100, .column = 12 });

    try chunk.writeReturn(.{});

    chunk.disassemble("test chunk");
}
