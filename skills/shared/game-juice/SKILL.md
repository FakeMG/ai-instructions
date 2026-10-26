---
name: game-juice
description: Add "game juice" (feedback and game feel) to any game or game-like interactive builds, edits, or debugs, proactively and WITHOUT being asked. Covers screen/camera shake, hit-stop, particles, squash-and-stretch, easing, floating score text, flashes, sound effects, combo escalation, and UI feedback. Make sure to use this skill whenever the user asks for a game, arcade clone, prototype, jam entry, puzzle, platformer, shooter, clicker/idle game, card or board game, quiz with scoring, or any interactive toy with player actions and outcomes, in any language or engine, even if the request only describes rules, mechanics, or levels and never mentions polish, feel, or juice. Also use it when a user says a game feels flat, dead, stiff, lifeless, unresponsive, or "needs more oomph", and when adding a new mechanic, enemy, pickup, or scoring system to an existing game.
---

# Game Juice

Juice is the layer of small, redundant feedback that tells the player "that mattered." A hit that only subtracts a number from a health bar feels like a spreadsheet; the same hit with a flash, a spray of sparks, a half-beat freeze, a kick of camera shake, and a crunchy sound feels like a game.

This skill is about *what* feedback to add, *where*, and *how much*. It is independent of language, engine, and platform: translate every idea into whatever the project already uses (its animation system, particle system, audio API, tween library, or plain code). `references/techniques.md` has engine-neutral pseudocode and numbers to start from.

## Why this skill is on by default

Users almost never ask for juice. They describe mechanics ("snake, but the food teleports") and assume the result will feel like a real game. A game with no feedback reads as broken or unfinished, because the player can't tell whether their input registered. So treat juice the way you treat collision detection: part of "working," not a bonus feature. Don't ask permission, and don't build a bare version first with an offer to "add polish later."

The one exception: if the user says they want it plain, minimal, or free of effects, respect that. Keep the hooks but set the intensity to zero rather than ripping them out.

## Workflow

1. **List the moments.** While planning the game, write down every player action and every state change: moving, jumping, landing, shooting, hitting, taking damage, collecting, scoring, combos, level-up, game over, restart, button presses, menu transitions. Each is a place where the player is waiting for an answer.
2. **Assign feedback by importance.** Use the tier table below so small things get small feedback and big things get big feedback. If everything is loud, nothing is.
3. **Layer channels.** A moment that should feel good hits at least three channels at once (see "Channels").
4. **Route it through one feedback layer.** Create a single place (a module, class, or set of functions) that owns effects like shake, hit-stop, particles, text pops, flashes, and sounds. Game events call it (`onEnemyHit`, `onPickup`); gameplay code never contains bespoke effect timers. This keeps effects consistent, tunable, and removable.
5. **Wire it into the loop correctly.** Effects that should freeze on impact (the world, particles) run on game time. Effects that must stay smooth through a freeze (camera shake, flashes, UI animation) run on real time. Draw order: world, then effects, then HUD (steady, not shaken), then full-screen overlays last.
6. **Expose one intensity dial** (a constant or setting at the top of the feedback layer) plus a mute control. Run the checklist at the bottom, then tell the user in one or two sentences what feedback you added and where the dial is. No long essay about it.

## Channels

| Channel | What it does | Examples |
|---|---|---|
| Visual pop | Marks the exact spot of the event | Particle burst, flash on the object, floating "+10", expanding ring |
| Motion | Gives objects weight and life | Squash and stretch, scale punch, overshoot easing, recoil, idle bob |
| Camera | Makes the world react | Trauma-based shake, brief zoom punch, screen flash |
| Time | Makes impact readable | Hit-stop (freeze 40-90ms), slow-motion on big moments |
| Audio | Fastest, cheapest feedback there is | Short blips, pitch rising with combo, dull thud vs. bright ping |
| UI | Connects action to the numbers | Score count-up, HUD pulse on change, health bar with a lagging trail |

Audio is the highest value per line of effort, and people skip it. If the project has no sound assets, generate simple sounds procedurally (see the sound recipes in the reference) so the game doesn't ship silent.

## Proportionality tiers

| Tier | Frequency | Examples | Feedback budget |
|---|---|---|---|
| Constant | Every frame or step | Walking, steering, idle | Subtle: tiny dust puffs, gentle bob, soft tick. No shake, no hit-stop. |
| Minor | Several per second | Coin pickup, shot fired, button hover | 1-2 channels: small burst + blip, small scale pop. |
| Major | Every few seconds | Enemy hit, taking damage, hard landing, line clear | 3+ channels: burst, shake 0.2-0.4, 40-70ms hit-stop, hit sound, squash. |
| Milestone | Rare | Level complete, boss kill, new high score, game over | All channels: big burst, shake 0.6-0.8, flash, slow-mo, jingle, text that animates in. |

The test: if the player does this 200 times in a session, will the feedback still be pleasant? If it would get annoying, drop a tier.

## Escalation and variation

Repetition without change turns feedback into noise. Two cheap fixes:

- **Escalate with streaks.** Raise pitch step by step with each consecutive success (a pentatonic ladder always sounds pleasant), grow particle count or text size with the combo, and reset on a miss. The player feels momentum building.
- **Randomize slightly.** Vary pitch by a few percent, particle angles, sizes, and shake direction. Identical repeats sound and look mechanical.

## Fit the game's personality

Juice expresses tone; it isn't a fixed effect pack. A cozy puzzle game wants soft rounded pops, warm colors, gentle sine-like sounds, and little or no shake. An arcade shooter wants sharp sparks, heavy shake, and crunchy sounds. Pull effect colors from the game's own palette instead of default white, and match sound character to the art style (soft and smooth for gentle games, buzzy and harsh for retro or aggressive ones).

## Guardrails

Juice that hurts readability or control is worse than none.

- **Never obscure the play.** Keep particles small and short-lived near anything the player must read. Don't flash the whole screen white over a field full of hazards.
- **Shake the world, not the HUD.** Cap the maximum displacement (roughly 1-2% of screen size) so text and controls stay legible.
- **Hit-stop only on major and milestone events, never above ~100ms,** and never on something that fires continuously. It must not swallow input; keep reading input during the freeze.
- **Juice never changes gameplay.** Effects are cosmetic. Don't tie collision, scoring, spawning, or win/lose logic to effect callbacks or particle lifetimes. Hit-stop pauses simulation through the time delta you pass along, not by blocking the loop.
- **Frame-rate independence.** Everything runs off a clamped time delta, so a lag spike or a paused-then-resumed app doesn't launch particles across the screen or skip animations.
- **Cap and recycle particles.** Games must stay smooth on weak hardware, including phones.
- **Respect the player.** Honor the platform's reduced-motion or accessibility settings when they exist (disable shake, flashes, and hit-stop), and avoid rapid full-screen flashing (no more than ~3 flashes per second). Keep default volume modest and provide a mute control. Where the platform blocks audio until the user interacts, start or resume audio on the first input.
- **Rate-limit sounds.** Don't trigger the same sound more than once every ~40ms; stacked identical sounds just get loud and harsh.

## Moment playbook

Starting recipes. Tune numbers to the game's scale and personality.

| Moment | Recipe |
|---|---|
| Pickup / coin | Small burst in the item's color, floating "+N", pitch-stepped blip, scale pop on the HUD score |
| Jump | Stretch on takeoff, dust puff at the feet, rising blip |
| Landing | Squash, dust burst sideways, soft thud; shake only if the fall was big |
| Shooting | Muzzle flash or spark, tiny recoil on the shooter, short pew with random pitch |
| Enemy hit | Flash the enemy white for 1-2 frames, sparks at the contact point, 50ms hit-stop, shake 0.25, thud |
| Enemy death | Larger burst plus shockwave ring, shake 0.4, descending noise pop, "+score" text |
| Player damage | Red flash, shake 0.5, 80ms hit-stop, invulnerability blink, low hit sound, HUD health pulse |
| Line clear / match | Staggered pops along the cleared cells, rising tones per cell, brief slow-mo for big clears |
| Button / UI click | Scale down then overshoot back, click tick; hover brightens |
| Score change | Count up toward the target over ~0.4s instead of snapping; pulse on change |
| New high score / level up | Confetti burst, flash, jingle arpeggio, text that pops in with overshoot easing |
| Game over | Slow-mo for ~0.6s, dim or desaturate, descending tone, then UI eases in |
| Start / restart | Quick fade or scale-in so the world appears rather than snaps |
| Wrong move / denied | Short low buzz, small shake or wobble on the offending element, no hit-stop |

## Worked example

Request: "make a snake game where the food teleports every 5 seconds."

Moments: eat food, food teleports, turn, grow, self-collision death, wall death, new high score, restart.

- **Eat food (minor):** burst of food-colored particles at the head, "+10" floating text, pitch-stepped blip that climbs on quick consecutive eats, head squash, small HUD score pulse.
- **Food teleports (minor):** old spot puffs out and the new spot scales in with overshoot, soft whoosh. The player needs to *see* the jump, which is a readability win as well.
- **Turn (constant):** barely-there tick, a one-frame lean on the head. No shake.
- **Death (milestone):** shake 0.7, red flash, body explodes segment by segment with staggered bursts, 0.5s slow-mo, descending tone, game-over panel eases in.
- **New high score:** confetti burst plus jingle.

Then one line to the user: "I added juice (particles, shake, sounds, combo pitch on pickups). There's an intensity setting at the top of the effects code, and M mutes."

## Checklist before delivering

- [ ] Every player action has some immediate response, even if tiny.
- [ ] Every major event hits at least three channels.
- [ ] Rare events are bigger than frequent ones.
- [ ] Effects live in one feedback layer, not scattered through gameplay code.
- [ ] Simulation uses the time-scaled delta; shake, flash, and UI animation use real time.
- [ ] HUD stays steady and legible during shake; full-screen overlays are drawn last.
- [ ] Sound works (including after any required first interaction) and there is a mute control.
- [ ] Reduced-motion is respected where the platform offers it; particles are capped; the time delta is clamped.
- [ ] The game is still fully readable and playable at full intensity.
- [ ] The reply briefly mentions the juice and names the intensity dial.

## Bundled resources

- `references/techniques.md`: engine-neutral pseudocode for the core techniques (time control, trauma shake, spring squash, easing, particles, count-up, lagging health bars), a numbers cheat sheet, procedural sound recipes, and common mistakes. Read it when implementing, or when you need starting values.
