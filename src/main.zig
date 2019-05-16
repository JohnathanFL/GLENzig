const std = @import("std");
const assert = std.debug.assert;

const sdl = @cImport(@cInclude("SDL2/SDL.h"));
const gl = @cImport(@cInclude("glad.h"));

pub fn Vec(comptime n: usize, comptime ty: type) type {
    const typeOf = @typeId(ty);
    comptime if(typeOf != .Float and typeOf != .Integer) @compileError("Vec can only be used with floats and ints!");
    
    // Would be nice
    //comptime if(n > 4) @compileWarning("Vec isn't tested with any n > 4.");

    return packed struct {
        // So we can easily swap to another implementation if need be
        const sin = std.math.sin;
        const cos = std.math.cos;

        data: [n] ty,

        // pub inline fn init(args: [n]ty) @This() {
        //     var res: @This() = undefined;
        //     comptime var i = 0;
        //     inline while (i < n) : (i += 1) {
        //         res.data[i] = args[i];
        //     }

        //     return res;
        // }

        pub inline fn x(self: @This()) ty {
            return self.data[0];
        }
        pub inline fn y(self: @This()) ty {
            return self.data[1];
        }
        pub inline fn z(self: @This()) ty {
            return self.data[2];
        }
        pub inline fn w(self: @This()) ty {
            return self.data[3];
        }

        pub inline fn r(self: @This()) ty {
            return self.data[0];
        }
        pub inline fn g(self: @This()) ty {
            return self.data[1];
        }
        pub inline fn b(self: @This()) ty {
            return self.data[2];
        }
        pub inline fn a(self: @This()) ty {
            return self.data[3];
        }

        pub inline fn length(self: @This()) ty {
            comptime if(@typeId(ty) != .Float) @compileError("Vec.length needs a floating-point type!");

            var sum: ty = self.data[0];
            comptime var i: usize = 1;
            inline while(i < n) : (i+=1) {
                sum += self.data[i] * self.data[i];
            }

            return @sqrt(ty, sum);
        }

        pub inline fn add(self: @This(), other: @This()) @This() {
            var res = self;
            comptime var i = 0;
            inline while (i < n) : (i += 1) {
                res.data[i] += other.data[i];
            }

            return res;
        }

        pub inline fn sub(self: @This(), other: @This()) @This() {
            var res = self;
            comptime var i = 0;
            inline while (i < n) : (i += 1) {
                res.data[i] -= other.data[i];
            }

            return res;
        }

        pub inline fn addScalar(self: @This(), other: ty) @This() {
            var res = self;
            comptime var i = 0;
            inline while (i < n) : (i += 1) {
                res.data[i] += other;
            }

            return res;
        }

        pub inline fn dot(self: @This(), other: @This()) ty {
            var res = self.x() * other.x();
            comptime var i = 1;
            inline while (i < n) : (i += 1) {
                res += self.data[i] * other.data[i];
            }

            return res;
        }

        // Currently causes a compiler bug
        pub inline fn cross(self: @This(), other: @This()) @This() {
            comptime if(n != 3) @compileError("Cross product is only defined for 3D!");

            return @This() {
                .data = [3]ty{
                    self.data[1] * other.data[2] - self.data[2] * other.data[1],
                    self.data[2] * other.data[0] - self.data[0] * other.data[2],
                    self.data[0] * other.data[1] - self.data[1] * other.data[0]
                }
            };
        }
    };
}

pub const ChunkSize = 48;

pub const VoxelVert = packed struct {
    normal: Vec(3, f32)
};

pub const Voxel = packed struct {
    // Flags: Should be designed such that 0 matches the properties of air
    solid: bool, // Can we fall through it?
    opaque: bool, // Does it block our sight?
    // POSSIBLE ZIG BUG: This makes the struct take 5 bytes instead of 1+1+6+24=32/8=4
    
    // Must be updated on every insert op, but should increase performance elsewhere
    frontVis: bool,
    backVis: bool,
    leftVis: bool,
    rightVis: bool,
    topVis: bool,
    botVis: bool,

    id: u24,

    pub fn asU32(self: Voxel) u32 {
        return @bitCast(u32, self);
    }

    pub fn isAir(self: Voxel) bool {
        return self.asU32() & 0x00FFFFFF == 0;
    }

    pub const Air = Voxel {
        .solid = false,
        .opaque = false,
        // No need to even really care here. We'll treat air as special anyway.
        .frontVis=false,
        .backVis=false,
        .leftVis=false,
        .rightVis=false,
        .topVis=false,
        .botVis=false,
        .id = 0
    };

};

pub const Chunk = struct {
    blocks: [ChunkSize]Voxel,

};

comptime {
    
    //assert(@sizeOf(Voxel) == 4);
}

pub fn main() anyerror!void {
    const Vec3 = Vec(3, f32);
    var v = Vec3 {
        .data = [3]f32{1.0, 1.0, 1.0}
    };//Vec3.init([]f32{1.0, 1.0, 1.0});
    var u = Vec3 {
        .data = [3]f32{0.0, 0.0, 0.0}
    };
    _ = v.cross(u);
    var vox = Voxel.Air;
    std.debug.warn("{}", @intCast(u64, @sizeOf(Voxel)));

    assert(sdl.SDL_Init(sdl.SDL_INIT_VIDEO) == 0);
    defer sdl.SDL_Quit();
    

    var window = sdl.SDL_CreateWindow(c"Methuka", 0, 0, 1920, 1080, sdl.SDL_WINDOW_OPENGL | sdl.SDL_WINDOW_FULLSCREEN) 
        orelse @panic("Failed to create SDL window");
    defer sdl.SDL_DestroyWindow(window);
    var glCtx = sdl.SDL_GL_CreateContext(window);
    assert(sdl.SDL_GL_MakeCurrent(window, glCtx) == 0);
    
    assert(gl.gladLoadGL() == 1);
    gl.glClearColor(44.0 / 255.0, 53.0 / 255.0, 57.0 / 255.0, 1.0);

    sdl.SDL_ShowWindow(window);

    var ev: sdl.SDL_Event = undefined;
    main: while(true) {
        while(sdl.SDL_PollEvent(&ev) != 0) {
            switch (ev.@"type") {
                sdl.SDL_QUIT => break :main,
                sdl.SDL_KEYDOWN => {
                    if (ev.key.keysym.scancode == @intToEnum(sdl.SDL_Scancode, sdl.SDL_SCANCODE_ESCAPE)) break :main;
                },
                else => {},
            }
            
        }

        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT | gl.GL_STENCIL_BUFFER_BIT);
        sdl.SDL_GL_SwapWindow(window);
    }



}
