extends ColorRect
class_name FogOfWar

@export var target_group: StringName = &"player"
@export var clear_radius: float = 110.0
@export var fade_radius: float = 235.0
@export_range(0.0, 1.0) var darkness_alpha: float = 0.96
@export var darkness_color: Color = Color(0.0, 0.0, 0.0, 1.0)

const FOG_SHADER_CODE = """
shader_type canvas_item;
render_mode unshaded;

uniform vec2 light_center_px = vec2(640.0, 360.0);
uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform float clear_radius_px = 110.0;
uniform float fade_radius_px = 235.0;
uniform float darkness_alpha = 0.96;
uniform vec4 darkness_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 pixel = SCREEN_UV * viewport_size;
	float distance_to_light = distance(pixel, light_center_px);
	float fog_alpha = smoothstep(clear_radius_px, fade_radius_px, distance_to_light) * darkness_alpha;
	COLOR = vec4(darkness_color.rgb, fog_alpha);
}
"""

var _target: Node2D = null
var _fog_material: ShaderMaterial = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	_setup_material()
	_find_target()
	# 应用设置：若「移除战争迷雾」已勾选，初始关闭迷雾层。
	# 控制台 /fog 命令仍可在游戏中重新打开。
	if Settings and Settings.disable_fog:
		var parent := get_parent()
		if parent is CanvasLayer:
			parent.visible = false

func _process(_delta: float) -> void:
	if not is_instance_valid(_target):
		_find_target()

	_update_shader_parameters()

func _setup_material() -> void:
	var shader := Shader.new()
	shader.code = FOG_SHADER_CODE

	_fog_material = ShaderMaterial.new()
	_fog_material.shader = shader
	material = _fog_material

func _find_target() -> void:
	var nodes := get_tree().get_nodes_in_group(target_group)
	for node in nodes:
		if node is Node2D:
			_target = node
			return
	_target = null

func _update_shader_parameters() -> void:
	if not _fog_material:
		return

	var viewport_size := get_viewport_rect().size
	var light_center := viewport_size * 0.5
	if is_instance_valid(_target):
		light_center = get_viewport().get_canvas_transform() * _target.global_position

	_fog_material.set_shader_parameter("light_center_px", light_center)
	_fog_material.set_shader_parameter("viewport_size", viewport_size)
	_fog_material.set_shader_parameter("clear_radius_px", clear_radius)
	_fog_material.set_shader_parameter("fade_radius_px", fade_radius)
	_fog_material.set_shader_parameter("darkness_alpha", darkness_alpha)
	_fog_material.set_shader_parameter("darkness_color", darkness_color)
