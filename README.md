<!--
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Zig Shellcode Runner Example
# Copyright (C) 2025 Ivan Stepanov <ivanstepanovftw@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
-->
# Zig Shellcode Runner Example

[![CI](https://github.com/ivanstepanovftw/zig-shellcode-runner-example/actions/workflows/ci.yml/badge.svg)](https://github.com/ivanstepanovftw/zig-shellcode-runner-example/actions/workflows/ci.yml)

This project is a demonstration of how to write shellcode in Zig, compile it to raw machine code, embed it into a separate "runner" executable, and execute it at runtime.

It showcases several powerful features of the Zig language and its build system:

*   Writing platform-specific shellcode using inline assembly.
*   A multi-stage build process to extract raw machine code from a compiled object.
*   Compile-time file embedding with `@embedFile`.
*   Runtime memory allocation and protection modification for executing dynamically loaded code.

## How It Works

The process is broken into several distinct steps, orchestrated by the Zig build system.

1.  **`src/shellcode.zig`**: This file contains a `naked` function with inline assembly. The assembly is a standard 28-byte shellcode for `x86-64 Linux` that executes the `execve` syscall to spawn `/bin/sh`. The `callconv(.naked)` is crucial as it prevents the Zig compiler from adding any function prologue or epilogue, ensuring the output is purely the assembly we've written.

2.  **`build.zig`**: The build script performs a multi-step compilation:
    *   First, it compiles `src/shellcode.zig` into an object file (`shellcode_obj`). Position-Independent Code (`.pic = true`) is enabled, which is essential for shellcode.
    *   Next, it uses `b.addObjCopy` (Zig's equivalent of `objcopy`) to extract *only* the `.text` section (the raw machine code) from the object file into a flat binary file, which we'll call `shellcode.bin`.
    *   Then, it compiles the main runner program, `src/main.zig`.
    *   Finally, it makes the generated `shellcode.bin` available to `main.zig` at compile-time via an anonymous import.

3.  **`src/main.zig`**: The runner executable performs the final steps at runtime:
    *   It uses `@embedFile("shellcode.bin")` to embed the raw machine code directly into the executable as a byte slice.
    *   It allocates a page of memory using `std.heap.page_allocator`. The memory must be page-aligned to work with memory protection APIs.
    *   It copies the embedded shellcode into this newly allocated page.
    *   It uses `std.posix.mprotect` to change the memory page's permissions to be readable, writable, and **executable** (RWX).
    *   It casts the pointer to the memory page into a function pointer.
    *   It calls the function pointer, executing the shellcode.

## Prerequisites

*   [Zig](https://ziglang.org/download/) version 0.15.0-dev.1149 or later.

## Building and Running

To build the project and run the final executable, use the Zig build system:

```sh
zig build run
```

**Expected Outcome:**

*   On **Linux (x86-64)**, this command will drop you into a new `/bin/sh` shell.
*   On **macOS or Windows**, the program will compile but will likely crash or fail at runtime. This is because the shellcode is specific to the Linux kernel's syscall interface and the runner uses POSIX-specific APIs for memory protection. See the section below for more details.

To just build the executable without running it:

```sh
zig build
```

The output will be in `zig-out/bin/runner`.

## Platform Compatibility

This example is intentionally designed to demonstrate a specific scenario and has platform limitations.

### Shellcode (`src/shellcode.zig`)

The assembly code is hardcoded for **x86-64 Linux**. It uses Linux-specific syscall numbers (`execve` is 59) and conventions. To run on other architectures (like AArch64) or operating systems (macOS, Windows), the assembly would need to be completely rewritten.

### Runner (`src/main.zig`)

The runner uses `std.posix.mprotect` to make the memory page executable. This function is available on POSIX-compliant systems like Linux and macOS.

To achieve the same result on **Windows**, you would need to use the Win32 API, specifically:
*   `VirtualAlloc` to allocate memory.
*   `VirtualProtect` to change the memory protection to `PAGE_EXECUTE_READWRITE`.

The CI workflow (`.github/workflows/ci.yml`) successfully **builds** the project on Linux, macOS, and Windows, demonstrating the cross-compilation capabilities of Zig. However, the `run` step is only expected to succeed on Linux.

## License

This project is licensed under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See [LICENSE-AGPL-3.0-or-later](LICENSE-AGPL-3.0-or-later) for the full license text.

## Copyright

Copyright (C) 2025 Ivan Stepanov <ivanstepanovftw@gmail.com>
