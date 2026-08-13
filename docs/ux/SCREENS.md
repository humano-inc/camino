# Screens

iPhone portrait. System navigation chrome unless noted. Copy lives in `COPY.md`.

Component rule: **system** for operate surfaces (sheet, list, date picker, weekday selection, alert, chart). **Custom** only for the Camino/Arrival scene and the step-as-object on the path.

---

## S0 — Disclaimer

**Job:** Say this is not medicine, once.

**Layout**

- Full-screen cover, system background
- App name
- Short body (see copy)
- One primary: Continue

**Not:** a pager, illustrations of lungs, “I agree” legalese wall.

**States:** only this.

---

## S1 — First protocol

**Job:** Make the first promise so the road has a trailhead.

Same editor as S5, with different title and a single primary **Begin** (disabled until ≥1 valid slot).

No Cancel (there is nothing to return to). Back to disclaimer is allowed if you must, but not important.

After Begin: system notification permission, then S2.

---

## S2 — Camino (root)

**Job:** Be the place. Confirm tonight. Reach rescue, protocol, look back.

**Layout (attention order)**

```
┌─────────────────────────────┐
│         sky + weather       │
│                             │
│            house            │  ← distance
│           / path /          │
│                             │
│         [ step(s) ]         │  ← primary
│                             │
│  protocol        look back  │  ← quiet
│         rescue              │  ← quiet, always
└─────────────────────────────┘
```

Exact composition is the designer’s. Constraints:

- Scene is full-bleed, edge to edge, under the status bar
- Step(s) sit on the path, inside the safe area, 44 pt+
- Protocol and Look back are findable in one tap, smaller than the step
- Rescue is always visible, never the visual hero, never hidden in a `...` menu
- If arrival is offerable, the house-is-here + offer owns the path (see S8)

**Entry from notification:** same screen, the relevant step already the obvious target.

---

## S3 — Confirm (sheet)

**Job:** Tell the truth about one scheduled event.

**Presentation:** medium/large detents. Scene visible through system material. Matched to the step if possible. Swipe down = cancel without change. Cancel button too.

**Layout**

```
22:00 · 0.125 mg          (the promise)
Thu 13 Aug                (the calendar day of the event — not always today)

[ Taken ]                 primary, uses promised amount
[ Skip ]
[ Different amount ]      reveals piece picker

Taken at                  [ now  ∨  time picker ]

[ Save ]                  if amount/time edited on an existing confirm
```

**Interaction**

- **Taken** on an open event can commit immediately (one tap) or require Save — pick one and use it everywhere. Prefer **one tap for Taken and Skip**; Different amount needs a picker then Save.
- Different amount: piece row `¼  ½  ¾  1` of 0.25, plus Custom (numeric mg).
- If custom or piece **> promised**: helper line, factual: extra is logged as rescue. Not a warning color that means danger.
- If **< promised**: no praise.
- Editing today: same sheet, current values filled.

**Do not** use a 1–10 mood slider, notes field, or “why did you skip?”

---

## S4 — Rescue (sheet)

**Job:** Log extra. Leave.

```
Rescue

[ ¼  ½  ¾  1 ]     of 0.25     + Custom
Taken at           [ now ]

[ Save ]           [ Cancel ]
```

Save disabled until an amount > 0. No “reason.” No protocol suggestion.

Overflow rescues created by a bigger slot appear in Look back as rescue, and may show a quiet “from 22:00” link. They are not edited here unless he opens them from Look back.

---

## S5 — Protocol

**Job:** Change the promise. Save = new version.

**Presentation:** sheet or pushed stack. **Cancel** / **Save**. Save disabled when clean. Swipe-to-dismiss if clean; if dirty, system unsaved alert.

**Layout** — grouped inset list:

```
Promise
  Slot  22:00 · 0.125     Sun Tue Thu Sat     ›
  Slot  08:00 · 0.0625    Mon Wed Fri         ›
  Add slot

(footer, quiet)
This week  0.625 mg planned
```

Add slot → S6 for a new slot.  
Tap slot → S6.  
Swipe to delete a slot (system swipe action), or delete inside S6.

**Zero slots + Save:** system alert, then allow. That is how he lays the promise down.

Dropping a weekday and shrinking a piece both happen inside S6. Neither is a special “taper wizard.”

---

## S6 — Slot

**Job:** One slot’s piece, time, weekdays.

```
Amount     [ ¼  ½  ¾  1 | Custom ]
Time       [ 22:00 ]          system time picker
Weekdays   S M T W T F S      locale-ordered; selected = in the promise
           at least one required to save

[ Delete slot ]               destructive, if not the only way to empty
```

Done/back merges into the draft protocol; nothing is versioned until Protocol **Save**.

If zero weekdays selected, Done is disabled.

---

## S7 — Look back

**Job:** Is the real load going toward zero?

**Presentation:** pushed navigation stack. Large title. System background. Edge-swipe back.

**Sections (one scrolling room):**

1. **This week** — actual mg, planned mg, rescue mg / count. Numbers first, then a small chart.
2. **Weeks** — bar or step chart: planned (staircase) vs actual, toward zero. Weeks as columns, not a sparkline so small it becomes decoration.
3. **Rescues** — count, total mg, list of recent (amount · time · date). Tap → read-only detail (edit same-day only while still walking).
4. **Promises** — protocol versions, date range, weekly planned. The staircase as a list.
5. **Nights** — skips and less, as facts (date · planned · actual).
6. **Export** — share journey JSON.

After arrival: same room, no edit affordances.

**Not:** pie charts of “adherence %,” heatmaps that look like GitHub, calendars with green/red dots as a score.

Charts: Swift Charts language. Readable at accessibility text sizes (stack number above chart, don’t rely on tiny axis labels).

---

## S8 — Arrival offer (on Camino)

When conditions are met, Camino *is* the offer. Not a modal alert on top of a tiny house.

- House is here
- No step
- Copy + **I’m home** + **Not yet**
- Rescue and Protocol may recede; Look back can stay

**Not yet** returns to empty-protocol Camino (rescue still possible — if he rescues today, the offer disappears until a later 0 mg day).

---

## S9 — Arrival (root)

**Job:** The story is over. Remember, don’t live here.

- Held daylight, house present
- No step, no rescue, no protocol
- A way to Look back
- Begin again is not visible as a button on this canvas

---

## S10 — Begin again (deliberate)

Reached from a buried control (specify one: e.g. last cell in Look back, or long-press house).

System alert: this starts a new road; the old one remains to read.

Then S1-like protocol editor, new trailhead, new Camino.

---

## Shared: piece picker

Use the same control in Confirm, Rescue, Slot.

```
¼    ½    ¾    1      Custom
0.0625  0.125  0.1875  0.25
```

Selected piece is the value. Custom opens a decimal pad, mg, allow values like 0.1 if he ever needs them. Do not offer 0.0675 as a preset.

On operate surfaces, this can be a system segmented control + an extra Custom, or a wrapping chip row that still looks like iOS, not a game inventory.

---

## Shared: amount display

| Surface | Form |
| --- | --- |
| Piece picker | Pieces of 0.25, mg as secondary |
| Step on the path | `22:00 · 0.125` |
| Charts and weekly totals | `mg` to 3–4 decimals only if needed (`0.625 mg`) |
| Rescue list | `0.125 · 01:12` |

Do not mix `½ tablet` on the path and `0.125 mg` in the same glance without a reason.

---

## Notification (system)

Title or body: `22:00 · 0.125 mg`  
No subtitle about streaks. No daily summary.

---

## Optional, not v1

Lock Screen Live Activity: same facts as the step (`22:00 · 0.125`, open/taken). Scene not required there. Designer may show a treatment; engineering may skip.
