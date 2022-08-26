extends AudioStreamPlayer

export (AudioStream)var card_play
export (AudioStream)var card_pickup
export (AudioStream)var win
export (AudioStream)var lose

func play_stream(custom_stream:AudioStream):
	stream = custom_stream
	play()

func play_card():
	play_stream(card_play)
	
func play_card_pickup():
	play_stream(card_pickup)

func play_win():
	play_stream(win)

func play_lose():
	play_stream(lose)
