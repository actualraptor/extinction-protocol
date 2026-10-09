extends Node2D
## Packaged articulated Meteor renderer, shared by public gameplay and reviews.
var viewport: SubViewport
var player: AnimationPlayer
var opening := 0.0
var plates := []
var neutral := {}
var current_clip := "shell_open_reform"
var active_clips := []
var debris_texture: Texture2D
var encounter_clock := 0.0
var fresh_study := false
var debris_nodes := []
var core:Node3D
var core_neutral:=Vector3.ZERO
var core_basis:=Basis.IDENTITY
var core_gaze:=Vector2.ZERO
var encounter_instance=-1
var encounter_uid=-1
var heat_light:OmniLight3D
var model_root:Node3D
var entry_flash:=0.0
const ENTRY_DURATION:=4.2

func apply_heat_material(mesh:MeshInstance3D,energy:float)->void:
    for surface in range(mesh.mesh.get_surface_count()):
        var source=mesh.mesh.surface_get_material(surface) as StandardMaterial3D
        if source==null:continue
        var material=ShaderMaterial.new()
        material.shader=preload("res://shaders/meteor_core_heat.gdshader")
        material.set_shader_parameter("stone_texture",source.albedo_texture)
        material.set_shader_parameter("heat_texture",source.emission_texture)
        material.set_shader_parameter("heat_energy",energy)
        material.set_shader_parameter("heat_response",.65)
        mesh.set_surface_override_material(surface,material)

func _ready() -> void:
    fresh_study=OS.has_feature("meteor_rework") or "--meteor-fresh-study" in OS.get_cmdline_user_args()
    preload("res://scripts/hostile_fx.gd").prewarm_meteor()
    var debris_image=(load("res://assets/boss-public/effects/game-camera.png") as Texture2D).get_image()
    if debris_image!=null and not debris_image.is_empty():debris_texture=ImageTexture.create_from_image(debris_image)
    viewport = SubViewport.new()
    viewport.size = Vector2i(512, 512)
    if fresh_study and "--meteor-low-res-review" not in OS.get_cmdline_user_args():
        viewport.size=Vector2i(640,640)
        viewport.msaa_3d=Viewport.MSAA_2X
    viewport.transparent_bg = true
    viewport.own_world_3d = true
    add_child(viewport)
    var packed=load("res://assets/boss-public/meteor/meteor.glb") as PackedScene
    assert(packed!=null,"Packaged Meteor scene is missing")
    var model=packed.instantiate()
    model_root=model
    viewport.add_child(model)
    if fresh_study:
        core=model.find_child("Molten_Core",true,false) as Node3D
        if core!=null:
            core_neutral=core.position
            core_basis=core.basis
            if "--meteor-eye-exposure-review" in OS.get_cmdline_user_args() and core is MeshInstance3D:
                # Review the original recessed surface with less clipped heat.
                # Duplicate materials so the shell's molten seams stay unchanged.
                for surface in range(core.mesh.get_surface_count()):
                    var material=core.mesh.surface_get_material(surface).duplicate() as StandardMaterial3D
                    material.emission_energy_multiplier=1.35
                    material.emission=Color(1.0,.68,.32)
                    core.set_surface_override_material(surface,material)
            if not "--meteor-original-heat-review" in OS.get_cmdline_user_args() and not "--meteor-eye-exposure-review" in OS.get_cmdline_user_args() and core is MeshInstance3D:
                for surface in range(core.mesh.get_surface_count()):
                    var source=core.mesh.surface_get_material(surface) as StandardMaterial3D
                    var material=ShaderMaterial.new()
                    material.shader=preload("res://shaders/meteor_core_heat.gdshader")
                    material.set_shader_parameter("stone_texture",source.albedo_texture)
                    material.set_shader_parameter("heat_texture",source.emission_texture)
                    core.set_surface_override_material(surface,material)
        var template=model.find_child("OrbitDebrisTemplate",true,false) as MeshInstance3D
        if "--meteor-original-rock-heat-review" not in OS.get_cmdline_user_args():
            for index in range(8):
                var rock=model.find_child("Crust_%d"%index,true,false) as MeshInstance3D
                if rock!=null:apply_heat_material(rock,2.6)
        if template!=null:
            template.visible=false
            for index in range(7):
                var debris=MeshInstance3D.new();debris.mesh=template.mesh
                if "--meteor-original-rock-heat-review" not in OS.get_cmdline_user_args():apply_heat_material(debris,2.6)
                debris.scale=Vector3.ONE*(.42+float(index%3)*.09)
                viewport.add_child(debris);debris_nodes.append(debris)
        heat_light=OmniLight3D.new();heat_light.light_color=Color("ff641c")
        heat_light.light_energy=1.15;heat_light.omni_range=4.5
        heat_light.shadow_enabled=false;viewport.add_child(heat_light)
    player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
    player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    player.play("shell_open_reform")
    player.pause()
    player.seek(0,true)
    for index in range(8):
        var plate := model.find_child("Crust_%d" % index,true,false) as Node3D
        plates.append(plate)
        neutral[plate]=plate.transform
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0, 0, 0, 0)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_energy = .35
    environment.environment.ambient_light_color = Color("9ca99b")
    environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    viewport.add_child(environment)
    var light := DirectionalLight3D.new()
    viewport.add_child(light)
    light.rotation_degrees = Vector3(-40, -35, 0)
    light.light_energy = .85
    if fresh_study:light.shadow_enabled=true
    var camera := Camera3D.new()
    viewport.add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 10.5 if fresh_study else 6.5
    camera.look_at_from_position(Vector3(5, 4.5, 8), Vector3.ZERO)
    camera.current = true

func present(sim, dt: float) -> void:
    if player == null:return
    encounter_clock=sim.time
    var entry=maxf(0.0,float(sim.meteor_entry_time))
    if model_root!=null and entry>0:
        var progress=1.0-entry/ENTRY_DURATION
        var impact=clampf((progress-.86)/.14,0,1)
        # Cross the whole viewport first, then reverse into the landing.
        # This is deliberately a readable streak rather than a short float.
        var flight=clampf(progress/.64,0,1)
        var return_progress=clampf((progress-.64)/.36,0,1)
        # Coordinates deliberately exceed the orthographic half-width: the
        # meteor disappears beyond the right edge, crosses fully offscreen,
        # then arcs back from beyond the left edge to the impact point.
        var flight_x=12.0-24.0*flight
        var flight_y=5.0-4.0*flight
        var return_path=PackedVector2Array([Vector2(-12,-1),Vector2(-8,-4),Vector2(-2,-3),Vector2.ZERO])
        var segment=mini(2,int(return_progress*3.0))
        var local_t=fposmod(return_progress*3.0,1.0)
        var return_x=return_path[segment].lerp(return_path[segment+1],local_t).x
        var return_y=return_path[segment].lerp(return_path[segment+1],local_t).y
        var path=Vector2(flight_x,flight_y).lerp(Vector2(return_x,return_y),return_progress)
        # Keep the 3D subject centered inside its own SubViewport. Moving
        # this root created a second crop before the full-screen canvas path
        # could position the rendered texture.
        model_root.position=Vector3.ZERO
        model_root.scale=Vector3.ONE
        model_root.rotation.z=0
        entry_flash=impact
    else:
        if model_root!=null:
            model_root.position=Vector3.ZERO;model_root.scale=Vector3.ONE;model_root.rotation.z=0
        entry_flash=0
    var target := 1.0 if sim.anchors.is_empty() else 0.0
    if encounter_instance!=sim.get_instance_id() or encounter_uid!=sim.boss.uid:
        encounter_instance=sim.get_instance_id();encounter_uid=sim.boss.uid
        opening=target;core_gaze=Vector2.ZERO
    opening = move_toward(opening, target, dt / .65)
    var offsets := {}
    var turns := {}
    active_clips.clear()
    current_clip="shell_open_reform"
    var casts:Array=sim.boss.get("meteor_casts",[])
    for cast in casts:
        var elapsed: float = maxf(0,sim.time-cast.started)
        var prefix: String = ["flare","skyfall","collapse"][cast.pattern]
        var name: String = prefix+"_windup" if elapsed<cast.warning else prefix
        var clip_time: float = elapsed*player.get_animation(name).length/maxf(.001,cast.warning) if elapsed<cast.warning else elapsed-cast.warning
        if clip_time<=player.get_animation(name).length:
            current_clip=name
            active_clips.append(name)
            # glTF omits constant rotation tracks. Restore the neutral pose
            # before sampling so a previous collapse tilt cannot leak into
            # a flare or skyfall clip that only keys translation.
            for plate in plates:plate.transform=neutral[plate]
            player.play(name);player.pause();player.seek(clip_time,true)
            for plate in plates:
                offsets[plate]=offsets.get(plate,Vector3.ZERO)+plate.position-neutral[plate].origin
                turns[plate]=turns.get(plate,Basis.IDENTITY)*(neutral[plate].basis.inverse()*plate.basis)
    player.play("shell_open_reform");player.pause()
    player.seek((29.0 + opening * 30.0) / 30.0, true)
    for plate in offsets:
        plate.position+=offsets[plate]
        plate.basis=plate.basis*turns[plate]
    if fresh_study:
        if core!=null:
            core.position=core_neutral+Vector3(0,sin(encounter_clock*.7)*.035,0)
            var target_direction=(sim.pos-sim.boss.p).normalized()
            var gaze_target=Vector2(target_direction.x*.38,target_direction.y*.20)
            core_gaze=core_gaze.lerp(gaze_target,1-exp(-dt*5))
            # Preserve the authored recessed-eye geometry and scale. Limited
            # independent core motion gives intent without orbiting the shell.
            var camera_right=Vector3(8,0,-5).normalized()
            core.basis=Basis(camera_right,core_gaze.y)*Basis(Vector3.UP,core_gaze.x)*core_basis
        heat_light.light_energy=1.15+sin(encounter_clock*1.5)*.07
        for index in range(plates.size()):
            plates[index].position+=Vector3(0,sin(encounter_clock*.65+index*1.7)*.035,0)
        for index in range(debris_nodes.size()):
            var angle=encounter_clock*.4+index*TAU/7
            debris_nodes[index].position=Vector3(cos(angle)*2.85,.12+sin(encounter_clock*.8+index)*.25,sin(angle)*2.4)
            debris_nodes[index].rotation=Vector3(encounter_clock*(.7+index*.04),encounter_clock*.85+index,encounter_clock*.45)

func draw_ground_shadow(canvas:CanvasItem,at:Vector2,phase:int,landing:float)->void:
    if player==null:return
    var radius=112.0*(1.0+(phase-1)*.12)*(1.0+.08*sin(encounter_clock*.7))
    for layer in range(4):
        canvas.draw_set_transform(at+Vector2(0,38),0,Vector2(1,.40))
        canvas.draw_circle(Vector2.ZERO,radius*(1-layer*.16),Color(0,0,0,.055*landing))
    canvas.draw_set_transform(Vector2.ZERO)

func draw_body(canvas: CanvasItem, at: Vector2, phase: int) -> void:
    if player == null:return
    var size := 520.0 * (1.0 + (phase - 1) * .12)
    draw_debris(canvas,at,false)
    canvas.draw_texture_rect(viewport.get_texture(), Rect2(at - Vector2.ONE * size / 2, Vector2.ONE * size), false)

    draw_debris(canvas,at,true)

func draw_debris(canvas:CanvasItem,center:Vector2,front:bool)->void:
    if fresh_study:return
    if debris_texture==null:return
    for index in range(7):
        var angle=encounter_clock*.4+index*TAU/7
        if (sin(angle)>0)!=front:continue
        var at=center+Vector2.from_angle(angle)*180
        var tangent=Vector2.from_angle(angle+PI/2)
        for ember in range(4):
            var behind=at-tangent*(10+ember*8)+Vector2(0,sin(encounter_clock*3+index+ember)*3)
            canvas.draw_circle(behind,1.7-ember*.3,Color(1,.24,.025,.32-ember*.07))
        var frame=posmod(int(encounter_clock*(12.0+index*.6))+index*7,64)
        var source=Rect2(Vector2(frame%8,floori(float(frame)/8))*128,Vector2(128,128))
        var dimensions=Vector2(56,48)*(1.0+sin(index*7.0)*.15)
        canvas.draw_texture_rect_region(debris_texture,Rect2(at-dimensions/2,dimensions),source)
