extends Control

func _ready() -> void:
	$AnimationPlayer.play("float_up")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "float_up":
		queue_free()
