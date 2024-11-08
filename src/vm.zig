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
                .Return => return InterpretResult.Ok,
                else => return InterpretResult.RuntimeError,
            }
        }
    }

    fn readByte() u8 {
        const byte = vm.ip[0];
        vm.ip = vm.ip + 1;
        return byte;
    }
};

const InterpretResult = enum {
    Ok,
    CompileError,
    RuntimeError,
};
