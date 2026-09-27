# `_spawn_v6` — what it actually does

`_spawn_v6` is the server's **loyalty/loot plugin**: every time a player respawns, it decides
what armor and what bonus items they get. It is not random-for-everyone — it is a priority
list of named *roles*, checked top to bottom, and the first role that matches the player
decides everything else.

This file explains the live plugin. `_spawn_v6_sanitized.asm` is the same code with every real
player nickname replaced by an obvious placeholder (`ExamplePatron1`, etc.) — same dispatch
order, same odds, same bugs. Nothing here changes behavior; it only explains it.

## 1. The shape: one dispatch, 14 roles, one fallback

Every 500ms, for every connected player who just respawned (tracked via a per-slot
`was_alive` flag so each life only triggers this once), the plugin checks the player's name
against 14 named lists **in a fixed order**. First match wins — nothing after it is checked.

```
premium_tg → patrony → server-bot-account → admin → tester → special-guest → cheater →
spec_bf → wola → solo_light → pro_tg → pro → pro_regular → regular_tg → energy(vodka) →
duo → regular → (no match) default
```

If nobody matches, `default` applies: 55% LIGHT / 30% MID / 9% flicker-military / 6% flicker-exo,
no bonus items — this is what an unrecognized new player gets.

## 2. The armor pools

Every "give X% chance of tier Y" instruction below draws from one of four fixed pools:

| Pool | Suits | Note |
|---|---|---|
| **LIGHT** (7) | novice, bandit, stalker, dolg, cs_light, svoboda_light, scientific | scientific has NVG |
| **MID** (3) | cs_heavy, specops, svoboda_heavy | |
| **FLICKER** (2) | mp_military_stalker (NVG), mp_exo (no sprint, 35 armor) | a real tradeoff, not strictly "better" than MID |
| **HEAVY** (4) | dolg_heavy (NVG), military/Bulat, svoboda_exo, exo | all ~60-65 armor; svoboda_exo/exo are singleplayer suits that "may fail silently in MP" per the original author's own note — never independently confirmed |

## 3. The 14 roles, what each one gets

| Role | Armor odds | Bonus items | Read as |
|---|---|---|---|
| **premium_tg** | 100% HEAVY | medkit_sci + (kolbasa or conserva, coin flip) | top tier — guaranteed best armor |
| **patrony** | 35% LIGHT / 25% MID / 28% FLICKER / **12% HEAVY** | medkit_sci | donors — better odds than default, but HEAVY is still rare |
| **server-bot-account** | fixed: bandit | 14× vodka | the account used for server-side/laptop testing, not a player |
| **admin** | fixed: bandit, nothing else | none | the operator's own account — deliberately gets the *least*, not the most |
| **tester** | n/a (no armor call) | 14× vodka | test accounts; vodka here reads as a joke/marker item, not gear |
| **special_guest** | fixed: quest outfit + quest AK | + kolbasa | one-off honored guest; both items marked unconfirmed in MP by the original author |
| **cheater** | 100% LIGHT | none | named troublemakers — worst tier, no bonuses, as a soft penalty |
| **spec_bf** | 10% exo / 45% Bulat / 45% mil-flicker | medkit_sci + (kolbasa or conserva) | a themed "battlefield" role — no LIGHT/MID at all, only the two heavier options |
| **wola** | faction-name check first, else 35/25/20/20 (LIGHT/MID/FLICKER/HEAVY) | medkit_army + bread | if their name says their faction, they get that faction's suit outright |
| **solo_light** | fixed: cs_light only | none | was a single named player in the live plugin, kept here as its own role |
| **pro_tg** | 74% LIGHT / 20% mil-flicker / 6% exo-flicker | + (kolbasa or conserva) | "pro" community members with TG bonus |
| **pro** | same 74/20/6 | none | same skill-tier odds, no snack bonus |
| **pro_regular** | same 74/20/6 | medkit_army + bread | |
| **regular_tg** | faction check first, else 35/25/**20**/20 | medkit_sci + bread + kolbasa (**all three, no coin flip**) | see §4 — this is richer than patrony |
| **energy (vodka_list)** | 35/25/20/20 | 10× energy_drink | |
| **duo** | faction check first, else 35/25/28/**12** | medkit_army + bread | was two friends' nicknames in the live plugin, same odds shape as patrony but the *regular*-tier bonus items, not patrony's medkit_sci |
| **regular** | faction check first, else 35/25/20/20 | medkit_army + bread | the "everyone else who's actually on a list" tier |
| *(no match)* **default** | 55/30/9/6 (LIGHT/MID/mil/exo) | none | anonymous/new players |

"Faction check first" means: before rolling a random tier, the plugin scans the player's name
for a bracketed tag (`[dolg]`, `[svoboda]`, `[merc]`, `[bandit]`, `[stalker]`) or the bare
Russian/Ukrainian word for that faction (in Win-1251 bytes, so it matches Cyrillic text too).
If found, they get that faction's themed suit directly — Duty gets `dolg_outfit`, Freedom gets
`svoboda_light_outfit`, Ecologists get `scientific_outfit`, Mercenaries get `cs_heavy_outfit`,
Bandits get `bandit_outfit`, Stalkers get `stalker_outfit` — and the random roll never runs.

## 4. Open question — patrony vs. regular_tg (documented, not resolved)

**`patrony`** (the paying-donor role, per the original list's own naming) gets a **12%** chance
at HEAVY armor and a coin-flip between kolbasa/conserva.

**`regular_tg`** (just being active in the Telegram community, no payment implied) gets a
**20%** chance at HEAVY *and* all three bonus items guaranteed (medkit_sci + bread + kolbasa,
no coin flip) — strictly more generous on both axes.

Two readings, both plausible:
- **Intentional**: patrony's real value is the *guaranteed* medkit_sci and the status of being
  on that list at all, not raw armor odds — donors aren't meant to out-gear everyone.
- **Drift**: regular_tg's table may have been copied from `wola`/`regular`'s 20%-HEAVY template
  and never tuned down to match patrony's more restrained one, while its bonus items grew
  richer over time by separate edits.

Not fixed here — flagged for you to test and decide, per your own call.

## 5. Known limits, carried over from the live plugin as-is

These are real properties of the code, kept unchanged in the sanitized version on your
explicit instruction (fix nothing, just document).

- **`was_alive` is sized for 50 slots, but the scan loop has no upper bound.** The other two
  example plugins in this repo (`welcome`, `teleport`) cap their loop at `MAX_SLOTS = 64`.
  `_spawn_v6` instead relies entirely on `GetClientByNum` returning null to know when to stop.
  If the server ever holds more than 50 simultaneously-tracked slots, `mov byte[was_alive+esi],1`
  writes past the array into the next declared variables (`tick_count`, `pSuit`). Not exploitable
  today — the documented May 2026 prod launch used `maxplayers=33` — but the array size isn't
  tied to whatever `maxplayers` is configured to, so raising the player cap is the thing to
  double check before it becomes a real problem.
- **A related quirk in the same loop**: hitting a client whose `CLIENTCLASS.ADDR` is still null
  (e.g. a player mid-connect) jumps straight to `.done` and **stops the whole scan for that
  tick** — every slot after it is skipped for those 500ms, not just this one player. `welcome`
  and `teleport` both treat a not-yet-ready slot as "skip and keep scanning." Whether this
  matters depends on whether client slots are always packed with no gaps once occupied — not
  verified either way here, just noted.
- **`item_vodka` is `'vodka'`**, but the header comment for `tester_list` describes the bonus as
  "14x vodka_fsk" — the actual section name used in the code and the name in the comment
  disagree. Carried over as-is; whichever is right, both can't be.
- **`item_medkit_sci` is spelled `'medkit_scientic'`**, marked "typo intentional" in the original.
  Left exactly as-is — if the real in-game section name for that item is actually spelled
  correctly, this bonus silently fails to spawn anything.
- **`item_quest_outfit` / `item_quest_ak`** (the `special_guest` role) are marked
  "[UNCONFIRMED items] — may silently fail" by the original author. Never independently tested.

## 6. What changed in the sanitized version, and what didn't

Changed: every real nickname → a generic `ExampleX` placeholder (kept 1-2 per group instead of
the live list's full rosters, which run up to ~50 names in the largest group); two group labels
that were themselves a nickname (`hodaki_list`, `biba_boba_list`) renamed to `solo_light_list` /
`duo_list`; two illustrative entries kept Win-1251-hex-encoded with generic Cyrillic placeholder
words, to preserve the encoding technique without any real identity attached.

Not changed, on your instruction: the `was_alive[50]`/no-cap behavior, the `.addr_null` early
stop, the patrony/regular_tg odds asymmetry, all the "[UNCONFIRMED]" items, and every roll table
and bonus-item rule. Compiled and verified as a valid PE32 DLL (`fasm`, native Linux build,
`5 passes, 8192 bytes`) before publishing.

## 7. A second file exists — `xrproc_extended.inc` — and it is NOT what's used here

`xrproc_extended.inc` (elsewhere in the source tree, not shipped in this repo) adds nine extra
AC-exported functions (`PlayerTeleport`, `KickClientIDMsg`, `ChatSend`, etc.) to the API table,
but its `CLIENTCLASS` struct has a different field set and order than the `xrproc.inc` used
here — meaning the two files disagree on the memory offset of every struct field. Only one of
them can match the live `xrCPU_Pipe.dll` layout.

Two things point at `xrproc.inc` (this repo's version) being the one actually in use:
`_struct_dump.asm` — a plugin whose only job is empirically logging every `CLIENTCLASS` field
at runtime — references exactly this file's field set, not the extended one's. And the one
live plugin that genuinely needs an AC function outside the shared table
(`_spawn_dynamic_alco_v1.asm`, calling `PlayerTeleport`) doesn't switch to the extended header
at all — it loads that one function itself, separately, via its own `GetProcAddress` call,
with an explicit "NOT FOUND, skipped" fallback if it's missing. That's the established pattern
in this codebase for a function the shared table doesn't have: add it locally to the one
plugin that needs it, not replace the shared struct definition everyone else already depends
on.
