extends Node3D

signal set_cam_rotation(_cam_rotation: float)

@onready var horizontal_node = $CamHorizontal
@onready var vertical_node = $CamHorizontal/CamVertical
@onready var camera = $CamHorizontal/CamVertical/SpringArm3D/Camera3D

var horizontal: float = 0
var vertical: float = 0

var horizontal_sensitivity: float = 0.07
var vertical_sensitivity: float = 0.07

var horizontal_acceleration: float = 15
var vertical_acceleration: float = 15

var vertical_min: float = -10
var vertical_max: float = 70

var tween: Tween

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		horizontal += -event.relative.x * horizontal_sensitivity
		vertical += event.relative.y * vertical_sensitivity

func _physics_process(delta):
	vertical = clamp(vertical, vertical_min, vertical_max)
	
	horizontal_node.rotation_degrees.y = lerp(horizontal_node.rotation_degrees.y, horizontal, horizontal_acceleration * delta)
	vertical_node.rotation_degrees.x = lerp(vertical_node.rotation_degrees.x, vertical, vertical_acceleration * delta)
	
	set_cam_rotation.emit(horizontal_node.rotation.y)

func _on_set_movement_state(_movement_state: MovementState):
	if tween:
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(camera, "fov",_movement_state.camera_fov, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
