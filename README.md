# xray-plugin-101

A minimal, from-scratch guide to writing plugins for the **XRAY PROJECT** server
extension (S.T.A.L.K.E.R. Clear Sky multiplayer, `xrCPU_Pipe.dll`). Two small,
complete example plugins plus the three headers you need to build your own.

This is deliberately narrow: no game balance, no server config, no player data —
just "how does a plugin attach to the server and do something."

## What a plugin actually is

A plugin is a **PE32 x86 DLL**, written in x86 assembly and assembled with
[FASM](https://flatassembler.net/) (the Flat Assembler), then renamed with a
`.plugin` extension. The server loads every `.plugin` file it finds **directly
in its `bin/` folder** — not in a subfolder — at startup. There is no plugin
manifest and no load order guarantee beyond "whatever's in `bin/` gets loaded."

```
your_plugin.asm  --[fasm]-->  your_plugin.plugin  --[copy into server's bin/]-->  loaded
```

## Building

FASM is free but not included here (get it from flatassembler.net). On Linux/macOS,
run it through `wine`:

```bash
wine /path/to/FASM.EXE examples/welcome.asm  welcome.plugin
wine /path/to/FASM.EXE examples/teleport.asm teleport.plugin
```

On Windows, just run `FASM.EXE examples\welcome.asm welcome.plugin` directly — no
wine needed, and this is the friendlier way to iterate if you're building
interactively rather than scripting it.

Both examples `include` the three files under `include/` (`kglobals.inc` for the
`iglobal`/`uglobal` macros, `macro.inc` for generic FASM helpers, `xrproc.inc` for
the game's own API table and the `CLIENTCLASS` struct layout — this is the part
that actually lets a plugin call back into the server). Keep the relative path
(`examples/*.asm` next to `include/*.inc`) or fix the `include` lines at the top.

## The two examples

- **`examples/welcome.asm`** — the simplest possible plugin. A timer fires every
  5 seconds, tracks which of the 64 client slots hold a *new* connection, and
  sends that player a one-time welcome message 90 seconds after they join. Good
  first read: it shows the minimum shape (`DllEntryPoint`, registering a timer,
  per-slot state, sending a packet) with nothing else going on.

- **`examples/teleport.asm`** — one step up. Defines a 3D trigger zone, checks
  every connected player against it every tick, and teleports anyone inside it
  to a second point, with a per-slot cooldown so it doesn't fire every tick.
  Shows `CLIENTCLASS` field access, the SSE float math XRAY uses for positions,
  and a real "if X then do Y to this specific player" pattern.

## The one thing that will trip you up

**The server does not log plugin loads.** Its own log records game events
(spawns, teleports, kills, votes) but never "loaded foo.plugin" or "foo.plugin
failed to load." You cannot tell from the server log whether your plugin is
even running.

Both examples send their own debug lines through `xrCore.msg` (the game's
internal message function) tagged with a filter prefix — `[welcome]` /
`[tele]`. Watch for these with **[DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview)**
(Sysinternals, free) running alongside the server. If you don't see your
plugin's own startup line (`- [welcome] welcome_v1 loaded...`) in DebugView,
it didn't load — check that the `.plugin` file is actually sitting in `bin/`
and not one level down in a subfolder, which is the single most common mistake.

## License / provenance

`kglobals.inc`'s `iglobal`/`uglobal` macros are © KolibriOS team 2004–2007, GPL.
`xrproc.inc`'s API table and struct layout are community-reverse-engineered
knowledge of the XRAY PROJECT server extension, assembled from the public
Clear Sky multiplayer modding scene. No server configuration, no player data,
no credentials of any kind are in this repo — just the mechanics.
