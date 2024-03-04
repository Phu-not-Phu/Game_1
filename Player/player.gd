extends CharacterBody3D

signal pressed_jump(jump_state: JumpState)
signal set_movement_state(_movement_state: MovementState)
signal set_movement_direction(_movement_direction: Vector3)

@export var max_air_jump: int = 1
@export var movement_states: Dictionary
@export var jump_states: Dictionary

var air_jump_count: int = 0
var movement_direction: Vector3

func _input(event):
	if event is InputEventKey:
		if event.as_text() == "W" || event.as_text() == "S" || event.as_text() == "A" || event.as_text() == "D" || event.as_text() == "Shift" || event.as_text() == "Space" || event.as_text() == "Ctrl":
				if event.pressed: 
					get_node("Status/" + event.as_text()).color = Color("ff6666")
				else:
					get_node("Status/" + event.as_text()).color = Color("ffffff")
	
	if event.is_action("movement"):
		movement_direction.x = Input.get_action_strength("left") - Input.get_action_strength("right")
		movement_direction.z = Input.get_action_strength("forward") - Input.get_action_strength("backward")
		
		if is_movement_ongoing():
			if Input.is_action_pressed("sprint"):
				set_movement_state.emit(movement_states["sprint"])
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
		
	if is_on_floor():
		air_jump_count = 0
	elif air_jump_count == 0:
		air_jump_count = 1
	
	if air_jump_count <= max_air_jump:
		if Input.is_action_just_pressed("jump"):
			var jump_name: String = "ground_jump"
			
			if air_jump_count > 0:
				jump_name = "air_jump"
			
			pressed_jump.emit(jump_states[jump_name])
			air_jump_count += 1

func is_movement_ongoing() -> bool:
	return abs(movement_direction.x) > 0 or abs(movement_direction.z) > 0
