const std = @import("std");
const debug = @import("builtin").mode == .Debug;

const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;

pub const VM = struct {
    chunk: *const Chunk,
    ip: [*]const u8,

    var vm = VM{ .chunk = undefined, .ip = undefined };

    pub fn init(_: std.mem.Allocator) void {}

    pub fn deinit() void {}

    pub fn interpret(chunk: *const Chunk) InterpretResult {
        vm.chunk = chunk;
        vm.ip = @ptrCast(chunk.code.items);
        return run();
    }

    fn run() InterpretResult {
        while (true) {
            if (debug) {
                const initial: [*]const u8 = @ptrCast(vm.chunk.code.items);
                const start: usize = @intFromPtr(initial);
                const offset: usize = @intFromPtr(vm.ip - start);
                _ = vm.chunk.dissasembleInstruction(offset);
            }

            const instruction: OpCode = @enumFromInt(readByte());
            switch (instruction) {
                .Constant => {
                    const constant: u8 = readByte();
                    const value: Value = vm.chunk.constants.items[constant];
                    std.debug.print("{d}\n", .{value});
                },
                .ConstantLong => {
                    const bytes = readBytes(3);
                    const constant: u24 =
                        @as(u24, bytes[0]) << 16 |
                        @as(u24, bytes[1]) << 8 |
                        @as(u24, bytes[2]);
                    const value: Value = vm.chunk.constants.items[constant];
                    std.debug.print("{d}\n", .{value});
                },
                .Return => return InterpretResult.Ok,
            }
        }
    }

    fn readByte() u8 {
        const byte = vm.ip[0];
        vm.ip += 1;
        return byte;
    }

    fn readBytes(n: comptime_int) [n]u8 {
        const bytes = vm.ip[0..n].*;
        vm.ip += n;
        return bytes;
    }
};

const InterpretResult = enum {
    Ok,
    CompileError,
    RuntimeError,
};

test "run ConstantLong" {
    var chunk = Chunk.init(std.testing.allocator);
    defer chunk.deinit();

    var constant_long: u24 = 0;
    while (constant_long < 256) {
        constant_long = try chunk.addConstant(@floatFromInt(constant_long));
    }
    try chunk.writeConstant(constant_long, .{ .line = constant_long, .column = 1 });

    try chunk.writeReturn(.{});

    try std.testing.expectEqual(InterpretResult.Ok, VM.interpret(&chunk));
}
