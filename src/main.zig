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
    try chunk.writeConstant(constant, .{ .line = 99, .column = 12 });

    var constant_long: u24 = constant;
    while (constant_long < 256) {
        constant_long = try chunk.addConstant(@floatFromInt(constant_long));
    }
    try chunk.writeConstant(constant_long, .{ .line = constant_long, .column = 1 });

    try chunk.writeReturn(.{});

    chunk.disassemble("test chunk");
}
