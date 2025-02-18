extends Spatial

####### THESE ENUMS ARE *ONLY* FOR CONFIGURATION IN THE GODOT EDITOR UI ########
####### See GameState for the actual global variables used in the code #########

# set the initial game mode. Can be overridden by 
# command-line arguments --server, --client, --standalone
enum modes {UNSET, CLIENT, SERVER, STANDALONE}
export(modes) var run_as = modes.UNSET

# by default, the game supports adding robots; robots can be disabled if eg
# it is only played online with human users.
enum RobotsMode {ROBOTS, NO_ROBOTS}
export(RobotsMode) var has_robots = RobotsMode.ROBOTS

export(bool) var enable_focus_blur = true

export(bool) var random_player_start_positions = true
export(bool) var random_robot_start_positions = true

###############################################################################

var SERVER_URL= "http://18.171.213.148/" #"127.0.0.1"#

var SERVER_PORT=6969 # only used for the server -- the client will always connect to the default wss port (80 or 443)

var time_start=0 
var time_now=0

var prolific_id

var is_networking_started

var local_player
var player_name
var player_skin

# dictionary of ImageTexture created by users of the Python API when
# uploading images to the server.
# used eg to set the texture on the robots' screens
var screen_textures = {}

# if changing that, make sure to add spawn points accordingly
var MAX_PLAYERS = 10

export(String) var username = "John Doe"

# Player info, associate ID to data
var player_info = {}

# stores the distances between players
var players_distances = {}

var robots = {}
var local_robot = null

# whether or not laserscans are displayed. Changed via the settings in the UI
# (cf callback 'toggle_robots_lasers')
var show_laserscans = false

var robot_server

var debug = false

var robot_visible



onready var navmesh = $MainOffice.get_navmesh()
onready var player = $Players
onready var ChatLabel = $CanvasLayer/UI/Bottom/ColorRect/VBoxContainer/CenterContainer/ColorRect/CenterContainer/VBoxContainer/Chat

func _ready():
	
	$CanvasLayer/Effects/VignetteEffect.visible = enable_focus_blur
	
	time_start= OS.get_unix_time()
		
	
	randomize()
	
	var _err = $CanvasLayer/UI/Settings.connect("on_toggle_laser", self, "toggle_robots_lasers")
	_err = $CanvasLayer/UI/Settings.connect("on_toggle_npcs", self, "toggle_npcs")
	toggle_npcs($CanvasLayer/UI/Settings.NPCsBtn.pressed)
	
	set_physics_process(false)
	
	# highest priority for cmd line arguments.
	# -> they override any other parameter
	for argument in OS.get_cmdline_args():
		if argument == "--server":
			GameState.mode = GameState.SERVER
		if argument == "--client":
			GameState.mode = GameState.CLIENT
		if argument == "--standalone":
			GameState.mode = GameState.STANDALONE
		if "--name=" in argument:
			player_name = argument.right(7)
			player_skin = "res://assets/characters/skins/casualFemaleA_neutral.png"
		if "--server=" in argument:
			SERVER_URL = argument.right(9)
			
		if "--port=" in argument:
			SERVER_PORT = argument.right(7).to_int()
			
	# then, if game mode has been set in Godot, use that:
	if GameState.mode == GameState.UNSET:
		GameState.mode = run_as
		
	# finally, if still not set, show the selection screen
	if GameState.mode == GameState.UNSET:
		$CanvasLayer/ParticipantInformation.visible = true
		var url = yield($CanvasLayer/ParticipantInformation,"on_mode_set")

		if url == null: # single player!
			GameState.mode = GameState.STANDALONE
		else:
			GameState.mode = GameState.CLIENT
			SERVER_URL=url
			print("Setting the game server to " + SERVER_URL)
	
	# at that point, we should know our game mode
	assert(GameState.mode != GameState.UNSET)
	
	
	set_physics_process(true)
		
	# the web version are always clients;
	if OS.get_name() == "HTML5" and GameState.mode == GameState.SERVER:
		print("ERROR: when exporting to HTML5 platform, the game can *not* be in server mode")
		get_tree().quit(1)
	
	if GameState.mode == GameState.CLIENT:

		$FakePlayer/Camera.current = false
		
		# the name of the player was given on cmd-line? no need to choose the dialog
		if player_name:
			$CanvasLayer/CharacterSelection.visible = false
	
	elif GameState.mode == GameState.SERVER:

		$FakePlayer/Camera.current = true
		$CanvasLayer/UI.visible = false
		$CanvasLayer/CharacterSelection.visible = false
		$CanvasLayer/Effects.visible = false
	
	elif GameState.mode == GameState.STANDALONE:
		
		$FakePlayer/Camera.current = false
		
		# the name of the player was given on cmd-line? no need to choose the dialog
		if player_name:
			$CanvasLayer/CharacterSelection.visible = false
		
	else:
		assert(false)
		
	var peer

			
	if GameState.mode == GameState.SERVER:
		print("STARTING AS SERVER")
		
		peer = WebSocketServer.new()
		
		# the last 'true' parameter enables the Godot high-level multiplayer API
		var error = peer.listen(SERVER_PORT, PoolStringArray(), true)
		
		if error != OK:
			match error:
				ERR_ALREADY_IN_USE:
					print("Port already in use! Most likely a server is already running. Exiting.")
					get_tree().quit(1)
					return
				_:
					print("Error code " + str(error) + " when starting the server. Exiting.")
					get_tree().quit(1)
					return
					
		get_tree().network_peer = peer
		is_networking_started = true        
		
		
		local_player = $FakePlayer
		configure_physics()
		
		if GameState.robots_enabled():
			robot_server = RobotServer.new(self)

		
	elif GameState.mode == GameState.CLIENT:
		print("STARTING AS CLIENT")
		
		set_physics_process(false)
	
		# if we do not already have the player name, wait for the character creation to be complete
		if not player_name:
			var res = yield($CanvasLayer/CharacterSelection,"on_character_created")
#			player_name = res[0]
			player_skin = res[0]
		
#		$CanvasLayer/UI.set_name_skin(player_name, player_skin)
		
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		
		# then, initiate the connection to the server
		
		peer = WebSocketClient.new()
		
		# the last 'true' parameter enables the Godot high-level multiplayer API
		peer.connect_to_url(SERVER_URL, PoolStringArray(), true)
		get_tree().network_peer = peer
		
		is_networking_started = true

	elif GameState.mode == GameState.STANDALONE:
		print("STARTING IN STANDALONE MODE")

		# if we do not already have the player name, wait for the character creation to be complete
		if not player_name:
			var res = yield($CanvasLayer/CharacterSelection,"on_character_created")
#			player_name = res[0]
			player_skin = res[0]
		
#		$CanvasLayer/UI.set_name_skin(player_name, player_skin)
		
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		
		configure_physics()
		
		if GameState.robots_enabled():
			robot_server = RobotServer.new(self)
			
		is_networking_started = true   
		
		pre_configure_game()
		
	yield(get_tree().create_timer(0.5), "timeout")
		
#	assign_random_ids_to_players()

	
	

func configure_physics():
	
	shuffle_spawn_points()
	
	# enable physics calculations for all the dynamics objects, *on the server only* (or in stand-alone mode)
	for o in $MainOffice/DynamicObstacles.get_children():
		o.call_deferred("set_physics_process", true)
	for o in $MainOffice/PickableObjects.get_children():
		o.call_deferred("set_physics_process", true)
	
	
func _process(_delta):
	

		
	if is_networking_started:
		
		
		if GameState.mode == GameState.SERVER or GameState.mode == GameState.CLIENT:
			# server & clients need to poll, according to https://docs.godotengine.org/en/stable/classes/class_websocketclient.html#description
			get_tree().network_peer.poll()
			
		if GameState.mode == GameState.SERVER or GameState.mode == GameState.STANDALONE:
			update_players_proximity()
		
		if GameState.robots_enabled():
			# only the server polls for the robot websocket server (or the standalone client)
			if GameState.mode == GameState.SERVER or GameState.mode == GameState.STANDALONE:
				robot_server.poll()

# should only run on the server!
func _physics_process(_delta):
	
	assert(GameState.mode == GameState.SERVER || GameState.mode == GameState.STANDALONE)
	if GameState.mode == GameState.SERVER:
		assert(is_network_master())
	
		# check visibility of players:
	# 1. select robot's camera
	# 2. quick discard using a VisbilityNotifier https://docs.godotengine.org/en/stable/classes/class_visibilitynotifier.html
	# 3. ray casting from robot to player to see if obstacle or not, using
	#    intersect_ray: https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html
	

func compute_visible_humans(robot):

	var humans = $Players.get_children()
	
	# add all the NPCs as well
	for npc_path in $NPCPath.get_children():
		humans.append(npc_path.get_child(0).get_child(0))

	for p in humans:
		if p in robot.players_in_fov:
			var ob = is_object_visible(p.face, robot.camera)
			if !ob or !ob.has_method("i_am_a_character"):
				robot.players_in_fov.erase(p)
		else:
			var ob = is_object_visible(p.face, robot.camera)
			if ob and ob.has_method("i_am_a_character"):
				robot.players_in_fov.append(ob)
				print("Robot " + robot.robot_name + " sees player " + p.username)
	
	return robot.players_in_fov
						
func is_object_visible(object, camera):
	if not object.visible:
		return null
		
	var target = object.global_transform.origin
	if is_point_in_frustum(target, camera):
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(camera.global_transform.origin, target)
		if result:
			return result.collider

	return null

func is_point_in_frustum(point, camera):
	var f = camera.get_frustum()
	
	return(!(f[0].is_point_over(point) or \
			 f[1].is_point_over(point) or \
			 f[2].is_point_over(point) or \
			 f[3].is_point_over(point) or \
			 f[4].is_point_over(point) or \
			 f[5].is_point_over(point)))
	


func shuffle_spawn_points():
	
	if random_player_start_positions:
		var order = range($SpawnPointsPlayers.get_child_count())
		order.shuffle()
		for p in range(order.size()):
			var child = $SpawnPointsPlayers.get_child(order[p])
			$SpawnPointsPlayers.move_child(child, p)
	
	if random_robot_start_positions:
		var order = range($SpawnPointsRobots.get_child_count())
		order.shuffle()
		for p in range(order.size()):
			var child = $SpawnPointsRobots.get_child(order[p])
			$SpawnPointsRobots.move_child(child, p)

##### NETWORK SIGNALS HANDLERS #####
# only triggered client-side
func _connected_ok():
	print("Yeah! Connected to the server")
	pre_configure_game()

# only triggered client-side
func _connected_fail():
	print("Impossible to connect :-(  Server dead?")

# only triggered client-side
func _server_disconnected():
	print("Server disconnect")
	
func _player_connected(id):
	# Called on both clients and server when a peer connects. Send my info to it.

	var my_info =  { "name": player_name, "skin": player_skin }
	
	if id == 1:
		print("Sending my player to the server")
	else:
		print("New player " + str(id) + " joined")
		create_file(str(id))
		
	if not get_tree().is_network_server():
		rpc_id(id, "register_player", my_info)
	
func _player_disconnected(id):
	print("Player " + str(id) + " disconnected")
	remove_player(id)
	player_info.erase(id) # Erase player from info.

########################################################

# excuted on every existing peer (incl server) when a new player joins
remote func register_player(info):
	
	var id = get_tree().get_rpc_sender_id()
	
	player_info[id] = info
	
	add_player(id)

	if get_tree().is_network_server():
		print("Player " + player_info[id]["name"] + " (peer id #" + str(id) + "): registration & initialization complete")
		

func remove_player(id):
	player_info[id]["object"].queue_free()
	
func add_player(id):
	# THIS RUNS BOTH ON THE SERVER AND ON THE CLIENTS
	
	print("Creating character instance for peer #" + str(id))
	var player = preload("res://Character.tscn").instance()
	
	# this is key: by re-using the id, each player (be it a Player instance or 
	# a Character instance) will have the *same* node path on every peers, enabling
	# RPC calls
	
	player.set_name(str(id))
	
	
	# the server is ultimately controlling all the characters position
	# -> the network master is 1 (eg, default)
	player.set_network_master(1)
	
	
	
	# physics *only* performed on server
	if get_tree().is_network_server():
		player.call_deferred("enable_collisions", true)
		player.call_deferred("set_physics_process", true)
		
		var start_location = $SpawnPointsPlayers.get_child($Players.get_child_count()).transform
		player_info[id]["start_location"] = start_location
		
		player.call_deferred("set_global_transform", start_location)        

		
	else:
		player.call_deferred("enable_collisions", false)
		player.call_deferred("connect", "player_msg", $CanvasLayer/UI/RightPanel/Chat, "add_msg")
	
	
	player.set_deferred("local_player", local_player)
	player.call_deferred("set_username", player_info[id]["name"])
	player.call_deferred("set_base_skin", player_info[id]["skin"])
	
	
	
	get_node("/root/Game/Players").add_child(player)
	
	player_info[id]["object"] = player
	

func add_robot(name):
	local_robot = add_robot_remote(name)
	local_robot.call_deferred("connect", "robot_msg", $CanvasLayer/UI/RightPanel/Chat, "add_msg")

	
	if GameState.mode == GameState.SERVER:
		rpc("add_robot_remote", name)
	
puppet func add_robot_remote(name):
	print("Adding robot " + str(name))
	var robot = preload("res://RobotBridge.tscn").instance()
	
	robots[name] = robot
	
	robot.set_name(name)
	robot.set_deferred("robot_name", name)
	robot.set_deferred("username", name) # alias for robot_name
	robot.set_deferred("game_instance", self)
	robot.get_node("LaserScanner").visible = show_laserscans
	
	# physics *only* performed on server
	if GameState.mode == GameState.SERVER or GameState.mode == GameState.STANDALONE:
		robot.enable_collisions(true)
		robot.call_deferred("set_physics_process", true)
		
		
	else:
		robot.enable_collisions(false)
	
	if GameState.mode == GameState.SERVER or GameState.mode == GameState.STANDALONE:
		
		var start_location = $SpawnPointsRobots.get_child($Robots.get_child_count()).transform
		robot.set_global_transform(start_location)
		
		robot.set_deferred("navigation", $MainOffice.nav)
	
	$Robots.add_child(robot)
	
	return robot

func toggle_robots_lasers(state):
	
	show_laserscans = state
	
	for robot in $Robots.get_children():
		robot.get_node("LaserScanner").visible = state

func toggle_npcs(state):
	for npc_path in $NPCPath.get_children():
		npc_path.get_child(0).get_child(0).visible = state
		npc_path.get_child(0).get_child(0).face.visible = state

remote func pre_configure_game():
	
	var selfPeerID = "myself" # used in STANDALONE mode
	
	if GameState.mode == GameState.CLIENT:
		selfPeerID = get_tree().get_network_unique_id()  # used in CLIENT/SERVER mode
			
		get_tree().set_pause(true)

	
	# Load my player
	local_player = preload("res://Player.tscn").instance()
	local_player.set_name(str(selfPeerID))
	local_player.username = player_name
	
	#local_player.set_network_master(selfPeerID)
	
	# the server is ultimately controlling the player position
	# -> the network master is 1 (eg, default)
	
	get_node("/root/Game/Players").add_child(local_player)
	
	var _err = $CanvasLayer/UI/RightPanel/Chat.connect("on_chat_msg", local_player, "say")
	_err = $CanvasLayer/UI/RightPanel/Chat.connect("typing", local_player, "typing")
	_err = $CanvasLayer/UI/RightPanel/Chat.connect("not_typing_anymore", local_player, "not_typing_anymore")
	_err = local_player.connect("player_list_updated", $CanvasLayer/UI/RightPanel/Chat, "set_list_players_in_range")
	_err = $CanvasLayer/UI.connect("on_expression", local_player, "set_expression")
	_err = local_player.connect("fire_putOut", $CanvasLayer/UI, "_on_nag_fire_put_out")
	_err = local_player.connect("fire_putOut", $RobotPath/PathFollow/Robot, "_is_fire_putOut")
	_err = local_player.connect("fire_putOut", $RobotPath/PathFollow/Robot/Breaking, "_is_fire_putOut")
	_err = local_player.connect("show_advise", $CanvasLayer/UI, "_show_advise")
	_err = $CanvasLayer/UI.connect("all_putOut", $CheckPoint, "_on_UI_gameOver")
	_err = $CheckPoint.connect("game_over", $CanvasLayer/UI, "_on_CheckPoint_game_over")
	_err = $CheckPoint.connect("game_over", $CanvasLayer/Gameover, "_on_CheckPoint_game_over")
	_err = $RobotPath/PathFollow/Robot.connect("show_interface", $CanvasLayer/nag, "_show_interface")
	_err = $RobotPath/PathFollow/Robot/Breaking.connect("show_interface", $CanvasLayer/nag, "_show_interface")
	_err = $TrainArea.connect("show_interface", $CanvasLayer/nag, "_show_interface")
	_err = local_player.connect("call_robot", $RobotPath/PathFollow/Robot, "_get_target_path")
	_err = local_player.connect("call_robot", $RobotPath/PathFollow, "_get_target_path")
	_err = local_player.connect("call_robot", $CanvasLayer/UI, "_get_target_path")
	_err = $RobotPath/PathFollow/Robot.connect("backed", $RobotPath/PathFollow, "_return_to_path")
	_err = $TrainArea.connect("tp", local_player, "_tp")
	_err = local_player.connect("call_robot", $TrainArea/Training2/Path/PathFollow/Robot, "_get_target_path")
	
	$MainOffice.set_local_player(local_player)

	if GameState.mode == GameState.CLIENT:
		# no local physics, all is managed by the server
		local_player.toggle_collisions(false)
		
		# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
		rpc_id(1, "done_preconfiguring", selfPeerID)
		
		print("Done pre-configuring game. Waiting for the server to un-pause me...")
	
	elif GameState.mode == GameState.STANDALONE:
		local_player.toggle_collisions(true)
		var start_location = $SpawnPointsPlayers.get_child($Players.get_child_count()-1).transform
		local_player.transform = start_location

# server has accepted our player, we can start the game.
# *if transform=null, the server has rejected our player*
# (typically because no more space). In which case, we must exit.
remote func post_configure_game(transform):
	if !transform:
		print("Server is full! Exiting")
		get_tree().quit()
	else:
		print("Starting the game!")
		local_player.transform = transform
		get_tree().set_pause(false)



# Executed on the server only
var players_done = []
remote func done_preconfiguring(who):
	# Here are some checks you can do, for example
	assert(get_tree().is_network_server())
	assert(who in player_info) # Exists
	assert(not who in players_done) # Was not added yet

	if players_done.size() == MAX_PLAYERS:
		print("Game full! Can not accept any extra player!")
		rpc_id(who, "post_configure_game", null)
		return
		
	print("Player #" + str(who) + " is ready.")
	players_done.append(who)

	# start the game immediately for whoever is connecting, passing the
	# start location of the player
	
	rpc_id(who, "post_configure_game", player_info[who]["start_location"])

var debug_points = []

# draws a point at a given position in the world coordinates
func debug_point(pos):
	
	if pos in debug_points:
		return
	
	var point = MeshInstance.new()
	point.mesh = SphereMesh.new()
	point.mesh.radius = 0.03
	point.mesh.height = 0.06
   
	add_child(point)
	
	point.global_transform.origin = pos
	
	debug_points.append(pos)
	
	
######### save data ###########
var file = File.new()
#var path ="logs"
#var path = "http://109.228.57.101/logs"


var timer = Timer.new()
var gamedata_logging_timer = Timer.new()

# Interval between two call to log game data
var LOGGING_PERIOD=1.0 #s


func _on_InfoCollect_infocollected(data):
	prolific_id = data[0].split(",")[0]
	print(prolific_id)  # Output: ewsragsergserg

#	assign_random_ids_to_players(data)
	create_d_file(prolific_id, data)

func assign_random_ids_to_players(answer_data):
	print(answer_data)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for player in $Players.get_children():
		player.player_id = rng.randi()
		print("Assigned ID:", player.player_id, "to player:", player.name)
#		create_q_file(player.player_id ,answer_data)
		create_d_file(player.player_id ,answer_data)

func _on_QNbefore_completed(answer_data):
	create_q_file(answer_data)
	

func _on_QNafter_completed(answer_data, count):
	create_q2_file(answer_data, count)



var URL_LOGS = "http://109.228.57.101/cgi-bin/save_game_data.py"  # Server URL where the script is located

func create_d_file(id, answer_data, use_ssl=false):
	var file_name = "%s_demographic.csv" % prolific_id  # File name for each player
	print("File Name Q: %s" % file_name)
	var data = {
		"file_name": file_name,
		"id": prolific_id,
		"answers": answer_data
	}
	
	# Convert data to JSON string
	var json_data = JSON.print(data)

	# Initialize HTTPRequest and send the POST request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Send the POST request to the server (no need to include file name here)
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	var query = "game_data=" + json_data
	var err = http_request.request(URL_LOGS, headers, use_ssl, HTTPClient.METHOD_POST, query)
	
	if err != OK:
		print("Error sending POST request: ", err)
		return
	
	# Handle response
	yield(http_request, "request_completed")
	print("Data sent to the server.")


func create_q_file(answer_data, use_ssl=false):
	
	for player in $Players.get_children():
		print("PLEASE GOD WORK:", prolific_id)
		var id = prolific_id
		var file_name = "%s_questionnaire1.csv" % id  # File name for each player
		print("File Name Q: %s" % file_name)
		
		# Prepare the data to be sent as JSON, including the header and answers
		var data = {
			"file_name": file_name,
			"header": "1,2,3,4,5,6,7,8,9,10",
			"answers": answer_data
		}
		
		# Convert data to JSON string
		var json_data = JSON.print(data)
		
		# Initialize HTTPRequest and send the POST request
		var http_request = HTTPRequest.new()
		add_child(http_request)
		
		# Send the POST request to the server
		var headers = ["Content-Type: application/x-www-form-urlencoded"]
		var query = "game_data=" + json_data
		var err = http_request.request(URL_LOGS, headers, use_ssl, HTTPClient.METHOD_POST, query)
		
		if err != OK:
			print("Error sending POST request for player ID %s: " % id, err)
			return
		
		# Handle response
		yield(http_request, "request_completed")
		print("Data sent to the server for player ID %s." % id)



func create_q2_file(answer_data, count, use_ssl=false):
	var questionnaire_type = "questionnaire2" if count == 1 else "questionnaire3"
	print(count)
	for player in $Players.get_children():
		var id = prolific_id
		var file_name = "%s_%s.csv" % [id, questionnaire_type]
		print("File Name: %s" % file_name)

		# Prepare data 
		var data = {
			"file_name": file_name,
			"header": "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16",
			"answers": answer_data
		}

		# Convert data to JSON string
		var json_data = JSON.print(data)

		# Initialize HTTPRequest and send the POST request
		var http_request = HTTPRequest.new()
		add_child(http_request)

		# Send POST request
		var headers = ["Content-Type: application/x-www-form-urlencoded"]
		var query = "game_data=" + json_data
		var err = http_request.request(URL_LOGS, headers, use_ssl, HTTPClient.METHOD_POST, query)

		if err != OK:
			print("Error sending POST request for player ID %s: %d" % [id, err])
			http_request.queue_free()
			continue

		yield(http_request, "request_completed")
		print("Data sent to the server for player ID %s." % id)



		

func _on_TrainArea_tp(origin, basis):
#	var id = yield($CanvasLayer/QNbefore, "completed")
	var id = prolific_id
#	print("ID: ", id)
	for player in $Players.get_children():
		create_file(prolific_id)
		start_recording_gamedata(prolific_id)
#	connect("game_over", self, "_on_CheckPoint_game_over")	

	# Create a file and add the first line: the user ID and headers
func create_file(id): 
	var file_name = "%s_logs.csv" % [id]
	# Prepare the data to be sent as JSON, including the header and answers
	
	var data_to_send = {
			"file_name": file_name,
			"header": "time,player_x,player_y,player_rotation,robot_x,robot_y,robot_rotation,fire_canteen,fire_HR,fire_manager,fire_lounge,fire_warehouse,fire_restroom,fireA_chair,fireA_printer,fireA_bin,fireA_table,robot_call,fps,robotvisible",
		}

	# Convert data to JSON string
	var json_data = JSON.print(data_to_send)

	# Initialize HTTPRequest and send the POST request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Send the POST request to the server
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	var query = "game_data=" + json_data
	var err = http_request.request(URL_LOGS, headers, false, HTTPClient.METHOD_POST, query)
	
	if err != OK:
		print("Error sending POST request for player ID %s: " % id, err)
		return
	
	# Handle response (optional, can be used for debugging)
	yield(http_request, "request_completed")
	print("Data sent to the server for player ID %s." % id)
	print("this should only be called once")

	# Start recording game data for this user
	start_recording_gamedata(id)


# Start recording game data and set up a timer for periodic logging
func start_recording_gamedata(id):
	var gamedata_logging_timer = Timer.new()
	add_child(gamedata_logging_timer)
	
	gamedata_logging_timer.connect("timeout", self, "log_positions", [id])
	gamedata_logging_timer.set_wait_time(LOGGING_PERIOD)  # Define the logging period
	gamedata_logging_timer.set_one_shot(false)  # Ensure it loops
	gamedata_logging_timer.start()
	
	# First data logging immediately
	log_positions(id)


# Track whether we are waiting for the signal to start logging
var waiting_for_signal = false

# Log player and robot positions, along with fire and other data
func log_positions(id):
	if not waiting_for_signal:
		waiting_for_signal = true
		yield($RobotPath/PathFollow, "entered")
		waiting_for_signal = false

	# Prepare the data to log
	for p in $Players.get_children(): 
		var datetime = OS.get_datetime()
		var formatted_time = "%04d-%02d-%02d %02d:%02d:%02d" % [
			datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute, datetime.second
		]


		var data = [
	formatted_time,  # time
	p.global_transform.origin.x,  # player_x
	p.global_transform.origin.z,  # player_y
	p.rotation_degrees.y,  # player_rotation
	$RobotPath/PathFollow/Robot.global_transform.origin.x,  # robot_x
	$RobotPath/PathFollow/Robot.global_transform.origin.z,  # robot_y
	$RobotPath/PathFollow/Robot.rotation_degrees.y,  # robot_rotation
	$FireGroup/Canteen/fire/flames.emitting,  # fire_canteen
	$FireGroup/HRdep/fire/flames.emitting,  # fire_HR
	$FireGroup/Manager/fire/flames.emitting,  # fire_manager
	$FireGroup/Lounge/fire/flames.emitting,  # fire_lounge
	$FireGroup/Warehouse/fire/flames.emitting,  # fire_warehouse
	$FireGroup/Restroom/fire/flames.emitting,  # fire_restroom
	$FireGroup_after/Lazychair/fire/flames.emitting,  # fireA_chair
	$FireGroup_after/Printer/fire/flames.emitting,  # fireA_printer
	$FireGroup_after/Bin/fire/flames.emitting,  # fireA_bin
	$FireGroup_after/Table/fire/flames.emitting,  # fireA_table
	ChatLabel.text,  # robot_call
	Performance.get_monitor(Performance.TIME_FPS),
	robot_visible
]
		print(data)
#		var data = [formatted_time, p.global_transform.origin.x, p.global_transform.origin.z, p.rotation_degrees.y, $RobotPath/PathFollow/Robot.global_transform.origin.x, $RobotPath/PathFollow/Robot.global_transform.origin.z, $RobotPath/PathFollow/Robot.rotation_degrees.y, $FireGroup/Canteen/fire/flames.emitting, $FireGroup/HRdep/fire/flames.emitting, $FireGroup/Manager/fire/flames.emitting, $FireGroup/Lounge/fire/flames.emitting, $FireGroup/Warehouse/fire/flames.emitting, $FireGroup/Restroom/fire/flames.emitting, $FireGroup_after/Lazychair/fire/flames.emitting, $FireGroup_after/Printer/fire/flames.emitting, $FireGroup_after/Bin/fire/flames.emitting, $FireGroup_after/Table/fire/flames.emitting, ChatLabel.text]
		
		# Log data for each player
#		print("Data logged for user %s: " % id, data)
		send_data_to_server(id, data)


# Send data via HTTP POST request to the server
func send_data_to_server(id, data, use_ssl=false):
	for player in $Players.get_children():
		var file_name = "%s_logs.csv" % [id]  
#		var data2 = ["w","w", "w","w","w", "w","w","w", "w","w","w", "w","w","w", "w"]
		# Prepare data to send
		var data_to_send = {
			"file_name": file_name,
			"answers": data
		}


		# Convert data to JSON string
		var json_data = JSON.print(data_to_send)
		# Initialize HTTPRequest and send the POST request
		var http_request = HTTPRequest.new()
		add_child(http_request)

		# Send POST request
		var headers = ["Content-Type: application/x-www-form-urlencoded"]
		var query = "game_data=" + json_data
		var err = http_request.request(URL_LOGS, headers, use_ssl, HTTPClient.METHOD_POST, query)

		if err != OK:
			print("Error sending POST request for player ID %s: %d" % [id, err])
			http_request.queue_free()
			continue

		yield(http_request, "request_completed")
#		print("Data sent to the server for player ID %s." % id)


func _on_nag_completed(answer_data, use_ssl=false):
	for player in $Players.get_children():
		var id = player.player_id
		var file_name = "%s_nags.csv" % [id]
		print("File Name: %s" % file_name)

		# Prepare data 
		var data = {
			"file_name": file_name,
			"header": "1,2,3,4,5,6,7",
			"answers": answer_data
		}
		print("nag data: ", answer_data)
		# Convert data to JSON string
		var json_data = JSON.print(data)

		# Initialize HTTPRequest and send the POST request
		var http_request = HTTPRequest.new()
		add_child(http_request)

		# Send POST request
		var headers = ["Content-Type: application/x-www-form-urlencoded"]
		var query = "game_data=" + json_data
		var err = http_request.request(URL_LOGS, headers, use_ssl, HTTPClient.METHOD_POST, query)

		if err != OK:
			print("Error sending POST request for player ID %s: %d" % [id, err])
			http_request.queue_free()
			continue

		yield(http_request, "request_completed")
		print("Data sent to the server for player ID %s." % id)


func _on_VisibilityNotifier_screen_entered():
	print("entered screen")
	robot_visible = true


func _on_VisibilityNotifier_screen_exited():
	print("exited screen")
	robot_visible = false	

	
# for each player, this function will create and save a string on a csv file with the position, orientation and expression of the player
 
#func pre_save(): 
#	for p in $Players.get_children(): 
#		var ID = p.get_name()
#
#		var time = OS.get_unix_time()
#		print(p.global_transform.origin[0])
#		print(p.global_transform.origin[1])
#		print(p.global_transform.origin[2])
#		var data = "%s"%time+ "," + "%.2f"%p.global_transform.origin[0]+ "," + "%.2f"%p.global_transform.origin[2] +"," + "%.1f"%p.rotation_degrees[1] + "," + "%s"%p.is_speaking()
#		print(data)
#		save_data(ID,data)
		
		
		#print(player_info)
	#for who in player_info: 
		#print(who) # print the id of the player 
		
func time_played(): 
	time_now= OS.get_unix_time()
	var elapsed = time_now - time_start
	return elapsed


#func _on_CheckPoint_game_over():
#	pre_save()
	
#func _on_timer_save_timeout():
#	if GameState.mode == GameState.SERVER:
#		pre_save()
#	pass # Replace with function body.

func update_players_proximity():
	# only executed on server
	
	var players = $Players.get_children()
	var robots = $Robots.get_children()
	
	var proximity = {}
	
	var min_dist = GameState.DISTANCE_AUDIBLE * GameState.DISTANCE_AUDIBLE
	
	## PLAYER <-> PLAYER
	for idx in range(players.size()):
		var p1 = players[idx]
		if not players_distances.has(p1):
			players_distances[p1] = {}
			
		for idx2 in range(idx + 1, players.size()):
			var p2 = players[idx2]
			if not players_distances.has(p2):
				players_distances[p2] = {}
			
			var dist = p1.translation.distance_squared_to(p2.translation)
			
			if not players_distances[p1].has(p2):
				players_distances[p1][p2] = dist
			
			if not players_distances[p2].has(p1):
				players_distances[p2][p1] = dist
			
			var prev_dist = players_distances[p1][p2]
			
			if dist < min_dist and prev_dist > min_dist:
				# p1 and p2 are now in range
				if not proximity.has(p1):
					proximity[p1] = {"in_range":[[p2.name, "player"]], "not_in_range":[]}
				else:
					proximity[p1]["in_range"].append([p2.name, "player"])
				
				if not proximity.has(p2):
					proximity[p2] = {"in_range":[[p1.name,"player"]], "not_in_range":[]}
				else:
					proximity[p2]["in_range"].append([p1.name,"player"])
				
				print(p1.username + " and " + p2.username + " in range")
				#$CanvasLayer/UI/RightPanel/Chat.add_msg(p1.username + " and " + p2.username + " in range", "[SERVER]")
			
			elif dist > min_dist and prev_dist < min_dist:
				# p1 and p2 are not in range anymore
				if not proximity.has(p1):
					proximity[p1] = {"in_range":[], "not_in_range":[[p2.name, "player"]]}
				else:
					proximity[p1]["not_in_range"].append([p2.name, "player"])
				
				if not proximity.has(p2):
					proximity[p2] = {"in_range":[], "not_in_range":[[p1.name, "player"]]}
				else:
					proximity[p2]["not_in_range"].append([p1.name, "player"])
				
				print(p1.username + " and " + p2.username + " not in range anymore")
				#$CanvasLayer/UI/RightPanel/Chat.add_msg(p1.username + " and " + p2.username + " not in range anymore")
			
			players_distances[p1][p2] = dist
			players_distances[p2][p1] = dist
	
	## PLAYER <-> ROBOT
	for idx in range(players.size()):
		var p1 = players[idx]
		if not players_distances.has(p1):
			players_distances[p1] = {}
			
		for idx2 in range(robots.size()):
			var r = robots[idx2]
			
			var dist = p1.translation.distance_squared_to(r.translation)
			
			if not players_distances[p1].has(r):
				players_distances[p1][r] = dist
			
			var prev_dist = players_distances[p1][r]
			
			if dist < min_dist and prev_dist > min_dist:
				# p1 and r are now in range
				if not proximity.has(p1):
					proximity[p1] = {"in_range":[[r.name,"robot"]], "not_in_range":[]}
				else:
					proximity[p1]["in_range"].append([r.name,"robot"])
				
				print(p1.username + " and " + r.robot_name + " in range")
				#$CanvasLayer/UI/RightPanel/Chat.add_msg(p1.username + " and " + r.robot_name + " in range", "[SERVER]")
			
			elif dist > min_dist and prev_dist < min_dist:
				# p1 and p2 are not in range anymore
				if not proximity.has(p1):
					proximity[p1] = {"in_range":[], "not_in_range":[[r.name, "robot"]]}
				else:
					proximity[p1]["not_in_range"].append([r.name,"robot"])
				
				print(p1.username + " and " + r.robot_name + " not in range anymore")
				#$CanvasLayer/UI/RightPanel/Chat.add_msg(p1.username + " and " + r.robot_name + " not in range anymore")
			
			players_distances[p1][r] = dist
			
			
	for p in proximity:
		if GameState.mode == GameState.SERVER:
			p.rpc("puppet_update_players_in_range", proximity[p]["in_range"],proximity[p]["not_in_range"])
		if GameState.mode == GameState.STANDALONE:
			local_player.puppet_update_players_in_range(proximity[p]["in_range"],proximity[p]["not_in_range"])
	





