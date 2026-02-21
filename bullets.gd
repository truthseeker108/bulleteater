extends Node2D

const BULLET_COUNT = 100
const RED_BULLET_COUNT = 10
const PINK_BULLET_COUNT = 5   # életet adó rózsaszín golyók száma
const SPEED_MIN = 20
const SPEED_MAX = 80
const bullet_image := preload("res://bullet.png")

var bullets := []
var shape := RID()
var eaten_count := 0
var white_total := 0
var game_won := false

@onready var player_node = $"../Player"  # igazítsd a node nevéhez!

class Bullet:
	var position := Vector2()
	var speed := 1.0
	var color := Color.WHITE  # WHITE, RED, vagy PINK
	var body := RID()

func _ready() -> void:
	shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape, 8)
	white_total = BULLET_COUNT - RED_BULLET_COUNT - PINK_BULLET_COUNT
	for i in BULLET_COUNT:
		var bullet := Bullet.new()
		bullet.speed = randf_range(SPEED_MIN, SPEED_MAX)
		if i < RED_BULLET_COUNT:
			bullet.color = Color.RED
		elif i < RED_BULLET_COUNT + PINK_BULLET_COUNT:
			bullet.color = Color.HOT_PINK
		else:
			bullet.color = Color.WHITE
		bullet.body = PhysicsServer2D.body_create()
		PhysicsServer2D.body_set_space(bullet.body, get_world_2d().get_space())
		PhysicsServer2D.body_add_shape(bullet.body, shape)
		PhysicsServer2D.body_set_collision_mask(bullet.body, 0)
		bullet.position = Vector2(
			randf_range(0, get_viewport_rect().size.x) + get_viewport_rect().size.x,
			randf_range(0, get_viewport_rect().size.y)
		)
		var transform2d := Transform2D()
		transform2d.origin = bullet.position
		PhysicsServer2D.body_set_state(bullet.body, PhysicsServer2D.BODY_STATE_TRANSFORM, transform2d)
		bullets.push_back(bullet)

func _process(_delta: float) -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	if game_won:
		return
	var transform2d := Transform2D()
	var offset := get_viewport_rect().size.x + 16
	for bullet: Bullet in bullets:
		bullet.position.x -= bullet.speed * delta
		if bullet.position.x < -16:
			bullet.position.x = offset
		transform2d.origin = bullet.position
		PhysicsServer2D.body_set_state(bullet.body, PhysicsServer2D.BODY_STATE_TRANSFORM, transform2d)

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var offset := -bullet_image.get_size() * 0.5
	for bullet: Bullet in bullets:
		draw_texture(bullet_image, bullet.position + offset, bullet.color)

	# Státuszsáv háttér
	var bar_height := 36.0
	draw_rect(Rect2(0, viewport_size.y - bar_height, viewport_size.x, bar_height), Color(0, 0, 0, 0.7))

	# Megevett golyók száma
	var status_text := "Megevett: %d / %d" % [eaten_count, white_total]
	draw_string(ThemeDB.fallback_font, Vector2(12, viewport_size.y - 10), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

	# Életek megjelenítése
	var lives_text := "Életek: %d" % player_node.lives
	draw_string(ThemeDB.fallback_font, Vector2(viewport_size.x * 0.5 - 50, viewport_size.y - 10), lives_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.HOT_PINK)

	# Győztes felirat
	if game_won:
		draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y), Color(0, 0, 0, 0.5))
		draw_string(ThemeDB.fallback_font, Vector2(viewport_size.x * 0.5 - 80, viewport_size.y * 0.5), "Győztél! 🎉", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color.YELLOW)

# Visszatér: 0 = fehér, 1 = piros, 2 = rózsaszín
func remove_bullet(body_rid: RID) -> int:
	for i in range(bullets.size() - 1, -1, -1):
		if bullets[i].body == body_rid:
			var bullet_color: Color = bullets[i].color  # explicit típus
			PhysicsServer2D.free_rid(bullets[i].body)
			bullets.remove_at(i)
			if bullet_color == Color.WHITE:
				eaten_count += 1
				_check_win()
				return 0
			elif bullet_color == Color.RED:
				return 1
			else:
				return 2
	return -1

func _check_win() -> void:
	for bullet: Bullet in bullets:
		if bullet.color == Color.WHITE:
			return
	game_won = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()

func _exit_tree() -> void:
	for bullet: Bullet in bullets:
		PhysicsServer2D.free_rid(bullet.body)
	PhysicsServer2D.free_rid(shape)
	bullets.clear()
