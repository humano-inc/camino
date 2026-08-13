# Information architecture and flows

## Map

```
First open
  Disclaimer
    → First protocol (required, ≥1 slot)
      → Notification permission (system, after save)
        → Camino

Camino                          ← the only root while walking
  sheet Confirm                 ← one scheduled step
  sheet Rescue                  ← extra dose
  sheet/stack Protocol          ← edit slots; Save versions
        sheet Slot              ← one slot’s piece, time, weekdays
  stack Look back
        Rescue list / day detail
        Protocol history
        Export
  cover Arrival offer
        → Arrival (new root, read-only)

Arrival
  stack Look back               ← same room, no logging
  (buried) Begin again          ← new journey; not on the arrival beat
```

No tab bar. No hamburger. No settings dump in v1 except whatever Look back needs for export and (if required) notification status.

## Session types

| Session | Frequency | Happy path |
| --- | --- | --- |
| Tonight | almost every open | See step → confirm → done |
| Off night | some weekdays | See no step → leave, or rescue |
| Rescue | occasional | Rescue sheet → amount + time → back on the road |
| Cut | occasional, considered | Protocol → change weekday or piece → Save |
| Remember | after arrival, or a Sunday | Look back |
| First night | once | Disclaimer → protocol → road |
| Last night | once | Empty protocol, 0 mg, accept home |

---

## Flow 1 — First open

```
Launch (no journey)
  → Disclaimer
       [Continue]
  → Protocol editor (title: Your first promise)
       must add ≥1 slot to continue
       [Begin]
  → System notification permission
       Allow or Don’t — both continue
  → Camino
       trailhead = this protocol’s weekly planned mg
```

No tour. No sample data. No “skip for now.”

---

## Flow 2 — Confirm tonight (dose day)

```
Notification (optional) 22:00 · 0.125 mg
  → Camino, today’s step focused / open

Tap step
  → Confirm sheet
       Taken  |  Skip  |  Different amount
       Time defaults to now; can change

Taken
  → dismiss, step = taken, light haptic

Skip
  → dismiss, step = skipped, no celebration

Different amount < planned
  → dismiss, step = less

Different amount > planned
  → dismiss, step = taken at planned
  → overflow rescue created (same timestamp)
```

Same sheet edits a same-day confirmation. Overflow rescue is updated or removed to match.

---

## Flow 3 — Off night

```
Camino
  no step on the path
  rescue still present
  protocol and look back still present
```

No empty-state illustration that says “nothing to do.” The place is the state.

---

## Flow 4 — Rescue

```
Camino (any day, including off nights and after a confirmed step)
  → Rescue sheet
       piece picker + time (now)
       [Save]  [Cancel]
  → Camino, weather may gather
```

No ask to change the protocol.

---

## Flow 5 — Cut the protocol

```
Camino → Protocol
  list of slots
  tap slot → edit piece / time / weekdays
  add slot / delete slot
  [Save] only enabled if dirty
    if slots remain → new version, house distance updates
    if zero slots → confirm once (“Lay this promise down?”)
      → empty protocol, arrival may become available if today is 0 mg
  [Cancel] discards
```

Never: “Drop Tuesdays?” after a skip. He comes here on purpose.

---

## Flow 6 — Late / leftover open steps

```
Camino
  if yesterday (or earlier) still open:
    those steps remain reachable (see SCREENS — unresolved)
    they do not auto-skip
  confirm/skip them the same way, with takenAt editable
```

Do not bury them only inside Look back. He must be able to tell the truth from the road.

---

## Flow 7 — Look back

```
Camino → Look back
  weekly actual vs planned (staircase)
  rescue summary
  protocol versions
  skips / less
  [Export]
  day or week drill-in for facts, not a second editor
```

After arrival, this is the main reason to open the app. Logging controls are gone.

---

## Flow 8 — Arrival

```
Conditions: protocol has 0 slots AND today actual == 0 AND not arrived

Camino shows the house here + Arrival offer
  [I’m home] → Arrival root, haptic, reminders off, logging gone
  [Not yet]  → stay on empty-protocol road; offer again next 0 mg day
```

Begin again is **not** on this screen.

---

## Flow 9 — After arrival

```
Arrival (house, daylight holds)
  → Look back (read-only)
  Begin again: behind a deliberate, easy-to-miss path
    (e.g. Look back → end of scroll, or a long-press on the house)
    → confirm
    → new journey, first protocol, new trailhead
    previous journey remains readable
```

---

## Flow 10 — Notification

```
Fires only on slot weekdays at slot time, if that day’s event is still open
Tap → Camino with that step ready
If already confirmed → do not fire
Arrival → none
```

---

## Permissions

| Permission | When asked | If denied |
| --- | --- | --- |
| Notifications | Right after first protocol save | App works. No banner nag. A single quiet line in Protocol or Look back can say reminders are off, with a link to Settings. |
| Nothing else | — | — |
