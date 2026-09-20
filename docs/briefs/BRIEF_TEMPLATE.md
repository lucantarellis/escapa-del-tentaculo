# Brief NN — <tema> (pasos X a Y) — "Escapa del Tentáculo"

> Plantilla. Copiar a `docs/briefs/brief-NN-<tema>.md`, completar cada sección y pegar en una conversación nueva de Claude (Cowork) junto con `docs/ROADMAP.md`. Borrar este bloque y los textos entre `<...>`.

Brief autocontenido: da todo el contexto necesario sin depender de conversaciones previas.

## Contexto

- **Juego:** una línea (ver `ROADMAP.md`, sección 1).
- **Stack:** Godot 4.7.2 stable, GDScript tipado.
- **Repo:** <URL> · **Rama base:** `main`
- **Estado del repo:** <qué existe ya, qué pasos del roadmap están hechos>
- **Alcance de este brief:** <pasos incluidos y qué queda explícitamente fuera>

## Qué necesita aportar LT

1. Adjuntos: `ROADMAP.md`, este brief, <otros>.
2. Ruta local del repo, `gh` autenticado y, si se quiere validación por CLI, la ruta del ejecutable de Godot.
3. <otros insumos>

## Decisiones ya tomadas

<Copiar de ROADMAP.md, sección 2, solo las que aplican a este brief. Cowork no las reabre: si ve un problema, lo avisa antes de improvisar.>

## Reglas de trabajo

- Detenerse al final de cada paso y esperar el "seguí" de LT.
- Sin `git push`, `gh pr create` ni cambios en GitHub sin confirmación explícita, mostrando antes árbol de archivos y resumen de cambios.
- Ningún valor de gameplay hardcodeado: todo en `Resource` de configuración.
- Documentación es parte de "hecho" (ver `docs/CONVENCIONES.md`).
- Si el brief contradice el estado real del repo, avisar antes de continuar.
- Sin acceso a shell: escribir archivos y entregar a LT los comandos para correr él mismo.

## Pasos

### Paso N — <nombre>

**Objetivo:** <una frase>

**Entregables:**
- <archivo o escena, con ruta>

**Especificación:** <parámetros con valor inicial, señales, API pública, estructura de nodos>

**Criterios de aceptación (checklist para que LT pruebe):**
- [ ] <comportamiento observable>

**Documentación a escribir:** <archivos de docs/ a crear o actualizar>

**Commit:** `<mensaje>`

## Cierre

1. Actualizar `docs/ROADMAP.md` (sección 4 y decisiones nuevas).
2. Actualizar `docs/ARQUITECTURA.md`.
3. Pedir confirmación y hacer push de la rama.

## Resultado esperado

<Estado del repo y del juego al terminar.>
