extends Spatial

onready var nav = $Navigation
onready var Ani = $"Navigation/NavigationMeshInstance/MainOffice 2/SM_Prop_Divider_Folding_01_Preset 1/AnimationPlayer"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# called by Game.gd upon player creation
func set_local_player(object):
	
	for d in $Doors.get_children():
		d.local_player = object
	
	for d in $PickableObjects.get_children():
		d.local_player = object


func get_navmesh():
	var navmesh = $Navigation/NavigationMeshInstance.navmesh
	var polygons = []
	var vertices = navmesh.get_vertices()
	
	for idx in navmesh.get_polygon_count():
		var polygon = []
		for v in navmesh.get_polygon(idx):
			var vertex = GameState.convert_coordinates_godot2robotics(global_transform.xform(vertices[v]))
			polygon.append([vertex.x, vertex.y, vertex.z])
		
		polygons.append(polygon)
	
	return polygons

func stage_2():
	Ani.play("down")	
