extends Node

const SAVE_PATH := "user://blockworld_games.json"
const PORT := 7000
const MAX_PLAYERS := 12

var games: Array = []
var current_game: Dictionary = {}
var current_blocks: Array = []
var player_name := "Player"
var status_text := ""

var root_ui: Control
var content: VBoxContainer

func _ready():
	load_games()
	build_ui()
	show_menu()

# =========================
# UI
# =========================

func build_ui():
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_ui)

func clear_ui():
	for child in root_ui.get_children():
		child.queue_free()

func make_button(text: String, action: Callable, width := 350, height := 55) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, height)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(action)
	return b

func base_screen(title: String, subtitle: String):
	clear_ui()

	var bg := ColorRect.new()
	bg.color = Color("#0c1220")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(bg)

	var header := ColorRect.new()
	header.color = Color("#151e30")
	header.position = Vector2(0, 0)
	header.size = Vector2(1280, 90)
	root_ui.add_child(header)

	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(45, 17)
	title_label.add_theme_font_size_override("font_size", 34)
	root_ui.add_child(title_label)

	var sub := Label.new()
	sub.text = subtitle
	sub.position = Vector2(47, 58)
	sub.modulate = Color("#9aa8c2")
	root_ui.add_child(sub)

	var back := Button.new()
	back.text = "← Back"
	back.position = Vector2(1100, 25)
	back.size = Vector2(125, 42)
	back.pressed.connect(show_menu)
	root_ui.add_child(back)

	content = VBoxContainer.new()
	content.position = Vector2(55, 125)
	content.size = Vector2(1170, 530)
	content.add_theme_constant_override("separation", 14)
	root_ui.add_child(content)

# =========================
# MAIN MENU
# =========================

func show_menu():
	clear_ui()

	var bg := ColorRect.new()
	bg.color = Color("#090e1a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(bg)

	var title := Label.new()
	title.text = "BLOCKWORLD"
	title.position = Vector2(75, 65)
	title.add_theme_font_size_override("font_size", 64)
	title.modulate = Color("#5da9ff")
	root_ui.add_child(title)

	var tagline := Label.new()
	tagline.text = "PLAY  •  CREATE  •  SHARE"
	tagline.position = Vector2(80, 140)
	tagline.add_theme_font_size_override("font_size", 18)
	tagline.modulate = Color("#9aa8c2")
	root_ui.add_child(tagline)

	var buttons := VBoxContainer.new()
	buttons.position = Vector2(75, 205)
	buttons.add_theme_constant_override("separation", 12)
	root_ui.add_child(buttons)

	buttons.add_child(make_button("▶  PLAY", show_discover))
	buttons.add_child(make_button("◆  DISCOVER", show_discover))
	buttons.add_child(make_button("＋  CREATE A GAME", show_create))
	buttons.add_child(make_button("⚒  STUDIO", show_studio))
	buttons.add_child(make_button("⚙  SETTINGS", show_settings))

	var info := Label.new()
	info.text = "Build your own worlds.\nCreate games.\nPublish them.\nPlay with friends."
	info.position = Vector2(650, 230)
	info.add_theme_font_size_override("font_size", 28)
	info.modulate = Color("#c3cee1")
	root_ui.add_child(info)

# =========================
# DISCOVER
# =========================

func show_discover():
	base_screen("DISCOVER", "Choose a game")

	var heading := Label.new()
	heading.text = "%d published game(s)" % games.size()
	heading.add_theme_font_size_override("font_size", 23)
	content.add_child(heading)

	if games.is_empty():
		var empty := Label.new()
		empty.text = "No games yet.\nCreate your first game in Studio!"
		empty.add_theme_font_size_override("font_size", 24)
		empty.modulate = Color("#9aa8c2")
		content.add_child(empty)
		return

	for game in games:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 75)

		var label := Label.new()
		label.text = "%s\nby %s" % [
			game.get("name", "Untitled"),
			game.get("creator", "Unknown")
		]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 20)

		row.add_child(label)

		var play := make_button(
			"PLAY",
			func(): launch_game(game),
			150,
			55
		)

		row.add_child(play)
		content.add_child(row)

# =========================
# CREATE
# =========================

func show_create():
	base_screen("CREATE GAME", "Create something new")

	var name := LineEdit.new()
	name.placeholder_text = "Game name"
	name.custom_minimum_size = Vector2(600, 55)
	name.add_theme_font_size_override("font_size", 20)
	content.add_child(name)

	var description := LineEdit.new()
	description.placeholder_text = "Description"
	description.custom_minimum_size = Vector2(600, 55)
	content.add_child(description)

	content.add_child(
		make_button(
			"CREATE",
			func():
				var game_name := name.text.strip_edges()

				if game_name.is_empty():
					game_name = "My BlockWorld Game"

				current_game = {
					"name": game_name,
					"description": description.text,
					"creator": player_name,
					"blocks": []
				}

				current_blocks = []
				show_studio()
		)
	)

# =========================
# STUDIO
# =========================

func show_studio():
	base_screen("STUDIO", "Build your game")

	var game_label := Label.new()
	game_label.text = "GAME: %s" % current_game.get("name", "New Game")
	game_label.add_theme_font_size_override("font_size", 25)
	content.add_child(game_label)

	var description := Label.new()
	description.text = current_game.get("description", "")
	description.modulate = Color("#9aa8c2")
	content.add_child(description)

	content.add_child(
		make_button("＋  ADD BLOCK", add_block)
	)

	content.add_child(
		make_button("💾  SAVE & PUBLISH", publish_game)
	)

	content.add_child(
		make_button("▶  TEST GAME", test_game)
	)

	content.add_child(
		make_button("🌐  HOST LAN GAME", host_game)
	)

	content.add_child(
		make_button("🔗  JOIN LAN GAME", join_game)
	)

	var stats := Label.new()
	stats.text = "Blocks: %d\nStatus: %s" % [
		current_blocks.size(),
		status_text
	]
	stats.modulate = Color("#9aa8c2")
	stats.add_theme_font_size_override("font_size", 18)
	content.add_child(stats)

func add_block():
	current_blocks.append({
		"position": [
			current_blocks.size() % 10,
			0,
			int(current_blocks.size() / 10)
		]
	})

	status_text = "Block added."
	show_studio()

func publish_game():
	current_game["blocks"] = current_blocks.duplicate(true)
	current_game["creator"] = player_name

	var replaced := false

	for i in range(games.size()):
		if games[i].get("name") == current_game.get("name"):
			games[i] = current_game.duplicate(true)
			replaced = true
			break

	if not replaced:
		games.append(current_game.duplicate(true))

	save_games()

	status_text = "Published!"
	show_discover()

func test_game():
	if current_game.is_empty():
		status_text = "Create a game first."
		show_studio()
		return

	launch_game(current_game)

# =========================
# GAME WORLD
# =========================

func launch_game(game: Dictionary):
	current_game = game.duplicate(true)
	current_blocks = game.get("blocks", []).duplicate(true)
	start_world()

func start_world():
	clear_ui()

	var world := Node3D.new()
	world.name = "GameWorld"
	root_ui.add_child(world)

	var camera := Camera3D.new()
	camera.position = Vector3(8, 8, 12)
	camera.look_at(Vector3(5, 0, 5))
	world.add_child(camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 1.3
	world.add_child(light)

	# Ground
	for x in range(12):
		for z in range(12):
			create_block(
				world,
				Vector3(x, -1, z),
				Color("#28344d")
			)

	# Player-created blocks
	for block in current_blocks:
		var p = block.get("position", [0, 0, 0])

		create_block(
			world,
			Vector3(p[0], p[1], p[2]),
			Color("#5da9ff")
		)

	var ui := CanvasLayer.new()
	world.add_child(ui)

	var panel := ColorRect.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(430, 125)
	panel.color = Color(0.04, 0.06, 0.1, 0.92)
	ui.add_child(panel)

	var info := Label.new()
	info.text = "%s\n%s\n\nESC = Main Menu" % [
		current_game.get("name", "Game"),
		current_game.get("description", "")
	]
	info.position = Vector2(35, 32)
	info.add_theme_font_size_override("font_size", 18)
	ui.add_child(info)

func create_block(parent: Node3D, position: Vector3, color: Color):
	var block := MeshInstance3D.new()

	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE

	block.mesh = mesh
	block.position = position

	var material := StandardMaterial3D.new()
	material.albedo_color = color

	block.material_override = material

	parent.add_child(block)

# =========================
# SETTINGS
# =========================

func show_settings():
	base_screen("SETTINGS", "Player settings")

	var name_edit := LineEdit.new()
	name_edit.text = player_name
	name_edit.placeholder_text = "Player name"
	name_edit.custom_minimum_size = Vector2(500, 55)
	content.add_child(name_edit)

	content.add_child(
		make_button(
			"SAVE",
			func():
				if not name_edit.text.strip_edges().is_empty():
					player_name = name_edit.text.strip_edges()

				show_menu()
		)
	)

# =========================
# SAVE SYSTEM
# =========================

func load_games():
	if not FileAccess.file_exists(SAVE_PATH):
		games = []
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	if data is Array:
		games = data

func save_games():
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(games))

# =========================
# MULTIPLAYER
# =========================

func host_game():
	var peer := ENetMultiplayerPeer.new()

	var error := peer.create_server(
		PORT,
		MAX_PLAYERS
	)

	if error != OK:
		status_text = "Could not host: %s" % error
		show_studio()
		return

	multiplayer.multiplayer_peer = peer

	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)

	status_text = "Hosting LAN game on port %d" % PORT
	show_studio()

func join_game():
	var ip := "127.0.0.1"

	var peer := ENetMultiplayerPeer.new()

	var error := peer.create_client(
		ip,
		PORT
	)

	if error != OK:
		status_text = "Could not connect."
	else:
		multiplayer.multiplayer_peer = peer
		status_text = "Connecting to %s..." % ip

	show_studio()

func _player_connected(id: int):
	status_text = "Player %d joined." % id

func _player_disconnected(id: int):
	status_text = "Player %d left." % id

# =========================
# INPUT
# =========================

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			show_menu()
