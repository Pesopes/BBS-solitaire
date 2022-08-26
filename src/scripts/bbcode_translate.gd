extends RichTextLabel


export (String,MULTILINE)var bbcode_text_translate = ""

# is this effective idk...probably not
func _process(_delta):
	bbcode_text = tr(bbcode_text_translate)

