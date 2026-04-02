# ESCALATIONS NEEDED — Decisions Required Before Launch

---

## 1. Non-Functional Sign-In Buttons (Google, Email)

**Issue:** SaveProgressView and SignInView show Google and Email sign-in buttons that are stubs — they just call `viewModel.advance()` without authenticating.

**Why it matters:** Apple may reject for misleading UI. Users who tap these expect authentication. Trust-breaking if they "sign in with Google" and nothing happens.

**Options:**
- A) **Remove the buttons entirely** — ship with Apple Sign-In only (recommended, fastest)
- B) Implement Google Sign-In (adds Firebase dependency, 2-3 days work)
- C) Implement email/password auth (adds complexity, password reset flow needed)

**Recommendation:** Option A. Remove stubs. Apple Sign-In alone is clean and sufficient for launch. Add others in v1.1.

**Launch impact if ignored:** Likely App Store rejection. Guaranteed trust damage.

---

## 2. Terms of Service / Privacy Policy URLs

**Issue:** All legal links point to `macra-app-star.github.io/macra-landing/` — an old domain with the old brand name.

**Why it matters:** Apple reviews legal links. Broken or misbranded URLs = rejection risk. Users seeing "MACRA" in legal docs = brand confusion.

**Options:**
- A) **Update URLs to new Qyra domain** (e.g., qyra.app/terms, qyra.app/privacy)
- B) Update the GitHub Pages content to say "Qyra" but keep the old URL (hacky)
- C) Host on the qyra-web Next.js site

**Recommendation:** Option A or C. You need production URLs. What domain are you using?

**Launch impact if ignored:** Rejection risk + legal exposure.

---

## 3. Delete Account Feature

**Issue:** No account deletion UI exists. Apple requires this since June 2022 for any app with account creation.

**Why it matters:** Guaranteed App Store rejection without it.

**Options:**
- A) **Add "Delete Account" to settings** with confirmation dialog, call existing `delete-account` edge function + confirmation flow
- B) Add email-based deletion request (slower, still compliant)

**Recommendation:** Option A. The Supabase edge function already exists. Just need the UI + confirmation flow.

**Launch impact if ignored:** Guaranteed rejection.

---

## 4. Username Availability — Real Check or Remove?

**Issue:** Username availability check is simulated (always returns true after 500ms delay).

**Options:**
- A) **Wire up real Supabase query** against profiles table
- B) Remove username from onboarding entirely (use display name only)
- C) Ship as-is and fix post-launch (risk: duplicate usernames, social features break)

**Recommendation:** Option A. The profiles table exists, the query is trivial. 30-minute fix.

**Launch impact if ignored:** Duplicate usernames in production. Social features (groups, versus) show wrong people.

---

## 5. Subscription Product Names in StoreKit

**Issue:** MACRA.storekit file has display names "MACRA Premium", "MACRA Monthly", "MACRA Yearly".

**Why it matters:** The .storekit file is for local testing. But the REAL product names in App Store Connect must say "Qyra". Are your App Store Connect products already configured with "Qyra" branding?

**Options:**
- A) Update .storekit file (local testing fix)
- B) Verify App Store Connect products match (production fix)

**Recommendation:** Both A and B. I can fix A. You need to verify B.

**Launch impact if ignored:** Users see "MACRA Premium" in purchase confirmation dialogs.

---

## 6. SwiftData Migration Strategy

**Issue:** On migration failure, the app deletes the old store and creates a fresh one. This means existing beta testers lose ALL data on schema changes.

**Options:**
- A) Acceptable for v1.0 launch (no existing production users)
- B) Add proper lightweight migration support now
- C) Add data export before migration attempts

**Recommendation:** Option A if this is first public release. Option B if there are TestFlight users with data worth preserving.

**Launch impact if ignored:** Low for v1.0, high for updates.

---

## 7. AI Health Claims Disclaimer

**Issue:** The AI coach gives health/nutrition advice. Apple and regulators require disclaimers that this is not medical advice.

**Options:**
- A) Add disclaimer in AI coach UI ("This is not medical advice")
- B) Add disclaimer in onboarding
- C) Add disclaimer in Terms of Service only

**Recommendation:** A + C. Visible disclaimer in the AI coach interface AND in Terms.

**Launch impact if ignored:** App Store review flag. Potential legal liability.

---

---

## 8. Missing userId Predicates in SwiftData Queries

**Issue:** All SwiftData fetch queries (MealRepository, GoalRepository, ProfileRepository) lack userId filtering. On a shared device, any signed-in user sees ALL meal/goal data from previous users.

**Why it matters:** Data leakage between users. Also affects streak calculations, nutrition totals, and social features.

**Options:**
- A) **Add userId to every FetchDescriptor predicate** — comprehensive fix, touches ~10 files
- B) Accept risk for v1.0 since most iPhones are single-user

**Recommendation:** Option A. This is a data privacy issue. Even on single-user devices, signing out and back in with a different account should not leak data.

**Launch impact if ignored:** Data privacy violation. If Apple tests with two accounts, they'll see the leak.

---

## 9. Supabase Table Rename: macra_subscription_events

**Issue:** Code now references `subscription_events` table (I updated the client), but the Supabase table is still named `macra_subscription_events`.

**Options:**
- A) **Rename the table in Supabase** — run `ALTER TABLE macra_subscription_events RENAME TO subscription_events;`
- B) **Revert the code change** — use old table name
- C) **Create a view** — `CREATE VIEW subscription_events AS SELECT * FROM macra_subscription_events;`

**Recommendation:** Option A. Clean break. Run the migration before deploying the new app build.

**Launch impact if ignored:** Subscription events silently fail to record. No crash, but you lose purchase telemetry.

---

## 10. Prompt Injection in AI Features

**Issue:** User messages are embedded directly into Gemini prompts without sanitization. An attacker could inject instructions to manipulate nutrition estimates.

**Options:**
- A) **Sanitize user input** — strip special characters, limit length
- B) **Use structured API** — separate system/user messages (Gemini supports this)
- C) Accept risk for v1.0 (low likelihood, high impact)

**Recommendation:** Option B is cleanest. Option A is fastest. At minimum, add input length limits.

**Launch impact if ignored:** Low probability, high severity. A motivated user could get the AI to return false nutrition data.

---

*10 escalations requiring your decision. All are launch-relevant.*
