extends Node3D

const S := 2.0
const R := 18
var player: CharacterBody3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.15
var locked := true

func _ready():
    make_world()
    make_player()
    make_ui()

func mat(c: Color):
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    return m

func block(pos: Vector3, c: Color):
    var b := StaticBody3D.new()
    b.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(S, S, S)
    mesh.mesh = box
    mesh.material_override = mat(c)
    b.add_child(mesh)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(S, S, S)
    col.shape = shape
    b.add_child(col)
    add_child(b)

func make_world():
    for x in range(-R, R + 1):
        for z in range(-R, R + 1):
            block(Vector3(x * S, -S / 2.0, z * S), Color(0.25, 0.65, 0.25))
    for x in range(6, 11):
        for z in range(5, 10):
            block(Vector3(x * S, S / 2.0, z * S), Color(0.55, 0.38, 0.20))

func make_player():
    player = CharacterBody3D.new()
    player.position = Vector3(0, 4, 8)
    add_child(player)

    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.height = 2.4
    capsule.radius = 0.55
    mesh.mesh = capsule
    mesh.material_override = mat(Color(0.2, 0.45, 0.9))
    mesh.position.y = 1.2
    player.add_child(mesh)

    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.height = 2.4
    shape.radius = 0.55
    col.shape = shape
    col.position.y = 1.2
    player.add_child(col)

    camera = Camera3D.new()
    camera.position = Vector3(0, 2.2, 6)
    player.add_child(camera)
    camera.current = true

func make_ui():
    var title := Label.new()
    title.text = "BLOCKWORLD"
    title.position = Vector2(32, 28)
    title.add_theme_font_size_override("font_size", 30)
    add_child(title)

    var hint := Label.new()
    hint.text = "WASD move  •  SPACE jump  •  ESC release mouse  •  F4 Studio"
    hint.position = Vector2(32, 68)
    hint.add_theme_font_size_override("font_size", 16)
    add_child(hint)

    var studio := Button.new()
    studio.text = "Open Studio"
    studio.position = Vector2(32, 105)
    studio.size = Vector2(170, 42)
    studio.pressed.connect(open_studio)
    add_child(studio)

    var cross := Label.new()
    cross.text = "+"
    cross.position = Vector2(637, 345)
    cross.add_theme_font_size_override("font_size", 26)
    add_child(cross)

func open_studio():
    get_tree().change_scene_to_file("res://scenes/studio.tscn")

func _unhandled_input(e):
    if e is InputEventKey and e.pressed and e.keycode == KEY_F4:
        open_studio()
        return
    if e is InputEventMouseMotion and locked:
        yaw -= e.relative.x * 0.0025
        pitch -= e.relative.y * 0.0025
        pitch = clamp(pitch, -1.2, 1.0)
        player.rotation.y = yaw
        camera.rotation.x = pitch
    elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
        locked = false
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
        locked = true
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    if not player:
        return
    var d := Vector3.ZERO
    var f := -player.global_transform.basis.z
    var r := player.global_transform.basis.x
    if Input.is_action_pressed("move_forward"):
        d += f
    if Input.is_action_pressed("move_back"):
        d -= f
    if Input.is_action_pressed("move_left"):
        d -= r
    if Input.is_action_pressed("move_right"):
        d += r
    d.y = 0
    if d.length() > 0.0:
        d = d.normalized()
    player.velocity.x = d.x * 7.0
    player.velocity.z = d.z * 7.0
    if not player.is_on_floor():
        player.velocity.y -= 20.0 * delta
    elif Input.is_action_just_pressed("jump"):
        player.velocity.y = 8.0
    player.move_and_slide()
    if player.position.y < -20:
        player.position = Vector3(0, 5, 8)
        player.velocity = Vector3.ZERO
