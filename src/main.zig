const std = @import("std");
const lexer_module = @import("lexer.zig");
const parser_module = @import("parser.zig");
const ast_module = @import("ast.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_size = try fileSize("test_data/simple.ifc");
    std.debug.print("File size is {} in bytes\n", .{file_size});

    const fileContent = try std.fs.cwd().readFileAlloc(allocator, "test_data/simple.ifc", file_size);
    defer allocator.free(fileContent);

    var lexer = lexer_module.Lexer.init(fileContent);

    std.log.info("------ Starting Parser ------", .{});
    var entities = try parser_module.Parser.parse(&lexer, allocator);
    defer {
        var it = entities.valueIterator();
        while (it.next()) |entity| {
            entity.deinit();
        }
        entities.deinit();
    }

    std.log.info("--- Parsing Complete. Found {d} entities. ---", .{entities.count()});

    std.log.info("--- FINDING ALL SLABS (IFCSLAB) ---", .{});

    var slab_list = std.ArrayList(ast_module.GenericEntity).init(allocator);
    defer slab_list.deinit();

    var it = entities.valueIterator();
    while (it.next()) |entity| {
        if (std.mem.eql(u8, entity.type_name, "IFCSLAB")) {
            // We found a slab! Add it to our list.
            try slab_list.append(entity.*);
        }
    }

    std.log.info("Found {d} slabs in the model.", .{slab_list.items.len});
}

fn fileSize(path: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const statistic = try file.stat();

    return statistic.size;
}
