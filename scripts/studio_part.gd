extends Node3D
class_name StudioPart

var part_name := "Part"
var part_color := Color(0.65, 0.65, 0.65)

func setup(new_name: String, new_color: Color):
    part_name = new_name
    part_color = new_color
    name = part_name
    var mesh := MeshInstance3D.new()
    mesh.name = "Mesh"
    var box := BoxMesh.new()
    box.size = Vector3.ONE * 2.0
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = part_color
    mesh.material_override = material
    add_child(mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3.ONE * 2.0
    collision.shape = shape
    add_child(collision)

func set_part_color(c: Color):
    part_color = c
    var mesh := get_node_or_null("Mesh") as MeshInstance3D
    if mesh:
        var material := mesh.material_override as StandardMaterial3D
        if material:
            material.albedo_color = c
