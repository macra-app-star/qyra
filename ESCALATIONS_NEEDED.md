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

*7 escalations requiring your decision. All are launch-relevant.*
