# Daily Rhythm implementation (1.5.9+18)

Approved direction: Outfit, compact pastel clay artwork, a quiet warm background,
real document activity, and explicit daily rewards. Native Flutter throughout.
Unslop by Damir Sokolovsky (https://heydamir.design/unslop), CC BY 4.0, informs the
spacing/hierarchy/visual review; existing attribution/license files are retained.

## Behavior

- Successful PDF, Office, text and image rendering owns a study lease only while
  its route is visible and the app is foregrounded. Opening a loading/error page
  does not start time. PDF annotation counts after its page renders.
- Closing/covering the last document pauses counted time immediately. A 30-second
  grace preserves the session; reopening joins it. After grace the session closes.
  Silent reading no longer stops at the previous five-minute touch timeout.
- Personal offline history is preserved. Competitive ranking and reward study
  credits use server-timed online heartbeats; offline history is not fabricated
  into verified points. Rank scoring and membership/consent rules stay unchanged.
- Rank boards refresh every fifteen seconds and after a verified heartbeat.
  Personal local seconds update independently from network latency.
- Home calendar opens the planner; a selected date can hold a colored test, exam
  or event and a phone reminder. Pending event writes survive offline/restart and
  remain account scoped. Calendar events use device-local dates and UTC instants.
- Dated tasks request notification permission before scheduling. Existing reminder
  channels/receivers remain, with a monochrome status-bar drawable. Inexact Android
  alarms can be deferred by Doze/OEM battery policies; force-stop delivery is not
  guaranteed. Real Infinix notification delivery must be checked on that phone.
- Daily claims: 100 points; every seven consecutive claims: +200; each eligible
  milestone: +50. Milestones are 5, 7, 14, 30, 60 and 100 consecutive days.
  Study credits: floor(total server-verified seconds × 100 / 3600), carrying
  fractional hours. Wallet and legacy leaderboard score are separate.
- Claims use server date in Asia/Karachi and immutable per-user ledger keys.
  Lost responses retry the same claim. Offline claims are pending, never credited
  optimistically. A pending claim from a previous day expires visibly.
- Missed claims reset the current reward streak, not earned points/badges. Existing
  15-minute study streak data remains available as a separate study statistic.
- The thought bubble hides for this Home session; it does not change points.
- Motion uses native Flutter and existing reduced-motion/lifecycle handling. No new
  animation library, GIF decoder, blur loop or per-second server write was added.

## Deployment

`push-worker/migrations/0002_rewards_calendar.sql` adds five tables, without
modifying production data. `study-backend-deploy.yml` runs tests and bundles the
worker before applying that additive migration and deploying with `--keep-vars`.
It needs repository secret `CLOUDFLARE_API_TOKEN` (Workers Scripts Edit, D1 Edit)
and repository variable `CLOUDFLARE_ACCOUNT_ID` for the existing account. Production
OneSignal/Firebase secrets and settings are neither read nor replaced.

Backend fixture tests are not evidence of a deployed authenticated production
claim. Require deployment success and an authenticated claim/calendar/rank check
before marking cloud behavior verified. GitHub Pages uses sample data and is
visual review evidence only. Physical Note 8 GPU, camera, Drive and notification
checks remain separate from widget/emulator verification.
