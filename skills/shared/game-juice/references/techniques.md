# Juice techniques (engine-neutral)

Pseudocode and numbers you can translate into any language, engine, or framework. Prefer the project's native tools (animation system, particle system, tween library, audio API) when they exist; use these as the model for what to build and what values to start from.

## Contents
- Two clocks: game time vs. real time
- Hit-stop and slow-motion
- Trauma-based shake
- Squash and stretch with a spring
- Easing
- Tweening values and count-ups
- Lagging health bar
- Particles
- Floating text
- Flashes
- Pitch ladders for streaks
- Cheat sheet: numbers
- Procedural sound recipes
- Platforms without much visual freedom
- Common mistakes

---

## Two clocks: game time vs. real time

Keep two deltas every frame:

```
real_dt = clamp(frame_delta, 0, 1/30)     # clamp so lag spikes and resumes don't explode effects
game_dt = real_dt * time_scale            # time_scale is 0 during hit-stop, <1 in slow-mo, else 1
```

- Use `game_dt` for: movement, physics, AI, timers that are gameplay, and world-attached particles.
- Use `real_dt` for: camera shake decay, flashes, UI animation, tweens on menus, and the hit-stop/slow-mo timers themselves.

If everything runs on `game_dt`, shake and UI freeze during hit-stop and the effect feels broken instead of punchy.

## Hit-stop and slow-motion

```
hitstop(ms):    stop_timer = max(stop_timer, min(ms, 100) / 1000)
slowmo(s, sec): slow_scale = s; slow_timer = sec

each frame:
    if stop_timer > 0:   stop_timer -= real_dt; time_scale = 0
    elif slow_timer > 0: slow_timer -= real_dt; time_scale = slow_scale
    else:                time_scale = 1
```

Keep reading input during a freeze, and queue it so presses aren't lost. Hit-stop on enemy hits is cheap and a large share of what makes combat feel heavy. Use slow-mo only for milestones.

## Trauma-based shake

Trauma is a 0..1 value that stacks and decays; displacement scales with trauma squared so small hits are subtle and big ones violent.

```
shake(amount):  trauma = min(1, trauma + amount * intensity)

each frame:
    trauma = max(0, trauma - 1.6 * real_dt)
    m = trauma * trauma
    offset_x = random(-1, 1) * MAX_OFFSET * m
    offset_y = random(-1, 1) * MAX_OFFSET * m
    rotation = random(-1, 1) * MAX_ROTATION * m
    apply offset/rotation to the camera or world root (not the HUD)
```

`MAX_OFFSET` about 1-2% of the screen's smaller dimension; `MAX_ROTATION` about 1-2 degrees (0 for games where rotation is jarring). For smoother shake, sample smooth noise instead of pure random.

## Squash and stretch with a spring

Briefly distort a sprite or model, then let a damped spring settle it back to 1.0 with a little overshoot.

```
punch(obj, amount):     # amount > 0 squash (wider, shorter); < 0 stretch (taller, thinner)
    obj.sx = 1 + amount; obj.sy = 1 - amount
    obj.vx = obj.vy = 0

each frame (real_dt):
    for axis in [x, y]:
        v[axis] += (1 - s[axis]) * STIFFNESS * dt     # STIFFNESS ~ 280
        v[axis] *= exp(-DAMPING * dt)                  # DAMPING ~ 11
        s[axis] += v[axis] * dt
    stop when |1 - s| < 0.002 and |v| < 0.01
```

Preserve volume: when one axis grows the other shrinks. Typical amounts 0.15-0.35. Use stretch on takeoff and fast moves, squash on landing and impact.

## Easing

Common curves for `t` in 0..1:

```
out_quad(t)    = 1 - (1 - t)^2
out_cubic(t)   = 1 - (1 - t)^3
in_out_quad(t) = t < 0.5 ? 2t^2 : 1 - (-2t + 2)^2 / 2
out_back(t)    = 1 + c3*(t-1)^3 + c1*(t-1)^2      where c1 = 1.70158, c3 = c1 + 1   # overshoots then settles
out_elastic(t) = t in {0,1} ? t : 2^(-10t) * sin((10t - 0.75) * 2pi/3) + 1
```

Use **ease-out** for things appearing or reacting (instant response, then settle), **ease-in** only for things leaving or accelerating, and **out_back** for pops and UI entrances. Linear motion looks robotic. Exits should be faster than entrances.

## Tweening values and count-ups

```
tween(from, to, duration, easing, on_update, on_done)
    each frame: t += real_dt; on_update(from + (to - from) * easing(clamp(t/duration, 0, 1)))

count_up(target):  tween(displayed_score, target, 0.4, out_cubic, v -> displayed_score = v)
```

Keep the real score (gameplay) separate from the displayed score (visual). Display whole numbers. Give the HUD element a small scale pulse whenever the target changes.

## Lagging health bar

Show damage as a trailing segment: the real value drops instantly, a second "ghost" bar waits ~0.4s and then drains to match.

```
on damage:   health = new_value; ghost_delay = 0.4
each frame:  if ghost_delay > 0: ghost_delay -= real_dt
             else: ghost = max(health, ghost - DRAIN_RATE * real_dt)
```

Pulse the bar and briefly flash it on damage. Reverse the idea for healing (ghost fills first, solid follows).

## Particles

A particle is: position, velocity, life, max_life, size, color, gravity, drag.

```
burst(pos, count, speed, life, size, colors, gravity, angle, spread):
    for i in 1..count * intensity:
        a = angle + random(-0.5, 0.5) * spread
        speed_i = speed * random(0.4, 1.0)
        spawn(pos, vel = (cos a, sin a) * speed_i, life = life * random(0.7, 1.2),
              size = size * random(0.6, 1.2), color = pick(colors))

each frame (game_dt):
    life -= dt; vel.y += gravity * dt; vel *= exp(-drag * dt); pos += vel * dt
    draw with alpha = life/max_life, size shrinking to ~40% by end of life
```

- Hard cap total particles (a few hundred) and recycle the oldest.
- Simple shapes (squares, circles, short lines) read well; you rarely need textures.
- **Shockwave ring:** an expanding circle outline whose radius goes 0 to R over ~0.35s while its alpha and line width fade.
- **Dust:** gray-brown circles, small, short life, slight gravity, spawned at the feet on landing or turning.
- **Confetti:** many small rectangles with random colors, gravity, and a slow rotation.
- **Trails:** emit one faint particle per frame behind fast objects.

## Floating text

Spawn at the event position; drift upward (~40-60 px/s, slowing), live 0.6-1.0s, fade out over the last half, and pop in with `out_back` scale over the first ~0.15s. Draw with an outline or shadow so it's legible on any background. Scale size with the value or combo (bigger number, bigger text). Color-code: gold for score, red for damage, green for healing.

## Flashes

- **Object hit flash:** draw the sprite fully white (or tinted) for 1-2 frames (~50ms). Strong, cheap, and readable.
- **Screen flash:** a full-screen color overlay at 20-40% alpha fading over 80-150ms. Reserve for major and milestone events and respect the flashing limit in the guardrails.
- **Damage vignette:** red edges fading over ~0.3s instead of a full-screen flash, which is less obscuring.

## Pitch ladders for streaks

Use a pentatonic scale so rising pitch always sounds pleasant, and cap at about two octaves.

```
PENTATONIC_SEMITONES = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
pitch_multiplier(n)  = 2^(PENTATONIC_SEMITONES[min(n, 10)] / 12)
play(sound, pitch = pitch_multiplier(combo) * random(0.97, 1.03))
```

Reset `n` to 0 on a miss or after a pause in the streak (~1-2s).

---

## Cheat sheet: numbers

| Effect | Starting value |
|---|---|
| Hit-stop | 30-50ms minor hit, 60-90ms big hit, never above ~100ms |
| Shake trauma | 0.15-0.25 light, 0.3-0.5 heavy, 0.6-0.8 milestone |
| Shake decay | About 1.5 trauma per second |
| Squash/stretch | 0.15-0.35 scale change, settle in ~0.25s with slight overshoot |
| UI press | Scale to 0.92-0.95 in ~60ms, overshoot back to 1.0 over ~150ms |
| Score count-up | 0.3-0.5s, ease-out |
| Floating text | 0.6-1.0s life, drift up 40-60 px, pop-in ~0.15s |
| Particle life | 0.25-0.6s; 6-20 particles for minor events, 20-50 for milestones |
| Screen flash | 0.08-0.15s at alpha 0.2-0.4; skip for frequent events |
| Slow-mo | Time scale 0.2-0.4 for 0.4-0.8s, milestones only |
| Entrances / exits | 0.2-0.35s entering, faster leaving |
| Same-sound rate limit | At least 40ms between identical sounds |
| Pitch variation | +/- 3-5% random per play |

Scale pixel values with the game's resolution; the numbers above assume roughly an 800px-tall playfield.

---

## Procedural sound recipes

For projects with no audio assets, synthesize these with whatever the platform offers (oscillators plus a volume envelope, and filtered noise). An envelope is a very fast attack (~5ms) and an exponential decay to silence.

| Feel | Recipe |
|---|---|
| Soft pickup | Sine or triangle, 700-1200Hz, 80-120ms |
| Retro pickup | Two square-wave notes a fifth apart, ~60ms each |
| Jump | Square wave sliding up from ~260Hz to ~640Hz over ~150ms |
| Land / thud | Short low-passed noise burst (~400Hz cutoff) plus a ~110Hz sine, ~90ms |
| Hit | Low-passed noise burst (~1800Hz) plus a sawtooth sliding down 220 to 70Hz, ~120ms |
| Shoot | Square wave sliding down 900 to 180Hz over ~100ms |
| Explosion | 0.4-0.5s low-passed noise (~700Hz cutoff) plus a sine sliding 90 to 30Hz |
| UI click | ~660Hz square, 40-50ms, quiet |
| Powerup / success | Rising major arpeggio, triangle wave, ~80-90ms per note |
| Failure | Falling notes, sawtooth, longer notes, slightly quieter |
| Denied | Single low sawtooth buzz around 150Hz, ~150ms |

Mix: keep master volume around 0.4-0.5 and individual voices under ~0.2. Shorten sounds that fire often. Rising pitch signals a streak; falling pitch signals a break.

If audio is impossible (text-only or silent environments), compensate with stronger visual and motion feedback, or with text cues for key events.

---

## Platforms without much visual freedom

The principles still apply when you can't shake a camera or spawn particles:

- **Text / terminal games:** color changes, brief inverse-video or bold flashes, staggered character-by-character reveals, short delays that build tension before a result, ASCII bursts (`* + .` fading out), and a bell or beep for key events.
- **Board/card games with static layouts:** animate pieces sliding with ease-out, pop on placement, highlight and pulse on capture or match, count up scores.
- **Tabletop or rules-only designs:** juice becomes ceremony: dramatic reveals, satisfying components, clear celebratory moments written into the rules.

---

## Common mistakes

- **Everything shakes.** Shake is a punctuation mark; reserve it for impacts.
- **Juice drives logic.** If an effect callback decides game state, hit-stop or a dropped frame will desync the game.
- **Unclamped delta.** Returning to a paused or backgrounded game produces a giant delta and a particle explosion. Clamp it.
- **Audio never plays.** Many platforms require a user interaction before sound can start. Initialize or resume audio on first input.
- **Effects on the wrong clock.** Shake, flash, and UI animation need real time; the simulated world uses game time.
- **Obscured gameplay.** If it feels like a firework show, halve the particle counts.
- **Same effect for different events.** A coin and an enemy kill should look and sound different because they mean different things.
- **No variation.** Identical repeats read as mechanical; randomize pitch, angle, and size a little.
