extends Node2D
class_name HudPanel

func _init(w:float,h:float, c:Color = Color.WHITE):
	var shape = Polygon2D.new()
	var packedArray :PackedVector2Array = []
	packedArray.append(Vector2(h,0))
	packedArray.append(Vector2(h+w,0))
	packedArray.append(Vector2(h+w+h,h*0.5))
	packedArray.append(Vector2(h+w,h))
	packedArray.append(Vector2(h,h))
	packedArray.append(Vector2(0,h*0.5))
	shape.polygon = packedArray
	shape.color = c
	add_child(shape)
	
