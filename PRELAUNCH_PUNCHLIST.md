# PRE-LAUNCH PUNCHLIST

---

## CRITICAL (Launch Blockers)

- [ ] **Add Delete Account feature** — UI in Settings + call existing edge function + confirmation dialog
- [ ] **Remove stub Google/Email sign-in buttons** — or implement real auth (decision needed)
- [ ] **Update all legal URLs** — Terms/Privacy point to macra-app-star.github.io (decision needed on new domain)
- [ ] **Wire up real username availability check** — currently simulated, always returns true
- [ ] **Rename MACRA → Qyra in StoreKit config** — product display names, descriptions
- [ ] **Rename MACRA → Qyra in Fastlane metadata** — app name, description, URLs
- [ ] **Verify #if DEBUG guard on dev skip button** — ensure it never appears in release builds
- [ ] **Add AI health disclaimer** — "Not medical advice" in AI coach UI
- [ ] **Add camera permission denial recovery** — guide user to Settings when camera denied

## HIGH PRIORITY

- [ ] **Rename MACRA → Qyra in all user-facing strings** — subscription labels, analytics events
- [ ] **Update Supabase migration comments** — remove "macra" references
- [ ] **Update default profile name** — "macra user" → "Qyra User" in SQL migration
- [ ] **Update macra_subscription_events table reference** — or create alias/new table
- [ ] **Add notification permission request** — in onboarding or first-run experience
- [ ] **Add offline state indicator** — network reachability check, user feedback
- [ ] **Harden subscription sync** — fire-and-forget → retry with exponential backoff
- [ ] **Rename internal code references** — LongTermResultsView macraLine → qyraLine functions
- [ ] **Update build scripts** — Tools/build.sh, train_food_classifier.py MACRA references
- [ ] **Update project.yml** — MACRA source paths and references

## MEDIUM PRIORITY

- [ ] **Add empty states for all list views** — groups, exercise history, meal history
- [ ] **Add pull-to-refresh on dashboard** — stale data after backgrounding
- [ ] **Add error retry on API failures** — Supabase calls, Gemini calls
- [ ] **Add loading states for AI features** — coach, food scan, debrief
- [ ] **Audit all sheet dismissal** — ensure data isn't lost on swipe-to-dismiss
- [ ] **Add keyboard avoidance** — verify all text inputs handle keyboard correctly
- [ ] **Test Dynamic Type** — ensure all screens handle accessibility text sizes
- [ ] **Add VoiceOver labels** — audit all custom components for accessibility
- [ ] **Verify safe area handling** — all screens, especially on different device sizes
- [ ] **Update landing page HTML** — Metadata/landing-page/ still references MACRA

## LOW PRIORITY (Polish)

- [ ] **Rename Xcode project** — MACRA.xcodeproj → Qyra.xcodeproj (complex, may break CI)
- [ ] **Rename directories** — MACRA/ → Qyra/, MACRATests/ → QyraTests/ (complex)
- [ ] **Rename MACRAApp struct** — to QyraApp (cascading changes)
- [ ] **Update Metadata/*.md files** — LaunchCopy, Roadmap, etc. with Qyra branding
- [ ] **Add app rating prompt** — appropriate timing after positive interaction
- [ ] **Optimize cold launch** — profile startup time
- [ ] **Add haptic feedback audit** — consistent haptic usage across interactions
- [ ] **Review animation timing** — ensure consistent easing across all transitions

---

*Last updated: 2026-03-31*
