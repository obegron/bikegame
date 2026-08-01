extends SceneTree

const PORT := 27821


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var server := ENetMultiplayerPeer.new()
	var client := ENetMultiplayerPeer.new()
	var server_error := server.create_server(PORT, 2)
	if server_error != OK:
		_fail("server creation failed: %s" % error_string(server_error))
		return
	var client_error := client.create_client("127.0.0.1", PORT)
	if client_error != OK:
		server.close()
		_fail("client creation failed: %s" % error_string(client_error))
		return

	for _attempt in 200:
		server.poll()
		client.poll()
		if client.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			client.close()
			server.close()
			print("Network loopback smoke test passed.")
			quit()
			return
		await create_timer(0.005).timeout

	client.close()
	server.close()
	_fail("client did not connect to the local server")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
