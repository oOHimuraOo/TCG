extends Control

@onready var card_img = $CardImg
@onready var vida = $Vida
@onready var nome = $Organizador/OrganizadorNome/Nome
@onready var tipo = $Organizador/OrganizadorTipagem/Tipo
@onready var classe_e_alcance = $Organizador/OrganizadorTipagem/ClasseEAlcance
@onready var habilidade_paragrafo = $Organizador/OrganizadorBottom/OrganizadorParagrafos/HabilidadeScroller/HabilidadeParagrafo
@onready var flavor_paragrafo = $Organizador/OrganizadorBottom/OrganizadorParagrafos/FlavorScroller/FlavorParagrafo
@onready var barra_atq = $Organizador/OrganizadorBottom/OrganizadorAtt/OrganizadorAtq/Marginalizador/Posicionador/BarraAtq
@onready var barra_def = $Organizador/OrganizadorBottom/OrganizadorAtt/OrganizadorDef/Marginalizador/Posicionador/BarraDef
@onready var barra_spd = $Organizador/OrganizadorBottom/OrganizadorAtt/OrganizadorSpd/Marginalizador/Posicionador/BarraSpd
@onready var barra_rgn = $Organizador/OrganizadorBottom/OrganizadorAtt/OrganizadorRgn/Marginalizador/Posicionador/BarraRgn
@onready var barra_cdn = $Organizador/OrganizadorBottom/OrganizadorAtt/OrganizadorCdn/Marginalizador/Posicionador/BarraCdn
@onready var cardfundo = $Cardfundo

var cardname:String = "Fari"
var CardInfo = Database.DATA[cardname]
 
var vida_atual:int = 0
var vida_maxima:int = 0
var ataque_atual:int = 0
var defesa_atual:int = 0
var velocidade_atual:int = 0
var regeneracao_atual:int = 0
var cooldown_atual:int = 0

var rotacao_inicial = 0
var rotacao_final = 0
var posicao_inicial = 0
var posicao_alvo = 0
var tempo = 0
var tempo_de_cava:float = 0.8

var escala_original

var setup:bool = true
var escala_inicial:Vector2 
var posicao_padrao
var zoom_no_tamanho = 3

var reoganizar_vizinhos:bool = true
var quantidade_de_cartas_na_mao
var numero_da_carta
var carta_vizinha
var verificador_de_movimento_de_vizinho:bool = false

var carta_selecionada:bool = true
var estado_antigo

var tempo_no_mouse:float = 0.01
var movendo_para_jogo:bool = false
var escala_alvo:Vector2
var carta_na_mao:bool = false

var discardpile
var movendo_para_o_discarte:bool

enum {NA_MAO, EM_JOGO, NO_MOUSE, FOCO_NA_MAO, FOCO_EM_JOGO, MOVENDO_CARTA_DO_DECK_PRA_MAO, REOGANIZANDO_MAO, MOVENDO_CARTA_PARA_DISCARTE} 
var estado = NA_MAO

func _ready():
	carregadora_de_informacao()
	atualizador_de_vida_maxima(CardInfo[1], true)
	atualizador_de_vida_atual(vida_maxima, true)
	atualizador_de_ataque_atual(10, true)
	atualizador_de_defesa_atual(CardInfo[3], true)
	atualizador_de_velocidade_atual(CardInfo[4], true)
	atualizador_de_regeneracao_atual(CardInfo[5], true)
	atualizador_de_cooldown_atual(CardInfo[6], true)
	escala_original = self.scale

func _input(_event):
	match estado:
		FOCO_NA_MAO, NO_MOUSE, EM_JOGO:
			if Input.is_action_pressed("left_click"):
				if carta_selecionada == true:
					estado_antigo = estado
					estado = NO_MOUSE
					setup = true
					carta_selecionada = false
			if Input.is_action_just_released("left_click"):
				if carta_selecionada == false:
					if estado_antigo == FOCO_NA_MAO:
						var slot_de_carta = find_parent("EspacoDeJogo").find_child("EspacoDeCartas")
						var slot_de_carta_vazio = find_parent("EspacoDeJogo").slot_de_carta_vazio
						for x in range(slot_de_carta.get_child_count()):
							if slot_de_carta_vazio[x] == true:
								var slot_position = slot_de_carta.get_child(x).position
								var slot_rotacao = slot_de_carta.get_child(x).rotation
								var slot_size = slot_de_carta.get_child(x).size
								var mouse_position = get_global_mouse_position()
								if mouse_position.x < slot_position.x + slot_size.x && mouse_position.x > slot_position.x && mouse_position.y < slot_position.y + slot_size.y && mouse_position.y > slot_position.y:
									setup = true
									movendo_para_jogo = true
									posicao_alvo = slot_position 
									rotacao_final = slot_rotacao
									escala_alvo = find_parent("EspacoDeJogo").CardSize / slot_size
									estado = EM_JOGO
									carta_selecionada = true
									carta_na_mao = false
									find_parent("EspacoDeJogo").slot_de_carta_vazio[x] = false
									break
						if estado != EM_JOGO:
							setup = true
							posicao_alvo = posicao_padrao
							estado = REOGANIZANDO_MAO
							carta_selecionada = true
					else:
						var inimigos = find_parent("EspacoDeJogo").find_child("Inimigos")
						for x in range(inimigos.get_child_count()):
							var inimigo_position = inimigos.get_child(x).position
							var inimigo_size = inimigos.get_child(x).size
							var mouse_position = get_global_mouse_position()
							if mouse_position.x < inimigo_position.x + inimigo_size.x && mouse_position.x > inimigo_position.x && mouse_position.y < inimigo_position.y + inimigo_size.y && mouse_position.y > inimigo_position.y:
								inimigos.get_child(x).recebi_dano(ataque_atual)
								inimigos.get_child(x).ataquei(self)
								setup = true
								movendo_para_jogo = true
								movendo_para_o_discarte = true
								estado = MOVENDO_CARTA_PARA_DISCARTE
#								estado = EM_JOGO
#								carta_selecionada = true
								carta_na_mao = false
								break
						if carta_selecionada == false:
							setup = true
							movendo_para_jogo = true
							#estado = EM_JOGO
							carta_selecionada = true
							carta_na_mao = false

func _physics_process(delta):
	match estado:
		NA_MAO:
			pass
		EM_JOGO:
			if movendo_para_jogo == true:
				if setup == true:
					incializador()
				if tempo <= 1:
					self.position = posicao_inicial.lerp(posicao_alvo, tempo)
					self.rotation = rotacao_inicial * (1-tempo) + rotacao_final * tempo
					self.scale = escala_original * (1-tempo) + escala_alvo * tempo
					if cardfundo.is_visible_in_tree():
						if tempo > 0.5:
							cardfundo.hide()
					tempo += delta/float(tempo_no_mouse)
				else:
					self.position = posicao_alvo
					self.scale = escala_alvo
					self.rotation = rotacao_final
		NO_MOUSE:
			if setup == true:
				incializador()
			if tempo <= 1:
				self.position = posicao_inicial.lerp(get_global_mouse_position() - find_parent("EspacoDeJogo").CardSize,tempo)
				self.rotation = rotacao_inicial * (1-tempo) + rotacao_final * tempo
				self.scale = escala_original * abs(2*tempo - 1)
				if cardfundo.is_visible_in_tree():
					if tempo > 0.5:
						cardfundo.hide()
				tempo += delta/float(tempo_no_mouse)
			else:
				self.position = get_global_mouse_position() - find_parent("EspacoDeJogo").CardSize
				self.rotation = 0
		FOCO_NA_MAO:
			if setup:
				incializador()
			if tempo <= 1:
				self.position = posicao_inicial.lerp(posicao_alvo,tempo)
				self.rotation = rotacao_inicial * (1-tempo) + 0 * tempo
				self.scale = escala_inicial.lerp(escala_original*zoom_no_tamanho, tempo)
				tempo += delta/float(tempo_de_cava/4)
				if carta_na_mao == true:
					if reoganizar_vizinhos:
						reoganizar_vizinhos = false
						quantidade_de_cartas_na_mao = find_parent("EspacoDeJogo").quantidade_de_cartas_na_mao - 1
						if numero_da_carta - 1 >= 0:
							mover_vizinho(numero_da_carta - 1, true, 1)
						if numero_da_carta - 2 >= 0:
							mover_vizinho(numero_da_carta - 2, true, 0.5)
						if numero_da_carta - 3 >= 0:
							mover_vizinho(numero_da_carta - 3, true, 0.25)
						if numero_da_carta + 1 <= quantidade_de_cartas_na_mao:
							mover_vizinho(numero_da_carta + 1, false, 1)
						if numero_da_carta + 2 <= quantidade_de_cartas_na_mao:
							mover_vizinho(numero_da_carta + 2, false, 0.5)
						if numero_da_carta + 3 <= quantidade_de_cartas_na_mao:
							mover_vizinho(numero_da_carta + 3, false, 0.25)
			else:
				self.position = posicao_alvo
				self.rotation = 0
				self.scale = escala_original*zoom_no_tamanho
		FOCO_EM_JOGO:
			pass
		MOVENDO_CARTA_DO_DECK_PRA_MAO:
			if setup == true:
				incializador()
			if tempo <= 1:
				self.position = posicao_inicial.lerp(posicao_alvo,tempo)
				self.rotation = rotacao_inicial * (1-tempo) + rotacao_final * tempo
				self.scale.x = escala_original.x * abs(2*tempo - 1)
				if cardfundo.is_visible_in_tree():
					if tempo > 0.5:
						cardfundo.hide()
				tempo += delta/float(tempo_de_cava)
			else:
				self.position = posicao_alvo
				self.rotation = rotacao_final
				estado = NA_MAO
				carta_na_mao = true
				tempo = 0
		REOGANIZANDO_MAO:
			if carta_na_mao == true:
				if setup:
					incializador()
				if tempo <= 1:
					if verificador_de_movimento_de_vizinho == true:
						verificador_de_movimento_de_vizinho = false
					self.position = posicao_inicial.lerp(posicao_alvo,tempo)
					self.rotation = rotacao_inicial * (1-tempo) + rotacao_final * tempo
					self.scale = escala_inicial.lerp(escala_original, tempo)
					tempo += delta/float(tempo_de_cava/4)
					if reoganizar_vizinhos == false:
						reoganizar_vizinhos = true
						if numero_da_carta - 1 >= 0:
							resetar_posicao(numero_da_carta - 1)
						if numero_da_carta - 2 >= 0:
							resetar_posicao(numero_da_carta - 2)
						if numero_da_carta - 3 >= 0:
							resetar_posicao(numero_da_carta - 3)
						if numero_da_carta + 1 <= quantidade_de_cartas_na_mao:
							resetar_posicao(numero_da_carta + 1)
						if numero_da_carta + 2 <= quantidade_de_cartas_na_mao:
							resetar_posicao(numero_da_carta + 2)
						if numero_da_carta + 3 <= quantidade_de_cartas_na_mao:
							resetar_posicao(numero_da_carta + 3)
				else:
					self.position = posicao_alvo
					self.rotation = rotacao_final
					self.scale = escala_original
					estado = NA_MAO
		MOVENDO_CARTA_PARA_DISCARTE:
			if movendo_para_o_discarte == true:
				if setup == true:
					incializador()
					posicao_alvo = discardpile
					rotacao_final = find_parent("EspacoDeJogo").find_child("CemiterioButton").rotation
					escala_alvo = find_parent("EspacoDeJogo").find_child("CemiterioButton").scale
				if tempo <= 1:
					self.position = posicao_inicial.lerp(posicao_alvo,tempo)
					self.rotation = rotacao_inicial * (1-tempo) + rotacao_final * tempo
					self.scale = escala_original * (1-tempo) + escala_alvo * tempo
					if cardfundo.is_visible_in_tree():
						if tempo > 0.5:
							cardfundo.hide()
					tempo += delta/float(tempo_de_cava)
				else:
					self.position = posicao_alvo
					self.rotation = rotacao_final
					movendo_para_o_discarte = false


func incializador():
	posicao_inicial = position
	rotacao_inicial = rotation
	escala_inicial = scale
	tempo = 0
	setup = false

func carregadora_de_informacao():
	var textura = load(str("res://Assets/Ilustracoes/", CardInfo[0], "/", cardname, ".jpg"))
	card_img.set_texture(textura)
	nome.set_text(cardname)
	tipo.set_text(CardInfo[0])
	classe_e_alcance.set_text(str(CardInfo[7] + " " + CardInfo[8]))
	habilidade_paragrafo.set_text(CardInfo[9])
	flavor_paragrafo.set_text(CardInfo[10])

func atualizador_de_vida_maxima(valor:int, ganho:bool):
	if ganho == true:
		vida_maxima += valor
	else:
		vida_maxima -= valor
		if vida_maxima <= 10:
			vida_maxima = 10

func atualizador_de_vida_atual(valor:int, ganho:bool):
	if ganho == true:
		vida_atual += valor
		vida.set_text(str(vida_atual))
		if vida_atual >= vida_maxima:
			vida_atual = vida_maxima
			vida.set_text(str(vida_atual))
	else:
		vida_atual -= valor
		vida.set_text(str(vida_atual))
		if vida_atual <= 0:
			vida_atual = 0
			vida.set_text(str(vida_atual))
			morreu()

func atualizador_de_ataque_atual(valor:int, ganho:bool):
	if ganho == true:
		ataque_atual += valor
		barra_atq.value = ataque_atual
		if ataque_atual >= barra_atq.max_value:
			ataque_atual = barra_atq.max_value
			barra_atq.value = ataque_atual
	else:
		ataque_atual -= valor
		barra_atq.value = ataque_atual
		if ataque_atual <= barra_atq.min_value:
			ataque_atual = 1
			barra_atq.value = ataque_atual

func atualizador_de_defesa_atual(valor:int, ganho:bool):
	if ganho == true:
		defesa_atual += valor
		barra_def.value = defesa_atual
		if defesa_atual >= barra_def.max_value:
			defesa_atual = barra_def.max_value
			barra_def.value = defesa_atual
	else:
		defesa_atual -= valor
		barra_def.value = defesa_atual
		if defesa_atual <= barra_def.min_value:
			defesa_atual = 1
			barra_def.value = defesa_atual

func atualizador_de_velocidade_atual(valor:int, ganho:bool):
	if ganho == true:
		velocidade_atual += valor
		barra_spd.value = velocidade_atual
		if velocidade_atual >= barra_spd.max_value:
			velocidade_atual = barra_spd.max_value
			barra_spd.value = velocidade_atual
	else:
		velocidade_atual -= valor
		barra_spd.value = velocidade_atual
		if velocidade_atual <= barra_spd.min_value:
			velocidade_atual = 1
			barra_spd.value = velocidade_atual

func atualizador_de_regeneracao_atual(valor:int, ganho:bool):
	if ganho == true:
		regeneracao_atual += valor
		barra_rgn.value = regeneracao_atual
		if regeneracao_atual >= barra_rgn.max_value:
			regeneracao_atual = barra_rgn.max_value
			barra_rgn.value = regeneracao_atual
	else:
		regeneracao_atual -= valor
		barra_rgn.value = regeneracao_atual
		if regeneracao_atual <= barra_rgn.min_value:
			regeneracao_atual = 1
			barra_rgn.value = regeneracao_atual

func atualizador_de_cooldown_atual(valor:int, ganho:bool):
	if ganho == true:
		cooldown_atual += valor
		barra_cdn.value = cooldown_atual
		if cooldown_atual >= barra_cdn.max_value:
			cooldown_atual = barra_cdn.max_value
			barra_cdn.value = cooldown_atual
	else:
		cooldown_atual -= valor
		barra_cdn.value = cooldown_atual
		if cooldown_atual <= barra_cdn.min_value:
			cooldown_atual = 1
			barra_cdn.value = cooldown_atual

func _on_mouse_focus_mouse_entered():
	match estado:
		NA_MAO, REOGANIZANDO_MAO:
			setup = true
			posicao_alvo = posicao_padrao
			posicao_alvo.y = get_viewport().size.y - find_parent("EspacoDeJogo").CardSize.y*zoom_no_tamanho
			estado = FOCO_NA_MAO

func _on_mouse_focus_mouse_exited():
	match estado:
		FOCO_NA_MAO:
			setup = true
			posicao_alvo = posicao_padrao
			estado = REOGANIZANDO_MAO

func mover_vizinho(vizinho:int, esquerda:bool, fator_de_movimento:float):
	carta_vizinha = find_parent("Cartas").get_child(vizinho)
	if esquerda == true:
		carta_vizinha.posicao_alvo = carta_vizinha.posicao_padrao - fator_de_movimento * Vector2(find_parent("EspacoDeJogo").CardSize.x, 0)
	else:
		carta_vizinha.posicao_alvo = carta_vizinha.posicao_padrao + fator_de_movimento * Vector2(find_parent("EspacoDeJogo").CardSize.x, 0)
	carta_vizinha.setup = true
	carta_vizinha.estado = carta_vizinha.REOGANIZANDO_MAO
	carta_vizinha.verificador_de_movimento_de_vizinho = true

func resetar_posicao(vizinho:int):
	carta_vizinha = find_parent("Cartas").get_child(vizinho)
	if carta_vizinha.verificador_de_movimento_de_vizinho == false:
		if carta_vizinha.estado != FOCO_NA_MAO:
			carta_vizinha.estado = carta_vizinha.REOGANIZANDO_MAO
			carta_vizinha.posicao_alvo = carta_vizinha.posicao_padrao
			carta_vizinha.setup = true

func morreu():
	print("morreu")
