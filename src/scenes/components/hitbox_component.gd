extends Area2D

class_name HitboxComponent

signal on_hit_hurtbox(hurtbox: HurtboxComponent)

var damage := 1.0
var critical := false
var knockback_power := 0
var source: Node2D
var weapon: Weapon
var pending_overlap_scan: bool = false
var hit_hurtbox_ids: Dictionary = {}
var damage_active: bool = true

#func _ready() -> void:
#	area_entered.connect(_on_area_entered)


func enable() -> void: 
	damage_active = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	pending_overlap_scan = true
	hit_hurtbox_ids.clear()
	
func disable() -> void:
	damage_active = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	pending_overlap_scan = false
	hit_hurtbox_ids.clear()
	
func setup(damage: float, critical: bool, knockback: float, source: Node2D, weapon: Weapon) -> void:
	self.damage = damage
	self.critical = critical
	knockback_power = knockback
	self.source = source
	self.weapon = weapon

func _physics_process(_delta: float) -> void:
	if not pending_overlap_scan:
		return
	if not monitoring:
		return

	pending_overlap_scan = false
	_emit_overlapping_hurtboxes()


func _emit_overlapping_hurtboxes() -> void:
	for area: Area2D in get_overlapping_areas():
		var hurtbox: HurtboxComponent = area as HurtboxComponent
		if hurtbox == null:
			continue
		_try_emit_hit(hurtbox)


func _on_area_entered(area: Area2D) -> void:
	var hurtbox: HurtboxComponent = area as HurtboxComponent
	if hurtbox == null:
		return
	_try_emit_hit(hurtbox)


func is_damage_active() -> bool:
	return damage_active


func _try_emit_hit(hurtbox: HurtboxComponent) -> void:
	if not damage_active:
		return

	if hurtbox == null or not is_instance_valid(hurtbox):
		return

	var hurtbox_id: int = hurtbox.get_instance_id()
	if hit_hurtbox_ids.has(hurtbox_id):
		return

	hit_hurtbox_ids[hurtbox_id] = true
	hurtbox.receive_hit_from_hitbox(self)
	if hurtbox.owner is Enemy:
		SoundManager.play_sound(SoundManager.Sound.ENEMY_HIT)
	on_hit_hurtbox.emit(hurtbox)
