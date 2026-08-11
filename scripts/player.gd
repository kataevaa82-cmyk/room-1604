extends CharacterBody3D

@export var speed := 3.3
@export var sprint_speed := 4.8
@export var mouse_sensitivity := 0.0022
@export var acceleration := 14.0
@export var deceleration := 18.0
@export var air_control := 4.0
@onready var head: Node3D = $Head

var step_player: AudioStreamPlayer
var carpet_step: AudioStreamWAV
var tile_step: AudioStreamWAV
var walked_since_step := 0.0
var previous_position := Vector3.ZERO
var left_step := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	previous_position = global_position
	if DisplayServer.get_name() != "headless":
		build_footsteps()

# Собственные шаги — единственный новый событийный звук. Они тихие, полностью
# зависят от движения игрока и потому не могут читаться как чужое присутствие.
# Оба коротких сэмпла создаются в памяти, внешних WAV/OGG в пакете нет.
func build_footsteps() -> void:
	carpet_step = make_step(false)
	tile_step = make_step(true)
	step_player = AudioStreamPlayer.new()
	step_player.name = "PlayerFootstep"
	step_player.volume_db = -25.0
	add_child(step_player)

func make_step(on_tile: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 16000
	wav.stereo = false
	var duration := .105 if on_tile else .125
	var frames := int(wav.mix_rate * duration)
	var samples := PackedByteArray()
	samples.resize(frames)
	var low := 0.0
	for i in range(frames):
		var progress := float(i) / float(frames)
		var raw := fmod(absf(sin(float(i) * 8.731) * 23841.317), 1.0) * 2.0 - 1.0
		low = lerpf(low, raw, .10 if on_tile else .045)
		var envelope := sin(PI * progress) * exp(-progress * (3.8 if on_tile else 2.8))
		var sole := sin(TAU * (92.0 if on_tile else 58.0) * float(i) / float(wav.mix_rate))
		var value := (low * (9.0 if on_tile else 6.0) + sole * (4.0 if on_tile else 5.0)) * envelope
		samples[i] = int(clampf(128.0 + value, 0.0, 255.0))
	wav.data = samples
	return wav

func play_footstep() -> void:
	if not step_player:
		return
	var bathroom_tile := global_position.x < -1.95 and global_position.z > -.95
	step_player.stream = tile_step if bathroom_tile else carpet_step
	left_step = not left_step
	step_player.pitch_scale = 1.025 if left_step else .975
	step_player.volume_db = -26.0 if bathroom_tile else -24.5
	step_player.play()

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
	var moved := Vector2(global_position.x - previous_position.x, global_position.z - previous_position.z).length()
	previous_position = global_position
	if is_on_floor() and not direction.is_zero_approx() and moved < 1.0:
		walked_since_step += moved
		var stride := .92 if Input.is_action_pressed("sprint") else .74
		if walked_since_step >= stride:
			walked_since_step = 0.0
			play_footstep()
	elif direction.is_zero_approx():
		walked_since_step = minf(walked_since_step, .25)
