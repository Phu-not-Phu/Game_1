extends Node

@export var player: CharacterBody3D
@export var mesh_root: Node3D
@export var rotation_speed: float = 8
@export var fall_gravity = 45
var jump_gravity: float = fall_gravity
var direction: Vector3
var velocity: Vector3
var acceleration: float
var speed: float
var cam_rotation: float = 0

#AttackDamage
var attack_damage: float = 0
var damage_done: float = 0

#WalkingStairs
@onready var stairs_below_raycast = $"../StairsBelowRayCast3D"
@onready var _initial_seperation_ray_dist = abs($"../StepUpSeperationRay_F".position.z)
@onready var _step_up_sepertaion_ray_f = $"../StepUpSeperationRay_F"
@onready var _step_up_sepertaion_ray_l = $"../StepUpSeperationRay_L"
@onready var _step_up_sepertaion_ray_r = $"../StepUpSeperationRay_R"
@onready var raycast_f = $"../StepUpSeperationRay_F/RayCast3D"
@onready var raycast_l = $"../StepUpSeperationRay_L/RayCast3D"
@onready var raycast_r = $"../StepUpSeperationRay_R/RayCast3D"
var _was_on_floor_last_frame = false
var _snapped_to_stairs_last_frame = false
var _last_xz_vel : Vector3 = Vector3(1, 0, 1)

#AttackState
@onready var hitbox_lefthand = $"../Model/Barbarian/Rig/Skeleton3D/1H_Axe_Offhand/1H_Axe_Offhand/Hitbox_lefthand"
@onready var hitbox_righthand = $"../Model/Barbarian/Rig/Skeleton3D/1H_Axe/1H_Axe/Hitbox_righthand"

func _physics_process(delta):
	velocity.x = speed * direction.normalized().x
	velocity.z = speed * direction.normalized().z
		
	if not player.is_on_floor():
		if velocity.y >= 0:
			velocity.y -= jump_gravity * delta
		else:
			velocity.y -= fall_gravity * delta
		
	player.velocity = player.velocity.lerp(velocity, acceleration * delta)
	_rotate_step_up_seperation_ray()
	player.move_and_slide()
	_snap_down_to_stairs_check()
	
	var target_rotation = atan2(direction.x, direction.z) - player.rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, rotation_speed * delta)

func _jump(jump_state: JumpState):
	velocity.y = 2 * jump_state.jump_height / jump_state.apex_duration
	jump_gravity = 1.5 * velocity.y / jump_state.apex_duration

func _on_set_movement_state(_movement_state: MovementState):
	speed = _movement_state.movement_speed
	acceleration = _movement_state.acceleration

func _on_set_movement_direction(_movement_direction: Vector3):
	direction = _movement_direction.rotated(Vector3.UP, cam_rotation)

func _on_set_cam_rotation(_cam_rotation: float):
	cam_rotation = _cam_rotation

func _snap_down_to_stairs_check():
	var did_snap = false
	
	if not player.is_on_floor() and velocity.y <= 0 and (_was_on_floor_last_frame or _snapped_to_stairs_last_frame) and stairs_below_raycast.is_colliding():
		var body_test_result = PhysicsTestMotionResult3D.new()
		var params = PhysicsTestMotionParameters3D.new()
		var max_step_down = -0.5
		params.from = player.global_transform
		params.motion = Vector3(0, max_step_down, 0)
		
		if PhysicsServer3D.body_test_motion(player.get_rid(), params, body_test_result):
			var translate_y = body_test_result.get_travel().y
			player.position.y += translate_y
			player.apply_floor_snap()
			did_snap = true
	
	_was_on_floor_last_frame = player.is_on_floor()
	_snapped_to_stairs_last_frame = did_snap

func _rotate_step_up_seperation_ray():
	var xz_vel = velocity * Vector3(1, 0, 1)
	
	if xz_vel.length() < 0.1:
		xz_vel = _last_xz_vel
	else:
		_last_xz_vel = xz_vel
	
	var xz_f_ray_pos = xz_vel.normalized() * _initial_seperation_ray_dist
	_step_up_sepertaion_ray_f.global_position.x = player.global_position.x + xz_f_ray_pos.x
	_step_up_sepertaion_ray_f.global_position.z = player.global_position.z + xz_f_ray_pos.z
	
	var xz_l_ray_pos = xz_f_ray_pos.rotated(Vector3(0, 1.0, 0), deg_to_rad(-50))
	_step_up_sepertaion_ray_l.global_position.x = player.global_position.x + xz_l_ray_pos.x
	_step_up_sepertaion_ray_l.global_position.z = player.global_position.z + xz_l_ray_pos.z

	var xz_r_ray_pos = xz_f_ray_pos.rotated(Vector3(0, 1.0, 0), deg_to_rad(50))
	_step_up_sepertaion_ray_r.global_position.x = player.global_position.x + xz_r_ray_pos.x
	_step_up_sepertaion_ray_r.global_position.z = player.global_position.z + xz_r_ray_pos.z
	
	raycast_f.force_raycast_update()
	raycast_l.force_raycast_update()
	raycast_r.force_raycast_update()
	var max_slope_ang_dot = Vector3(0, 1, 0).rotated(Vector3(1.0, 0, 0), player.floor_max_angle).dot(Vector3(0, 1, 0))
	var any_too_steep = false
	if raycast_f.is_colliding() and raycast_f.get_collision_normal().dot(Vector3(0, 1, 0)) < max_slope_ang_dot:
		any_too_steep = true  
	if raycast_l.is_colliding() and raycast_l.get_collision_normal().dot(Vector3(0, 1, 0)) < max_slope_ang_dot:
		any_too_steep = true  
	if raycast_r.is_colliding() and raycast_r.get_collision_normal().dot(Vector3(0, 1, 0)) < max_slope_ang_dot:
		any_too_steep = true  
	
	_step_up_sepertaion_ray_f.disabled = any_too_steep
	_step_up_sepertaion_ray_l.disabled = any_too_steep
	_step_up_sepertaion_ray_r.disabled = any_too_steep

func _on_set_attack_state(_attack_state: AttackState):
	hitbox_lefthand.monitoring = true
	hitbox_righthand.monitoring = true
	hitbox_lefthand.monitorable = true
	hitbox_righthand.monitorable = true
	attack_damage = _attack_state.damage_deal
	$"../Timer".start()
#
func _on_timer_timeout():
	hitbox_lefthand.monitoring = false
	hitbox_righthand.monitoring = false
	hitbox_lefthand.monitorable = false
	hitbox_righthand.monitorable = false
	print("out")
	damage_done = 0

func _on_hitbox_lefthand_area_entered(area):
	if area.is_in_group("enemy"):
		damage_done += attack_damage
		print(damage_done)
		print("left-hit")

func _on_hitbox_righthand_area_entered(area):
	if area.is_in_group("enemy"):
		damage_done += attack_damage
		print(damage_done)
		print("right-hit")
