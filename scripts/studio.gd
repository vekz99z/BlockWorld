extends Control

const StudioPartScene = preload("res://scripts/studio_part.gd")
const LuaSandbox = preload("res://scripts/lua_script.gd")

var world: Node3D
var camera: Camera3D
var selected: StudioPart
var selected_index := 0
var parts: Array[StudioPart] = []
var explorer: ItemList
var script_editor: TextEdit
var output_box: TextEdit
var properties: VBoxContainer
var toolbox: VBoxContainer
var name_edit: LineEdit
var pos_x: SpinBox
var pos_y: SpinBox
var pos_z: SpinBox
var size_x: SpinBox
var size_y: SpinBox
var size_z: SpinBox
var color_option: OptionButton

func _ready():
    _build_world()
    _build_ui()
    _insert_part("Part", Color(0.65, 0.65, 0.65), Vector3.ZERO)
    _select_part(0)

func _build_world():
    world = Node3D.new()
    world.name = "Workspace"
    add_child(world)

    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.08, 0.10, 0.14)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.7, 0.75, 0.85)
    env.ambient_light_energy = 0.8
    environment.environment = env
    world.add_child(environment)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -30, 0)
    light.light_energy = 1.2
    world.add_child(light)

    camera = Camera3D.new()
    camera.position = Vector3(12, 10, 16)
    camera.look_at_from_position(camera.position, Vector3.ZERO)
    world.add_child(camera)

func _build_ui():
    var bg := ColorRect.new()
    bg.color = Color(0.055, 0.065, 0.08, 1)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    move_child(bg, 0)

    var top := ColorRect.new()
    top.color = Color(0.09, 0.105, 0.13, 1)
    top.position = Vector2(0, 0)
    top.size = Vector2(1280, 58)
    add_child(top)

    var title := Label.new()
    title.text = "BLOCKWORLD STUDIO"
    title.position = Vector2(18, 15)
    title.add_theme_font_size_override("font_size", 22)
    add_child(title)

    _button("▶ Play", Vector2(250, 10), Vector2(85, 38), _play_test)
    _button("■ Stop", Vector2(342, 10), Vector2(85, 38), _stop_test)
    _button("💾 Save", Vector2(434, 10), Vector2(85, 38), _save_project)
    _button("← Exit", Vector2(526, 10), Vector2(85, 38), _exit_studio)

    var left := Panel.new()
    left.position = Vector2(0, 58)
    left.size = Vector2(230, 662)
    add_child(left)
    toolbox = VBoxContainer.new()
    toolbox.position = Vector2(12, 12)
    toolbox.size = Vector2(206, 638)
    left.add_child(toolbox)
    var tb := Label.new()
    tb.text = "TOOLBOX"
    tb.add_theme_font_size_override("font_size", 18)
    toolbox.add_child(tb)
    var search := LineEdit.new()
    search.placeholder_text = "Search toolbox..."
    toolbox.add_child(search)
    _toolbox_button("Block", Color(0.65, 0.65, 0.65))
    _toolbox_button("Red Block", Color(0.9, 0.2, 0.2))
    _toolbox_button("Blue Block", Color(0.2, 0.4, 0.95))
    _toolbox_button("Grass Block", Color(0.2, 0.75, 0.25))
    _toolbox_button("Community House", Color(0.75, 0.45, 0.2))
    _toolbox_button("Community Tree", Color(0.15, 0.55, 0.2))
    var note := Label.new()
    note.text = "Community assets are local placeholders for now. Online publishing can be added later."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    toolbox.add_child(note)

    var center := Panel.new()
    center.position = Vector2(230, 58)
    center.size = Vector2(720, 430)
    add_child(center)
    var viewport := SubViewportContainer.new()
    viewport.position = Vector2(2, 2)
    viewport.size = Vector2(716, 426)
    viewport.stretch = true
    center.add_child(viewport)
    var sub := SubViewport.new()
    sub.size = Vector2i(716, 426)
    sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.add_child(sub)
    # Move the existing 3D workspace into the editor viewport.
    remove_child(world)
    sub.add_child(world)
    world = sub.get_node("Workspace")
    camera.current = true

    var right := Panel.new()
    right.position = Vector2(950, 58)
    right.size = Vector2(330, 662)
    add_child(right)

    var rbox := VBoxContainer.new()
    rbox.position = Vector2(12, 12)
    rbox.size = Vector2(306, 638)
    right.add_child(rbox)
    var ex := Label.new()
    ex.text = "EXPLORER"
    ex.add_theme_font_size_override("font_size", 18)
    rbox.add_child(ex)
    explorer = ItemList.new()
    explorer.custom_minimum_size = Vector2(0, 180)
    explorer.item_selected.connect(_on_explorer_selected)
    rbox.add_child(explorer)
    var prop_title := Label.new()
    prop_title.text = "PROPERTIES"
    prop_title.add_theme_font_size_override("font_size", 18)
    rbox.add_child(prop_title)
    properties = VBoxContainer.new()
    properties.size_flags_vertical = Control.SIZE_EXPAND_FILL
    rbox.add_child(properties)
    _make_properties()

    var script_panel := Panel.new()
    script_panel.position = Vector2(230, 488)
    script_panel.size = Vector2(720, 232)
    add_child(script_panel)
    var st := Label.new()
    st.text = "SCRIPT — Part.Script (Lua-style sandbox)"
    st.position = Vector2(10, 8)
    script_panel.add_child(st)
    script_editor = TextEdit.new()
    script_editor.position = Vector2(10, 35)
    script_editor.size = Vector2(480, 150)
    script_editor.text = "local part = script.Parent\\n\\npart.Color = \"Blue\"\\npart.Size = Vector3.new(4, 2, 4)\\n\\nprint(\"Hello from BlockWorld!\")"
    script_editor.add_theme_font_size_override("font_size", 15)
    script_panel.add_child(script_editor)
    _button("▶ Run Script", Vector2(505, 38), Vector2(120, 38), _run_script, script_panel)
    output_box = TextEdit.new()
    output_box.position = Vector2(505, 84)
    output_box.size = Vector2(200, 100)
    output_box.editable = false
    output_box.text = "Output\\n"
    script_panel.add_child(output_box)

func _button(text_value: String, p: Vector2, s: Vector2, callback: Callable, parent: Node = self):
    var b := Button.new()
    b.text = text_value
    b.position = p
    b.size = s
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _toolbox_button(label: String, color: Color):
    var b := Button.new()
    b.text = "＋ " + label
    b.pressed.connect(func(): _insert_part(label, color, Vector3(randf_range(-4, 4), 1, randf_range(-4, 4))))
    toolbox.add_child(b)

func _insert_part(label: String, color: Color, p: Vector3):
    var part := StudioPart.new()
    world.add_child(part)
    part.setup(label, color)
    part.position = p
    parts.append(part)
    _refresh_explorer()
    _select_part(parts.size() - 1)

func _refresh_explorer():
    if not explorer:
        return
    explorer.clear()
    for p in parts:
        explorer.add_item("▣ " + p.part_name)

func _select_part(index: int):
    if parts.is_empty():
        return
    selected_index = clamp(index, 0, parts.size() - 1)
    selected = parts[selected_index]
    _refresh_explorer()
    explorer.select(selected_index)
    _load_properties()

func _on_explorer_selected(index: int):
    _select_part(index)

func _make_properties():
    name_edit = LineEdit.new()
    name_edit.placeholder_text = "Part name"
    name_edit.text_submitted.connect(func(v):
        if selected:
            selected.part_name = v
            selected.name = v
            _refresh_explorer()
    )
    properties.add_child(name_edit)
    _add_axis("Position X", "px")
    _add_axis("Position Y", "py")
    _add_axis("Position Z", "pz")
    _add_axis("Size X", "sx")
    _add_axis("Size Y", "sy")
    _add_axis("Size Z", "sz")
    color_option = OptionButton.new()
    for c in ["Gray", "Red", "Green", "Blue", "Yellow", "White", "Black"]:
        color_option.add_item(c)
    color_option.item_selected.connect(_color_changed)
    properties.add_child(color_option)
    var delete := Button.new()
    delete.text = "Delete Selected"
    delete.pressed.connect(_delete_selected)
    properties.add_child(delete)

func _add_axis(label_text: String, key: String):
    var row := HBoxContainer.new()
    var label := Label.new()
    label.text = label_text
    label.custom_minimum_size.x = 100
    row.add_child(label)
    var spin := SpinBox.new()
    spin.min_value = -100
    spin.max_value = 100
    spin.step = 0.25
    spin.value_changed.connect(func(_v): _apply_property(key))
    row.add_child(spin)
    properties.add_child(row)
    if key == "px": pos_x = spin
    elif key == "py": pos_y = spin
    elif key == "pz": pos_z = spin
    elif key == "sx": size_x = spin
    elif key == "sy": size_y = spin
    elif key == "sz": size_z = spin

func _load_properties():
    if not selected:
        return
    name_edit.text = selected.part_name
    pos_x.value = selected.position.x
    pos_y.value = selected.position.y
    pos_z.value = selected.position.z
    var box := selected.get_node("Mesh").mesh as BoxMesh
    size_x.value = box.size.x
    size_y.value = box.size.y
    size_z.value = box.size.z

func _apply_property(key: String):
    if not selected:
        return
    if key == "px": selected.position.x = pos_x.value
    elif key == "py": selected.position.y = pos_y.value
    elif key == "pz": selected.position.z = pos_z.value
    else:
        var size := Vector3(size_x.value, size_y.value, size_z.value)
        var box := selected.get_node("Mesh").mesh as BoxMesh
        box.size = size
        var collision := selected.get_node("CollisionShape3D") as CollisionShape3D
        var shape := collision.shape as BoxShape3D
        shape.size = size

func _color_changed(index: int):
    if not selected:
        return
    var colors := [Color(0.65,0.65,0.65), Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.WHITE, Color.BLACK]
    selected.set_part_color(colors[index])

func _delete_selected():
    if not selected:
        return
    var idx := selected_index
    selected.queue_free()
    parts.remove_at(idx)
    selected = null
    if parts.size() > 0:
        _select_part(min(idx, parts.size() - 1))
    else:
        _refresh_explorer()

func _run_script():
    if not selected:
        return
    output_box.text += "Running script on " + selected.part_name + "...\\n"
    var sandbox := LuaSandbox.new(func(msg): output_box.text += str(msg) + "\\n")
    if sandbox.run(script_editor.text, selected):
        output_box.text += "Script finished.\\n"
        _load_properties()
    else:
        output_box.text += "No supported commands found.\\n"

func _save_project():
    var data := []
    for p in parts:
        var box := p.get_node("Mesh").mesh as BoxMesh
        data.append({"name": p.part_name, "position": [p.position.x,p.position.y,p.position.z], "size": [box.size.x,box.size.y,box.size.z]})
    var file := FileAccess.open("user://studio_project.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(data))
    output_box.text += "Saved to user://studio_project.json\\n"

func _play_test():
    output_box.text += "Play mode: test simulation started.\\n"

func _stop_test():
    output_box.text += "Play mode: stopped.\\n"

func _exit_studio():
    get_tree().change_scene_to_file("res://scenes/main.tscn")
