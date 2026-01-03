# LUAU-Enemy-FSM-simple

A simple FSM (Finite State Machine) system for enemies in Roblox using **Luau**, with built-in animation support and basic attack, pursuit, and player detection functionality.

---

## Repository Contents

1. **`enemyAnimsfsm.lua`**  
   Handles enemy animations based on their state.  
   Features:
   - Plays Idle, Walk, Run, Attack, Hit, and Death animations.
   - Caches animations to prevent unnecessary reloads.
   - Supports instant animations (like Attack or Hit) without interfering with other animations.
   - Adjusts animation priorities (`Movement` vs `Action`).

2. **`enemyfsm.lua`**  
   Main enemy FSM: manages states and transitions.  
   Included states:
   - `IDLE` → Random movement and player searching.
   - `DETECTION` → Move towards detected player.
   - `PERSECUTION` → Actively chase the player.
   - `FOCUS` → Stand in front of the player and attack when ready.  

   Key functions:
   - `Setup(enemy, config, objectOriented, animsFSM)` to initialize the FSM on an enemy model.
   - Handles attack timers and rotation toward the target.
   - Calls the animation system based on the current state.

3. **`enemyconfig.lua`**  
   Enemy configuration, including:
   - Animations (Idle, Walk, Run, Attack, etc.)
   - Stats: damage, detection range, persecution range, movement speed per state.
   - FSM used by the enemy.
   - Weapons setup (currently empty, ready for expansion).

---

## Installation

1. Clone or download the repository.
2. Place the modules in `ReplicatedStorage.Modules` or a preferred location.
3. Ensure a RemoteEvent called `Comms` exists in `ReplicatedStorage.Remotes`.

---

## Usage

### Creating an Enemy

```lua
local enemyFSM = require(ReplicatedStorage.Modules.enemyfsm)
local enemyAnimsFSM = require(ReplicatedStorage.Modules.enemyAnimsfsm)
local enemyConfig = require(ReplicatedStorage.Modules.enemyconfig)

local enemyModel = workspace.Enemy -- your enemy model
local config = enemyConfig.Types.Skeleton

enemyFSM:Setup(enemyModel, config, ObjectOrientedModule, enemyAnimsFSM)
