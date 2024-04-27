extends Control

@onready var barra_vida = $OrganizadorInterface/BarraVida
@onready var etiqueta_vida = $OrganizadorInterface/BarraVida/EtiquetaVida
@onready var etiqueta_nome = $OrganizadorInterface/backgroundNome/EtiquetaNome
@onready var imagem_inimigo = $OrganizadorInterface/ImagemInimigo
@onready var respawn = $respawn

var vida_atual:int
var vida_maxima:int
var vida_percentual:int = 100

var morto:bool = false
var vida_mudou:bool = true
var ataque:int = 15

func _ready():
	vida_maxima = 100
	vida_atual = vida_maxima

func _process(_delta):
	atualizador_de_barra_de_vida()

func atualizador_de_barra_de_vida():
	if morto == false:
		if vida_mudou == true:
			vida_mudou = false
			barra_vida.value = vida_atual
			etiqueta_vida.set_text(str(vida_atual) + "/" + str(vida_maxima))
			if vida_maxima != barra_vida.max_value:
				barra_vida.max_value = vida_maxima
			if vida_atual > vida_maxima:
				vida_atual = vida_maxima
			if vida_atual <= 0:
				vida_atual = 0
				morto = true
				morreu()

func morreu():
	imagem_inimigo.self_modulate = "ff0000"
	await get_tree().create_timer(3).timeout
	self.hide()
	respawn.start()
	
func respawn_funcao():
	if morto == true:
		if self.is_visible_in_tree() == false:
			morto = false
			vida_atual = vida_maxima
			imagem_inimigo.self_modulate = "ffffff"
			self.show()

func _on_respawn_timeout():
	respawn_funcao()

func recebi_dano(dano:int):
	vida_atual -= dano
	vida_mudou = true

func recebi_cura(cura:int):
	vida_atual += cura
	vida_mudou = true

func aumentou_minha_vida_maxima(aumento:int):
	vida_maxima += aumento

func diminuio_minha_vida_maxima(diminuio:int):
	vida_maxima -= diminuio

func ataquei(carta_atacante):
	carta_atacante.atualizador_de_vida_atual(ataque,false)
