extends Label

var splash_text: Array = [
	"The farm always was bustling with activity.",
	"The farm produced a variety of crops.",
	"The farm was nestled in a valley.",
	"The farm was surrounded by fields.",
	"The farm was a peaceful place to be.",
	"The farm was a place of hard work.",
	"The farm had a rustic charm and beauty.",
	"The farm was a source of food and livelihood."
]

var generator = RandomNumberGenerator.new()


func _ready():
	generator.randomize()

	text = splash_text[generator.randi_range(0, splash_text.size() - 1)]
