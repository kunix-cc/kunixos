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
