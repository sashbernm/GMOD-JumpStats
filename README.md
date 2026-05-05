# GMOD-JumpStats

A WIP upgrade from previous JHUD / SSJ / JumpStats iterations.

Basically, this is a cleaner remake of the old jumpstats stuff for Garry's Mod. The goal is to keep the old JHUD / SSJ feel, but make the codebase less painful to work on and easier to expand.

This is not really meant to be a perfect final release yet. It is still being worked on.

## What it does

- Shows a jump HUD with your current jump stats.
- Shows a velocity HUD while moving.
- Prints SSJ-style stats in chat after jumps.
- Lets spectators see the stats of the player they are watching.
- Has a modern in-game settings menu.
- Saves client settings locally.
- Keeps the code split into actual modules instead of one giant mess.

## Current stats

Right now it tracks / displays stuff like:

- jump count
- velocity
- gain
- sync
- JSS / yaw stat
- efficiency
- strafes per jump
- prestrafe

## Commands

| Command | What it does |
| --- | --- |
| `js_menu` | opens the JumpStats menu |
| `js_reset` | resets all JumpStats settings |
| `js_jhud` | toggles the jump HUD |
| `js_velhud` | toggles the velocity HUD |
| `js_ssj` | toggles SSJ chat output |
| `js_help` | prints the command list |
| `js_jhud_pos <x> <y>` | moves the jump HUD using screen ratios from `0.0` to `1.0` |
| `js_velhud_pos <x> <y>` | moves the velocity HUD using screen ratios from `0.0` to `1.0` |

You can also open the menu in chat with:

```txt
!jhud
/jhud
!jumpstats
/jumpstats
!js
/js
```

## Install

Put the addon folder in:

```txt
garrysmod/addons/jumpstats
```

The folder should contain:

```txt
lua/autorun/sh_init.lua
```

So it should look roughly like:

```txt
garrysmod/addons/jumpstats/lua/autorun/sh_init.lua
```

After that, restart the server / game and run:

```txt
js_menu
```

## Settings

Settings are saved clientside in:

```txt
data/jumpstats/settings.json
```

The menu lets you change things like:

- what HUDs are enabled
- what stats show on JHUD
- what stats show in SSJ chat
- HUD positions
- font sizes
- spectator stat sending / receiving

## File structure

```txt
lua/autorun/sh_init.lua
```

Loads the addon and includes the shared, client, and server files.

```txt
lua/jumpstats/sh_namespace.lua
lua/jumpstats/sh_util.lua
lua/jumpstats/sh_config.lua
lua/jumpstats/sh_net.lua
```

Shared setup, config, utility functions, and networking.

```txt
lua/jumpstats/client/settings/
```

Client settings, menu, saved settings, and console commands.

```txt
lua/jumpstats/client/stats/
```

The actual jump tracking / stat calculation code.

```txt
lua/jumpstats/client/hud/
```

JHUD, velocity HUD, fonts, and HUD dispatching.

```txt
lua/jumpstats/client/chat/
```

SSJ chat output.

```txt
lua/jumpstats/server/
```

Server init, chat commands, and spectator stat forwarding.

## Current status

This is still WIP.

Stuff is being rewritten from the old versions, so some things may change or break while it gets cleaned up. The main idea is to get the addon functional first, then keep polishing the visuals, accuracy, and settings.

## Notes

- This is for Garry's Mod.
- This is mostly clientside, but spectators use server networking.
- No external addon should be required, though if you want proper logging, it's highly recommended to download my BetterLog addon.
- If BetterLog exists, it will use it. If not, it falls back to normal printing.

## TODO / planned

- keep improving stat accuracy
- polish the HUD/menu visuals more
- clean up any old JHUD/SSJ behavior that still feels off
- add more settings where they make sense
- test more edge cases like noclip, water, ladders, teleporting, and spectating
- add Strafe trainers
- add sync trainers
- add strafe width trainer
