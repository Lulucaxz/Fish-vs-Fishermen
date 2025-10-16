extends GridContainer


@export var custom_columns := 3

func _ready():
	update_alignment()

func update_alignment():
	var children = get_children()
	if children.is_empty():
		return

	# Limpa wrappers anteriores (se existirem)
	for child in children:
		if child.name.begins_with("CenterWrapper_"):
			remove_child(child)
			child.queue_free()

	children = get_children()
	var remainder = children.size() % custom_columns

	# Se sobrar 1 elemento na última linha:
	if remainder == 1:
		var last_child = children[-1]
		remove_child(last_child)

		# Cria um container que centraliza
		var wrapper = HBoxContainer.new()
		wrapper.name = "CenterWrapper_%s" % last_child.name
		wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Adiciona o botão dentro do wrapper
		wrapper.add_child(last_child)
		add_child(wrapper)
