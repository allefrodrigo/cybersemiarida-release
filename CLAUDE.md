# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **cybersemiarida**, a 2D platformer game built with Godot 4.4. The game features a character navigating through levels in a northeastern Brazilian (sertão) setting, with accessibility features including colorblind support.

## Development Commands

This project uses Godot Engine and doesn't have traditional build scripts. Development is done through the Godot editor:

- **Run Game**: Open project.godot in Godot Editor and press F5 or click the play button
- **Export**: Use Godot's export presets defined in export_presets.cfg
- **Scene Testing**: Run individual scenes by opening them in the editor

## Architecture Overview

### Core Singletons (Autoloads)
Located in project.godot autoload section:
- `CheckpointManager` - Handles player checkpoint saving/loading across levels
- `GameManager` - Manages global game state and level transitions  
- `GameState` - Tracks player statistics (death count, time elapsed, key possession)
- `MusicPlayer` - Handles background music management
- `FallManager` - Manages fall damage and respawn mechanics
- `DialogManager` - Manages dialogue system integration
- `global_accesibility_signal` - Colorblind filter state (from the accessibility addon)
- `ColorBlindLayer` - Persistent colorblind filter layer (`colorblind_shaderscreen.tscn` + `scripts/colorblind_layer.gd`, CanvasLayer 120, hidden on "Normal"); covers every scene, so new scenes must NOT instance the filter again

### Key Components

**Player System** (`Player/player.gd`):
- CharacterBody2D-based player controller with platformer physics
- Wall sliding and wall jumping mechanics
- Sound effects and camera shake
- Checkpoint respawn system
- Key collection mechanics

**Level Structure**:
- Playable route (set/2026): `scenes/main_title.tscn` → `levels/release/caf_01` → `caf_02` → `caf_03` → fall cutscene `scenes/caf_fall_dg.tscn` → `caf_03_dg` (key + door) → `des_01` (dead end, no exit yet)
- Also in `levels/release/` but off the route (nothing leads to them): `caf_04`, `caf_05`, `caf_dg`; credits `scenes/CreditsScreen.tscn` is unreachable too
- Some release levels still use scripts stored in `levels/Level_design/TILED/CSA/Mapa/`
- Level design files in `levels/Level_design/TILED/` (uses Tiled map editor)
- `levels/Level_design/_arquivo_morto/` holds archived Tiled test files; it has a `.gdignore`, so Godot ignores it
- Scenes follow naming pattern: caf_XX for "Cafundó" levels, des_XX for desert levels

**Dialogue System**:
- Uses dialogue_manager addon for narrative content
- `dialogues/` = addon example dialogue ("Nathan", English) + the balloon scene; `dialogos/` = the real Dona Graça dialogue
- Balloon UI system for conversation display

**Accessibility Features**:
- Colorblind support via `addons/accesibilitytools/`
- Shader-based color filters for different types of colorblindness
- Accessibility signal system for enhanced UI feedback

### Audio System
- Background music managed by MusicPlayer singleton
- SFX integrated into player actions (jump, footstep, fall sounds)
- Audio files in `audio/` and `assets/Music/` directories

### Visual Assets
- Parallax backgrounds with multiple layers (`assets/background/`, `assets/bg_deserto/`)
- Tilesets for level construction in `scenes/World/Tilesets/`
- Character sprites and animations in `Player/` directory
- UI elements and buttons in `assets/Buttons/`

## File Organization

- `scenes/` - Game scenes and UI components
- `scripts/` - Core game logic scripts  
- `levels/` - Level files and design assets
- `Player/` - Player character assets and scripts
- `assets/` - Game art, music, and visual resources
- `addons/` - Third-party plugins (dialogue_manager, accessibility tools)
- `shaders/` - Custom shader files for visual effects
- `singleton/` - Global manager scripts

## Important Notes

- Main scene entry point: `scenes/main_title.tscn`
- Player character uses groups system ("player" group) for identification
- Checkpoint system prevents regression (only saves checkpoints with higher IDs)
- Game supports both keyboard and gamepad input
- Resolution: 272x153 with canvas scaling for pixel art aesthetic