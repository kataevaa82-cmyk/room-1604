extends Node3D

## Central state machine for Room 1604 / Limbo.
enum LimboState { INTRO, TV_CLUE, BATHROOM_CLUE, FIND_CLOCK_KEY, ROOM_CHANGED, CLOCK_ATTEMPT, RESTORE_ROOM, CLOCK_RUNNING, FINAL_CARD, EXIT_UNLOCKED, COMPLETE }
enum DoorState { LOCKED, FINAL_LOCK, UNLOCKED }
enum ClockState { STOPPED_1604, KEY_INSERTED_BUT_BLOCKED, RUNNING_TO_1605, FINISHED_1605 }
enum TelevisionState { OFF, FIRST_HINT, STATIC, RESTORE_HINT, FINAL_ANOMALY, OFF_FINAL }

@export var debug_limbo := false
@export var intro_delay := 75.0
@export var hint_soft_delay := 45.0
@export var hint_clear_delay := 90.0
@export var hint_obvious_delay := 150.0

var state := LimboState.INTRO
var door_state := DoorState.LOCKED
var clock_state := ClockState.STOPPED_1604
var television_state := TelevisionState.OFF
var timer_since_progress := 0.0
var intro_elapsed := 0.0
var door_attempts := 0
var has_clock_key := false
var final_card_taken := false
var restored_objects := 0
var curtains_closed := false
var lamps_off := [false, false]
var faucet_running := false
var interaction_lock := false
var door_feedback_cooldown := 0.0
var clock_attempt_count := 0
var drip_timer := 0.0
var desk_flash_count := 0
var clock_seconds := 4.0 * 60.0
var final_elapsed := 0.0
var final_event := -1
var level_elapsed := 0.0
var state_elapsed := 0.0
var completion_elapsed := 0.0
var door_opened := false
var exit_fade_started := false
var original := {}
var restored := {"chair":false, "wardrobe":false, "painting":false, "phone":false, "pillow":false}

var player: CharacterBody3D
var camera: Camera3D
var interaction_ray: RayCast3D
var aimed_target := ""
var crosshair: Control
var crosshair_active := false
var prompt: Label
var message: Label
var debug_label: Label
var fade: ColorRect
var tv_text: Label3D
var tv_static_mesh: MeshInstance3D
var mirror_text: Label3D
var mirror_fog: MeshInstance3D
var mirror_fog_material: StandardMaterial3D
var clock_text: Label3D
var key_prop: Node3D
var key_highlight: OmniLight3D
var inserted_key_prop: Node3D
var pillow_prop: Node3D
var card_prop: Node3D
var wardrobe_door: Node3D
var wardrobe_model: Node3D
var wardrobe_proxy: Node3D
var exit_darkness: MeshInstance3D
var chair: Node3D
var painting: Node3D
var phone: Node3D
var phone_proxy_base: Node3D
var handset_prop: Node3D
var entrance_door: Node3D
var door_handle_proxy: Node3D
var door_handle_lever: Node3D
var entrance_collision: StaticBody3D
var entrance_details: Array[Node3D] = []
var world_environment: WorldEnvironment
var lamp_lights: Array[OmniLight3D] = []
var desk_final_light: OmniLight3D
var bed_lamp_meshes := []
var lamp_off_material: StandardMaterial3D
var room_lights: Array[Light3D] = []
var room_light_energy: Array[float] = []
var ambient_player: AudioStreamPlayer
var cue_streams := {}
var zones := {}
var room_light_groups := {}
var room_switch_on := {"switch_hall":true, "switch_bedroom":true, "switch_bathroom":true, "switch_living":true}
var tv_power_on := false
var tv_screen_requested := false
var tv_puzzle_completing := false
var mirror_clue_available := false
var mirror_clue_visible := false
var hint_stage := 0
var sequence_epoch := 0
var message_tween: Tween

func _ready() -> void:
	player = get_parent().get_node("Player")
	camera = player.get_node("Head/Camera3D")
	interaction_ray = RayCast3D.new()
	interaction_ray.name = "LimboInteractionRay"
	interaction_ray.target_position = Vector3(0, 0, -3.15)
	interaction_ray.collide_with_areas = true
	interaction_ray.collide_with_bodies = true
	interaction_ray.collision_mask = 3 # World geometry on layer 1, interaction areas on layer 2.
	interaction_ray.enabled = true
	camera.add_child(interaction_ray)
	world_environment = get_parent().get_node("Environment")
	cache_room_nodes()
	build_runtime_props()
	build_interaction_zones()
	build_ui()
	full_reset()
	var qa_phase := OS.get_environment("LIMBO_QA_PHASE")
	if not qa_phase.is_empty():
		apply_qa_phase(qa_phase)
	elif OS.has_environment("LIMBO_DEBUG_AUDIT"):
		debug_limbo = true; await get_tree().process_frame; run_debug_audit()
	elif OS.has_environment("LIMBO_EXPORT_AUDIT"):
		await get_tree().process_frame; run_export_audit()
	elif OS.has_environment("LIMBO_RAY_AUDIT"):
		await get_tree().physics_frame; assert_interaction_visibility(); prepare_shutdown(); await get_tree().create_timer(.35).timeout; get_tree().quit()
	elif OS.has_environment("LIMBO_AUDIT"):
		await get_tree().process_frame
		run_limbo_audit()
	else:
		show_message("ЛИМБ\nКомната 1604", 3.5)
		show_controls_once()

func show_controls_once() -> void:
	var epoch := sequence_epoch
	await get_tree().create_timer(4.5).timeout
	if epoch != sequence_epoch: return
	if state == LimboState.INTRO:
		show_message("WASD — движение   ·   Мышь — взгляд   ·   E — взаимодействие", 4.0)

func cache_room_nodes() -> void:
	chair = get_parent().find_child("BedroomReadingChair", true, false)
	painting = get_parent().find_child("MeaningfulBedPainting", true, false)
	phone = get_parent().find_child("VintageTelephone", true, false)
	wardrobe_model = get_parent().find_child("Wardrobe", true, false)
	entrance_door = get_parent().find_child("EntranceDoorModel", true, false)
	entrance_collision = get_parent().find_child("EntranceDoorCollision", true, false)
	for detail_name in ["Peephole", "RoomNumberPlate", "RoomNumber1604"]:
		var detail := get_parent().find_child(detail_name, true, false) as Node3D
		if detail: entrance_details.append(detail)
	# Give fitted model roots local pivots before gameplay rotations.
	move_pivot(chair, Vector3(3.48, 0, .15))
	move_pivot(painting, Vector3(1.25, 1.88, -3.08))
	move_pivot(phone, Vector3(2.61, .56, -2.78))
	move_pivot(entrance_door, Vector3(-3.10, 0, -3.13))
	for node in get_tree().get_nodes_in_group("downloaded_models"):
		if node.name == "BedLamp": pass
	for node in get_parent().find_children("*", "Light3D", true, false): room_lights.append(node); room_light_energy.append(node.light_energy)
	cache_room_light_groups()
	original.chair = chair.transform
	original.painting = painting.transform
	original.phone = phone.transform
	original.door = entrance_door.transform
	original.curtain_left = get_parent().get_node("HotelSuite/LivingRoom/CurtainLeft").transform
	original.curtain_right = get_parent().get_node("HotelSuite/LivingRoom/CurtainRight").transform
	original.player = player.transform
	door_handle_proxy = Node3D.new(); door_handle_proxy.name = "GameplayDoorHandle"; door_handle_proxy.position = Vector3(.73,1.08,.15); entrance_door.add_child(door_handle_proxy)
	make_box(door_handle_proxy,"HandlePlate",Vector3(.055,0,0),Vector3(.035,.15,.025),Color("7b5527")); door_handle_lever = Node3D.new(); door_handle_lever.name = "MovingLever"; door_handle_proxy.add_child(door_handle_lever); make_box(door_handle_lever,"HandleLever",Vector3(-.055,0,.025),Vector3(.18,.035,.035),Color("9a7038")); original.door_handle = door_handle_proxy.transform; original.door_lever = door_handle_lever.transform
	lamp_off_material = StandardMaterial3D.new(); lamp_off_material.albedo_color = Color("181512"); lamp_off_material.roughness = .9
	for side_name in ["BedsideTableLeft", "BedsideTableRight"]:
		var lamp_root := get_parent().get_node("HotelSuite/Bedroom/%s/BedLamp" % side_name)
		bed_lamp_meshes.append(lamp_root.find_children("*", "MeshInstance3D", true, false))

func cache_room_light_groups() -> void:
	var names := {
		"switch_hall":["HallAmber"],
		"switch_bedroom":["BedroomAmber", "BedroomMoonFill"],
		"switch_bathroom":["BathroomSconce", "BathroomSoftFill"],
		"switch_living":["LivingAmber", "LivingSoftFill", "LivingMoonFill"]
	}
	for switch_id in names:
		var lights: Array[Light3D] = []
		for light_name in names[switch_id]:
			var light := get_parent().find_child(light_name, true, false) as Light3D
			if light: lights.append(light)
		room_light_groups[switch_id] = lights

func build_runtime_props() -> void:
	clock_text = make_label3d("ClockDisplay", "16:04", Vector3(2.28, 1.74, .915), Vector3.ZERO, 48, .0032)
	tv_static_mesh = make_box(self, "TelevisionStatic", Vector3(-1.725, 1.28, 3.15), Vector3(.012,.60,.98), Color("080a0c"))
	var static_shader := Shader.new()
	static_shader.code = "shader_type spatial; render_mode unshaded; float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);} void fragment(){float n=hash(floor(UV*vec2(180.0,110.0))+floor(TIME*18.0)); float scan=step(.92,fract(UV.y*85.0-TIME*4.0)); vec3 c=vec3(.018+n*.10+scan*.035); ALBEDO=c; EMISSION=c*.35;}"
	var static_material := ShaderMaterial.new(); static_material.shader = static_shader; tv_static_mesh.material_override = static_material; tv_static_mesh.visible = false
	tv_text = make_label3d("TelevisionMessage", "", Vector3(-1.715, 1.32, 3.15), Vector3(0, PI / 2.0, 0), 29, .00275)
	tv_text.modulate = Color("d8ded7")
	mirror_text = make_label3d("MirrorMessage", "", Vector3(-4.12, 1.7, -.30), Vector3(0, PI / 2.0, 0), 30, .0025)
	mirror_text.modulate = Color("342f2a")
	mirror_fog = make_box(self, "MirrorFog", Vector3(-4.145, 1.69, -.30), Vector3(.012, .82, .68), Color(1,1,1,0))
	mirror_fog_material = mirror_fog.material_override as StandardMaterial3D
	mirror_fog_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mirror_fog_material.albedo_color = Color(0.82, 0.84, 0.80, 0.0)
	mirror_fog_material.roughness = 1.0

	key_prop = Node3D.new(); key_prop.name = "ClockKey"; add_child(key_prop)
	make_box(key_prop, "KeyStem", Vector3(1.25, .17, -1.02), Vector3(.035, .035, .20), Color("b99555"))
	make_torus(key_prop, "KeyRing", Vector3(1.25, .17, -.91), .035, .055, Color("b99555"), Vector3(PI / 2.0, 0, 0))
	key_highlight = OmniLight3D.new(); key_highlight.name = "ClockKeyHighlight"; key_highlight.position = Vector3(1.25,.24,-.91); key_highlight.light_color = Color("d9b56d"); key_highlight.light_energy = .18; key_highlight.omni_range = .65; add_child(key_highlight)
	inserted_key_prop = Node3D.new(); inserted_key_prop.name = "InsertedClockKey"; inserted_key_prop.position = Vector3(2.28,1.52,.955); add_child(inserted_key_prop)
	make_box(inserted_key_prop,"InsertedStem",Vector3(0,-.07,0),Vector3(.025,.15,.025),Color("b99555")); make_torus(inserted_key_prop,"InsertedRing",Vector3(0,.035,0),.025,.045,Color("b99555"),Vector3(PI/2.0,0,0)); original.inserted_key = inserted_key_prop.transform; inserted_key_prop.visible = false

	pillow_prop = Node3D.new(); pillow_prop.name = "LimboPillow"; pillow_prop.position = Vector3(1.25, .93, -2.55); add_child(pillow_prop)
	var pillow_mesh := make_sphere(pillow_prop, "Pillow", Vector3.ZERO, .5, Color("c9bea9")); pillow_mesh.scale = Vector3(.62,.16,.36)
	original.pillow = pillow_prop.transform

	wardrobe_proxy = Node3D.new(); wardrobe_proxy.name = "WardrobeAnomalyProxy"; add_child(wardrobe_proxy)
	make_box(wardrobe_proxy,"CabinetBack",Vector3(-1.76,1.05,-.15),Vector3(.05,2.0,1.1),Color("25150e")); make_box(wardrobe_proxy,"CabinetTop",Vector3(-1.50,2.04,-.15),Vector3(.55,.08,1.1),Color("3d2417")); make_box(wardrobe_proxy,"CabinetBottom",Vector3(-1.50,.06,-.15),Vector3(.55,.08,1.1),Color("3d2417")); make_box(wardrobe_proxy,"CabinetSideA",Vector3(-1.50,1.05,-.68),Vector3(.55,2.0,.06),Color("3d2417")); make_box(wardrobe_proxy,"CabinetSideB",Vector3(-1.50,1.05,.38),Vector3(.55,2.0,.06),Color("3d2417"))
	wardrobe_door = Node3D.new(); wardrobe_door.name = "WardrobeDoor"; wardrobe_door.position = Vector3(-1.22, 1.12, -.68); wardrobe_proxy.add_child(wardrobe_door)
	make_box(wardrobe_door, "DoorLeaf", Vector3(0,0,.25), Vector3(.035, 1.75, .50), Color("3d2417"))
	original.wardrobe = wardrobe_door.transform
	wardrobe_proxy.visible = false

	phone_proxy_base = Node3D.new(); phone_proxy_base.name = "PhoneBaseProxy"; add_child(phone_proxy_base)
	make_box(phone_proxy_base, "Base", Vector3(2.61,.64,-2.78), Vector3(.25,.12,.19), Color("10100f")); make_torus(phone_proxy_base,"Dial",Vector3(2.61,.71,-2.72),.025,.055,Color("4c4438"),Vector3.ZERO); phone_proxy_base.visible = false
	handset_prop = Node3D.new(); handset_prop.name = "PhoneHandset"; handset_prop.position = Vector3(2.61,.77,-2.78); add_child(handset_prop)
	make_capsule(handset_prop, "Receiver", Vector3.ZERO, .055, .30, Color("0b0b0a"), Vector3(0,0,PI/2.0)); original.handset = handset_prop.transform; handset_prop.visible = false
	make_sphere(handset_prop,"ReceiverLeft",Vector3(-.12,0,0),.075,Color("0b0b0a")); make_sphere(handset_prop,"ReceiverRight",Vector3(.12,0,0),.075,Color("0b0b0a"))

	card_prop = Node3D.new(); card_prop.name = "RoomCard1604"; card_prop.position = Vector3(4.10, .795, 1.85); add_child(card_prop)
	make_box(card_prop, "Card", Vector3.ZERO, Vector3(.22, .014, .14), Color("bba77e"))
	var card_label := make_label3d("CardNumber", "1604", Vector3(0, .009, 0), Vector3(-PI / 2.0, 0, 0), 32, .0016, card_prop)
	card_label.modulate = Color("32251b")
	var card_back := make_label3d("CardCheckout", "ВЫЕЗД\n16:05", Vector3(0,-.009,0), Vector3(PI/2.0,0,0), 18, .00125, card_prop); card_back.modulate = Color("32251b")

	for i in range(2):
		var light := OmniLight3D.new(); light.name = "BedsideGameplayLight%d" % i
		light.position = Vector3(0.0 if i == 0 else 2.37, 1.20, -2.82); light.light_color = Color("ffd09a"); light.light_energy = .38; light.omni_range = 2.2; add_child(light); lamp_lights.append(light)
	desk_final_light = OmniLight3D.new(); desk_final_light.name = "DeskFinalFlash"; desk_final_light.position = Vector3(4.0,1.20,1.12); desk_final_light.light_color = Color("ffd09a"); desk_final_light.light_energy = .55; desk_final_light.omni_range = 1.45; desk_final_light.shadow_enabled = false; desk_final_light.visible = false; add_child(desk_final_light)

	exit_darkness = make_box(self, "ExitDarkness", Vector3(-2.65, 1.15, -3.23), Vector3(.95, 2.3, .05), Color("000000"))
	exit_darkness.visible = false
	build_ambient_hum()

func build_interaction_zones() -> void:
	add_zone("door", Vector3(-2.65, 1.05, -2.88), Vector3(.8, 1.9, .35))
	add_zone("curtains", Vector3(.8, 1.35, 5.25), Vector3(2.8, 2.4, .45))
	add_zone("lamp_left", Vector3(0, .95, -2.82), Vector3(.55, .85, .55))
	add_zone("lamp_right", Vector3(2.37, .95, -2.82), Vector3(.55, .85, .55))
	add_zone("faucet", Vector3(-3.93, 1.04, -.30), Vector3(.65, .55, .75))
	add_zone("clock", Vector3(2.28, 1.72, .67), Vector3(1.0, 1.15, .38))
	add_zone("key", Vector3(1.25, .18, -1.02), Vector3(.65, .35, .55))
	add_zone("chair", Vector3(3.48, .65, .15), Vector3(.9, 1.2, .9))
	add_zone("wardrobe", Vector3(-1.25, 1.05, -.15), Vector3(.45, 1.9, 1.1))
	add_zone("painting", Vector3(1.25, 1.88, -2.94), Vector3(1.1, .8, .3))
	add_zone("phone", Vector3(2.61, .78, -2.78), Vector3(.6, .5, .6))
	add_zone("pillow", Vector3(1.85, .34, -.65), Vector3(.8, .65, .7))
	add_zone("card", Vector3(4.10, .86, 1.85), Vector3(.40, .32, .40))
	add_zone("tv", Vector3(-1.63, 1.25, 3.15), Vector3(.45, 1.0, 1.4))
	add_zone("mirror", Vector3(-4.05, 1.72, -.30), Vector3(.38, .95, .85))
	add_zone("switch_hall", Vector3(-2.05, 1.18, -2.52), Vector3(.48, .58, .40))
	add_zone("switch_bedroom", Vector3(-1.72, 1.18, -1.15), Vector3(.42, .58, .48))
	add_zone("switch_bathroom", Vector3(-2.03, 1.18, .25), Vector3(.38, .58, .48))
	add_zone("switch_living", Vector3(.18, 1.18, .90), Vector3(.42, .58, .40))

func build_ui() -> void:
	var layer := CanvasLayer.new(); layer.name = "LimboUI"; add_child(layer)
	crosshair = Control.new(); crosshair.name = "Crosshair"; crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE; crosshair.set_anchors_preset(Control.PRESET_CENTER); crosshair.position = Vector2(-14,-14); crosshair.size = Vector2(28,28); crosshair.pivot_offset = Vector2(14,14); layer.add_child(crosshair)
	var horizontal := ColorRect.new(); horizontal.color = Color(1,1,1,.82); horizontal.position = Vector2(3,13); horizontal.size = Vector2(22,2); horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE; crosshair.add_child(horizontal)
	var vertical := ColorRect.new(); vertical.color = Color(1,1,1,.82); vertical.position = Vector2(13,3); vertical.size = Vector2(2,22); vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE; crosshair.add_child(vertical)
	prompt = Label.new(); prompt.name = "InteractionPrompt"; prompt.text = "[E]"; prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; prompt.add_theme_font_size_override("font_size", 20); prompt.set_anchors_preset(Control.PRESET_CENTER); prompt.position = Vector2(-70, 38); prompt.size = Vector2(140, 32); prompt.visible = false; layer.add_child(prompt)
	message = Label.new(); message.name = "RoomMessage"; message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; message.add_theme_font_size_override("font_size", 27); message.add_theme_color_override("font_color", Color("e3ddd1")); message.add_theme_color_override("font_shadow_color", Color(0,0,0,.9)); message.add_theme_constant_override("shadow_offset_x", 2); message.add_theme_constant_override("shadow_offset_y", 2); message.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); message.position = Vector2(-430, -145); message.size = Vector2(860, 70); message.modulate.a = 0.0; layer.add_child(message)
	debug_label = Label.new(); debug_label.position = Vector2(16,16); debug_label.add_theme_font_size_override("font_size",16); layer.add_child(debug_label)
	fade = ColorRect.new(); fade.color = Color.BLACK; fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); fade.mouse_filter = Control.MOUSE_FILTER_IGNORE; fade.modulate.a = 0.0; layer.add_child(fade)

func _process(delta: float) -> void:
	if state == LimboState.COMPLETE: return
	level_elapsed += delta
	state_elapsed += delta
	door_feedback_cooldown = maxf(0.0, door_feedback_cooldown - delta)
	if state == LimboState.BATHROOM_CLUE and not faucet_running:
		drip_timer -= delta
		if drip_timer <= 0.0: play_cue("drip"); drip_timer = 2.6
	intro_elapsed += delta
	timer_since_progress += delta
	if state == LimboState.INTRO and (door_attempts >= 2 or intro_elapsed >= intro_delay): start_tv_clue()
	if state == LimboState.CLOCK_RUNNING: update_final_countdown(delta)
	if state == LimboState.EXIT_UNLOCKED and door_opened and not exit_fade_started and player.global_position.z < -2.95 and absf(player.global_position.x + 2.65) < .65: complete_exit()
	update_aim_prompt()
	update_hints()
	update_debug()
	if Input.is_action_just_pressed("interact") and prompt.visible and not interaction_lock:
		if not aimed_target.is_empty(): interact(aimed_target)

func _unhandled_input(event: InputEvent) -> void:
	if not debug_limbo or not event is InputEventKey or not event.pressed: return
	if event.keycode == KEY_F6: debug_next_phase()
	if event.keycode == KEY_F8: full_reset()

func _exit_tree() -> void:
	prepare_shutdown()

func prepare_shutdown() -> void:
	if ambient_player: ambient_player.stop(); ambient_player.stream = null
	cue_streams.clear()

func aimed_zone() -> String:
	if not interaction_ray or not interaction_ray.is_colliding(): return ""
	var collider := interaction_ray.get_collider()
	if not collider is Area3D: return ""
	return str(collider.get_meta("interaction_id", ""))

func update_aim_prompt() -> void:
	aimed_target = aimed_zone()
	var reactive := not interaction_lock and not aimed_target.is_empty() and is_target_reactive(aimed_target)
	prompt.visible = reactive
	if reactive != crosshair_active:
		crosshair_active = reactive
		crosshair.modulate = Color("e8bf73") if reactive else Color("e8e2d8")
		crosshair.scale = Vector2(1.22,1.22) if reactive else Vector2.ONE

func is_target_reactive(id: String) -> bool:
	if id in ["door", "clock"]: return true
	if id == "tv": return state not in [LimboState.CLOCK_RUNNING, LimboState.COMPLETE]
	if id.begins_with("switch_"): return state not in [LimboState.CLOCK_RUNNING, LimboState.COMPLETE]
	if id in ["lamp_left", "lamp_right"]: return state not in [LimboState.CLOCK_RUNNING, LimboState.COMPLETE]
	if id == "mirror": return mirror_clue_available and state != LimboState.COMPLETE
	if id == "curtains": return state == LimboState.TV_CLUE
	if id == "faucet": return state == LimboState.BATHROOM_CLUE
	if id == "key": return state == LimboState.FIND_CLOCK_KEY and not has_clock_key
	if id in restored: return state == LimboState.RESTORE_ROOM and not restored[id]
	if id == "card": return state == LimboState.FINAL_CARD and not final_card_taken
	return false

func interact(id: String) -> void:
	if interaction_lock: return
	if id.begins_with("switch_"):
		toggle_room_light(id)
		return
	match id:
		"door": interact_door()
		"curtains": if state == LimboState.TV_CLUE and not curtains_closed: close_curtains()
		"lamp_left": toggle_bedside_lamp(0)
		"lamp_right": toggle_bedside_lamp(1)
		"faucet": if state == LimboState.BATHROOM_CLUE: start_faucet()
		"mirror": if mirror_clue_available: toggle_mirror_clue()
		"key": if state == LimboState.FIND_CLOCK_KEY and not has_clock_key: take_key()
		"clock": interact_clock()
		"chair", "wardrobe", "painting", "phone", "pillow": if state == LimboState.RESTORE_ROOM and not restored[id]: restore_object(id)
		"card": if state == LimboState.FINAL_CARD: take_card()
		"tv": toggle_tv_power()

func interact_door() -> void:
	if door_state == DoorState.UNLOCKED:
		open_exit()
		return
	door_attempts += 1
	if door_feedback_cooldown <= 0.0:
		door_feedback_cooldown = .35
		play_cue("locked")
		var tween := create_tween(); tween.tween_property(door_handle_lever, "rotation:z", -.38, .10).set_trans(Tween.TRANS_BACK); tween.tween_property(door_handle_lever, "rotation:z", 0.0, .13)
		show_message("Не открывается.", 1.8)
	if state == LimboState.INTRO and door_attempts >= 2: start_tv_clue()

func start_tv_clue() -> void:
	if state != LimboState.INTRO: return
	set_state(LimboState.TV_CLUE)
	television_state = TelevisionState.FIRST_HINT
	set_tv_power(true, true)
	update_tv_puzzle_display()
	play_cue("tv")
	show_message("Тишина любит закрытые шторы.", 3.5)

func close_curtains() -> void:
	curtains_closed = true
	var left := get_parent().get_node("HotelSuite/LivingRoom/CurtainLeft") as Node3D
	var right := get_parent().get_node("HotelSuite/LivingRoom/CurtainRight") as Node3D
	create_tween().set_parallel().tween_property(left, "position:x", .575, .65).set_trans(Tween.TRANS_SINE)
	create_tween().set_parallel().tween_property(right, "position:x", 1.025, .65).set_trans(Tween.TRANS_SINE)
	progress_tick(); check_tv_puzzle()

func switch_lamp(index: int) -> void:
	if lamps_off[index]: return
	set_bedside_lamp(index, false)
	if state == LimboState.TV_CLUE:
		progress_tick()
		check_tv_puzzle()

func toggle_bedside_lamp(index: int) -> void:
	if state in [LimboState.CLOCK_RUNNING, LimboState.COMPLETE]: return
	var turn_on: bool = lamps_off[index]
	set_bedside_lamp(index, turn_on)
	play_cue("switch")
	if state == LimboState.TV_CLUE:
		if not turn_on: progress_tick()
		check_tv_puzzle()

func set_bedside_lamp(index: int, turn_on: bool) -> void:
	lamps_off[index] = not turn_on
	lamp_lights[index].visible = turn_on
	for mesh in bed_lamp_meshes[index]: mesh.material_override = null if turn_on else lamp_off_material

func toggle_room_light(id: String) -> void:
	if not room_light_groups.has(id) or state in [LimboState.CLOCK_RUNNING, LimboState.COMPLETE]: return
	var turn_on := not bool(room_switch_on[id])
	room_switch_on[id] = turn_on
	for light: Light3D in room_light_groups[id]:
		var index := room_lights.find(light)
		if index >= 0: light.light_energy = room_light_energy[index] if turn_on else 0.0
	play_cue("switch")

func set_tv_power(powered: bool, screen_requested: bool) -> void:
	tv_power_on = powered
	tv_screen_requested = screen_requested
	apply_tv_power_visibility()

func apply_tv_power_visibility() -> void:
	tv_static_mesh.visible = tv_power_on and tv_screen_requested
	tv_text.visible = tv_power_on

func toggle_tv_power() -> void:
	if state in [LimboState.CLOCK_RUNNING, LimboState.COMPLETE]: return
	if tv_power_on:
		tv_power_on = false
		television_state = TelevisionState.OFF
	else:
		tv_power_on = true
		tv_screen_requested = true
		match state:
			LimboState.TV_CLUE:
				television_state = TelevisionState.FIRST_HINT
				update_tv_puzzle_display()
			LimboState.RESTORE_ROOM:
				television_state = TelevisionState.RESTORE_HINT
				tv_text.text = "ВЕРНИ ЕЙ ПАМЯТЬ"
			LimboState.FINAL_CARD:
				television_state = TelevisionState.STATIC
				tv_text.text = "16:05"
			_:
				television_state = TelevisionState.STATIC
				if state == LimboState.INTRO: tv_text.text = "16:04"
	apply_tv_power_visibility()
	play_cue("tv")

func check_tv_puzzle() -> void:
	if curtains_closed and lamps_off[0] and lamps_off[1]:
		if tv_puzzle_completing: return
		tv_puzzle_completing = true; interaction_lock = true
		var epoch := sequence_epoch
		set_tv_power(true, true); show_message("Теперь видно лучше.", 3.0); tv_text.text = "ТЕПЕРЬ ВИДНО ЛУЧШЕ"; play_cue("tv")
		await get_tree().create_timer(1.2).timeout
		if epoch != sequence_epoch: return
		tv_text.text = ""; set_tv_power(false, false); television_state = TelevisionState.OFF; tv_puzzle_completing = false; interaction_lock = false; set_state(LimboState.BATHROOM_CLUE); drip_timer = .1
	else:
		update_tv_puzzle_display()

func update_tv_puzzle_display() -> void:
	var curtain_icon := "■" if curtains_closed else "▯"
	var left_icon := "●" if lamps_off[0] else "○"
	var right_icon := "●" if lamps_off[1] else "○"
	tv_text.text = "ТИШИНА ЛЮБИТ\nЗАКРЫТЫЕ ШТОРЫ\n\n%s    %s    %s" % [curtain_icon,left_icon,right_icon]

func start_faucet() -> void:
	if faucet_running: return
	faucet_running = true; play_cue("water"); mirror_text.text = "ТО, ЧТО ИЩЕШЬ,\nНИЖЕ СНА."; mirror_clue_available = true
	set_mirror_clue_visible(true, 2.4)
	show_message("То, что ищешь, ниже сна.", 3.5); set_state(LimboState.FIND_CLOCK_KEY); key_prop.visible = true
	key_highlight.visible = true
	var epoch := sequence_epoch
	await get_tree().create_timer(4.0).timeout
	if epoch != sequence_epoch: return
	if state == LimboState.FIND_CLOCK_KEY: mirror_text.text += "\n\n▰\n↓"

func toggle_mirror_clue() -> void:
	if not mirror_clue_available: return
	set_mirror_clue_visible(not mirror_clue_visible, .38)
	play_cue("wipe")

func set_mirror_clue_visible(make_visible: bool, duration: float) -> void:
	mirror_clue_visible = make_visible
	mirror_text.visible = true
	var text_alpha := 1.0 if make_visible else 0.0
	var fog_alpha := .48 if make_visible else .12
	var fog_color := mirror_fog_material.albedo_color
	fog_color.a = fog_alpha
	var tween := create_tween().set_parallel()
	tween.tween_property(mirror_text, "modulate:a", text_alpha, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(mirror_fog_material, "albedo_color", fog_color, duration).set_trans(Tween.TRANS_SINE)

func take_key() -> void:
	has_clock_key = true; key_prop.visible = false; key_highlight.visible = false; play_cue("metal"); show_message("Не каждая дверь открывается ключом.", 3.5)
	set_state(LimboState.ROOM_CHANGED); blackout_and_change_room()

func blackout_and_change_room() -> void:
	var epoch := sequence_epoch
	interaction_lock = true; fade.modulate.a = 1.0; play_cue("flicker")
	await get_tree().create_timer(.85).timeout
	if epoch != sequence_epoch: return
	apply_room_anomaly()
	fade.modulate.a = 0.0; interaction_lock = false; set_state(LimboState.CLOCK_ATTEMPT)

func apply_room_anomaly() -> void:
	chair.rotation.y = original.chair.basis.get_euler().y + 1.35
	wardrobe_model.visible = false; wardrobe_proxy.visible = true; wardrobe_door.rotation.y = -1.2
	painting.rotation.z = .13
	phone.visible = false; phone_proxy_base.visible = true; handset_prop.visible = true; handset_prop.position = Vector3(2.35,.66,-2.58); handset_prop.rotation = Vector3(.08,.55,.18)
	pillow_prop.position = Vector3(1.85, .14, -.65); pillow_prop.rotation = Vector3(.08,.25,.20)

func apply_qa_phase(phase: String) -> void:
	match phase.to_lower():
		"tv": start_tv_clue()
		"lamps_off": start_tv_clue(); switch_lamp(0); switch_lamp(1)
		"mirror":
			set_state(LimboState.FIND_CLOCK_KEY); faucet_running = true; key_prop.visible = true; key_highlight.visible = true
			mirror_clue_available = true; mirror_clue_visible = true; mirror_text.visible = true; mirror_text.modulate.a = 1.0
			mirror_fog_material.albedo_color = Color(.82,.84,.80,.48); mirror_text.text = "ТО, ЧТО ИЩЕШЬ,\nНИЖЕ СНА.\n\n▰\n↓"
		"anomaly":
			has_clock_key = true; apply_room_anomaly(); set_state(LimboState.CLOCK_ATTEMPT)
		"clock_key":
			has_clock_key = true; apply_room_anomaly(); set_state(LimboState.CLOCK_ATTEMPT); interact_clock()
		"restore":
			has_clock_key = true; apply_room_anomaly(); set_state(LimboState.RESTORE_ROOM); television_state = TelevisionState.RESTORE_HINT; set_tv_power(true, true); tv_text.text = "ВЕРНИ ЕЙ ПАМЯТЬ"
		"final":
			clock_text.text = "16:05:00"; clock_text.font_size = 30; clock_state = ClockState.FINISHED_1605; door_state = DoorState.FINAL_LOCK; ambient_player.stop(); set_state(LimboState.FINAL_CARD)
		"exit":
			clock_text.text = "16:05:00"; final_card_taken = true; card_prop.visible = false; door_state = DoorState.UNLOCKED; set_state(LimboState.EXIT_UNLOCKED)
			entrance_door.rotation.y = -1.35; entrance_collision.collision_layer = 0; exit_darkness.visible = true; door_opened = true
			for detail in entrance_details: detail.visible = false

func interact_clock() -> void:
	if state == LimboState.CLOCK_ATTEMPT and has_clock_key:
		interaction_lock = true; clock_attempt_count += 1
		var epoch := sequence_epoch
		clock_state = ClockState.KEY_INSERTED_BUT_BLOCKED; inserted_key_prop.visible = true; inserted_key_prop.rotation.z = 0.0; create_tween().tween_property(inserted_key_prop,"rotation:z",.75,.65).set_trans(Tween.TRANS_BACK); play_cue("metal")
		for i in range(5):
			await get_tree().create_timer(.18).timeout
			if epoch != sequence_epoch: return
			play_cue("tick")
		show_message("Время не идёт в беспорядке.", 4.0); set_state(LimboState.RESTORE_ROOM); interaction_lock = false
		television_state = TelevisionState.RESTORE_HINT; set_tv_power(true, true); tv_text.text = "ВЕРНИ ЕЙ ПАМЯТЬ"; play_cue("tv")
	elif state == LimboState.INTRO:
		show_message("16:04\nВремя здесь не спешит.", 3.2)
	elif state < LimboState.CLOCK_ATTEMPT:
		show_message("16:04", 1.8)
	elif state == LimboState.RESTORE_ROOM:
		show_message("Время не идёт в беспорядке.", 2.5)

func restore_object(id: String) -> void:
	restored[id] = true; restored_objects += 1
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match id:
		"chair": tween.tween_property(chair, "transform", original.chair, .55)
		"wardrobe":
			tween.tween_property(wardrobe_door, "transform", original.wardrobe, .55)
			tween.finished.connect(finish_wardrobe_restore)
		"painting": tween.tween_property(painting, "transform", original.painting, .45)
		"phone":
			tween.tween_property(handset_prop, "transform", original.handset, .45)
			tween.finished.connect(finish_phone_restore)
		"pillow": tween.tween_property(pillow_prop, "transform", original.pillow, .55)
	progress_tick()
	if restored_objects < 5: tv_text.text = "ВЕРНИ ЕЙ ПАМЯТЬ"
	if restored_objects == 5: room_restored()

func finish_phone_restore() -> void:
	handset_prop.visible = false; phone_proxy_base.visible = false; phone.visible = true

func finish_wardrobe_restore() -> void:
	wardrobe_proxy.visible = false; wardrobe_model.visible = true

func room_restored() -> void:
	var epoch := sequence_epoch
	tv_text.text = ""; set_tv_power(false, false); television_state = TelevisionState.OFF
	interaction_lock = true
	await get_tree().create_timer(1.25).timeout
	if epoch != sequence_epoch: return
	play_cue("tick"); show_message("Теперь можно ждать.", 3.0)
	clock_state = ClockState.RUNNING_TO_1605; clock_seconds = 16.0 * 3600.0 + 4.0 * 60.0 + 52.0
	clock_text.font_size = 30
	set_state(LimboState.CLOCK_RUNNING); interaction_lock = false

func update_final_countdown(delta: float) -> void:
	final_elapsed += delta; clock_seconds = min(clock_seconds + delta, 16.0 * 3600.0 + 5.0 * 60.0)
	var second := int(clock_seconds) % 60; clock_text.text = "16:04:%02d" % second
	var event := int(final_elapsed)
	if event == final_event: return
	final_event = event
	if event >= 0 and event <= 6: play_cue("tick")
	match event:
		2: dim_room(.82)
		3: television_state = TelevisionState.FINAL_ANOMALY; set_tv_power(true, true); tv_text.text = "1604"; play_cue("tv")
		4: tv_text.text = "┌────────┐\n│  КОМНАТА  │\n└────────┘"
		5: tv_text.text = "КОМНАТА 1604\n\nКРЕСЛО  ↶"
		6: tv_text.text = ""; set_tv_power(false, false); television_state = TelevisionState.OFF_FINAL
		7: dim_room(.65); ambient_player.stop()
		8: finish_clock()

func finish_clock() -> void:
	var epoch := sequence_epoch
	clock_text.text = "16:05:00"; clock_state = ClockState.FINISHED_1605; play_cue("unlock"); door_state = DoorState.FINAL_LOCK
	desk_flash_count += 1; desk_final_light.visible = true
	await get_tree().create_timer(.12).timeout
	if epoch != sequence_epoch: return
	desk_final_light.visible = false
	card_prop.visible = true; set_state(LimboState.FINAL_CARD)

func take_card() -> void:
	if final_card_taken: return
	final_card_taken = true; interaction_lock = true; card_prop.visible = false; play_cue("card"); show_message("1604\nВыезд — 16:05", 4.0)
	var epoch := sequence_epoch
	await get_tree().create_timer(.55).timeout
	if epoch != sequence_epoch: return
	door_state = DoorState.UNLOCKED; set_state(LimboState.EXIT_UNLOCKED); play_cue("unlock"); interaction_lock = false

func open_exit() -> void:
	if state != LimboState.EXIT_UNLOCKED or door_opened: return
	var epoch := sequence_epoch
	interaction_lock = true; exit_darkness.visible = true
	for detail in entrance_details: detail.visible = false
	if entrance_collision: entrance_collision.collision_layer = 0; entrance_collision.collision_mask = 0
	create_tween().tween_property(entrance_door, "rotation:y", -1.35, 1.1).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1.2).timeout
	if epoch != sequence_epoch: return
	door_opened = true; interaction_lock = false
	show_message("За дверью нет коридора.", 2.5)

func complete_exit() -> void:
	if exit_fade_started or state != LimboState.EXIT_UNLOCKED: return
	exit_fade_started = true; interaction_lock = true
	var epoch := sequence_epoch
	create_tween().tween_property(fade, "modulate:a", 1.0, 1.4)
	await get_tree().create_timer(1.4).timeout
	if epoch != sequence_epoch: return
	completion_elapsed = level_elapsed; set_state(LimboState.COMPLETE); show_message("ЛИМБ", 2.0)

func show_tv_context() -> void:
	if state == LimboState.TV_CLUE: show_message("Тишина любит закрытые шторы.", 2.5)
	elif state == LimboState.RESTORE_ROOM: show_message("Верни ей память.", 2.5)

func update_hints() -> void:
	if state not in [LimboState.TV_CLUE, LimboState.FIND_CLOCK_KEY, LimboState.RESTORE_ROOM]: return
	var next_stage := 3 if timer_since_progress >= hint_obvious_delay else (2 if timer_since_progress >= hint_clear_delay else (1 if timer_since_progress >= hint_soft_delay else 0))
	if next_stage <= hint_stage: return
	hint_stage = next_stage
	if state == LimboState.TV_CLUE:
		if hint_stage == 1:
			if not curtains_closed: show_message("Ткань всё ещё помнит окно.", 3.0)
			else: flash_needed_lamp()
		else:
			set_tv_power(true, true); television_state = TelevisionState.STATIC
			var pending: Array[String] = []
			if not curtains_closed: pending.append("ШТОРЫ: ЗАКРЫТЬ")
			if not lamps_off[0]: pending.append("ЛЕВАЯ ЛАМПА: OFF")
			if not lamps_off[1]: pending.append("ПРАВАЯ ЛАМПА: OFF")
			tv_text.text = "\n".join(pending)
			if hint_stage == 3 and curtains_closed: flash_needed_lamp()
	elif state == LimboState.FIND_CLOCK_KEY:
		if hint_stage == 1: play_cue("metal")
		elif hint_stage == 2: set_tv_power(true, true); television_state = TelevisionState.STATIC; play_cue("tv"); tv_text.text = "КРОВАТЬ"
		else: set_tv_power(true, true); tv_text.text = "КРОВАТЬ\n↓"
	elif state == LimboState.RESTORE_ROOM:
		var id := next_unrestored()
		set_tv_power(true, true); television_state = TelevisionState.RESTORE_HINT
		if hint_stage == 1: tv_text.text = "КОМНАТА ПОМНИТ:\n" + object_display_name(id).to_upper()
		elif hint_stage == 2: show_message(hint_for(id), 3.5)
		else: pulse_zone(id)

func hint_for(id: String) -> String:
	return {"chair":"Некоторые вещи смотрят не туда.", "wardrobe":"Закрытое должно оставаться закрытым.", "painting":"Даже стены помнят прямые линии.", "phone":"Молчание должно лежать на месте.", "pillow":"Сон не любит беспорядка."}.get(id, "Верни ей память.")

func object_display_name(id: String) -> String:
	return {"chair":"кресло", "wardrobe":"шкаф", "painting":"картина", "phone":"телефон", "pillow":"подушка"}.get(id, "комната")

func next_unrestored() -> String:
	for id in ["chair", "wardrobe", "painting", "phone", "pillow"]:
		if not restored[id]: return id
	return ""

func flash_needed_lamp() -> void:
	var idx := 0 if not lamps_off[0] else 1
	if lamps_off[idx]: return
	lamp_lights[idx].light_energy = .9
	var tween := create_tween(); tween.tween_property(lamp_lights[idx], "light_energy", .38, .5)

func pulse_zone(id: String) -> void:
	var area: Area3D = zones.get(id)
	if not area: return
	var glow := OmniLight3D.new(); glow.name = "HintPulse"; glow.position = area.global_position; glow.light_color = Color("d8bd88"); glow.light_energy = .55; glow.omni_range = 1.15; glow.shadow_enabled = false; add_child(glow)
	var tween := create_tween(); tween.tween_property(glow, "light_energy", 0.0, 1.2); tween.finished.connect(glow.queue_free)
	show_message(hint_for(id), 3.5)

func progress_tick() -> void:
	timer_since_progress = 0.0; hint_stage = 0; play_cue("tick")

func set_state(next_state: LimboState) -> void:
	state = next_state; state_elapsed = 0.0; timer_since_progress = 0.0; hint_stage = 0

func show_message(text: String, duration := 2.8) -> void:
	if message_tween and message_tween.is_valid(): message_tween.kill()
	message.text = text
	message_tween = create_tween(); message_tween.tween_property(message, "modulate:a", 1.0, .25); message_tween.tween_interval(duration); message_tween.tween_property(message, "modulate:a", 0.0, .45)

func dim_room(factor: float) -> void:
	for light in room_lights: light.light_energy *= factor

func play_cue(kind: String) -> void:
	# Cache tiny generated samples: repeated ticks no longer allocate generators/buffers.
	if not cue_streams.has(kind): cue_streams[kind] = build_cue_stream(kind)
	var player_audio := AudioStreamPlayer.new(); player_audio.stream = cue_streams[kind]; player_audio.volume_db = -16.0 if kind not in ["unlock", "flicker"] else -9.0; add_child(player_audio)
	player_audio.finished.connect(player_audio.queue_free); player_audio.play()

func build_cue_stream(kind: String) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new(); wav.format = AudioStreamWAV.FORMAT_8_BITS; wav.mix_rate = 22050; wav.stereo = false
	var frequency: float = {"tick":1250.0,"locked":145.0,"unlock":620.0,"tv":95.0,"drip":720.0,"water":260.0,"metal":980.0,"flicker":70.0,"card":840.0,"switch":510.0,"wipe":330.0}.get(kind,440.0)
	var duration: float = {"water":.45,"flicker":.18,"tv":.12,"unlock":.14,"switch":.055,"wipe":.16}.get(kind,.075)
	var frames := int(wav.mix_rate * duration); var samples := PackedByteArray(); samples.resize(frames)
	for i in range(frames):
		var envelope := 1.0 - float(i) / frames
		var value := sin(TAU * frequency * float(i) / wav.mix_rate) * 29.0 * envelope
		if kind == "water":
			var pseudo := fmod(abs(sin(float(i) * 12.9898) * 43758.5453), 1.0) * 2.0 - 1.0
			value = pseudo * 21.0 * minf(1.0, envelope * 6.0)
		elif kind in ["tv","flicker"]:
			var static_noise := fmod(abs(sin(float(i) * 9.731) * 31741.231),1.0) * 2.0 - 1.0
			value = static_noise * (18.0 if kind == "tv" else 25.0) * envelope
		samples[i] = int(clamp(128.0 + value, 0.0, 255.0))
	wav.data = samples; return wav

func full_reset() -> void:
	sequence_epoch += 1
	for tween in get_tree().get_processed_tweens(): tween.kill()
	for hint_light in find_children("HintPulse", "OmniLight3D", true, false): hint_light.queue_free()
	state = LimboState.INTRO; door_state = DoorState.LOCKED; clock_state = ClockState.STOPPED_1604; television_state = TelevisionState.OFF
	timer_since_progress = 0.0; intro_elapsed = 0.0; level_elapsed = 0.0; state_elapsed = 0.0; completion_elapsed = 0.0; door_attempts = 0; door_feedback_cooldown = 0.0; clock_attempt_count = 0; drip_timer = 0.0; desk_flash_count = 0; has_clock_key = false; final_card_taken = false; restored_objects = 0; restored = {"chair":false,"wardrobe":false,"painting":false,"phone":false,"pillow":false}; curtains_closed = false; lamps_off = [false,false]; faucet_running = false; interaction_lock = false; door_opened = false; exit_fade_started = false; final_elapsed = 0.0; final_event = -1; hint_stage = 0
	tv_power_on = false; tv_screen_requested = false; tv_puzzle_completing = false; mirror_clue_available = false; mirror_clue_visible = false; room_switch_on = {"switch_hall":true, "switch_bedroom":true, "switch_bathroom":true, "switch_living":true}
	chair.transform = original.chair; painting.transform = original.painting; phone.transform = original.phone; phone.visible = true; phone_proxy_base.visible = false; handset_prop.transform = original.handset; handset_prop.visible = false; wardrobe_door.transform = original.wardrobe; wardrobe_proxy.visible = false; wardrobe_model.visible = true; pillow_prop.transform = original.pillow; entrance_door.transform = original.door; door_handle_proxy.transform = original.door_handle; door_handle_lever.transform = original.door_lever
	player.transform = original.player; player.velocity = Vector3.ZERO
	get_parent().get_node("HotelSuite/LivingRoom/CurtainLeft").transform = original.curtain_left
	get_parent().get_node("HotelSuite/LivingRoom/CurtainRight").transform = original.curtain_right
	clock_text.text = "16:04"; clock_text.font_size = 48; inserted_key_prop.transform = original.inserted_key; inserted_key_prop.visible = false; tv_text.text = ""; set_tv_power(false, false); mirror_text.text = ""; mirror_text.visible = false; mirror_text.modulate.a = 0.0; mirror_fog_material.albedo_color = Color(.82,.84,.80,0.0); key_prop.visible = false; key_highlight.visible = false; card_prop.visible = true; exit_darkness.visible = false; fade.modulate.a = 0.0; message.text = ""; message.modulate.a = 0.0; aimed_target = ""; prompt.visible = false; crosshair_active = false; crosshair.modulate = Color("e8e2d8"); crosshair.scale = Vector2.ONE
	for light in lamp_lights: light.visible = true; light.light_energy = .38
	desk_final_light.visible = false
	for meshes in bed_lamp_meshes:
		for mesh in meshes: mesh.material_override = null
	for i in range(room_lights.size()): room_lights[i].light_energy = room_light_energy[i]
	if ambient_player and not ambient_player.playing: ambient_player.play()
	if entrance_collision: entrance_collision.collision_layer = 1; entrance_collision.collision_mask = 1
	for detail in entrance_details: detail.visible = true

func update_debug() -> void:
	debug_label.visible = debug_limbo
	if debug_limbo: debug_label.text = "LIMBO: %s\ntime: %s · phase: %s\nrestored: %d/5\nactive: %s\nF6 next phase · F8 reset" % [LimboState.keys()[state], format_elapsed(level_elapsed), format_elapsed(state_elapsed), restored_objects, active_targets()]

func format_elapsed(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds / 60.0), int(seconds) % 60]

func active_targets() -> String:
	var ids: Array[String] = []
	for id in zones:
		if is_target_reactive(id): ids.append(id)
	return ", ".join(ids)

func debug_next_phase() -> void:
	match state:
		LimboState.INTRO: start_tv_clue()
		LimboState.TV_CLUE: close_curtains(); switch_lamp(0); switch_lamp(1)
		LimboState.BATHROOM_CLUE: start_faucet()
		LimboState.FIND_CLOCK_KEY: take_key()
		LimboState.CLOCK_ATTEMPT: interact_clock()
		LimboState.RESTORE_ROOM: for id in restored.keys(): if not restored[id]: restore_object(id)
		LimboState.CLOCK_RUNNING: finish_clock()
		LimboState.FINAL_CARD: take_card()
		LimboState.EXIT_UNLOCKED:
			if door_opened: complete_exit()
			else: open_exit()

func run_debug_audit() -> void:
	print("LIMBO_DEBUG_AUDIT_BEGIN")
	full_reset(); debug_limbo = true
	debug_next_phase(); assert(state == LimboState.TV_CLUE)
	debug_next_phase(); await get_tree().create_timer(1.3).timeout; assert(state == LimboState.BATHROOM_CLUE and curtains_closed and lamps_off == [true,true])
	debug_next_phase(); assert(state == LimboState.FIND_CLOCK_KEY)
	debug_next_phase(); await get_tree().create_timer(.9).timeout; assert(state == LimboState.CLOCK_ATTEMPT and has_clock_key)
	debug_next_phase(); await get_tree().create_timer(1.1).timeout; assert(state == LimboState.RESTORE_ROOM)
	debug_next_phase(); await get_tree().create_timer(1.4).timeout; assert(state == LimboState.CLOCK_RUNNING and restored_objects == 5)
	debug_next_phase(); await get_tree().create_timer(.15).timeout; assert(state == LimboState.FINAL_CARD)
	debug_next_phase(); await get_tree().create_timer(.6).timeout; assert(state == LimboState.EXIT_UNLOCKED)
	debug_next_phase(); await get_tree().create_timer(1.25).timeout; assert(door_opened)
	debug_next_phase(); await get_tree().create_timer(1.65).timeout; assert(state == LimboState.COMPLETE)
	full_reset(); assert(state == LimboState.INTRO and format_elapsed(level_elapsed) == "00:00")
	print("LIMBO_DEBUG_AUDIT_OK F6 full route, stepped final override, F8-equivalent reset")
	prepare_shutdown(); await get_tree().create_timer(.4).timeout; get_tree().quit()

func run_export_audit() -> void:
	print("LIMBO_EXPORT_AUDIT_BEGIN")
	var files: Array[String] = []
	collect_resource_files("res://", files)
	var forbidden: Array[String] = []
	for path in files:
		var normalized := path.trim_prefix("res://")
		if normalized.begins_with("Задания/") or normalized.begins_with("qa_screens/") or normalized.ends_with(".avi"): forbidden.append(normalized)
	assert(forbidden.is_empty(), "Forbidden export resources: " + str(forbidden))
	assert(ResourceLoader.exists("res://main.tscn") and ResourceLoader.exists("res://scripts/LimboController.gd"))
	print("LIMBO_EXPORT_AUDIT_OK resources=%d forbidden=0 required entrypoints present" % files.size())
	prepare_shutdown(); await get_tree().create_timer(.4).timeout; get_tree().quit()

func collect_resource_files(path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if not directory: return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var full_path := path.path_join(entry)
		if directory.current_is_dir(): collect_resource_files(full_path, output)
		else: output.append(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

func run_limbo_audit() -> void:
	print("LIMBO_AUDIT_BEGIN")
	assert(format_elapsed(61.0) == "01:01")
	await get_tree().physics_frame
	assert_interaction_visibility()
	# Ambient interactions must be reversible and must not advance the story.
	interact("tv"); assert(tv_power_on and tv_static_mesh.visible and tv_text.text == "16:04")
	interact("tv"); assert(not tv_power_on and not tv_static_mesh.visible)
	interact("lamp_left"); assert(lamps_off[0]); interact("lamp_left"); assert(not lamps_off[0])
	for switch_id in room_light_groups:
		interact(switch_id); assert(not room_switch_on[switch_id])
		for light: Light3D in room_light_groups[switch_id]: assert(is_zero_approx(light.light_energy))
		interact(switch_id); assert(room_switch_on[switch_id])
	interact("mirror"); assert(not mirror_clue_available and not mirror_clue_visible)
	assert(state == LimboState.INTRO)
	full_reset()
	# Out-of-order interactions must not advance state.
	interact("faucet"); interact("key"); interact("card"); interact("chair")
	assert(state == LimboState.INTRO and not has_clock_key and not final_card_taken)
	# Reset must cancel pending phase transitions and blackout callbacks.
	start_tv_clue(); interact("curtains"); interact("lamp_left"); interact("lamp_right"); full_reset()
	await get_tree().create_timer(1.3).timeout
	assert(state == LimboState.INTRO and not curtains_closed)
	set_state(LimboState.FIND_CLOCK_KEY); take_key(); full_reset()
	await get_tree().create_timer(.9).timeout
	assert(state == LimboState.INTRO and not has_clock_key and chair.transform == original.chair)
	set_state(LimboState.RESTORE_ROOM); timer_since_progress = hint_obvious_delay; update_hints()
	assert(find_children("HintPulse", "OmniLight3D", true, false).size() == 1)
	full_reset(); await get_tree().process_frame
	assert(find_children("HintPulse", "OmniLight3D", true, false).is_empty() and message.modulate.a == 0.0)
	for i in range(20): interact("door")
	assert(state == LimboState.TV_CLUE and door_attempts == 20)
	full_reset()
	interact_door(); interact_door(); await get_tree().process_frame; assert(state == LimboState.TV_CLUE)
	interact("curtains"); interact("lamp_left")
	timer_since_progress = hint_clear_delay; update_hints()
	assert("ПРАВАЯ" in tv_text.text and not "ЛЕВАЯ" in tv_text.text and not "ШТОРЫ:" in tv_text.text)
	interact("lamp_right")
	await get_tree().create_timer(1.3).timeout; assert(state == LimboState.BATHROOM_CLUE)
	interact("faucet"); assert(state == LimboState.FIND_CLOCK_KEY and mirror_clue_available and mirror_clue_visible)
	interact("mirror"); assert(not mirror_clue_visible); interact("mirror"); assert(mirror_clue_visible)
	timer_since_progress = hint_clear_delay; update_hints(); assert(tv_static_mesh.visible and "КРОВАТЬ" in tv_text.text)
	interact("key"); await get_tree().create_timer(.9).timeout; assert(state == LimboState.CLOCK_ATTEMPT and has_clock_key)
	assert(chair.position.distance_to(original.chair.origin) < .01 and abs(chair.rotation.y - original.chair.basis.get_euler().y) > 1.0)
	assert(handset_prop.visible and handset_prop.position.distance_to(original.handset.origin) > .2 and pillow_prop.position.y < .2)
	assert(wardrobe_proxy.visible and not wardrobe_model.visible and abs(wardrobe_door.rotation.y) > 1.0)
	for i in range(20): interact("clock")
	await get_tree().create_timer(1.1).timeout; assert(state == LimboState.RESTORE_ROOM and clock_attempt_count == 1)
	timer_since_progress = hint_soft_delay; update_hints(); assert("КРЕСЛО" in tv_text.text)
	interact("chair"); assert(tv_text.text == "ВЕРНИ ЕЙ ПАМЯТЬ")
	for id in ["chair","wardrobe","painting","phone","pillow"]:
		for i in range(10): interact(id)
	await get_tree().create_timer(1.4).timeout; assert(state == LimboState.CLOCK_RUNNING and restored_objects == 5)
	await get_tree().create_timer(3.0).timeout; assert(television_state == TelevisionState.FINAL_ANOMALY and tv_static_mesh.visible and tv_text.text == "1604")
	await get_tree().create_timer(1.0).timeout; assert("КОМНАТА" in tv_text.text)
	await get_tree().create_timer(1.0).timeout; assert("КРЕСЛО" in tv_text.text)
	await get_tree().create_timer(1.0).timeout; assert(television_state == TelevisionState.OFF_FINAL and not tv_static_mesh.visible)
	await get_tree().create_timer(2.3).timeout; assert(state == LimboState.FINAL_CARD and clock_state == ClockState.FINISHED_1605 and not ambient_player.playing and desk_flash_count == 1)
	for i in range(20): interact("card")
	await get_tree().create_timer(.6).timeout; assert(state == LimboState.EXIT_UNLOCKED and final_card_taken)
	for i in range(20): interact("door")
	await get_tree().create_timer(1.25).timeout; assert(door_opened and state == LimboState.EXIT_UNLOCKED)
	player.global_position = Vector3(-2.65,.05,-3.05)
	await get_tree().process_frame
	await get_tree().create_timer(1.65).timeout; assert(state == LimboState.COMPLETE)
	print("LIMBO_AUDIT_OK full sequence, reversible ambient interactions, out-of-order guards, 20x input stress, async reset safety, stepped exit and COMPLETE")
	ambient_player.stop()
	await get_tree().create_timer(.35).timeout
	get_tree().quit()

func assert_interaction_visibility() -> void:
	var origins := {
		"door":Vector3(-2.65,1.55,-1.75), "curtains":Vector3(.8,1.55,4.35),
		"lamp_left":Vector3(0,1.45,-1.75), "lamp_right":Vector3(2.37,1.45,-1.75),
		"faucet":Vector3(-2.75,1.45,-.30), "clock":Vector3(2.28,1.55,2.05),
		"key":Vector3(1.25,1.50,-.42), "chair":Vector3(2.55,1.35,.15),
		"wardrobe":Vector3(-.45,1.45,-.15), "painting":Vector3(1.25,1.60,-2.05),
		"phone":Vector3(2.61,1.40,-2.0), "pillow":Vector3(1.85,1.45,.05),
		"card":Vector3(3.48,1.35,1.85), "tv":Vector3(-.45,1.45,3.15),
		"mirror":Vector3(-3.15,1.55,-.30), "switch_hall":Vector3(-2.05,1.45,-1.82),
		"switch_bedroom":Vector3(-.95,1.45,-1.15), "switch_bathroom":Vector3(-2.75,1.45,.25),
		"switch_living":Vector3(.18,1.45,1.55)
	}
	var saved_ray_transform := interaction_ray.transform
	var saved_target := interaction_ray.target_position
	for id in origins:
		interaction_ray.global_position = origins[id]
		interaction_ray.target_position = interaction_ray.to_local(zones[id].global_position)
		interaction_ray.force_raycast_update()
		var collider := interaction_ray.get_collider()
		var hit_description := "none"
		if collider is Node:
			hit_description = collider.name
			if collider is Area3D: hit_description += "/" + str(collider.get_meta("interaction_id", ""))
		assert(interaction_ray.is_colliding() and collider is Area3D and collider.get_meta("interaction_id", "") == id, "Interaction occluded: %s by %s" % [id,hit_description])
	interaction_ray.transform = saved_ray_transform
	interaction_ray.target_position = saved_target
	interaction_ray.force_raycast_update()
	print("LIMBO_RAY_AUDIT_OK persistent camera RayCast3D sees all 19 interaction zones from reachable approach points")

func move_pivot(node: Node3D, pivot: Vector3) -> void:
	if not node or not node.position.is_zero_approx(): return
	for child in node.get_children():
		if child is Node3D: child.position -= pivot
	node.position = pivot

func add_zone(id: String, position: Vector3, size: Vector3) -> void:
	var area := Area3D.new(); area.name = "Interact_" + id; area.position = position; area.set_meta("interaction_id", id); area.collision_layer = 2; area.collision_mask = 0
	var shape_node := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; shape_node.shape = shape; area.add_child(shape_node); add_child(area); zones[id] = area

func make_box(parent: Node, name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.name = name; var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh; node.position = position; var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = .55; node.material_override = material; parent.add_child(node); return node

func make_torus(parent: Node, name: String, position: Vector3, inner: float, outer: float, color: Color, rotation: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.name = name; var mesh := TorusMesh.new(); mesh.inner_radius = inner; mesh.outer_radius = outer; node.mesh = mesh; node.position = position; node.rotation = rotation; var material := StandardMaterial3D.new(); material.albedo_color = color; material.metallic = .7; node.material_override = material; parent.add_child(node); return node

func make_capsule(parent: Node, name: String, position: Vector3, radius: float, height: float, color: Color, rotation: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.name = name; var mesh := CapsuleMesh.new(); mesh.radius = radius; mesh.height = height; mesh.radial_segments = 12; mesh.rings = 4; node.mesh = mesh; node.position = position; node.rotation = rotation; var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = .4; node.material_override = material; parent.add_child(node); return node

func make_sphere(parent: Node, name: String, position: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.name = name; var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius * 2.0; mesh.radial_segments = 10; mesh.rings = 5; node.mesh = mesh; node.position = position; var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = .4; node.material_override = material; parent.add_child(node); return node

func make_label3d(name: String, text: String, position: Vector3, rotation: Vector3, font_size: int, pixel_size: float, parent: Node = self) -> Label3D:
	var label := Label3D.new(); label.name = name; label.text = text; label.position = position; label.rotation = rotation; label.font_size = font_size; label.pixel_size = pixel_size; label.outline_size = 4; label.no_depth_test = false; parent.add_child(label); return label

func build_ambient_hum() -> void:
	ambient_player = AudioStreamPlayer.new(); ambient_player.name = "RoomHum"; ambient_player.volume_db = -31.0; add_child(ambient_player)
	var wav := AudioStreamWAV.new(); wav.format = AudioStreamWAV.FORMAT_8_BITS; wav.mix_rate = 11025; wav.stereo = false
	var samples := PackedByteArray(); samples.resize(11025)
	for i in range(samples.size()):
		var low := sin(TAU * 58.0 * float(i) / 11025.0) * 3.0
		var air := sin(TAU * 117.0 * float(i) / 11025.0) * 1.2
		samples[i] = int(clamp(128.0 + low + air, 0.0, 255.0))
	wav.data = samples; wav.loop_mode = AudioStreamWAV.LOOP_FORWARD; wav.loop_begin = 0; wav.loop_end = samples.size()
	ambient_player.stream = wav; ambient_player.play()
