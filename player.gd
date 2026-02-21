extends Node2D

const PINK_LIVES := 5  # ennyi életet ad egy rózsaszín golyó

var lives := 3
var is_dead := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bullets_node = $"../Bullets"  # igazítsd a node nevéhez!

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	sprite.scale = Vector2(0.25, 0.25)

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseMotion:
		position = event.position - Vector2(0, 16)

func _on_body_shape_entered(_body_id: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if is_dead:
		return
	var result: int = bullets_node.remove_bullet(_body_id)
	if result == 1:  # piros golyó
		lives -= 1
		if lives <= 0:
			_die()
		else:
			# Villogás jelzi az életerő csökkenést
			sprite.frame = 1
			await get_tree().create_timer(0.3).timeout
			sprite.frame = 0
	elif result == 2:  # rózsaszín golyó
		lives += PINK_LIVES

func _on_body_shape_exited(_body_id: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	pass

func _die() -> void:
	is_dead = true
	sprite.frame = 1
	sprite.modulate = Color.RED
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
