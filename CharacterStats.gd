@tool
extends Resource
class_name CharacterStats

@export var character_name: String = "Character"
@export_group("Stats")
@export var health: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 10
