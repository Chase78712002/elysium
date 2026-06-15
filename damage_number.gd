extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Float up and fade out, then remove self
	var tween:= create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 80.0, 0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.finished.connect(queue_free)
