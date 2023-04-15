const std = @import("std");
const expect = @import("std").testing.expect;

pub fn forLoop() void {
    const string = [_]u8{ 'H', 'e', 'l', 'l', 'o' };
    for (string, 0..) |char, i| {
        _ = i;
        std.debug.print("{c}", .{char});
    }
}
pub fn main() void {
    // const pi: f32 = 3.14;
    // var degrees: u32 = 12;
    // const inferred_pi = @as(f32, 3.14);
    // const inferred_degrees = @as(u32, 12);
    // const string = "Hello";

    const eggs = [_]u8{ 'c', 'h', 'i', 'c', 'k', 'e', 'n' };
    const stricter_eggs = [7]u8{ 'c', 'h', 'i', 'c', 'k', 'e', 'n' };
    std.debug.print("{s}", .{eggs});
    std.debug.print("{s}", .{stricter_eggs});
    std.debug.print("Hello, {s}!\n", .{"World"});
    forLoop();
}

test "if statement" {
    const a = true;
    var x: u16 = 0;
    // if (a) {
    //     x += 1;
    // } else {
    //     x += 2;
    // }
    x += if (a) 1 else 2;
    try expect(x == 1);
}

test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    try expect(i == 128);
}

test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    try expect(sum == 55);
}

test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    try expect(sum == 4);
}

test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }
    try expect(sum == 1);
}

//recursion is allowed
fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "function recursion" {
    const x = fibonacci(10);
    try expect(x == 55);
}

//execute statement when exiting current block
test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}

//reverse order whaaaaaaat???
test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2;
        defer x /= 2;
    }
    try expect(x == 4.5);
}

//errors are values and error set is like an enum
const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};
const AllocationError = error{OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}

test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}

fn failingFunction() error{Oops}!void {
    return error.Oops;
}

test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}

fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12); // is never reached
}

var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}

fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    //type coercion successfully takes place
    const x: error{AccessDenied}!void = createFile();

    //Zig does not let us ignore error unions via _ = x;
    //we must unwrap it with "try", "catch", or "if" by any means
    _ = x catch {};
}

//Switch
test "switch expression" {
    var x: i8 = 20;
    x = switch (x) {
        -1...1 => -x,
        //special considerations must be made
        //when dividing signed integers
        10...100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 2);
}

//SAFEEEEETY

// test "out of bounds" {
//     const a = [3]u8{ 1, 2, 3 };
//     var index: u8 = 5;
//     const b = a[index];
//     _ = b;
// }

test "out of bounds, no safety" {
    @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}

//unreachable as a value(ish? type - noreturn so it can coerce to any type)
test "unreachable" {
    // const x: i32 = 1; OG
    const x: i32 = 2;
    const y: u32 = if (x == 2) 5 else unreachable;
    _ = y;
}

fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        //it subtracts 32 - the difference of ascii values between upper and lower case
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable switch" {
    try expect(asciiToUpper('z') == 'Z');
    try expect(asciiToUpper('A') == 'A');
}
