extends CharacterBody3D;

@onready var _jump_hold: Timer = $JumpHold;

@export_category("locamotion")
@export var _walking_speed: float = 4;
@export var _running_speed: float = 8;
@export var _acceleration: float = 16;
@export var _desaceleration: float = 64;
@export var _rotation_speed: float = PI * 180;
var _direction: Vector3;

@export_category("jump")
@export var _min_jump_height: float = 1.5;
@export var _max_jump_height: float = 2.5;
@export var _air_control: float = 0.5;
@export var _air_brakes: float = 0.5;
@export var _mass: float = 1;

var _min_jump_velocity: float;
var _max_jump_velocity: float;

@onready var _movement_speed: float = _walking_speed;
var _xz_velocity: Vector3;
var _angle_difference: float;
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity");

@onready var _animation: AnimationTree = $AnimationTree;
@onready var _rig: Node3D = $Rig;
@onready var _state_machine: AnimationNodeStateMachinePlayback = _animation["parameters/playback"];

func _ready():
	_rotation_speed = deg_to_rad(_rotation_speed);
	_min_jump_velocity = sqrt(_min_jump_height * _gravity * _mass * 2);
	_max_jump_velocity = sqrt(_max_jump_height * _gravity * _mass * 2);

func move(direction: Vector3):
	_direction = direction;
	pass;
	
func walk():
	_movement_speed = _walking_speed;
	print("now is walking");
	
func run():
	_movement_speed = _running_speed;
	print("now is runningss");
	
func start_jump():
	if is_on_floor():
		_state_machine.travel("Jump_Start");
		_jump_hold.start();
		_jump_hold.paused = false;
	
func complete_jump():
	_jump_hold.paused = true;
	
func jump():
		# Handle jump.
	if is_on_floor():
		_state_machine.travel("Jump_Start");

func _apply_jump_velocity():
	_jump_hold.paused = true;
	#velocity.y = _min_jump_velocity;;
	if(is_on_floor()):
		velocity.y = _min_jump_velocity + (_max_jump_velocity - _min_jump_velocity) * min(1 - _jump_hold.time_left, 0.3) / 0.3;

func _physics_process(delta: float) -> void:
	if _direction:
		_angle_difference = wrapf(atan2(_direction.x, _direction.z) - _rig.rotation.y, -PI, PI);
		_rig.rotation.y += clamp(_rotation_speed * delta, 0, abs(_angle_difference)) * sign(_angle_difference);
	
	_xz_velocity = Vector3(velocity.x, 0, velocity.z)

	if(is_on_floor()):
		_ground_physics(delta);
	else:
		_air_physics(delta);

	velocity.x = _xz_velocity.x;
	velocity.z = _xz_velocity.z;

	move_and_slide()

func _ground_physics(delta:float):
	if _direction:
		# accelerate
		if (_direction.dot(velocity) >= 0):
			_xz_velocity = _xz_velocity.move_toward(_direction * _movement_speed, _acceleration * delta);
		else:
			_xz_velocity = _xz_velocity.move_toward(_direction * _movement_speed, _desaceleration * delta);
	else:
		_xz_velocity = _xz_velocity.move_toward(Vector3.ZERO, _desaceleration * delta);

	_animation.set("parameters/Locomotion/blend_position", _xz_velocity.length() / _running_speed);
	
func _air_physics(delta:float):
	# Add the gravity.
	velocity.y -= _gravity * _mass * delta;
	
	if _direction:
		# accelerate
		if (_direction.dot(velocity) >= 0):
			_xz_velocity = _xz_velocity.move_toward(_direction * _movement_speed, _acceleration * _air_control * delta);
		else:
			_xz_velocity = _xz_velocity.move_toward(_direction * _movement_speed, _desaceleration * _air_control * delta);
	else:
		_xz_velocity = _xz_velocity.move_toward(Vector3.ZERO, _desaceleration * _air_brakes * delta);
