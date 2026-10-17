extends RefCounted
## Head-anchored text shared by combat and the studio scene.
static func lines(text,font,size,width=290.0):
	var result=[];var line=""
	for word in text.split(" "):
		var candidate=word if line.is_empty() else line+" "+word
		if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and not line.is_empty():
			result.append(line);line=word
		else:line=candidate
	if not line.is_empty():result.append(line)
	return result
static func draw(target,font,text,head,size=18,color=Color("f4eadb"),width=290.0):
	var wrapped=lines(text,font,size,width)
	var anchor=Vector2(clampf(head.x,width*.5+12,1440-width*.5-12),maxf(105,head.y))
	for i in range(wrapped.size()):
		var line=wrapped[i];var w=font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		var at=anchor+Vector2(-w*.5,-12-(wrapped.size()-1-i)*(size+4))
		target.draw_string_outline(font,at,line,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color("15101d"))
		target.draw_string(font,at,line,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
static func utterances(line):
	if line.speaker=="Jimmy / Johan":return [{"speaker":"Jimmy","text":"Okej, tänk dig följande scenario..."},{"speaker":"Johan","text":"Jaha, då kör vi väl."}]
	return [{"speaker":line.speaker,"text":line.text}]
