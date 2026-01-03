# LUAU-Enemy-FSM-simple

Un sistema simple de FSM (Finite State Machine) para enemigos en Roblox usando **Luau**, con animaciones integradas y soporte básico de ataque, persecución y detección de jugadores.

---

## Contenido del repositorio

1. **`enemyAnimsfsm.lua`**  
   Maneja las animaciones de los enemigos según su estado.  
   Funcionalidades:
   - Detecta y reproduce animaciones de Idle, Walk, Run, Attack, Hit y Death.
   - Cache de animaciones para evitar recargas innecesarias.
   - Permite reproducir animaciones instantáneas de ataque o hit sin interferir con otras animaciones.
   - Ajusta prioridades de animación (`Movement` vs `Action`).

2. **`enemyfsm.lua`**  
   FSM principal del enemigo: gestiona los estados y transiciones.  
   Estados incluidos:
   - `IDLE` → Movimiento aleatorio y búsqueda de jugadores.
   - `DETECTION` → Movimiento hacia jugador detectado.
   - `PERSECUTION` → Persecución activa del jugador.
   - `FOCUS` → Pararse frente al jugador y atacar cuando corresponda.  
   
   Funciones principales:
   - `Setup(enemy, config, objectOriented, animsFSM)` para inicializar el FSM en un modelo de enemigo.
   - Maneja temporizadores de ataque y rotación hacia el objetivo.
   - Llama al sistema de animaciones según el estado actual.

3. **`enemyconfig.lua`**  
   Configuración de enemigos, incluyendo:
   - Animaciones (Idle, Walk, Run, Attack, etc.)
   - Estadísticas: daño, rango de detección, rango de persecución, velocidad por estado.
   - FSM utilizada por el enemigo.
   - Configuración de armas (vacía actualmente, lista para extender).

---

## Instalación

1. Clonar o descargar el repositorio.
2. Colocar los módulos en `ReplicatedStorage.Modules` o donde prefieras.
3. Asegurarte de tener un RemoteEvent llamado `Comms` en `ReplicatedStorage.Remotes`.

---

## Uso

### Crear un enemigo

```lua
local enemyFSM = require(ReplicatedStorage.Modules.enemyfsm)
local enemyAnimsFSM = require(ReplicatedStorage.Modules.enemyAnimsfsm)
local enemyConfig = require(ReplicatedStorage.Modules.enemyconfig)

local enemyModel = workspace.Enemy -- tu modelo de enemigo
local config = enemyConfig.Types.Skeleton

enemyFSM:Setup(enemyModel, config, ObjectOrientedModule, enemyAnimsFSM)
