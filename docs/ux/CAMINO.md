# Camino scene language

This is the product’s face. A designer paints it. These rules are not optional.

You are always on the road **at night, walking toward morning**. Home is **daylight that holds**.

There is no avatar to steer. The scene is a place that is already true.

---

## Three signals, never one score

| Signal | Input | Visual | When it changes |
| --- | --- | --- | --- |
| **Distance** | Current protocol weekly planned mg ÷ trailhead weekly planned mg, toward 0 | How close / large the **house** is | Only when he **saves a new protocol** |
| **Brightness** | Actual mg in the last 7 days (every swallow: scheduled + rescue) | The **sky** — night thins → dawn → day | When the last-7-days actual changes |
| **Weather** | Rescue mg (and count) in the last 7 days | **Cloud, wind, rain** over the same road | When rescue in the window changes |

**Forbidden:** one ring, one percentage, one “Camino score,” a step counter, a health-green/red path, the house sliding backward because he rescued.

A hard week **weathers**. It does not rewind him to the trailhead.

A week he took less than the promise **brightens** even if he has not cut yet.

A cut **shortens the path** even if the sky is still heavy.

---

## Mapping (so two designers don’t invent two physics)

Let `T` = trailhead weekly planned mg (first protocol).  
Let `P` = current protocol weekly planned mg.  
Let `A` = sum of actual mg in the last 7 local calendar days.  
Let `R` = sum of rescue mg in that same window.  
Let `Rc` = count of rescue events in that window.

**Distance** `d` in `[0, 1]`, 1 = home:

- If `T == 0`, `d = 1` (should not happen).
- Else `d = clamp(1 - P/T, 0, 1)`.
- Adding load (`P > T`) stays at `d = 0` (still at the trailhead, house far). Do not put the house behind the camera.

**Brightness** `b` in `[0, 1]`, 1 = held daylight:

- `b = clamp(1 - A/T, 0, 1)` using the same `T` so sky and road share a scale.
- If he is swallowing more than the trailhead, `b = 0` (deepest night). Not a special “punishment” state.

**Weather** `w` in `[0, 1]`:

- `w = clamp(R / max(T * 0.25, 0.125), 0, 1)` — a quarter-trailhead-week of rescue fills the sky; a single 0.125 still registers.
- Also let `Rc` thicken the same weather (more events = more broken cloud) without a second metaphor.

At **arrival**, stop mapping. Daylight holds. Weather is gone. The house is here.

---

## What must be readable in one glance

Without reading a chart, he should be able to answer:

1. Is the house nearer than last week? → he has cut, or not.
2. Is the night thinner? → he has been swallowing less.
3. Is there weather? → there have been rescues.
4. Is there a step at his feet? → tonight is a dose night, and whether it is open.

If the painting is beautiful but those four are ambiguous, the design fails.

**Do not encode 2 or 3 in color alone.** Brightness is *how much night vs morning*. Weather is *atmosphere in front of that sky* (cloud, rain, wind in the grass). A color-blind, Reduce Motion, or bright-room glance must still parse them.

---

## The step on the path

Today’s scheduled events sit **on the path**, not in a floating app bar.

| Day | What is on the path |
| --- | --- |
| Dose day, open | One step per slot: time · amount, clearly tappable |
| Dose day, taken / less / skipped | Same step, settled, still tappable to edit today |
| Two slots | Two steps, both readable, neither a list from another app |
| Off day | Path without a step. Not a greyed card that says “Rest day!” |
| Unresolved past | A second, quieter mark — behind him on the path, or a single “open from earlier” cue that opens those steps. Must be findable. |

The step is part of the world (a stone, a mark on dirt, a small lantern). It is not a Material/iOS list row pasted on a wallpaper.

---

## Chrome in the place

These must exist and must not become a HUD:

- **Rescue** — always reachable, never the largest control, never red-alert.
- **Protocol** — a way into the promise.
- **Look back** — a way into memory.

Safe area respected. Home indicator clear. No control under the Dynamic Island.

When a sheet is up, the scene remains behind system material. Confirm should feel like it **rose out of the step** (matched geometry). Rescue may rise from its own control.

---

## Motion

- Idle: the place breathes. Sky and weather are slow. Battery-quiet. No walk cycle.
- Confirm: the step settles; brightness may ease if the 7-day window changed.
- Save protocol: the house eases closer or farther. One motion. Not a celebration.
- Rescue: weather may gather. No shake, no flash.
- Arrival: night gives way to held day. Once.
- **Reduce Motion:** no parallax, no weather swirl, no house travel — crossfade states.

Haptics: light on confirm and on arrival. **None on rescue.**

---

## What the painting is not

- A fitness route with km and pace
- A fantasy RPG path with XP
- A meditation sunrise video behind glass cards
- A cartoon mascot walking home
- A calendar strip with seven circle-pills

It can be spare, almost still, almost photographic, almost ink — that is the designer’s world. The physics above stay.

---

## Arrival scene

Same world, end of the road. House at full presence. Daylight that does not keep brightening. No step. No rescue control. No protocol control. A way to Look back. The offer “I’m home” happens on the walking Camino when conditions are met, then this place replaces it.
