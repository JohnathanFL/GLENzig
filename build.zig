const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("Methuka-zig", "src/main.zig");
    exe.setBuildMode(builtin.Mode.Debug);
    exe.addIncludeDir("/usr/include");
    exe.addIncludeDir("src/");

    exe.addCSourceFile("src/glad.c", [][]const u8{"-std=c11"});


    exe.linkSystemLibrary("GL");
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("c");
    
    

    const run_cmd = exe.run();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
