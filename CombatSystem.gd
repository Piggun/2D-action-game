extends Node2D

@onready var player_health_bar = %PlayerHealthBar
@onready var player_stamina_bar = %PlayerStaminaBar
@onready var enemy_health_bar = %EnemyHealthBar
@onready var parry_success = $ParrySuccess
@onready var player_attack_bar = %PlayerAttackBar
@onready var enemy_attack_bar = %EnemyAttackBar
@onready var player_fatigued_timer = %PlayerFatiguedTimer

# Player Variables
var player_health = 100
var player_stamina = 100
var player_attack_stamina_usage = 20
var player_stamina_recovery_rate = 20
var player_stamina_recovery_delay = 2
var player_attack_damage = 10
var player_attacking = false
var player_attack_speed = 2.0
var player_attack_progress = 0.0
var parry_window_duration = 0.3  # Parry window lasts for 0.3 seconds
var parry_cooldown = 0.0  # Cooldown after a parry before initiating another one
var parry_cooldown_duration = 0.5  # Cooldown period after parry
var parry_success_timer = 0.0  # Timer to track the duration of successful parry icon
var player_fatigued = false # Out of stamina

# Enemy Variables
var enemy_health = 100
var enemy_attack_damage = 10
var enemy_attacking = false
var enemy_attack_speed = 2.0
var enemy_attack_timer = 0.0
var enemy_attack_interval = 2.5  # Time between enemy attacks
var enemy_attack_progress = 0.0
var parry_active = false  # Track if parry is active (successful)
var parry_timer = 0.0  # Timer to track the parry window


# <--------------------TESTING ATTACK PATTERNS -------------------------------->
var attack_pattern_A = [
	{ "delay": 0.5, "attack_type" : "light"},
	{ "delay": 0.5, "attack_type" : "light"},
	{ "delay": 1.5, "attack_type" : "heavy"}
]

# Variables to manage the pattern execution
var current_pattern = []
var current_step = 0
var pattern_timer = 0.0
var pattern_active = false

func start_attack_pattern():
	current_pattern = attack_pattern_A
	current_step = 0
	pattern_active = true
	pattern_timer = current_pattern[0]["delay"]
	print("Starting Pattern A")
	
func execute_attack_step(step: Dictionary) -> void:
	var type = step["attack_type"]
	start_enemy_attack()
	match type:
		"light":
			print("Enemy performs a light attack")
			# Add logic for a light attack here
		"heavy":
			print("Enemy performs a heavy attack")
			# Add logic for a heavy attack here
		"break":
			print("Enemy takes a break")
			# Add logic for a break (wind-up, pause, etc.) here


func _ready():
	start_attack_pattern()
# <---------------------------------------------------------------------------->



func _process(delta):
	player_health_bar.value = player_health
	enemy_health_bar.value = enemy_health
	player_stamina_bar.value = player_stamina
	
	
# <--------------------TESTING ATTACK PATTERNS -------------------------------->
	if pattern_active:
		pattern_timer -= delta
		print(pattern_timer)
		if pattern_timer <= 0:
			execute_attack_step(current_pattern[current_step])
			current_step += 1
			if current_step < current_pattern.size():
				pattern_timer = current_pattern[current_step]["delay"]
			else:
				pattern_active = false
				print("Pattern finished")
# <---------------------------------------------------------------------------->


	if player_stamina == 0 and not player_fatigued:
		player_fatigued = true
		print("Out of stamina!")
		%PlayerFatiguedTimer.start(player_stamina_recovery_delay)
		
	if player_stamina <= 100 and not player_attacking and not player_fatigued:
		recover_stamina(delta)
	
	# Player attack logic
	if player_attacking:
		player_attack_progress += player_attack_speed * delta
		player_attack_bar.value = 100 * player_attack_progress
		
		if player_attack_progress >= 1.0:
			print("Player Attack Hit!")
			enemy_health -= player_attack_damage
			%EnemyHitTimer.start()
			%Enemy.hide()
			%EnemyHurtSound.play()
			player_attack_progress = 0.0  # Reset attack
			player_attacking = false  # Stop attacking
			player_attack_bar.value = 0.0  # Reset bar visual

	# Enemy attack logic
	if not enemy_attacking:
		enemy_attack_timer += delta  # Only increase timer when enemy isn't attacking
	
	#if enemy_attack_timer >= enemy_attack_interval and not enemy_attacking:
		#start_enemy_attack()
#
	if enemy_attacking:
		enemy_attack_progress += enemy_attack_speed * delta
		enemy_attack_bar.value = 100 * enemy_attack_progress  # Fill up the enemy attack bar
		
		if enemy_attack_progress >= 1.0:
			enemy_attack_lands()
			
	# Parry window countdown
	if parry_timer > 0:
		parry_timer -= delta
		if parry_timer <= 0:
			print("Parry window closed.")
			parry_active = false  # Disable parry when window is closed
			parry_cooldown = parry_cooldown_duration  # Start cooldown
			print("Parry cooldown started.")

	# Parry cooldown countdown
	if parry_cooldown > 0:
		parry_cooldown -= delta
		if parry_cooldown <= 0:
			parry_cooldown = 0  # Reset cooldown

	# Parry icon timer
	if parry_success_timer > 0:
		parry_success_timer -= delta
		if parry_success_timer <= 0:
			parry_success.hide()


func _input(event):
	# Player starts attack when pressing "attack"
	if event.is_action_pressed("attack") and not player_attacking and not player_fatigued:
		player_stamina = max(player_stamina - player_attack_stamina_usage, 0)  # Ensures it never goes below 0
		player_attacking = true
	# Player parry logic
	if event.is_action_pressed("parry"):
		if parry_cooldown <= 0 and not parry_active:  # Only initiate parry if cooldown is over and player isn't parrying
			print("Player parrying...")
			parry_active = true  # Activate parry
			parry_timer = parry_window_duration  # Set the timer for the parry window
		elif parry_cooldown > 0:
			print("Parry is on cooldown. Please wait.")

	# Check if enemy attack lands during the parry window
	if parry_active and enemy_attack_progress >= 1.0:
		print("Attack has been deflected successfully!")
		parry_success_timer = 0.5  # Set timer to hide parry icon
		parry_active = false  # End the parry window once it is completed

func start_enemy_attack():
	enemy_attacking = true
	enemy_attack_timer = 0.0  # Reset attack timer
	enemy_attack_progress = 0.0  # Reset attack progress
	parry_timer = 0.0  # Reset parry timer
	
func enemy_attack_lands():
	if parry_active:
		print("Attack has been deflected successfully!")  # Successful parry
		%SwordClash.play()
		parry_success.show()
		parry_success_timer = 0.5  # Set timer to hide parry icon
	else:
		print("Enemy Attack Hit!")  # Player didn't parry successfully
		player_health -= enemy_attack_damage
		%PlayerHitTimer.start()
		%Player.hide()
		%PlayerHurtSound.play()
	parry_active = false  # Reset parry status
	enemy_attacking = false  # Stop attack state
	enemy_attack_progress = 0.0  # Reset bar
	enemy_attack_bar.value = 0.0  # Reset bar visual
	
func recover_stamina(delta):
		player_stamina += player_stamina_recovery_rate * delta  #  Gradually recovers stamina
		player_stamina = min(player_stamina, 100)  # Ensures it never exceeds 100

func _on_player_hit_timer_timeout() -> void:
	%Player.show()

func _on_enemy_hit_timer_timeout() -> void:
	%Enemy.show()

func _on_player_fatigued_timer_timeout() -> void:
	print("Stamina recovery started")
	player_fatigued = false
	player_stamina += 1
