# Building gui.lua

`gui.lua` is the whole hub GUI — every instance under `StarterGui.ScreenGui`, all 9 LocalScripts and
5 ModuleScripts (LuaHighlighter included) — in one file that runs with a single `loadstring`.
It's generated from the place; edit the place, then rebuild. Don't edit `gui.lua` by hand.

## Rebuild

1. Start the local bridge from the project folder (Studio's HttpService can reach 127.0.0.1):

   ```
   python build/devserver.py
   ```

2. In Studio (Edit mode, `HttpService.HttpEnabled` on), run in the command bar:

   ```lua
   local H = game:GetService("HttpService")
   print(loadstring(H:GetAsync("http://127.0.0.1:8768/build/bundle.luau"))()())
   ```

   It writes `gui.lua` (project root) and `build/assets.txt`, and prints the size and counts. It refuses to
   write a bundle that doesn't compile. Anything it can't encode is listed under "unsupported value types"
   and "unrecreated refs" (both should read `none`).

## Run it

In an executor, either paste the file or host it and run:

```lua
loadstring(game:HttpGet("<raw url of gui.lua>"))()
```

Running it again replaces the running copy instead of stacking a second one.

## What the bundle does

- Waits for `game.Loaded` and `Players.LocalPlayer` first.
- Rebuilds the tree from a table: class, name, every serialized property that differs from a fresh
  instance, attributes, tags. Classes that can't be created (e.g. `UIShadow` on an old client) are skipped
  with a warning rather than stopping the build.
- Each script is a function taking `script` (its rebuilt instance) and a bundle `require` that runs GUI
  modules once and caches them; anything else falls through to the real `require`.
- Modules load first, then the LocalScripts, Splash first, each in its own `task.spawn` + `xpcall`, so one
  failing script is reported (`[gui] ...` in the console) without stopping the others.
- Parents to `gethui()`, else CoreGui, else PlayerGui; sets `ResetOnSpawn = false`, `DisplayOrder = 100`.
- Keeps one copy: the ScreenGui is stored in `getgenv()` (or `shared`); a re-run destroys it first, and
  every script disconnects its service-level connections on `Gui.Destroying`.
- Server-side pieces are not part of the GUI and aren't bundled: `ScriptBloxProxy`, its RemoteFunction.
  ScriptBlox only looks the remote up with `FindFirstChild` as a last Studio-only fallback.

## Testing in Studio

Studio clients can't `loadstring` and cap `Script.Source` at 200,000 characters, so
`build/studio_harness.luau` cuts `gui.lua` along its own seams (runtime, script functions, tree split at
the root's children) into ModuleScripts without changing any code, and adds a runner that executes it twice:

```lua
-- move StarterGui.ScreenGui to ServerStorage first so only the bundle's copy shows up
local H = game:GetService("HttpService")
local rig = loadstring(H:GetAsync("http://127.0.0.1:8768/build/studio_harness.luau"))()
print(rig.install())   -- then Play; afterwards: rig.uninstall() and move the ScreenGui back
```

`build/fingerprint.luau` hashes what's on screen per page, for comparing the place's GUI with the bundle.
`build/storage_tests.luau` is the Storage suite (`loadstring(...)()(game.StarterGui.ScreenGui.Storage)`).

## Assets

`build/assets.txt` lists every `rbxassetid://` / `rbxasset://` the GUI uses (33): 28 images, 2 font
assets (`11702779409` output gutter, `12187365364` tooltips) and 3 built-in font families.
