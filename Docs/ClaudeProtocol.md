# MACRA Claude Code Protocol

## File Output Rules
- Every file output MUST be complete and compilable. No snippets, no pseudocode, no `// TODO: implement` stubs.
- If a file changes, re-output the ENTIRE file.
- Include all imports at the top of every file.

## Architecture Rules (Strict MVVM)
- **Views** (`UI/`): SwiftUI only. No business logic. No direct service calls. No `import` of Data/ or Services/.
- **ViewModels** (`ViewModels/`): `@Observable` classes. Depend on protocols, never concrete types. All dependencies injected via init.
- **Domain** (`Domain/`): Pure Swift. No UIKit/SwiftUI imports. Models, UseCases, and enums only.
- **Data** (`Data/`): Persistence (SwiftData) and networking (Supabase). Repository pattern.
- **Services** (`Services/`): Protocol-defined. Each service has `{Name}ServiceProtocol` + concrete implementation.

## Swift & Concurrency Rules
- Use `@Observable` (Observation framework), NOT `ObservableObject`/`@Published`/Combine for new code.
- All I/O uses `async/await`. No `DispatchQueue.main.async` unless wrapping a legacy callback API.
- Use `@ModelActor` for background SwiftData operations.
- Use `@MainActor` only on ViewModels and UI-bound properties.
- Never block the main thread.

## Naming Conventions
- Files: `{Feature}{Layer}.swift` (e.g., `DashboardView.swift`, `DashboardViewModel.swift`)
- Models: singular nouns (`MealLog`, not `MealLogs`)
- Services: `{Noun}Service` with matching `{Noun}ServiceProtocol`
- Views: `{Feature}View`
- ViewModels: `{Feature}ViewModel`

## Security Rules
- NO API keys, secrets, or tokens in client code. Ever.
- All AI calls go through Supabase Edge Functions.
- Supabase anon key is the ONLY key in client (it's designed to be public).
- All sensitive operations require server-side validation (subscription status, rate limits).

## Subscription Rules
- App is premium-only. No free tier.
- StoreKit 2 native. No RevenueCat.
- `Transaction.currentEntitlements` is the source of truth.
- PaywallView is a hard gate (no dismiss).

## Error-Fix Loop
When build errors occur:
1. Errors are provided in format: `[file:line:col] error: message`
2. Identify root cause
3. Output the COMPLETE corrected file(s)
4. Brief explanation of what changed and why
5. No partial edits, no diffs

## Testing Rules
- Every ViewModel gets a test file in `MACRATests/ViewModelTests/`
- Every Service gets a test file in `MACRATests/ServiceTests/`
- Every View gets a SwiftUI Preview
- Use protocol-based mocks for testing
