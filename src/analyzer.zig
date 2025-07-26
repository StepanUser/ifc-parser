const std = @import("std");
const ast_module = @import("ast.zig");
const Matrix = @import("matrix.zig");
const Matrix4 = ast_module.Matrix4;
const GenericEntity = ast_module.GenericEntity;
const AllEntities = ast_module.AllEntities;

fn parseAxis2Placement3D(
    placement_entity: *const GenericEntity,
    entities: *const AllEntities,
) !Matrix4 {
    var matrix = Matrix.identity();

    const location_ref = placement_entity.attributes.items[0].Reference;
    const location_point = entities.get(location_ref) orelse error.MissingEntity;
    const coord_list = location_point.attributes.items[0].List;

    matrix.column3 = .{ @floatCast(coord_list.items[0].Float), @floatCast(coord_list.items[1].Float), @floatCast(coord_list.items[2].Float), 1.0 };

    //todo: handle rotation

    return matrix;
}

pub fn calculateWorldTransform(
    target_id: u32,
    entities: *const AllEntities,
) !Matrix4 {
    const entity = entities.get(target_id) orelse return error.MissingEntity;

    if (entity.attributes.items.len <= 4) return Matrix.identity();
    const placement_value = entity.attributes.items[4];
    if (placement_value != .Reference) return Matrix.identity();

    const local_placement_entity = entities.get(placement_value.Reference) orelse return error.MissingEntity;
    const relative_placement_ref = local_placement_entity.attributes.items[1].Reference;
    const placement_3d_entity = entities.get(relative_placement_ref) orelse return error.MissingEntity;

    const local_matrix = try parseAxis2Placement3D(placement_3d_entity, entities);

    const parent_ref_value = local_placement_entity.attributes.items[0];

    if (parent_ref_value == .Reference) {
        const parent_matrix = try calculateWorldTransform(parent_ref_value.Reference, entities);

        return Matrix.multiplyMatrix(parent_matrix, local_matrix);
    } else {
        return local_matrix;
    }
}
