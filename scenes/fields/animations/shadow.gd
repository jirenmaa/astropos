extends TileMap

# for scaling animation
var scaled: bool = false
var size_x = scale.x
var size_y = scale.y
var counter = 6  # frame per (.18) second


func _ready():
	var animation = Timer.new()
	add_child(animation)

	animation.connect("timeout", self, "_on_Timer_timeout")
	animation.set_wait_time(0.18)
	animation.set_one_shot(false)
	animation.start()


func _on_Timer_timeout():
	if scaled and counter < 6:
		size_x -= 0.01
		size_y -= 0.01
		counter += 1
		scaled = true
		scale = Vector2(size_x, size_y)
	else:
		scaled = false

	# the animation will start by scaling it up
	if not scaled and counter >= 0:
		size_x += 0.01
		size_y += 0.01
		counter -= 1
		scaled = false
		scale = Vector2(size_x, size_y)
	else:
		scaled = true
