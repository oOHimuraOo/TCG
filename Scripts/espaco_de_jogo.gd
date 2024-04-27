extends Node2D


const CardSize = Vector2(175,250)
const CardBase = preload("res://Cenas/card_layout.tscn")
const CardSlot = preload("res://Cenas/CardSlot.tscn")

var carta_selecionada = []
var tamanho_deck = Playerhand.CARDLIST.size()

@onready var cartas = $Cartas
@onready var deck_cava = $Deck/DeckCava
@onready var cemiterio = $Cemiterio/CemiterioButton
@onready var carta_central_oval = Vector2(get_viewport().size) * Vector2(0.5, 1.25)
@onready var raio_horizontal = get_viewport().size.x * 0.5
@onready var raio_vertical = get_viewport().size.y * 0.4
@onready var posicao_do_deck:Vector2 = deck_cava.position
@onready var discard_position:Vector2 = cemiterio.position


var angulo #= deg_to_rad(90) - 0.69
var angulo_oval_vetor:Vector2
var epacamento_de_cartas = 0.185
var quantidade_de_cartas_na_mao = -1
var numero_da_carta = 0

var slot_de_carta_vazio:Array = []


func _ready():
	randomize()
	await get_tree().create_timer(0.1).timeout
	novo_espaco_de_cartas()

func novo_espaco_de_cartas():
	var count = 0
	for x in range(3):
		if find_child("EspacoDeCartas").get_child_count() <= 3:
			var novo_slot = CardSlot.instantiate()
			novo_slot.scale = CardSize/novo_slot.size
			novo_slot.position = get_viewport().size * 0.4 + Vector2(-400,-400)
			novo_slot.rotation = deg_to_rad(90)
			slot_de_carta_vazio.append(true)
			find_child("EspacoDeCartas").add_child(novo_slot)
	for child in find_child("EspacoDeCartas").get_children():
		child.position += Vector2(0, 200 * count)
		count += 1

func comprar_carta():
	angulo = PI/2 + epacamento_de_cartas * (float(quantidade_de_cartas_na_mao)/2 - quantidade_de_cartas_na_mao)
	var nova_carta = CardBase.instantiate()
	carta_selecionada = randi_range(0,tamanho_deck-1)
	nova_carta.cardname = Playerhand.CARDLIST[carta_selecionada]
	nova_carta.position = posicao_do_deck - CardSize/2
	nova_carta.discardpile = discard_position - CardSize/1.337
	nova_carta.scale *= CardSize/nova_carta.size
	nova_carta.estado = nova_carta.MOVENDO_CARTA_DO_DECK_PRA_MAO
	numero_da_carta = 0
	cartas.add_child(nova_carta)
	Playerhand.CARDLIST.erase(Playerhand.CARDLIST[carta_selecionada])
	tamanho_deck -= 1
	angulo += 0.23
	quantidade_de_cartas_na_mao += 1
	organizador_de_mao()
	return tamanho_deck

func organizador_de_mao():
	for carta in cartas.get_children():
		angulo = PI/2 + epacamento_de_cartas * (float(quantidade_de_cartas_na_mao)/2 - numero_da_carta)
		angulo_oval_vetor = Vector2(raio_horizontal * cos(angulo), -raio_vertical * sin(angulo))
		carta.posicao_alvo = Vector2(carta_central_oval) + angulo_oval_vetor - CardSize
		carta.posicao_padrao = Vector2(carta_central_oval) + angulo_oval_vetor - CardSize
		carta.rotacao_inicial = deck_cava.rotation
		carta.rotacao_final = (deg_to_rad(90) - angulo)/4
		carta.numero_da_carta = quantidade_de_cartas_na_mao
		numero_da_carta += 1
		if carta.estado == carta.NA_MAO:
			carta.setup = true
			carta.estado = carta.REOGANIZANDO_MAO
		elif carta.estado == carta.MOVENDO_CARTA_DO_DECK_PRA_MAO:
			carta.posicao_inicial = carta.posicao_alvo - (carta.posicao_alvo - carta.position/(1-carta.tempo))
