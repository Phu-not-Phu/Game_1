extends Area3D

func _on_area_entered(area):
	if area.is_in_group("player"):
		$"../Dummy_Base2/AnimationPlayer".play("hit")
