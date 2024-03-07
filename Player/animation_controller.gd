extends Node

@export var animation_tree: AnimationTree
@export var player: CharacterBody3D

var on_floor_blend: float = 1
var on_floor_blend_target: float = 1

var last_frame_movement_state: String
var last_frame_attack = false

var tween: Tween

func _physics_process(delta):
	on_floor_blend_target = 1 if player.is_on_floor() else 0
	on_floor_blend = lerp(on_floor_blend, on_floor_blend_target, 10 * delta)
	animation_tree["parameters/on_floor_blend/blend_amount"] = on_floor_blend
	if !player.is_on_floor() and last_frame_movement_state == "sprint" and last_frame_attack == true:
		animation_tree["parameters/" + "dash_attack" + "/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		last_frame_attack = false

func _jump(jump_state: JumpState):
	animation_tree["parameters/" + jump_state.animation_name + "/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	if jump_state.animation_name == "air_jump":
		animation_tree["parameters/" + "ground_jump" + "/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT

func _on_set_movement_state(_movement_state: MovementState):
	if tween:
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(animation_tree, "parameters/movement_blend/blend_position", _movement_state.id, 0.25)
	tween.parallel().tween_property(animation_tree, "parameters/movement_anim_speed/scale", _movement_state.animation_speed, 0.7)
	if _movement_state.id == 3:
		last_frame_movement_state = "sprint"
	else:
		last_frame_movement_state = ""

func _attack(_attack_state: AttackState):
	last_frame_attack = true
	if last_frame_movement_state == "sprint":
		animation_tree["parameters/" + "dash_attack" + "/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	else:
		animation_tree["parameters/" + _attack_state.name + "/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		if _attack_state.name == "dash_attack":
			animation_tree["parameters/" + "normal_attack" + "/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
