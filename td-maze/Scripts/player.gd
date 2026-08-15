extends CharacterBody2D

@export_group("Movement")
@export var baseSpeed := 100 #Player base speed.
@export var sprintSpeed := 200 #Player sprint speed.

@export_group("Stamina")
@export var staminaAmountCap := 200 #Player stamina Maximum.
@export var staminaRegen := 1 #Rate of stamina regeneration 
@export var staminaDrain := 2 #Rate of stamina depletion while sprinting (amount is subtracted, use positive number)

var staminaToggle := true #If the player can use sprint
var staminaAmount := staminaAmountCap #Current amount of stanima
var facingDirection := "Down" #Direction the player is facing
var facingVector := Vector2.ZERO #Vector for facing control

@onready var sprite := $AnimatedSprite2D
@onready var StaminaLabel := $StaminaLabel

func _physics_process(_delta: float) -> void:
	updateFacingDirection()
	readInput()
	
	move_and_slide()
	
	var moved : float = velocity.length() > 0.1
	updateStamina(moved)
	updateAnimation()
	
	StaminaLabel.text = str(staminaAmount)

#Reads movement input and produces a normalized movement vector
func readInput() -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if velocity:
		var move_speed : int = baseSpeed
		
		if Input.is_action_pressed("sprint") and staminaToggle:
			move_speed = sprintSpeed
			sprite.speed_scale = 1.5
		else:
			sprite.speed_scale = 1
		velocity = velocity.normalized() * move_speed * movementPenalty()
	else:
		sprite.speed_scale = 1

#Updates stamina drain, regeneration, and sprint lock/unlock
func updateStamina(moved : float) -> void:
	if staminaToggle:
		if staminaAmount <= 0:
			staminaToggle = false
	else:
		if staminaAmount > (staminaAmountCap/2):
			staminaToggle = true
	
	#Drains stamina if sprinting and moving
	if Input.is_action_pressed("sprint") and staminaToggle and moved:
		staminaAmount -= staminaDrain
	elif (staminaAmount < staminaAmountCap):
		staminaAmount += staminaRegen

#Calculates if the player is facing the direction they move and returns a penalty value
func movementPenalty() -> float:
	var move_dir : Vector2 = velocity.normalized()
	var alignment : float = move_dir.dot(facingVector)
	
	if alignment > 0.5: #Facing Mostly same direction
		return 1.0
	elif alignment > -0.5: #Facing Near Perpindicular
		return 0.85
	else: #Facing Opposite Direction
		return 0.7

#Updates the facing direction for animation based on mouse position in relation to player
func updateFacingDirection() -> void:
	var controller_dir :Vector2 = get_controller_facing()
	if controller_dir.length() > 0.2:
		setFacingFromVector(controller_dir)
		return
	var mouse_dir : Vector2 = (get_global_mouse_position() - global_position)
	setFacingFromVector(mouse_dir)

func setFacingFromVector(vect : Vector2) -> void:
	#Updates the global variable for facing Vector
	facingVector = vect.normalized()
	
	if vect == Vector2.ZERO:
		return
	
	if abs(vect.x) > abs(vect.y):
		facingDirection = "Right" if vect.x > 0 else "Left"
	else:
		facingDirection = "Down" if vect.y > 0 else "Up"
	

#Looking Controll for controller compatability
func get_controller_facing() -> Vector2:
	return Input.get_vector("look_left", "look_right", "look_up", "look_down")

#Plays idle or walking animations based on movement and direction
func updateAnimation() -> void:
	#if velocity is 0 play idle animations, else walk animations (Idlex and walkX flip_h based on direction)
	var is_idle : bool = (velocity == Vector2.ZERO)
	
	if facingDirection in ["Left", "Right"]:
		sprite.flip_h = facingDirection == "Left"
		sprite.play("IdleX" if is_idle else "walkX")
	else:
		sprite.play(("Idle" if is_idle else "walk") + facingDirection)
