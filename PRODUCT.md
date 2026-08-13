# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

One person: the owner of this phone. He takes clonazepam and is walking the dose toward zero. He opens the app at night, often tired, sometimes after a hard day, sometimes after taking extra. He is not a clinician, not a “wellness user,” and not a stranger we must onboard at scale.

He has been erratic. The app exists so the promise and the ledger are clearer than his memory. He wants to be at zero within about two months. That wish is his, not a feature.

## Product Purpose

Camino holds a **protocol** — a promise of which pieces, on which weekdays, at which clock times — and a **true ledger** of what was actually taken, including **rescue** (extra, off-protocol).

The front door is a night road toward a house. Home is zero. Home is peace. When the load is gone, the story closes and the app becomes something to look back on.

Success: he can keep a flexible promise, cut it when he can hold less, see that the real milligrams are going toward zero, and arrive home without being shamed or scheduled by the software.

## Positioning

Not a taper calculator, not a habit tracker, not a benzo-education product, not a journal.

The mechanism a neighboring app cannot copy: a **versioned weekday protocol** you confirm dose by dose, where extra is **weather** on a road whose **house only moves when you cut the promise**, while the **sky** answers what you actually swallowed.

## Operating Context

- Physical unit: **0.25 mg** tablets, split to ¾ / ½ / ¼ (0.1875 / 0.125 / 0.0625 mg). Custom mg is allowed.
- Typical starting attempt: one night slot, about 0.125 mg, on chosen weekdays.
- Confirm every scheduled dose. Nothing is assumed taken.
- Rescue is logged any day (amount + time).
- Reminders only at slot times on those weekdays.
- Used mostly at night, in bed or in a dim room, one-handed, in a hurry or in a fog.
- Personal, on this iPhone, TestFlight. No account. No clinician portal.
- English only.
- Horizon ~weeks to a couple of months, then the app should be finished.

## Capabilities and Constraints

**In v1**

- Protocol of one or more slots (amount, local time, weekdays). Saving a change versions history.
- Confirm: taken / skip / different amount. More than the slot **splits** (promised + rescue overflow). Less is a quieter night.
- Rescue log. Look-back: weekly planned, weekly actual, rescues, protocol staircase, skips and less.
- Camino scene driven by three separate signals (see SPEC.md §4).
- Arrival when protocol has no slots and today is 0 mg; then read-only memory.
- Local notifications. On-device data. Journey export (JSON).

**Out of v1**

Automatic % tapers, Ashton schedules, clinician sharing, accounts, cloud sync, HealthKit, symptoms, journal, backfill, 60-day countdown, badges, streaks, social, “you failed,” Android.

**Undecided (designer may propose; product owner confirms)**

- Whether a slot has a name (“Night”) or only time + amount.
- Exact painting of house, path, weather.
- App icon.
- Lock Screen Live Activity (nice, not required).
- Bundle identifier.

Stack (not for the visual designer to change): SwiftUI, SwiftData, UserNotifications, Swift Charts. iOS 18+.

## Brand Commitments

- Name: **Camino**.
- Language: English only. Do not put Spanish in the UI (`rescate`, `casa`, `protocolo`) unless quoting this document.
- Voice: quiet, direct, factual. Not clinical, not cute, not coachy, not gamified.
- Rescue is weather, not failure. The road is never taken away.
- No copy that tells him to cut or to hold. No “good job” / “you slipped.”
- Not medical advice. First-run must say that once, then get out of the way.

## Evidence on Hand

- Product spec: `SPEC.md`
- Interview decisions: `SPEC.md` §11
- No existing UI, brand kit, photography, or icon.
- Do not invent testimonials, clinical claims, or other users.

## Product Principles

1. A protocol is a **commitment**, not a ceiling and not a suggestion.
2. The ledger is **true** — the app never invents a dose.
3. He **cuts when he can hold it**. The app does not nag or auto-schedule.
4. Rescue is **honest weather, no shame**.
5. **Only doses.** The front door is the road, not a form.

## Accessibility & Inclusion

- Dynamic Type on all chrome, labels, sheets, lists, charts.
- Reduce Motion: the scene does not parallax or swirl; arrival does not pan.
- 44 pt minimum targets. VoiceOver names every control and every step state.
- Do not encode weather or brightness in color alone.
- Dark/light: the **Camino and Arrival scenes are a place** (night road → held daylight), not system Dark Mode. Sheets and Look back follow system appearance so they remain readable at accessibility sizes and contrast.
