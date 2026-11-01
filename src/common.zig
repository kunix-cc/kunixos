pub extern fn putchar(ch: u8) void;

pub export fn strcmp(s1: [*:0]const u8, s2: [*:0]const u8) c_int {
    var i: usize = 0;
    while (s1[i] != 0 and s2[i] != 0) : (i += 1) {
        if (s1[i] != s2[i]) {
            break;
        }
    }
    return @as(c_int, s1[i]) - @as(c_int, s2[i]);
}

pub export fn strcpy(dst: [*]u8, src: [*:0]const u8) [*:0]u8 {
    var i: usize = 0;
    while (src[i] != 0) : (i += 1) {
        dst[i] = src[i];
    }
    dst[i] = 0;
    return dst[0..i :0].ptr;
}

pub export fn memset(buf: *anyopaque, c: u8, n: usize) *anyopaque {
    var p: [*]u8 = @ptrCast(buf);

    for (0..n) |i| {
        p[i] = c;
    }
    return buf;
}

pub export fn memcpy(dst: *anyopaque, src: *const anyopaque, n: usize) *anyopaque {
    var d: [*]u8 = @ptrCast(dst);
    const s: [*]const u8 = @ptrCast(src);

    for (0..n) |i| {
        d[i] = s[i];
    }
    return dst;
}

pub export fn printf(fmt: [*]const u8, ...) void {
    var args = @cVaStart();
    defer @cVaEnd(&args);

    var i: usize = 0;
    while (fmt[i] != 0) : (i += 1) {
        if (fmt[i] == '%') {
            i += 1;
            switch (fmt[i]) {
                0 => {
                    putchar('%');
                    return;
                },
                '%' => putchar('%'),
                's' => {
                    const s: [*]u8 = @cVaArg(&args, [*]u8);
                    var j: usize = 0;
                    while (s[j] != 0) : (j += 1) {
                        putchar(s[j]);
                    }
                },
                'd' => {
                    const value: isize = @cVaArg(&args, isize);
                    var magnitude: usize = @abs(value);
                    if (value < 0) {
                        putchar('-');
                        magnitude -= magnitude;
                    }

                    var divisor: usize = 1;
                    while (magnitude / divisor > 9) {
                        divisor *= 10;
                    }

                    while (divisor > 0) {
                        const c: usize = '0' + magnitude / divisor;
                        putchar(@truncate(c));
                        magnitude %= divisor;
                        divisor /= 10;
                    }
                },
                else => unreachable,
            }
        } else {
            putchar(fmt[i]);
        }
    }
}
