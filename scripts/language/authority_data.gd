class_name AuthorityData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var tags: Array[StringName] = []
@export var effect_id: StringName = &""
@export var corruption: int = 0
@export_multiline var description: String = ""
## Optional Boss-offer condition. Empty means the authority is only offered when
## a chapter plan lists it explicitly. "corruption" / "records" read this run;
## "profile_records" reads the cross-run Profile counter.
@export var unlock_condition: StringName = &""
@export var unlock_threshold: int = 0
