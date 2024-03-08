extends CharacterBody3D

signal pressed_jump(jump_state: JumpState)
signal set_movement_state(_movement_state: MovementState)
signal set_movement_direction(_movement_direction: Vector3)
signal set_attack_state(attack_state: AttackState)

@export var max_air_jump: int = 1
@export var movement_states: Dictionary
@export var jump_states: Dictionary
@export var attatck_states: Dictionary

var air_jump_count: int = 0
var movement_direction: Vector3

#CoyoteTime
@export var _jump_frame_grace = 5
var _cur_frame = 0
var _last_frame_was_on_floor = -_jump_frame_grace - 1

func _input(event):
	if event is InputEventKey:
		if event.as_text() == "W" || event.as_text() == "S" || event.as_text() == "A" || event.as_text() == "D" || event.as_text() == "Shift" || event.as_text() == "Space" || event.as_text() == "Ctrl":
			if event.pressed: 
				get_node("Status/" + event.as_text()).color = Color("ff6666")
			else:
				get_node("Status/" + event.as_text()).color = Color("ffffff")
	
	if event is InputEventMouse:
		if event.as_text() == "Left Mouse Button" || event.as_text() == "Right Mouse Button":
			if event.pressed: 
				get_node("Status/" + event.as_text()).color = Color("ff6666")
			else:
				get_node("Status/" + event.as_text()).color = Color("ffffff")
	
	if is_on_floor() and event.is_action("attacks"):
		if Input.is_action_pressed("normal_attack"):
			if Input.is_action_pressed("sprint"):
				set_attack_state.emit(attatck_states["dash_attack"])
			else:
				set_attack_state.emit(attatck_states["normal_attack"])
		elif Input.is_action_pressed("dash_attack"):
			set_attack_state.emit(attatck_states["dash_attack"])
	
	if event.is_action("movement"):
		if event.is_action("attacks"):
			movement_direction.x = 0 
			movement_direction.z = 0
		else:
			movement_direction.x = Input.get_action_strength("left") - Input.get_action_strength("right")
			movement_direction.z = Input.get_action_strength("forward") - Input.get_action_strength("backward")
		
			if is_movement_ongoing():
				if Input.is_action_pressed("sprint"):
					set_movement_state.emit(movement_states["sprint"])
					if Input.is_action_just_pressed("sprint") and Input.is_action_pressed("normal_attack"):
						set_attack_state.emit(attatck_states["dash_attack"])
				else:
					if Input.is_action_pressed("walk"):
						set_movement_state.emit(movement_states["walk"])
					else:
						set_movement_state.emit(movement_states["run"])
			else:
				set_movement_state.emit(movement_states["stand"])
		
func _ready():
	set_movement_state.emit(movement_states["stand"])
	var anim_player = $Model/Barbarian/AnimationPlayer
	var animations = ['Idle', 'Running_A', 'Running_B', 'Walking_A', 'Walking_B', 'Jump_Idle']
	
	for animation in animations:
		animation = anim_player.get_animation(animation)
		animation.loop = true

func _physics_process(delta):
	if is_movement_ongoing():
		set_movement_direction.emit(movement_direction)
		
	if is_on_floor() or (_cur_frame - _last_frame_was_on_floor <= _jump_frame_grace):
		air_jump_count = 0
	elif air_jump_count == 0:
		air_jump_count = 1
	
	if air_jump_count <= max_air_jump:
		if Input.is_action_just_pressed("jump"):
			var jump_name: String = "ground_jump"
			
			if Input.is_action_pressed("normal_attack"):
				set_attack_state.emit(attatck_states["dash_attack"])
				
			if air_jump_count > 0:
				jump_name = "air_jump"
				
				if Input.is_action_pressed("normal_attack"):
					set_attack_state.emit(attatck_states["dash_attack"])
					
			pressed_jump.emit(jump_states[jump_name])
			air_jump_count += 1

func is_movement_ongoing() -> bool:
	return abs(movement_direction.x) > 0 or abs(movement_direction.z) > 0

