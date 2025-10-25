extends Control

@onready var team_a_selectors: Array[OptionButton] = [
	$Panel/VBox/Selectors/TeamA_Slot1,
	$Panel/VBox/Selectors/TeamA_Slot2,
	$Panel/VBox/Selectors/TeamA_Slot3
]
@onready var team_b_selectors: Array[OptionButton] = [
	$Panel/VBox/Selectors/TeamB_Slot1,
	$Panel/VBox/Selectors/TeamB_Slot2,
	$Panel/VBox/Selectors/TeamB_Slot3
]
@onready var team_a_health_labels: Array[Label] = [
	$Panel/VBox/HealthDisplays/TeamA_VBox/Health1,
	$Panel/VBox/HealthDisplays/TeamA_VBox/Health2,
	$Panel/VBox/HealthDisplays/TeamA_VBox/Health3
]
@onready var team_b_health_labels: Array[Label] = [
	$Panel/VBox/HealthDisplays/TeamB_VBox/Health1,
	$Panel/VBox/HealthDisplays/TeamB_VBox/Health2,
	$Panel/VBox/HealthDisplays/TeamB_VBox/Health3
]
@onready var summon_button: Button = $Panel/VBox/SummonButton
@onready var start_button: Button = $Panel/VBox/StartSimulationButton
@onready var combat_log: RichTextLabel = $Panel/VBox/CombatLog
@onready var winner_label: Label = $Panel/VBox/WinnerLabel

var team_a_combatants: Array[Combatant] = []
var team_b_combatants: Array[Combatant] = []
var summon_count: int = 1
const ACTION_THRESHOLD: float = 100.0


func _ready() -> void:
	randomize()
	summon_button.pressed.connect(_on_summon_button_pressed)
	start_button.pressed.connect(_on_start_simulation_pressed)
	_populate_selectors()


func _populate_selectors() -> void:
	if CharacterDatabase.characters.is_empty():
		combat_log.add_text("NO CHARACTERS AVAILABLE! HIT SUMMON NEW CHARACTER TO GATHER COMBATANTS")
		start_button.disabled = true
		return

	for i in range(CharacterDatabase.characters.size()):
		var char_stats: CharacterStats = CharacterDatabase.characters[i]
		if char_stats:
			var char_name = char_stats.character_name
			for selector in team_a_selectors:
				selector.add_item(char_name, i)
			for selector in team_b_selectors:
				selector.add_item(char_name, i)
		else:
			print("Warning: Null character resource in CharacterDatabase at index %d" % i)

func _on_start_simulation_pressed() -> void:
	start_button.disabled = true
	winner_label.text = ""
	combat_log.clear()
	
	team_a_combatants.clear()
	team_b_combatants.clear()
	
	add_log_entry("--- Simulation Starting! ---", Color.WHITE)
	
	for i in 3:
		var char_a_index: int = team_a_selectors[i].get_selected_id()
		var stats_a: CharacterStats = CharacterDatabase.characters[char_a_index]
		team_a_combatants.append(Combatant.new(stats_a, 0))
		
		var char_b_index: int = team_b_selectors[i].get_selected_id()
		var stats_b: CharacterStats = CharacterDatabase.characters[char_b_index]
		team_b_combatants.append(Combatant.new(stats_b, 1))

	_update_health_ui()
	_run_simulation()
	
func _on_summon_button_pressed() -> void:
	var min_health = 80
	var max_health = 150
	var min_attack = 10
	var max_attack = 25
	var min_defense = 5
	var max_defense = 20
	var min_speed = 10
	var max_speed = 30

	var rand_health = randi_range(min_health, max_health)
	var rand_attack = randi_range(min_attack, max_attack)
	var rand_defense = randi_range(min_defense, max_defense)
	var rand_speed = randi_range(min_speed, max_speed)
	
	var new_char = CharacterStats.new()
	var new_char_name = "Summoned #%d" % summon_count
	new_char.character_name = new_char_name
	new_char.health = rand_health
	new_char.attack = rand_attack
	new_char.defense = rand_defense
	new_char.speed = rand_speed

	CharacterDatabase.characters.append(new_char)
	
	if CharacterDatabase.characters.size() == 1:
		combat_log.clear()
		start_button.disabled = false
	
	var new_char_index = CharacterDatabase.characters.size() - 1
	
	for selector in team_a_selectors:
		selector.add_item(new_char_name, new_char_index)
	for selector in team_b_selectors:
		selector.add_item(new_char_name, new_char_index)

	summon_count += 1
	
	var log_color = Color.MEDIUM_PURPLE
	add_log_entry("New character summoned!", log_color)
	add_log_entry("  %s (H:%d, A:%d, D:%d, S:%d)" % [new_char_name, rand_health, rand_attack, rand_defense, rand_speed], log_color)
	
func _run_simulation() -> void:
	
	var all_combatants: Array[Combatant] = team_a_combatants + team_b_combatants
	
	add_log_entry("--- Combat Started (ATB System) ---", Color.WHITE)
	add_log_entry("Action Threshold is %d. Ticks advance..." % ACTION_THRESHOLD, Color.LIGHT_GRAY)
	
	await get_tree().create_timer(1.0).timeout

	while _is_team_alive(team_a_combatants) and _is_team_alive(team_b_combatants):
		
		var actor: Combatant = null
		
		while actor == null:
			if not (_is_team_alive(team_a_combatants) and _is_team_alive(team_b_combatants)):
				break
				
			for c in all_combatants:
				if c.current_health > 0:
					c.action_bar += c.stats.speed
					
					if c.action_bar >= ACTION_THRESHOLD:
						actor = c
						break
			
			if actor:
				break
				
			await get_tree().create_timer(0.05).timeout
			
		if actor == null:
			break
			
		actor.action_bar -= ACTION_THRESHOLD
		
		var target_team: Array[Combatant]
		if actor.team == 0:
			target_team = team_b_combatants
		else:
			target_team = team_a_combatants
			
		var target: Combatant = _find_random_living_target(target_team)
		
		if target:
			var damage = max(1, actor.stats.attack - target.stats.defense)
			
			target.current_health -= damage
			
			var team_color = Color.AQUAMARINE if actor.team == 0 else Color.LIGHT_PINK
			add_log_entry("%s attacks %s for %d damage!" % [actor.stats.character_name, target.stats.character_name, damage], team_color)
			
			if target.current_health <= 0:
				target.current_health = 0 
				add_log_entry("%s has been defeated!" % target.stats.character_name, Color.RED)
			
			_update_health_ui()
			await get_tree().create_timer(0.5).timeout
			
	if _is_team_alive(team_a_combatants):
		add_log_entry("--- TEAM A WINS! ---", Color.GOLD)
		winner_label.text = "TEAM A WINS!"
	else:
		add_log_entry("--- TEAM B WINS! ---", Color.GOLD)
		winner_label.text = "TEAM B WINS!"

	start_button.disabled = false

func add_log_entry(text: String, color: Color = Color.WHITE) -> void:
	combat_log.push_color(color)
	combat_log.add_text(text + "\n")
	combat_log.pop()

func _is_team_alive(team: Array[Combatant]) -> bool:
	for combatant in team:
		if combatant.current_health > 0:
			return true
	return false

func _find_random_living_target(team: Array[Combatant]) -> Combatant:
	var living_targets: Array[Combatant] = []
	for combatant in team:
		if combatant.current_health > 0:
			living_targets.append(combatant)
	
	if living_targets.is_empty():
		return null
	
	return living_targets.pick_random()

func _update_health_ui() -> void:
	for i in 3:
		var c_a = team_a_combatants[i]
		team_a_health_labels[i].text = "%s: %d / %d HP" % [c_a.stats.character_name, c_a.current_health, c_a.stats.health]
		if c_a.current_health == 0:
			team_a_health_labels[i].modulate = Color(0.5, 0.5, 0.5)
		else:
			team_a_health_labels[i].modulate = Color.WHITE
			
		var c_b = team_b_combatants[i]
		team_b_health_labels[i].text = "%s: %d / %d HP" % [c_b.stats.character_name, c_b.current_health, c_b.stats.health]
		if c_b.current_health == 0:
			team_b_health_labels[i].modulate = Color(0.5, 0.5, 0.5)
		else:
			team_b_health_labels[i].modulate = Color.WHITE
