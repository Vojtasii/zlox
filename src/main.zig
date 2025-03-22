const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const VM = @import("vm.zig").VM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const ally = gpa.allocator();

    VM.init(ally);
    defer VM.deinit();

    var chunk = Chunk.init(ally);
    defer chunk.deinit();

    const constant = try chunk.addConstant(1.2);
    try chunk.writeConstant(constant, .{ .line = 99, .column = 12 });

    try chunk.writeReturn(.{});

    _ = VM.interpret(&chunk);
}
