const std = @import("std");

pub const GeometryObject = struct {
    id: u32,
    type: []const u8,
    geometry: Mesh,
    matrix: [16]f32,
};

pub const Mesh = struct {
    vertices: []f32,
    indices: []f32,
};

pub const Vector4 = @Vector(4, f32);

pub const Matrix4 = struct {
    column0: Vector4,
    column1: Vector4,
    column2: Vector4,
    column3: Vector4,
};

pub const Value = union(enum) {
    String: []const u8,
    Reference: u32,
    Integer: i64,
    Float: f64,
    Enum: []const u8,
    List: std.ArrayList(Value),
    Null,
};

pub const GenericEntity = struct {
    id: u32,
    type_name: []const u8,
    attributes: std.ArrayList(Value),

    pub fn deinit(self: *GenericEntity) void {
        for (self.attributes.items) |*value| {
            if (value.* == .List) {
                value.List.deinit();
            }
        }

        self.attributes.deinit();
    }
};

pub const AllEntities = std.AutoHashMap(u32, GenericEntity);
