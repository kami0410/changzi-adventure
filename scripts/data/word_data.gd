class_name WordData
extends Resource

enum GrammarRole { NOUN, VERB, MODIFIER }

@export var id: StringName = &""
@export var glyph: String = ""
@export var phoneme: String = ""
@export var meaning: String = ""
@export var grammar_role: GrammarRole = GrammarRole.NOUN
@export var tags: Array[StringName] = []
@export var power: int = 1
@export var corruption: int = 0
@export var decoded: bool = false
@export var components: Dictionary[StringName, float] = {}
@export_multiline var description: String = ""
