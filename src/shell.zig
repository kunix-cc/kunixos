const user = @import("user.zig");
const common = @import("common.zig");

pub export fn main() void {
    outer: while (true) {
        common.printf("> ");
        var cmdline: [128:0]u8 = undefined;
        for (0..cmdline.len - 1) |i| {
            const ch: u8 = @intCast(user.getchar());
            user.putchar(ch);
            if (i == cmdline.len - 1) {
                common.printf("command line too long\n");
                continue :outer;
            } else if (ch == '\r') {
                common.printf("\n");
                cmdline[i] = 0;
                break;
            } else {
                cmdline[i] = ch;
            }
        }

        if (common.strcmp(&cmdline, "hello") == 0) {
            common.printf("Hello World from shell!\n");
        } else if (common.strcmp(&cmdline, "exit") == 0) {
            user.exit();
        } else {
            common.printf("unknown command: %s\n", &cmdline);
        }
    }
}
