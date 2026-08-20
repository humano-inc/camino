# Camino

A personal iPhone app for walking off clonazepam.

UX to design and validate against (before any code): [`docs/ux/README.md`](docs/ux/README.md). Product record for a designer agent: [`PRODUCT.md`](PRODUCT.md).

Home is zero. Home is peace. The app is the road.

This spec is for one user (you). Day one is the first protocol you save. The story should be over in a couple of months; that horizon stays out of the app.

---

## 1. What it is

You keep a **protocol**: a promise of which pieces, on which weekdays, at which times. Each due dose is **confirmed** — nothing is assumed. Extra clonazepam is a **rescue**. It is weather on the road, not a failure.

The front door is not a form. It is the **Camino**: a night road toward a house. As the week gets lighter, the day brightens and the house comes closer. When the load is zero, you arrive, and the app becomes a finished thing you can look back on.

English only. The name is Camino.

Not a doctor. Not a taper calculator. Not a streak game.

---

## 2. Principles

1. **A protocol is a commitment**, not a ceiling and not a suggestion.
2. **The ledger is true.** You tap what happened. The app does not invent a dose.
3. **You cut when you can hold it.** The app never proposes a schedule and never nags “make this the new protocol?”
4. **Rescue is weather, not shame.** The road is not taken away.
5. **Only doses.** No journal, no symptom sliders, no badges.
6. **Start today.** No archaeology of the erratic past.
7. **Two months is yours.** No countdown, no fail-by date.
8. **Zero is home.** Arrival closes the story.

---

## 3. Object model

### 3.1 Tablet

The physical unit is a **0.25 mg** tablet.

| Piece | mg |
| --- | ---: |
| 1 | 0.250 |
| ¾ | 0.1875 |
| ½ | 0.125 |
| ¼ | 0.0625 |

The amount picker is these pieces first. A custom milligram field exists for anything else. Never show `0.0675` as a quarter — a quarter of 0.25 is **0.0625**.

Display: prefer `½ × 0.25` or `0.125 mg`. Be consistent in a given surface (picker uses pieces; charts use mg).

### 3.2 Protocol

A versioned promise.

| Field | Meaning |
| --- | --- |
| `id` | Stable id |
| `startedAt` | When this promise became current |
| `endedAt` | When it was replaced. `nil` = current |
| `slots` | One or more dose slots |

Cutting the protocol **ends** the current version and **starts** a new one. History is a staircase, never an overwrite.

There is at most one current protocol. An empty slot list means “no promise” (the last cut before home).

### 3.3 Slot

One repeating dose inside a protocol.

| Field | Meaning |
| --- | --- |
| `id` | Stable id |
| `amountMg` | Promised milligrams |
| `timeLocal` | Clock time for the reminder (your phone’s local time) |
| `weekdays` | Which days this slot exists (`Sun`…`Sat`) |

Example: `0.125 mg · 22:00 · Sun Tue Thu Sat`.

A protocol may have several slots (night + morning, two different night sizes, etc.). v1 will likely start as a single night slot.

A weekday with no slot is an **off night**. No reminder. Rescue is still possible.

### 3.4 Scheduled event

Created for each `(slot, date)` on a matching weekday, once that day exists.

Nothing is logged as taken until you confirm.

| Confirmation | Ledger |
| --- | --- |
| Took the promised amount | Planned mg, kept. Status `taken`. |
| Skipped | 0 mg. Status `skipped`. |
| Took less | Actual mg. Status `less`. A quieter night, not a broken promise. |
| Took more | **Split.** Promised mg stays the scheduled event (`taken`). Overflow mg is a linked **rescue**. |

You may confirm late. The event stores:

- `plannedAmountMg`
- `actualAmountMg` (0 if skipped)
- `confirmedAt` (when you tapped)
- `takenAt` (the time you say you took it; defaults to now; editable)

An unconfirmed slot past its time is **open**, not skipped. Skipped is a choice.

### 3.5 Rescue

Any clonazepam that is not the promised piece of a slot.

| Source | How it appears |
| --- | --- |
| Unscheduled extra | Rescue: amount + time |
| Overflow of a bigger slot | Rescue linked to that scheduled event |

Stored: `amountMg`, `takenAt`, optional `linkedScheduledId`, optional `note`.

Rescue does not rewrite the protocol.

### 3.6 Journey

One road, from first protocol to arrival.

| Field | Meaning |
| --- | --- |
| `startedAt` | First protocol saved |
| `arrivedAt` | When you accepted home. `nil` = still walking |
| `trailheadWeeklyMg` | Weekly planned mg of the first protocol. Used as the far end of the road. |

After arrival the journey is **read-only**. Looking back is allowed. Logging is not. Beginning again is a conscious new journey, not a one-tap from the house.

---

## 4. How load becomes the Camino

Three signals, three visuals. They must not be collapsed into one score.

| Signal | What it is | What you see |
| --- | --- | --- |
| **Distance to home** | Current protocol’s weekly planned mg, relative to the trailhead, toward 0 | The house gets closer. You walk when you **cut**. |
| **Brightness** | Actual mg swallowed in the last 7 days (scheduled + rescue) | The sky. Less load → night thins, then dawn, then day. |
| **Weather** | Rescue mg (and count) in the last 7 days | Cloud, wind, rain. The road stays. |

You are always on the road at **night, walking toward morning**. Home is daylight that holds.

- High planned load: house small, far, almost only a porch light.
- Cut: the path shortens. The house is nearer.
- A week you took less than the promise: the sky lightens even if you have not cut yet.
- A week with rescue: weather. No step backward off the road. No “you lose.”
- Protocol empty and a day at 0 mg: the house is here. Arrival can be offered.

**Progress is not a day counter.** A hard week does not rewind you to the trailhead.

### 4.1 Arrival

Offered when **all** of these are true:

1. Current protocol has **no slots** (weekly planned = 0).
2. **Today’s actual is 0** (no scheduled take, no rescue).
3. You have not already arrived.

You accept. `arrivedAt` is set. The scene becomes the house in held daylight. The app is a finished thing: open it to remember, not to live in.

If you must walk again later, you start a **new journey**. That is a separate, deliberate act, not on the arrival screen.

---

## 5. Shape of the app

### 5.1 First open

1. One short screen: this is a personal ledger, not medical advice. You are responsible for your taper and your clinician.
2. Build the first protocol (at least one slot).
3. The road begins. `trailheadWeeklyMg` is that protocol’s weekly planned total.

No onboarding tour. No backfill.

### 5.2 Camino (home)

The whole screen is the scene.

On the path, today:

- **Dose day:** the step — piece, time, open / confirmed / skipped / less.
- **Off day:** no step. Rescue still within reach.

Gestures / controls (quiet, on the road):

- Tap the step → confirm sheet.
- Rescue → always available, never the hero button.
- A small way to the protocol, and to look back. They are not the front door.

The scene is alive but still. Light and weather breathe. It is not a game character you steer.

### 5.3 Confirm

For an open (or already confirmed, editable) scheduled event:

- **Taken** — promised amount, `takenAt` default now.
- **Skip**
- **Different amount** — piece picker.  
  - Less → status `less`.  
  - More → promised amount `taken` + overflow rescue.

Optional: change `takenAt`.

No copy like “good job” or “you slipped.” Facts only. A quieter night can feel quieter in the sky later; it does not need a toast.

Confirming is a step on the path. The sheet should feel like it rose out of the road (matched geometry, same light behind it).

### 5.4 Rescue

Amount (pieces first) + time (default now) + optional note. Save. Weather can gather. No lecture. The note is memory, not a reason you must give.

### 5.5 Protocol

List of slots. Each slot: piece, time, weekday chips.

- Add slot, edit slot, delete slot.
- Save **is** a cut if anything changed: end current version, start a new one with `startedAt = now`.
- If nothing changed, save is a no-op.
- You can save a protocol with **zero slots** (lay the promise down).

Dropping a weekday and shrinking a piece are equally one-tap obvious. That is the whole editor.

Do not ask “are you sure?” unless you are about to save zero slots while still mid-journey (that leads toward home). Then one clear confirmation is enough.

### 5.6 Look back

Secondary room. Charts and lists, still in the same night/home palette — not a medical dashboard.

Must show:

- Weekly **actual** mg (everything swallowed).
- Weekly **planned** mg (the protocol that week) — the staircase.
- Rescue: count, mg, times, notes.
- Each protocol version and when you cut.
- Skips and `less` as facts.

The question this room answers: *is the real load going toward zero?*

After arrival, this is the main reason to open the app.

### 5.7 Home (arrival)

The road ends. Daylight holds. No protocol chrome. No confirm.

A way back into look back. No logging.

---

## 6. Reminders

One local notification per slot, on its weekdays, at `timeLocal`.

Copy, quiet: `Night · 0.125 mg` (use the slot’s piece/amount, not the word “Night” if you have named times — prefer the time and amount: `22:00 · 0.125 mg`).

- Off weekdays: silence.
- After confirm that day: do not fire, or cancel if still pending.
- After arrival: all reminders off.
- No marketing, no “you missed yesterday,” no streaks.

Tapping the notification opens Camino on today’s step.

---

## 7. User stories

### Protocol

- I can create a protocol of one or more slots (amount, time, weekdays) so I have a promise I can keep.
- I can change that promise whenever I can hold less, and the previous promise remains in history.
- I can drop a weekday or shrink the piece with the same ease.
- I can add a slot or a weekday back if I overshot, as a new version, without erasing the last one.
- I can lay the protocol down (zero slots) when I am ready to try home.

### Tonight

- On a dose weekday I get a reminder at the slot time.
- I confirm taken, skipped, or a different amount, so the ledger is true.
- If I take more than the slot, the extra is rescue and the promised piece still counts as the slot.
- If I take less, the night is recorded as less — a quieter step.
- On any day I can log a rescue (amount, time, optional note) without rewriting the protocol.
- If I confirm late, I can set the real time.
- An old open step stays open until I confirm or skip it; the app does not auto-skip midnight.

### The road

- I can see, without reading a chart, whether the week is getting lighter.
- I can see that a cut moved me closer to the house.
- Rescue can change the weather and never take the road away.
- Taking less can brighten the sky before I officially cut.

### Look back

- I can see weekly actual mg.
- I can see weekly planned mg and the staircase of protocols.
- I can see how many rescues, how big, when, and any note I left.
- I can see skips and “took less.”
- I can tell whether the trend is toward zero.

### Arrival

- When there is no protocol and today is 0 mg, I can arrive home.
- After that I can open Camino only to remember.
- If I ever need to walk again, I start a new journey on purpose.

### Not in this version

Automatic % tapers, Ashton schedules, clinician sharing, accounts, cloud sync, HealthKit, symptoms, journal, backfill, a 60-day countdown, badges, streaks, social, “you failed,” Android.

---

## 8. Technology

**Platform:** iOS, SwiftUI. One personal iPhone. Android is a later rewrite if it ever matters.

**Minimum OS:** iOS 18. Personal device; use current SwiftUI (Observation, SwiftData, Swift Charts, MeshGradient / rich gradients).

**Data:** SwiftData, on device only. No account. No telemetry.

**Notifications:** `UserNotifications`, calendar-style per slot/weekday. Reschedule when the protocol changes and on confirm.

**Camino scene:** SwiftUI first — `TimelineView` + `Canvas` and/or layered views, `MeshGradient` (or equivalent) for sky, particle/overlay weather. Stay in SwiftUI until a Metal shader is obviously needed for atmosphere. No SpriteKit character, no game loop.

**Charts:** Swift Charts in look back.

**Haptics:** Light, on confirm and on arrival. Nothing on rescue.

**Distribution:** TestFlight, then the App Store only if you decide to. Bundle working name: `Camino`. Repo folder may stay `clona`.

**Backup:** On-device is the source of truth. v1 should include a simple **export** of the journey (JSON is enough) from look back, so a lost phone does not erase the road. No iCloud requirement in v1.

**Architecture:** One app target. SwiftUI views + `@Observable` stores + SwiftData. No TCA, no server, no feature-flag service. Small enough to hold in one head.

**Why not Expo:** The road as a painting can be equal in Skia. The thing you hold every night — sheet, type, motion, Live Activity later, battery-quiet sky — is an iPhone object. This spec is that object. A future Android app should reuse §4 (the three signals) and the scene language, not the UIKit/SwiftUI chrome.

### 8.1 Suggested data types

```text
Journey
  startedAt: Date
  arrivedAt: Date?
  trailheadWeeklyMg: Double

Protocol
  startedAt: Date
  endedAt: Date?
  slots: [Slot]

Slot
  amountMg: Double
  timeLocal: DateComponents   // hour, minute
  weekdays: Set<Weekday>

ScheduledEvent
  date: Date                  // calendar day
  slotId: UUID
  protocolId: UUID
  plannedAmountMg: Double
  actualAmountMg: Double?
  status: open | taken | skipped | less
  takenAt: Date?
  confirmedAt: Date?

Rescue
  takenAt: Date
  amountMg: Double
  linkedScheduledId: UUID?
  note: String?
```

Derived, not stored: weekly planned, weekly actual, weather, brightness, distance.

---

## 9. Edge cases

| Case | Behavior |
| --- | --- |
| Two slots the same day | Two steps, two reminders, two confirms. |
| Time zone / travel | Use the phone’s local calendar. Do not try to be clever. |
| Protocol cut mid-day | Future reminders follow the new protocol. Already-confirmed events today stay. Unconfirmed events for slots that no longer exist today remain open until you resolve them (confirm against what you actually did, or skip). |
| App killed / phone off at dose time | Notification still fires if the system allows. Event stays `open`. |
| Confirm then edit | Allowed the same day. Overflow rescue is created/updated/removed to match the split rule. |
| Rescue then you also have a slot | Independent, unless the rescue was overflow from that slot. |
| Last 7 days spans two protocols | Actual is still “what you swallowed.” Planned for “this week” uses each day’s then-current protocol. |
| Arrival offered, you refuse | Stay on the empty-protocol road. Offer again the next day that is still 0 mg. |
| New journey after arrival | Previous journey remains readable. New trailhead from the new first protocol. |

---

## 10. Safety and privacy

- First-run: not medical advice; not a substitute for a clinician; benzodiazepine withdrawal can be dangerous; you own the protocol.
- No copy that tells you to cut or to hold.
- No data leaves the phone unless you export.
- No analytics SDK.

---

## 11. Decisions (from the interview)

| Question | Decision |
| --- | --- |
| Who | Just you |
| Name | Camino |
| Language | English only |
| Logging | Tap to confirm every scheduled dose |
| Different amount | Less = quieter night. More = split (planned + rescue) |
| Protocol | A commitment. Weekdays you pick. |
| Cut | When you can hold it. You open the protocol. No in-the-moment “make this official?” |
| Day contents | Only doses |
| Reminders | At each slot time, those weekdays only |
| Pieces | Quarters of a 0.25 mg tablet (0.0625 mg) |
| Past | Start today |
| Two months | Out of the app |
| Home screen | The road, then the dose |
| Rescue on the Camino | Honest weather, no shame |
| Zero | You arrive home. The app becomes a finished thing. |
| Stack | SwiftUI, on device |

---

## 12. Build order (when we implement)

1. SwiftData model + first-protocol editor + confirm/rescue ledger (truth first).
2. Local notifications from slots.
3. Look-back charts (planned vs actual vs rescue).
4. Camino scene driven by the three signals.
5. Arrival + read-only memory.
6. Export.

Do not start with the sky. A beautiful road on a lying ledger is worse than a plain ledger that is true.

---

## 13. Left to the designer

Interaction, IA, copy, states, and scene **physics** are specified in [`docs/ux/`](docs/ux/). Still open on purpose (visual world, not product rules):

- Exact painting of the house, the path, the weather (still: night → morning, weather ≠ punishment).
- How the step is embodied on the path.
- Whether a slot has a user-facing name (“Night”) or only time + amount (copy default is time + mg).
- App icon.
- Whether v1 ships a Lock Screen Live Activity (nice; not required).
- Bundle identifier.
