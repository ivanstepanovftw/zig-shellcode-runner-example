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

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1. Compile the shellcode source into an object file.
    const shellcode_obj = b.addObject(.{
        .name = "shellcode_obj",
        .root_source_file = b.path("src/shellcode.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Position-Independent Code is crucial for shellcode.
    shellcode_obj.root_module.pic = true;

    // 2. Extract only the raw machine code (the .text section) from the object file.
    const shellcode_bin = b.addObjCopy(shellcode_obj.getEmittedBin(), .{
        .format = .bin,
        .only_section = ".text",
    });

    // 3. Build the main executable.
    const exe = b.addExecutable(.{
        .name = "runner",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // 4. Make the raw shellcode binary available to the main executable at compile-time.
    //    It can be accessed via `@embedFile("shellcode.bin")`.
    exe.root_module.addAnonymousImport("shellcode.bin", .{ .root_source_file = shellcode_bin.getOutput() });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
