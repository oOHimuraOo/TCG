extends TextureButton


var tamanho_deck = INF

func _ready():
	self.scale = find_parent("EspacoDeJogo").CardSize/self.size

func _on_pressed():
	if tamanho_deck > 0:
		tamanho_deck = find_parent("EspacoDeJogo").comprar_carta()
		if tamanho_deck <= 0:
			self.set_disabled(true)
