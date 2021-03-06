extends KinematicBody2D

#Configurando valores de velocidade máxima, aceleração e friccção do personagem.
export var MAX_SPEED = 80
export var ACCELERATION = 580
export var FRICTION = 580

#Definindo constantes para as ações do personagem.
enum {
	MOVE,
	ATTACK
}

#Definindo variáveis para velocidade e estado do personagem.
var velocity = Vector2.ZERO
var state = MOVE
var stats = PlayerStats

#Definindo variaveis para a animação.
onready var animationPlayer = $AnimationPlayer
onready var animationTree = $PreAnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitobox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox

signal player_morto(global_position)

#Função para ativar elementos ao abrir o jogo.
func _ready():
	stats.connect("no_health", self, "player_death")
	connect("player_morto", get_tree().get_current_scene(), "on_player_morto")
	connect("player_morto", get_parent().get_node("Camera"), "on_player_morto")
	if stats.armor == true:
		_on_ArmorPickUp_pegar_armor()
	#Ativar árvore de animação.
	animationTree.active = true
	#Ativar direção inicial para o knockback.
	swordHitobox.knockback_vector = Vector2.LEFT

func _physics_process(delta):
	#Definido a animação e ações do personagem baseados nos inputs
	match state:
		MOVE:
			move_state(delta)
		
		ATTACK:
			attack_state()
	
	#Variável que garante que o jogador não tenha mais do que o limite de chaves
	#chaves = min(chaves,9)

func move_state(delta):
	#Ligando inputs do teclado a direções que o jogador irá se movimentar. 
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		swordHitobox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	move()
	
	#Ativar state ATTACK, quando pressionar botão para atacar.
	if Input.is_action_just_pressed("atacar") and stats.espada:
		state = ATTACK

#função para o player parar de se movimentar e puxar a animação de ataque.
func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func move():
	velocity = move_and_slide(velocity)

# Aciona o state MOVE quando o ataque finaliza.
func attack_end():
	state = MOVE

# Diminui a vida quando detecta um ataque.
func _on_Hurtbox_area_entered(_area):
	stats.health -= 1
	hurtbox.start_invincibility(0.7)
	hurtbox.create_hit_effect()
	
# Emite um sinal com a posição do player antes de morrer
func player_death():
	emit_signal("player_morto", global_position)
	queue_free()
		

func _on_ArmorPickUp_pegar_armor():
	animationTree.active = false
	animationTree = $AnimationTree
	animationState = animationTree.get("parameters/playback")
	animationTree.active = true
	get_node("PreSprite").hide()
	get_node("Sprite").show()
	
	
	
