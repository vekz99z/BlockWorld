extends RefCounted
class_name LuaScriptSandbox

var output: Callable

func _init(output_callback: Callable = Callable()):
    output = output_callback

func run(source: String, part: Node3D) -> bool:
    var did_anything := false
    for raw_line in source.split("\\n"):
        var line := raw_line.strip_edges()
        if line.is_empty() or line.begins_with("--"):
            continue
        if line.begins_with("print("):
            var msg := line.trim_prefix("print(").trim_suffix(")").strip_edges()
            msg = msg.trim_prefix("\"").trim_suffix("\"")
            _say(msg)
            did_anything = true
        elif line.contains(".Color") and line.contains("="):
            var value := line.split("=", false, 1)[1].strip_edges().trim_suffix(";")
            value = value.trim_prefix("\"").trim_suffix("\"")
            var colors := {"Red": Color.RED, "Green": Color.GREEN, "Blue": Color.BLUE, "Yellow": Color.YELLOW, "White": Color.WHITE, "Black": Color.BLACK}
            if colors.has(value):
                if part.has_method("set_part_color"):
                    part.set_part_color(colors[value])
                did_anything = true
        elif line.contains(".Size") and line.contains("Vector3.new"):
            var args := _vector_args(line)
            if args.size() == 3 and part.get_node_or_null("Mesh"):
                var size := Vector3(args[0], args[1], args[2])
                var mesh := part.get_node("Mesh") as MeshInstance3D
                var box := mesh.mesh as BoxMesh
                if box:
                    box.size = size
                var collision := part.get_node_or_null("CollisionShape3D") as CollisionShape3D
                if collision and collision.shape is BoxShape3D:
                    collision.shape.size = size
                did_anything = true
    return did_anything

func _vector_args(line: String) -> Array:
    var start := line.find("Vector3.new(")
    if start < 0:
        return []
    start += "Vector3.new(".length()
    var end := line.find(")", start)
    if end < 0:
        return []
    var values: Array = []
    for item in line.substr(start, end - start).split(","):
        values.append(float(item.strip_edges()))
    return values

func _say(message: String):
    if output.is_valid():
        output.call(message)
