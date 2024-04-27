extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready():
	self.scale = find_parent("EspacoDeJogo").CardSize / 2 / self.size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
