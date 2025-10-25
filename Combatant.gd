extends RefCounted
class_name Combatant

var stats: CharacterStats
var current_health: int
var team: int
var action_bar: float = 0.0

func _init(base_stats: CharacterStats, combat_team: int):
	self.stats = base_stats
	self.team = combat_team
	self.current_health = stats.health
	self.action_bar = randf() * 25.0 #Optional to start with a random amount of filled action bar
