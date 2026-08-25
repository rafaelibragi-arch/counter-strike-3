class_name ViewModelMeshFactory
extends RefCounted
## Procedural FP meshes (placeholder until GLB import). Used by Godot + export for browser.

const SEG := 16


static func build_arms(team: WeaponDefinition.Team, glove_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Arms"
	var body_col := Color(0.72, 0.58, 0.46) if team == WeaponDefinition.Team.T else Color(0.58, 0.66, 0.78)
	var glove_col := glove_color
	var body_mat := _mat(body_col, 0.08, 0.82)
	var glove_mat := _mat(glove_col, 0.12, 0.78)
	var dark_mat := _mat(glove_col.darkened(0.35), 0.18, 0.7)

	var right := _build_hand("RightHand", glove_mat, dark_mat, 1.0)
	right.position = Vector3(0.28, -0.10, -0.18)
	right.rotation = Vector3(0.15, -0.15, 1.15)
	root.add_child(right)

	var left := _build_hand("LeftHand", glove_mat, dark_mat, -1.0)
	left.position = Vector3(0.18, -0.08, -0.52)
	left.rotation = Vector3(0.35, 0.12, -0.55)
	root.add_child(left)

	# Forearms
	var r_fore := _box(Vector3(0.07, 0.06, 0.22), body_mat)
	r_fore.position = Vector3(0.24, -0.08, 0.02)
	r_fore.rotation = Vector3(0.3, -0.2, 0.8)
	root.add_child(r_fore)
	var l_fore := _box(Vector3(0.07, 0.06, 0.22), body_mat)
	l_fore.position = Vector3(0.12, -0.06, -0.18)
	l_fore.rotation = Vector3(0.45, 0.15, -0.6)
	root.add_child(l_fore)
	_tag_viewmodel(root)
	return root


static func build_weapon(weapon_id: StringName, paint_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Weapon_%s" % String(weapon_id)
	var paint := _phys_mat(paint_color, 0.35, 0.32, 0.85)
	var steel := _phys_mat(Color(0.16, 0.19, 0.22), 0.92, 0.16, 0.25)
	var blued := _phys_mat(Color(0.10, 0.12, 0.14), 0.95, 0.12, 0.2)
	var polymer := _phys_mat(Color(0.11, 0.11, 0.12), 0.12, 0.62, 0.2)
	var rubber := _mat(Color(0.07, 0.07, 0.07), 0.05, 0.95)
	var wood := _phys_mat(paint_color.darkened(0.2), 0.05, 0.72, 0.35)

	match String(weapon_id):
		"knife":
			_build_knife(root, paint, steel, rubber)
		"awp":
			_build_awp(root, paint, steel, blued, polymer, rubber)
		"glock", "usps", "p250", "pistol", "deagle":
			_build_pistol(root, weapon_id, paint, steel, blued, polymer, rubber)
		"mac10", "mp9", "ump", "mp7":
			_build_smg(root, weapon_id, paint, steel, blued, polymer)
		"nova", "xm", "mag7":
			_build_shotgun(root, weapon_id, paint, steel, blued, polymer, wood, rubber)
		_:
			_build_rifle(root, weapon_id, paint, steel, blued, polymer, wood, rubber)

	_tag_viewmodel(root)
	return root


static func _build_rifle(root: Node3D, wid: String, paint: Material, steel: Material, blued: Material, polymer: Material, wood: Material, rubber: Material) -> void:
	var is_ak := wid == "ak" or wid == "galil"
	var body := _capsule(Vector3(0.05, 0.28, 0.05), paint)
	body.position = Vector3(0, 0, -0.42)
	body.rotation.x = PI / 2
	root.add_child(body)
	var handguard := _box(Vector3(0.06, 0.05, 0.32), wood if is_ak else polymer)
	handguard.position = Vector3(0, 0.02, -0.62)
	root.add_child(handguard)
	var barrel := _cyl(0.014, 0.016, 0.42, blued)
	barrel.position = Vector3(0, 0.012, -0.95)
	barrel.rotation.x = PI / 2
	root.add_child(barrel)
	var stock := _box(Vector3(0.05, 0.08, 0.22), wood if is_ak else paint)
	stock.position = Vector3(0, 0.01, 0.08)
	root.add_child(stock)
	var mag := _box(Vector3(0.035, 0.14, 0.06), polymer)
	mag.position = Vector3(0, -0.16, -0.46)
	mag.rotation.x = 0.12
	mag.name = "mag"
	root.add_child(mag)
	var muzzle := Marker3D.new()
	muzzle.name = "muzzle"
	muzzle.position = Vector3(0, 0.012, -1.18)
	root.add_child(muzzle)


static func _build_awp(root: Node3D, paint: Material, steel: Material, blued: Material, polymer: Material, rubber: Material) -> void:
	var receiver := _box(Vector3(0.09, 0.07, 0.55), paint)
	receiver.position = Vector3(0, 0, -0.55)
	root.add_child(receiver)
	var barrel := _cyl(0.018, 0.022, 0.95, blued)
	barrel.position = Vector3(0, 0.012, -1.35)
	barrel.rotation.x = PI / 2
	root.add_child(barrel)
	var scope := _cyl(0.038, 0.038, 0.32, blued)
	scope.position = Vector3(0, 0.12, -0.52)
	scope.rotation.x = PI / 2
	scope.name = "scope_glass"
	root.add_child(scope)
	var stock := _box(Vector3(0.06, 0.07, 0.28), paint)
	stock.position = Vector3(0, 0, 0.12)
	root.add_child(stock)
	var pad := _box(Vector3(0.08, 0.05, 0.04), rubber)
	pad.position = Vector3(0, 0, 0.26)
	root.add_child(pad)
	var mag := _box(Vector3(0.04, 0.1, 0.05), polymer)
	mag.position = Vector3(0, -0.12, -0.55)
	mag.name = "mag"
	root.add_child(mag)
	var muzzle := Marker3D.new()
	muzzle.name = "muzzle"
	muzzle.position = Vector3(0, 0.012, -1.85)
	root.add_child(muzzle)


static func _build_pistol(root: Node3D, wid: StringName, paint: Material, steel: Material, blued: Material, polymer: Material, rubber: Material) -> void:
	var is_deag := String(wid) == "deagle"
	var slide := _box(Vector3(0.04, 0.05, 0.26 if is_deag else 0.22), paint)
	slide.position = Vector3(0, 0.04, -0.38)
	root.add_child(slide)
	var frame := _box(Vector3(0.038, 0.08, 0.14), polymer)
	frame.position = Vector3(0, -0.02, -0.34)
	root.add_child(frame)
	var grip := _box(Vector3(0.03, 0.12, 0.06), paint)
	grip.position = Vector3(0.02, -0.1, -0.28)
	grip.rotation.z = 0.55
	root.add_child(grip)
	if String(wid) == "usps":
		var sup := _cyl(0.012, 0.012, 0.24, blued)
		sup.position = Vector3(0, 0.02, -0.62)
		sup.rotation.x = PI / 2
		root.add_child(sup)
	var mag := _box(Vector3(0.022, 0.1, 0.04), steel)
	mag.position = Vector3(0, -0.12, -0.28)
	mag.name = "mag"
	root.add_child(mag)
	var muzzle := Marker3D.new()
	muzzle.name = "muzzle"
	muzzle.position = Vector3(0, 0.03, -0.58 if is_deag else -0.52)
	root.add_child(muzzle)


static func _build_smg(root: Node3D, wid: StringName, paint: Material, steel: Material, blued: Material, polymer: Material) -> void:
	var body := _box(Vector3(0.08, 0.06, 0.38), paint)
	body.position = Vector3(0, 0, -0.42)
	root.add_child(body)
	var barrel := _cyl(0.01, 0.012, 0.22, blued)
	barrel.position = Vector3(0, 0.01, -0.72)
	barrel.rotation.x = PI / 2
	root.add_child(barrel)
	if String(wid) != "mac10":
		var stock := _box(Vector3(0.04, 0.05, 0.18), polymer)
		stock.position = Vector3(0, 0, -0.08)
		root.add_child(stock)
	var mag := _box(Vector3(0.03, 0.12, 0.05), polymer)
	mag.position = Vector3(0, -0.14, -0.38)
	mag.name = "mag"
	root.add_child(mag)
	var muzzle := Marker3D.new()
	muzzle.name = "muzzle"
	muzzle.position = Vector3(0, 0.01, -0.86)
	root.add_child(muzzle)


static func _build_shotgun(root: Node3D, wid: StringName, paint: Material, steel: Material, blued: Material, polymer: Material, wood: Material, rubber: Material) -> void:
	var short := String(wid) == "mag7"
	var body := _box(Vector3(0.09, 0.07, 0.42), paint)
	body.position = Vector3(0, 0, -0.52)
	root.add_child(body)
	var barrel := _cyl(0.02, 0.024, 0.22 if short else 0.46, blued)
	barrel.position = Vector3(0, 0.01, -0.88 if short else -1.08)
	barrel.rotation.x = PI / 2
	root.add_child(barrel)
	var pump := _box(Vector3(0.06, 0.05, 0.18), wood)
	pump.position = Vector3(0, -0.01, -0.82)
	root.add_child(pump)
	var stock := _box(Vector3(0.05, 0.06, 0.22), paint)
	stock.position = Vector3(0, 0, 0.02)
	root.add_child(stock)
	var mag := _box(Vector3(0.05, 0.08, 0.05), polymer)
	mag.position = Vector3(0, -0.1, -0.45)
	mag.name = "mag"
	root.add_child(mag)
	var muzzle := Marker3D.new()
	muzzle.name = "muzzle"
	muzzle.position = Vector3(0, 0.01, -1.02 if short else -1.32)
	root.add_child(muzzle)


static func _build_knife(root: Node3D, paint: Material, steel: Material, rubber: Material) -> void:
	var blade := _box(Vector3(0.02, 0.04, 0.32), paint)
	blade.position = Vector3(0.06, 0.01, -0.58)
	blade.rotation = Vector3(0.05, 0.5, 1.05)
	root.add_child(blade)
	var handle := _cyl(0.022, 0.022, 0.14, rubber)
	handle.position = Vector3(0, 0, -0.18)
	handle.rotation.x = PI / 2
	root.add_child(handle)
	var guard := _box(Vector3(0.06, 0.02, 0.02), steel)
	guard.position = Vector3(0.02, 0, -0.3)
	root.add_child(guard)
	var muzzle := Marker3D.new()
	muzzle.name = "muzzle"
	muzzle.position = Vector3(0.1, 0.02, -0.72)
	root.add_child(muzzle)


static func _build_hand(side: String, glove: Material, knuckle: Material, flip: float) -> Node3D:
	var hand := Node3D.new()
	hand.name = side
	var palm := _box(Vector3(0.078, 0.048, 0.085), glove)
	hand.add_child(palm)
	var kn := _box(Vector3(0.07, 0.016, 0.02), knuckle)
	kn.position = Vector3(0, 0.03, -0.048)
	hand.add_child(kn)
	for i in 4:
		var x := (-0.028 + i * 0.019) * flip
		var prox := _box(Vector3(0.016, 0.02, 0.032), knuckle)
		prox.position = Vector3(x, 0.016, -0.055)
		hand.add_child(prox)
		var tip := _box(Vector3(0.014, 0.016, 0.022), glove)
		tip.position = Vector3(x, 0.014, -0.078)
		tip.rotation.x = 0.25
		hand.add_child(tip)
	var cuff := _box(Vector3(0.082, 0.04, 0.028), knuckle)
	cuff.position = Vector3(0, 0.002, 0.052)
	hand.add_child(cuff)
	_tag_viewmodel(hand)
	return hand


static func _box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _cyl(rt: float, rb: float, h: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rt
	cm.bottom_radius = rb
	cm.height = h
	cm.radial_segments = SEG
	mi.mesh = cm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _capsule(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = size.x
	cm.height = size.y
	mi.mesh = cm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _mat(col: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	return m


static func _phys_mat(col: Color, metal: float, rough: float, clearcoat: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	if clearcoat > 0.01:
		m.clearcoat = clearcoat
		m.clearcoat_roughness = 0.12
	return m


static func _tag_viewmodel(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.layers = 2
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	for child in node.get_children():
		_tag_viewmodel(child)
