extends CharacterBody3D

@export var speed := 3.3
@export var sprint_speed := 4.8
@export var mouse_sensitivity := 0.0022
@export var acceleration := 14.0
@export var deceleration := 18.0
@export var air_control := 4.0
@onready var head: Node3D = $Head

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Поворот взгляда. Вынесен из обработчика мыши, потому что на телефоне его
# зовёт перетаскивание пальцем: правило ограничения наклона должно быть одно
# на оба ввода, а не переписанное во второй раз рядом.
func apply_look(relative: Vector2) -> void:
	rotate_y(-relative.x * mouse_sensitivity)
	head.rotate_x(-relative.y * mouse_sensitivity)
	head.rotation.x = clamp(head.rotation.x, -1.45, 1.45)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_look((event as InputEventMouseMotion).relative)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y -= 9.8 * delta
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var target := sprint_speed if Input.is_action_pressed("sprint") else speed
	var desired := direction * target
	var response := acceleration if not direction.is_zero_approx() else deceleration
	if not is_on_floor(): response = air_control
	velocity.x = move_toward(velocity.x, desired.x, response * delta)
	velocity.z = move_toward(velocity.z, desired.z, response * delta)
	move_and_slide()
