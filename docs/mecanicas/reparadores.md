# Reparadores

## Propósito
Dar al jugador una forma de recuperar vidas durante la partida (mejora Reparador I, II y III del mercado, rama Repara). Hace falta tener más de una vida (rama Vidas) para que sirvan.

## Modelo
- Hay tres tipos (`Repairer.Kind`): **llave inglesa** (cura 1 vida), **venda** (cura 2) y **botiquín** (cura todas y da un escudo).
- El nivel de reparador comprado (`PlayerProgress.get_repair_level()`: 0 a 3) decide cuáles pueden aparecer: nivel 1 = llave; 2 = llave y venda; 3 = llave, venda y botiquín. Se sortea entre los habilitados con pesos (llave 5, venda 3, botiquín 1).
- Al armar el nivel, `LevelBuilder` pasa por cada segmento intermedio con `RepairerSpawner`: 40 % de chance de poner un reparador en un lugar libre (mismo criterio que las monedas: lejos de plataformas, paredes y otros objetos). Usa su propio azar (`seed + REPAIRER_SEED_OFFSET`), así que **no mueve las monedas** y la misma seed da los mismos reparadores.
- Sin comprar Reparador I (o con el progreso apagado) no aparece ninguno.
- La llave y la venda **no se recogen con la vida llena**: quedan en su lugar y se recogen apenas hace falta (si estás encima, reintenta cada frame de física). El botiquín se recoge siempre, por el escudo.
- **Escudo del botiquín:** dura 5 s (10 s con la mejora **Escudo 10 s**; sin tiempo, hasta que absorbe un golpe, con **Escudo eterno**), absorbe UN golpe común y se rompe (el golpe no quita vida y no cuenta como golpe recibido: sin parpadeo ni invulnerabilidad; un golpe sin escudo sí hace parpadear y da 1,5 s de invulnerabilidad). No frena a los perseguidores (`tentacle`) ni a la caída (`fell`). Se ve como un óvalo vertical cian (aro más relleno translúcido, ~34 × 54 px, placeholder) que cubre al astronauta entero y la llama del jetpack, y parpadea el último segundo (el eterno no parpadea ni se vence). Si agarrás otro botiquín con el escudo activo, se renueva. `Player.reset()` lo quita.

## Parámetros (`ProgressConfig`, grupo "Reparadores")
| Parámetro | Valor | Unidad |
|---|---|---|
| `repairer_chance_percent` | 40 | % por segmento |
| `repairer_weight_wrench` / `bandage` / `medkit` | 5 / 3 / 1 | peso relativo |
| `repairer_heal_wrench` / `bandage` | 1 / 2 | vidas |
| `repairer_shield_duration` | 5 | s |
| `shield_upgrade_duration` (con Escudo 10 s) | 10 | s |

## Señales y API
- `Repairer.collected(kind, healed)`.
- `Player.heal(amount)` (menor que 0 = todas; devuelve lo curado), `Player.needs_healing()`, `Player.give_shield(duration)` (negativo = sin tiempo, dura hasta que te pegan), `PlayerProgress.get_shield_level()` / `get_shield_duration()`, `Player.has_shield()`, señal `Player.shield_changed(active)`. Los corazones del HUD se actualizan solos (`hit_points_changed`).

## Nodos
`Repairer` (`Area2D`, capa 6 `pickups`, máscara 2 `player`) con un hijo `PickupSkin` creado en código según el tipo: llave → `pickup_wrench`, venda → `pickup_tape` (cinta selladora), botiquín → `pickup_toolbox` (caja de herramientas). Al recogerlo reproduce el destello de recolección y se oculta. Ver "Recogibles con sprites" en `docs/mecanicas/tanques.md`. Escena: `scenes/pickups/Repairer.tscn`.

## Cómo probar
1. En el mercado (rama Repara) comprar Vidas I, Vidas II y Reparador I (alcanzan monedas de varias partidas; o `debug_set_coins` en `ProgressConfig`).
2. F6 sobre `Level.tscn`: aparecen reparadores en algunos segmentos. Pegarte con un obstáculo y juntar una llave: la vida sube 1.
3. Comprar Reparador II y III y repetir: venda (+2) y botiquín (todo + aro de escudo; el siguiente obstáculo no te saca vida).
4. Con la seed fija en `level_config.tres` ves siempre los mismos lugares.

## Pendiente
sprites finales, sonido y animación del escudo.
