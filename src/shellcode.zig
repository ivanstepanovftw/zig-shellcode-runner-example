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

export fn entry() callconv(.naked) void {
    // This is a standard 28-byte shellcode for x86-64 Linux to spawn /bin/sh.
    // zig fmt: off
    asm volatile (
        \\  xorq %%rax, %%rax
        \\  pushq %%rax                     # Push NULL for string terminator
        \\  movq $0x68732f6e69622f, %%rdi   # Move '/bin/sh' (as '/bin/sh\0') into rdi
        \\  pushq %%rdi                     # Push '/bin/sh\0' onto the stack
        \\  movq %%rsp, %%rdi               # rdi = &("/bin/sh")
        \\  pushq %%rax                     # Push NULL for argv terminator
        \\  pushq %%rdi                     # Push rdi (pointer to /bin/sh) for argv[0]
        \\  movq %%rsp, %%rsi               # rsi = &argv
        \\  xorq %%rdx, %%rdx               # rdx = NULL (for envp)
        \\  movb $59, %%al                  # rax = 59 (syscall number for execve)
        \\  syscall                         # Execute the system call
    );
    // zig fmt: on
}
