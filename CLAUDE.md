# 2D Creepy Cozy Farm â€” notes for Claude

Godot 4.6 GDScript, top-down pixel-art farming game with a no-monster horror mood.
`REQUIREMENTS.md` is the source of truth for features (IDs like FSH-2, ATM-3).

## Layout
- `scripts/` â€” shared code. Autoloads: `UI` (`ui.gd`: dialogue, list menus, messages, prompt, backpack, fishing signals, options) and `GameState` (`game_state.gd`: day/clock, money, needs/health, shipping, sleep, village state, mine progress; owns `inventory`, `jobs: JobBoard`, `quests: QuestBoard`). Also `world_area.gd` (base of Farm and Mine), `shop.gd`, `save_game.gd` (JSON save), `ui_theme.gd` (shared look), `tools.gd` (tool enum).
- `scripts/data/` â€” Resource types: ItemData, CropData, FishData, JobData, AnimalData, QuestData, EnemyData, MineFloorData, BuildingData, ShopData, RecipeData.
- `data/` â€” `.tres` instances (items, crops, fish, jobs, quests, animals, enemies, mine floors, village buildings/shops/recipes). Add content here, not in code.
- `scene/` â€” `main/` (main.tscn, farm.gd, tile highlight), `player/`, `house/`, `objects/` (bed, phone, shipping box, signpost), `animals/`, `crops/`, `mine/` (mine.gd builds floors in code, enemy.gd, cave entrance), `village/` (buildings, quest board, well), `menus/` (title = main scene, pause menu, options), `atmosphere/`, `ui/` (hud, inventory slot, fishing ring).
- `tools/` â€” `generate_assets.gd` draws `assets/Generated/` (placeholder art + sounds); `build_world.gd` repaints the surface map into main.tscn. Run with `-s`, then re-import.
- `scene/test/` â€” the user's old test scenes.

## Rules for working here
- **Never read `.tscn` files whole**: `main.tscn` and the test scenes contain huge base64 `tile_map_data`. Use Grep for the lines you need.
- `.tres`/`.tscn` saved from a `-s` script lose their `uid=` attributes; restore them or edit text directly.
- Keep replies short. Only take screenshots when visuals changed.

## Tools and commands (Windows, PowerShell)
- git is not on PATH: `$g = (Resolve-Path "$env:LOCALAPPDATA\GitHubDesktop\app-*\resources\app\git\cmd\git.exe" | Select-Object -Last 1).Path`. Use `git commit -F <file>` for multi-line messages. gh CLI handles push auth.
- Godot: `$godot = "C:\Users\lukea\Downloads\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64_console.exe"`
- Re-import after adding scripts/assets: `& $godot --headless --path . --import`
- Gameplay test (kept outside the repo): `& $godot --headless --path . --quit-after 9000 -s "C:\Users\lukea\.claude\scheduled-tasks\farm-test-and-cleanup\test_loop.gd" *> "$env:TEMP\t.txt"`, then check for `FAIL`/`RESULT`/`ERROR`. In `-s` mode autoload types aren't known at compile time, so the test uses untyped vars.
