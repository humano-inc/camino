# Copy deck

English only. Quiet, direct, factual.

**Do not add:** good job, you slipped, stay strong, almost there, day 14, keep your streak, medical instructions, Spanish soul words in the chrome.

Placeholders in `{braces}`. Times use the device’s 12/24-hour setting. Amounts on the path and in notifications: `{amount}` like `0.125`. Weekly totals: `{n} mg`.

---

## App

| Key | String |
| --- | --- |
| app.name | Camino |

---

## Disclaimer (S0)

| Key | String |
| --- | --- |
| disclaimer.title | Camino |
| disclaimer.body | This is a personal ledger for your clonazepam, not medical advice. Withdrawal can be dangerous. You own your protocol. A clinician owns the medicine. |
| disclaimer.continue | Continue |

---

## First protocol (S1)

| Key | String |
| --- | --- |
| protocol.first.title | Your first promise |
| protocol.first.lead | Which pieces, which nights, which time. You can cut this whenever you can hold less. |
| protocol.begin | Begin |
| protocol.add_slot | Add a time |

---

## Camino (S2)

The scene has no headline. If a date is needed at all, a small `{weekday d MMM}` is enough.

| Key | String |
| --- | --- |
| step.open | `{time} · {amount}` |
| step.taken | `{time} · {amount}` |
| step.less | `{time} · {actual}` |
| step.skipped | `{time} · skipped` |
| rescue.action | Rescue |
| protocol.action | Promise |
| lookback.action | Look back |
| unresolved.one | One night still open |
| unresolved.many | `{n} nights still open` |

VoiceOver extras (not visible):

| Key | String |
| --- | --- |
| vo.scene | Road toward home. House {nearer\|far}. Sky {dark\|thinning\|morning}. Weather {clear\|cloud\|rain}. |
| vo.step.open | `{time}, {amount} milligrams, not confirmed` |
| vo.step.taken | `{time}, took {amount} milligrams` |
| vo.step.less | `{time}, promised {planned}, took {actual}` |
| vo.step.skipped | `{time}, skipped` |
| vo.off | No dose on the path tonight |

---

## Confirm (S3)

| Key | String |
| --- | --- |
| confirm.title | `{time} · {amount}` |
| confirm.date | `{EEE d MMM}` |
| confirm.taken | Taken |
| confirm.skip | Skip |
| confirm.different | Different amount |
| confirm.taken_at | Time |
| confirm.overflow | `{extra} above the promise is logged as rescue.` |
| confirm.save | Save |
| confirm.cancel | Cancel |

No helper on skip. No helper on less.

---

## Rescue (S4)

| Key | String |
| --- | --- |
| rescue.title | Rescue |
| rescue.taken_at | Time |
| rescue.note | Note |
| rescue.save | Save |
| rescue.cancel | Cancel |
| rescue.from_slot | From `{time}` |

---

## Protocol (S5–S6)

| Key | String |
| --- | --- |
| protocol.title | Promise |
| protocol.save | Save |
| protocol.cancel | Cancel |
| protocol.slot.row | `{time} · {amount}` |
| protocol.slot.days | `{short weekdays}` e.g. `Sun Tue Thu Sat` |
| protocol.week_total | This week `{n} mg` planned |
| protocol.slot.title | Time |
| protocol.amount | Amount |
| protocol.time | Time |
| protocol.weekdays | Days |
| protocol.delete_slot | Delete this time |
| protocol.custom | Custom |
| protocol.piece.quarter | ¼ |
| protocol.piece.half | ½ |
| protocol.piece.three_quarter | ¾ |
| protocol.piece.one | 1 |
| protocol.piece.unit | of 0.25 mg |
| protocol.lay_down.title | Lay this promise down? |
| protocol.lay_down.body | No scheduled doses. Rescue will still be possible until you are home. |
| protocol.lay_down.confirm | Lay it down |
| protocol.discard.title | Discard changes? |
| protocol.discard.discard | Discard |
| protocol.discard.keep | Keep editing |
| protocol.notifications_off | Reminders are off. |
| protocol.notifications_open | Open Settings |

First protocol uses `Your first promise` / `Begin` instead of `Promise` / `Save`.

---

## Look back (S7)

| Key | String |
| --- | --- |
| lookback.title | Look back |
| lookback.this_week | This week |
| lookback.actual | Taken |
| lookback.planned | Promised |
| lookback.rescue | Rescue |
| lookback.weeks | Weeks |
| lookback.rescues | Rescues |
| lookback.promises | Promises |
| lookback.nights | Nights |
| lookback.skip | Skipped |
| lookback.less | Less than promised |
| lookback.export | Export journey |
| lookback.version_range | `{started} – {ended\|now}` |
| lookback.empty_week | Just this week so far. |
| lookback.no_rescues | No rescues. |

Chart accessibility: `{week}: promised {p} mg, taken {a} mg, rescue {r} mg`.

---

## Arrival (S8–S9)

| Key | String |
| --- | --- |
| arrive.lead | No promise. Nothing taken today. |
| arrive.confirm | I’m home |
| arrive.not_yet | Not yet |
| arrived.vo | Home. The road has ended. |

No poem on the arrival canvas unless the designer proposes **one short line** and it is approved. Default is silence plus the place.

---

## Begin again (S10)

| Key | String |
| --- | --- |
| again.action | Begin again |
| again.title | Start a new road? |
| again.body | The one you finished stays here to look back on. |
| again.confirm | Begin again |
| again.cancel | Cancel |

---

## Notifications

| Key | String |
| --- | --- |
| notif.body | `{time} · {amount}` |

No title if the body is enough. If a title is required: `Camino`.

---

## System alerts (generic)

| Key | String |
| --- | --- |
| ok | OK |
| cancel | Cancel |

---

## Words we do not use

Missed, failed, cheated, relapsed, streak, points, taper plan, dose adherence, compliance, stay strong, you’ve got this, almost there, rescate, casa, protocolo (in the UI), medication reminder, pill, Rx.

“Skipped,” “rescue,” “promise,” “look back,” and “home” are the load-bearing words. Keep them.
