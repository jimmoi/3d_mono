extends Node3D

var played = false
func _ready() -> void:
		$AnimationPlayer.play("explode")
		await get_tree().create_timer(3).timeout
		queue_free()
