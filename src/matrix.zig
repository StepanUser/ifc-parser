const std = @import("std");
const ast_module = @import("./ast.zig");

const Vector4 = ast_module.Vector4;
const Matrix4 = ast_module.Matrix4;

pub fn identity() Matrix4 {
    return Matrix4{
        .column0 = @as(Vector4, .{ 1, 0, 0, 0 }),
        .column1 = @as(Vector4, .{ 0, 1, 0, 0 }),
        .column2 = @as(Vector4, .{ 0, 0, 1, 0 }),
        .column3 = @as(Vector4, .{ 0, 0, 0, 1 }),
    };
}

pub fn multiplyMatrix(a: Matrix4, b: Matrix4) Matrix4 {
    return .{
        .column0 = multiplyVector(a, b.column0),
        .column1 = multiplyVector(a, b.column1),
        .column2 = multiplyVector(a, b.column2),
        .column3 = multiplyVector(a, b.column3),
    };
}

pub fn multiplyVector(matrix: Matrix4, vector: Vector4) Vector4 {
    return matrix.column0 * @as(Vector4, @splat(vector[0])) +
        matrix.column1 * @as(Vector4, @splat(vector[1])) +
        matrix.column2 * @as(Vector4, @splat(vector[2])) +
        matrix.column3 * @as(Vector4, @splat(vector[3]));
}
