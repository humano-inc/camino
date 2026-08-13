# Validate a design against this packet

Use this before any code. A board that looks beautiful and fails a P0 does not pass.

How to use with a designer agent: ask it to present frames for every screen in `SCREENS.md` and every state marked below. Score this list. Anything P0 open means revise, don’t implement.

---

## P0 — product truth

- [ ] One root: **Camino**. No tab bar, no pill-card home.
- [ ] Tonight’s step is the primary action on a dose day.
- [ ] Rescue is always reachable and **never** the hero.
- [ ] Confirm is taken / skip / different amount. No mood, no note, no “why.”
- [ ] More than the slot is explained as **overflow → rescue**, not as failure.
- [ ] Less than the slot is not praised.
- [ ] Protocol save versions the promise. No “make this official?” after a skip.
- [ ] Dropping a weekday and shrinking a piece are equally obvious.
- [ ] Look back shows **planned, actual, rescue, versions, skips/less** — and answers “toward zero?”
- [ ] **Three signals remain three.** House ≠ sky ≠ weather. No single score/ring.
- [ ] House does **not** move backward because of rescue.
- [ ] Arrival requires empty protocol + 0 mg today; then the app is a finished place.
- [ ] Begin again is not on the arrival beat.
- [ ] No countdown, streaks, badges, journal, symptoms, backfill, or clinician share.
- [ ] English only. Copy meaning matches `COPY.md` (wording may tighten; meaning may not drift).
- [ ] First open is disclaimer → first promise → road. No tour.

## P0 — iPhone

- [ ] Safe area, Dynamic Island, home indicator respected.
- [ ] Sheets for confirm/rescue/protocol; push for look back. Edge-swipe back lives.
- [ ] Time, weekday, and alert controls are system (or indistinguishable from system).
- [ ] 44 pt targets. Dynamic Type planned (at least one XXXL frame).
- [ ] Reduce Motion specified (crossfade, no swirl/parallax).
- [ ] Weather and brightness are not color-only.
- [ ] VoiceOver names exist for step, rescue, rooms, and the three signals.

## P1 — the place

- [ ] Camino is a **place**, not wallpaper behind cards.
- [ ] The step belongs on the path.
- [ ] Off night has **no** fake rest-day card.
- [ ] Unresolved past steps are reachable from the road.
- [ ] Two slots in one day are two steps.
- [ ] Late same-day open is not styled as “missed.”
- [ ] Scene extremes in `STATES.md` V0–V4 are drawn and still readable.
- [ ] Confirm sheet feels like it comes out of the step; scene stays behind material.
- [ ] Arrival is the same world in held daylight — not a certificate screen.

## P1 — operate surfaces

- [ ] Piece picker is one control everywhere (`¼ ½ ¾ 1` + custom). No `0.0675` preset.
- [ ] Path/notification amounts are `time · mg`; picker shows pieces.
- [ ] Protocol weekly planned total is visible before save.
- [ ] Dirty protocol cannot vanish without discard confirmation.
- [ ] Laying the promise down (0 slots) has one clear confirm.
- [ ] Look back day-1 state is honest and small, not an empty mascot.
- [ ] Actual > planned in a week is visible without a shame banner.
- [ ] Export exists in Look back.

## P2 — craft (does not block a first design pass)

- [ ] One visual world, not “dark wellness” generic + a stock sunset.
- [ ] Motion is slow and cheap on the scene; system elsewhere.
- [ ] Light haptic on confirm and arrival only.
- [ ] Optional Live Activity is extra, not a substitute for the road.
- [ ] Icon proposed.

---

## Frames a designer must show

Minimum set to validate:

1. Disclaimer  
2. First protocol (empty + one slot)  
3. Camino dose night, open  
4. Camino off night  
5. Camino two slots  
6. Camino late open (same day)  
7. Camino + unresolved yesterday  
8. Confirm — default, less, overflow  
9. Rescue  
10. Protocol list + slot editor  
11. Look back with several weeks (planned vs actual vs rescue)  
12. Scene extremes: far+dark, near+dark, far+bright, weather  
13. Arrival offer  
14. Arrival (finished)  
15. One sheet at XXXL Dynamic Type  
16. Reduce Motion note or frame  

---

## How to reject quickly

| If you see… | It failed |
| --- | --- |
| Today’s pills + weekly rings | Category default |
| Red rescue / broken path | Shame |
| “Great job skipping” | Cheerleading |
| Tab bar: Home / Meds / Stats | Wrong topology |
| One “progress %” | Collapsed signals |
| Calendar of green days | Streaks in costume |
| Custom time wheel chrome | iOS slop |
| Journal on the confirm sheet | Scope break |

---

## Prompt to give a designer agent

> Read `PRODUCT.md`, `SPEC.md`, and everything in `docs/ux/`. Design native iOS frames for Camino. Follow `BRIEF.md` and `CAMINO.md`. Use `COPY.md`. Cover the frame list in `VALIDATE.md`. Do not write code. Do not change the object model. Present the frames for validation against `VALIDATE.md` P0 and P1.
