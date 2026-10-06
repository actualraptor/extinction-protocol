extends RefCounted
## Skin the lower part of each painted attack pose; the weapon and emission
## anchor stay rigid. Distance-driven strides continue beneath the upper action.
static func draw(target,frame,p,flip,tint,phase,moving,hero):
	var rect=Rect2(-frame.anchor*frame.scale,frame.texture.get_size()*frame.scale)
	target.draw_set_transform(p+Vector2(0,8),0,Vector2(-1 if flip else 1,1))
	if not moving:
		target.draw_texture_rect(frame.texture,rect,false,tint)
	else:
		var vertices=PackedVector2Array();var uv=PackedVector2Array();var colors=PackedColorArray();var indices=PackedInt32Array()
		var columns=16;var rows=24
		var gait=phase*TAU/4.0
		for y in range(rows+1):
			for x in range(columns+1):
				var st=Vector2(float(x)/columns,float(y)/rows)
				var at=rect.position+st*rect.size
				# Weight around the two leg chains, never the outer weapon silhouette.
				var leg_left=-15.0 if hero==1 else -9.0
				var leg_right=-2.0 if hero==1 else 7.0
				var lower=smoothstep(-33,-4,at.y)
				var left=exp(-pow((at.x-leg_left)/9.0,4))*lower
				var right=exp(-pow((at.x-leg_right)/8.0,4))*lower
				var stride=sin(gait)
				at.x+=stride*(left-right)*3.0
				at.y-=maxf(0,stride)*left*3.5+maxf(0,-stride)*right*3.5
				vertices.append(at);uv.append(st);colors.append(tint)
		for y in range(rows):
			for x in range(columns):
				var a=y*(columns+1)+x;var b=a+1;var c=a+columns+1;var d=c+1
				indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
		RenderingServer.canvas_item_add_triangle_array(target.get_canvas_item(),indices,vertices,colors,uv,PackedInt32Array(),PackedFloat32Array(),frame.texture.get_rid())
	target.draw_set_transform(Vector2.ZERO)
