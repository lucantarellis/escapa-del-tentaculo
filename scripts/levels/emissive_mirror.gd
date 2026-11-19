@tool
class_name EmissiveMirror
extends TileMapLayer
## Capa emisiva de una capa de paredes: copia las celdas de su capa padre y las dibuja con el
## tileset `*_emissive.tres` (solo los píxeles que emiten luz) en un material sin sombreado.
##
## Va como HIJA de la capa que refleja. Las celdas cuyo tile no existe en el tileset emisivo
## (fuentes sin píxeles emisivos) simplemente no se dibujan. En el editor se mantiene
## sincronizada mientras se pinta la capa padre; las celdas copiadas no se guardan en la escena
## (se vuelven a copiar al cargar). Ver `docs/arte/paredes-nave.md`.


func _ready() -> void:
	var source: TileMapLayer = get_parent() as TileMapLayer
	if source == null:
		push_warning("EmissiveMirror: el padre de '%s' no es un TileMapLayer, no hay nada que reflejar." % name)
		return
	_sync()
	if Engine.is_editor_hint() and not source.changed.is_connected(_sync):
		source.changed.connect(_sync)


# Las celdas se copian del padre al cargar: no se serializan en la escena.
func _validate_property(property: Dictionary) -> void:
	if property.name == "tile_map_data":
		property.usage &= ~PROPERTY_USAGE_STORAGE


func _sync() -> void:
	var source: TileMapLayer = get_parent() as TileMapLayer
	if source == null:
		return
	var data: PackedByteArray = source.tile_map_data
	if data != tile_map_data:
		tile_map_data = data
