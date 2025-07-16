// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Zig Shellcode Runner Example
// Copyright (C) 2025 Ivan Stepanov <ivanstepanovftw@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");

// Embed the raw shellcode bytes provided by build.zig.
const shellcode = @embedFile("shellcode.bin");

pub fn main() !void {
    const page_size = std.heap.pageSize();

    // Allocate a page of memory. It must be page-aligned for mprotect.
    const executable_page = try std.heap.page_allocator.alignedAlloc(u8, page_size, page_size);

    if (shellcode.len > executable_page.len) {
        std.log.err("shellcode ({} bytes) is larger than a page ({} bytes)!", .{ shellcode.len, page_size });
        return;
    }

    // Copy the shellcode into our executable page.
    std.mem.copyForwards(u8, executable_page, shellcode);

    // Mark the page as Readable, Writable, and Executable.
    try std.posix.mprotect(executable_page, std.posix.PROT.READ | std.posix.PROT.WRITE | std.posix.PROT.EXEC);

    // Cast the pointer to our memory page into a function pointer.
    const shellcode_fn: *const fn () callconv(.C) void = @ptrCast(executable_page.ptr);

    // Call the shellcode!
    shellcode_fn();
}
