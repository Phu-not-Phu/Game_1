extends RigidBody3D

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0
var acceleration = 5.0
var accel_multiplier = 1.0
var jump_vel = 10
var speed = 1500.0

var gravity = 9.8
var is_on_floor = true

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
@onready var feets := $Feets
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if gravity_scale >= 0: gravity_scale = 0
	is_on_floor = false
	
	var input := Vector3.ZERO
	input.x = Input.get_axis("left", "right")
	input.z = Input.get_axis("forward", "down")
	
	apply_central_force(twist_pivot.basis * input * speed * delta)
	
	if Input.is_action_pressed("run"):
		apply_central_force(twist_pivot.basis * input * speed * 0.5 * delta)
	
	if feets.is_colliding():
		is_on_floor = true
		gravity_scale = 1.0
		accel_multiplier = 1.0
		#print("on floor")
	if Input.is_action_just_pressed("jump") and is_on_floor:
		accel_multiplier = 0.1
		is_on_floor = false
		apply_central_impulse(Vector3.UP * jump_vel)
	elif !feets.is_colliding():
		#print("not touching")
		is_on_floor = false
		gravity_scale = 1.5;
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x,
		deg_to_rad(-30),
		deg_to_rad(30)
	)
	twist_input = 0.0
	pitch_input = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sensitivity
			pitch_input = - event.relative.y * mouse_sensitivity
