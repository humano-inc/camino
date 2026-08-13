# Design brief

Visitor mode: **Experience** on Camino and Arrival. **Operate** on confirm, rescue, protocol, and look back.

HIG owns navigation, sheets, lists, pickers, targets, Dynamic Type. Brand owns the scene.

---

## 1. Job and audience

He opens the phone at night, often in the dark, to do one thing: **tell the truth about tonight**, and see that the road is still there.

He is not exploring a product. He is mid-taper, possibly shaky, possibly after a rescue. Cognitive load must be near zero on the home screen. The protocol editor can ask for more attention; he opens that only when he is ready to change the promise.

## 2. Outcome and proof

**Primary action tonight:** confirm the step, or log a rescue.

**Success of a design:**

- In one glance he knows: is tonight a dose night, is the step still open, is the week lighter, is the house nearer.
- Confirming taken / skip / a different amount is obvious and unmoralized.
- Rescue is always possible and never the hero.
- Cutting a weekday and shrinking a piece are equally easy.
- Look back answers *is the real load going toward zero?* without a medical dashboard.
- A stranger could not mistake this for Streaks, Medisafe, or a wellness journal.

**Product-specific truth to keep visible:** three signals stay three things — house (protocol), sky (actual), weather (rescue).

## 3. Direction (interaction, not painting)

**Thesis:** The app is a place you stand in, with a small true instrument at your feet. It refuses the category default (today’s pill card + weekly calendar + circular progress).

**Topology:** One root. No tab bar. Camino is the only home. Protocol and Look back are rooms you enter and leave. Confirm and Rescue are sheets that rise out of the road.

**Sequence:** Disclaimer → first protocol → the road. After that, almost every session is: open → see the step → confirm or rescue → close.

**Focal moment:** Today’s step sitting on the path, in the current sky and weather, with the house at the distance of the current promise.

**Implementation consequence:** The scene is a full-bleed SwiftUI view. Chrome is system. Designers specify how the step, rescue, and two room-entries sit *in* the scene without turning it into a HUD.

## 4. Scope and boundaries

**Fidelity expected from the designer:** production-intent iPhone frames for every screen and material state listed in `SCREENS.md` and `STATES.md`. Light enough to validate; tight enough that engineering does not invent hierarchy.

**Breadth:** the whole v1 app. Not a marketing site. Not Android. Not a widget (optional later).

**Interactivity to specify:** sheet presentations, weekday chips, piece picker, time picker, confirm/edit, arrival accept/decline. Not micro-parallax recipes unless Reduce Motion is also specified.

**Untouched / do not add:**

- Countdown to two months
- Suggested cuts after skip or “less”
- Journal, mood, symptoms
- Points, levels, badges, “day 14”
- Auto-skip at midnight
- Accounts, sharing, Health
- Spanish UI words

**Anti-goals (a polished design that does these still fails):**

- Shame on rescue (red alerts, broken hearts, steps backward off the road)
- Cheerleading on skip / less
- Progress as a single ring or score
- A tab bar that makes Protocol equal to the road
- Custom form kits for time, weekdays, or alerts
- A character you walk like a game

## 5. States and ranges

See `STATES.md`. Design against these ranges, not lorem:

| Thing | Min | Typical | Max |
| --- | --- | --- | --- |
| Slots in a protocol | 0 (laid down) | 1 night | 3–4 (e.g. morning + night) |
| Weekdays on a slot | 1 | 4–7 | 7 |
| Amount | 0.0625 mg | 0.125 | 0.25+ custom |
| Open steps today | 0 (off night) | 1 | 2–3 |
| Unresolved past steps | 0 | 0–2 | a week of opens if he vanished |
| Rescues in 7 days | 0 | 0–3 | daily |
| Journey length | day 1 | weeks | ~60 days of data |
| Protocol versions | 1 | 5–15 | many small cuts |

## 6. Interaction and layout

**Hierarchy on Camino (top → bottom in attention, not necessarily in y):**

1. The place (sky, weather, path, house)
2. Today’s step(s)
3. Rescue (reachable, quiet)
4. Protocol and Look back (findable, not competing)

**Affordances:**

- Tap step → confirm sheet
- Rescue control → rescue sheet
- Protocol → editor (sheet or pushed stack with Cancel / Save)
- Look back → pushed room
- System swipe-to-dismiss on sheets; edge-swipe back in Look back

**Feedback:**

- Confirm: light haptic, step settles, sheet dismisses, sky/weather may shift
- Rescue: no haptic, weather may gather
- Cut saved: house moves closer (or farther if he added load)
- Arrival: light haptic, daylight holds

**Responsive:** iPhone portrait only for v1. Respect safe area, Dynamic Island, home indicator. Dynamic Type must not cover the step or clip primary actions.

## 7. Constraints and open decisions

**Locked:** iOS 18, SwiftUI, system sheets/lists/pickers/charts, English, copy meaning in `COPY.md`, three-signal scene in `CAMINO.md`.

**Designer decides:**

- Visual world of the road (still: night walking toward morning; weather ≠ punishment)
- How the step is embodied on the path (stone, lantern, folded paper — not a floating material card that could be any app)
- Slot naming vs time-only (propose one; default in copy is time + mg)
- Icon
- Optional Live Activity treatment (not required)

**A builder must not invent:** tab bars, streak chrome, auto-skip, a combined “wellness score,” or new first-run steps.
