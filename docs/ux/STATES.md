# States

Every row needs a frame or a written treatment. Happy-path-only boards will be rejected.

## Journey

| ID | State | What you see |
| --- | --- | --- |
| J0 | No journey | Disclaimer → first protocol |
| J1 | Walking, day 1 | Camino at trailhead (house far). Sky from today’s actual only (a short window). |
| J2 | Walking, mid | House at current `d`. Sky/weather from last 7 days. |
| J3 | Empty protocol, not home | Path with no step (unless leftover opens). Arrival offer only if today is 0 mg. |
| J4 | Arrival offered | S8 |
| J5 | Arrived | S9, Look back read-only |
| J6 | New journey after one arrived | New Camino; old journey still in Look back history |

## Today on the path

| ID | State | Path |
| --- | --- | --- |
| D0 | Off night, nothing open | No step |
| D1 | One open step, before time | Step waiting |
| D2 | One open step, after time (late same day) | Same step, still open — not “missed,” not red |
| D3 | Taken as promised | Settled step |
| D4 | Skipped | Settled step, factually skipped |
| D5 | Less | Settled step, shows actual |
| D6 | Taken + overflow rescue | Settled step + weather may already show |
| D7 | Two slots | Two steps, independent states |
| D8 | Confirmed + a later rescue | Step stays settled; weather can change |
| D9 | Off night + rescue | No step; weather |

## Unresolved past

| ID | State | Treatment |
| --- | --- | --- |
| U0 | None | Clean path |
| U1 | Yesterday open | Quiet “behind you” cue; tappable; same confirm sheet, date visible |
| U2 | Several days open | Cue shows a count; list of open steps; none auto-skipped |

## Protocol editor

| ID | State | Treatment |
| --- | --- | --- |
| P0 | First protocol, empty | Add slot is the only way forward; Begin disabled |
| P1 | One slot, clean | Save/Begin enabled |
| P2 | Dirty | Save on; dismiss asks to discard |
| P3 | Two or more slots | List |
| P4 | Zero slots, walking | Save asks to lay the promise down |
| P5 | Notifications denied | Quiet line + Open Settings |

## Confirm / rescue

| ID | State | Treatment |
| --- | --- | --- |
| C0 | Open | Taken / Skip / Different |
| C1 | Editing today | Prefill; Save |
| C2 | Different < planned | Picker, no praise |
| C3 | Different > planned | Factual overflow line |
| C4 | Custom mg | Decimal pad |
| C5 | Rescue, empty | Save off |
| C6 | Rescue, ready | Save on |

## Scene extremes (must still parse)

| ID | State | Scene |
| --- | --- | --- |
| V0 | High P and A (start, heavy) | House far, deep night, maybe weather |
| V1 | Cut a lot, still swallowing (low P, high A) | House near, sky still dark |
| V2 | Didn’t cut, swallowed less (high P, low A) | House far, sky lighter |
| V3 | Heavy rescue week | Weather; house unmoved |
| V4 | Near zero | House large, morning, weather thin |
| V5 | Reduce Motion | Crossfades only |
| V6 | Accessibility XXXL | Step and actions remain usable; scene may crop, chrome must not |

## Look back

| ID | State | Treatment |
| --- | --- | --- |
| L0 | Day 1, almost no history | One week, honest and small — not an empty-state mascot |
| L1 | Several weeks, downward | Staircase + actual |
| L2 | Week actual > planned | Visible, not a red fail banner |
| L3 | No rescues yet | Omit the list or show zero; don’t invent a cheer |
| L4 | Arrived | Same data, no edit, no rescue composer |
| L5 | Export | System share sheet |

## System / device

| ID | State | Treatment |
| --- | --- | --- |
| X0 | Notification tap | Camino, that step |
| X1 | Notifications denied | App works |
| X2 | Dynamic Type XXXL | Sheets scroll; 44 pt targets; no overlap with home indicator |
| X3 | Dark / Light system | Sheets and Look back adapt; Camino/Arrival stay a place |
| X4 | Increase Contrast | Weather and brightness still separable |
| X5 | VoiceOver | Step announces time, amount, status; rescue; rooms; scene signals described in words (“house nearer,” “sky darker,” “rain”) |
| X6 | Time zone change | Local calendar; no designer special case beyond “dates are local” |
