extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # 获取子节点

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
@export var INERTIA=0.4

func _ready()->void:
	position=Vector2(100,-50)

func _enter_tree() -> void:
	# 设置权限标识
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	# 检查权限
	if not is_multiplayer_authority():
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = (1-INERTIA)*direction * SPEED+INERTIA*velocity.x
		# 翻转动画方向
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED*(1-INERTIA))

	move_and_slide()
