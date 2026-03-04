# MACRA — Launch Checklist

## Pre-Submission

### Apple Developer Account
- [ ] Enroll in Apple Developer Program ($99/year) at developer.apple.com
- [ ] Create App ID: `co.tamras.macra`
- [ ] Enable capabilities: HealthKit, In-App Purchases, Sign in with Apple
- [ ] Create App Group: `group.co.tamras.macra`

### App Store Connect Setup
- [ ] Create new app in App Store Connect
- [ ] Set bundle ID: `co.tamras.macra`
- [ ] Set primary language: English (US)
- [ ] Set category: Health & Fitness (primary), Food & Drink (secondary)

### Subscription Configuration
- [ ] Create subscription group: "MACRA Pro"
- [ ] Create Monthly product: `co.tamras.macra.pro.monthly` — $9.99
- [ ] Create Annual product: `co.tamras.macra.pro.annual` — $79.99
- [ ] Add subscription descriptions and review screenshots
- [ ] Set up Sandbox tester accounts for review

### Certificates & Provisioning
- [ ] Create distribution certificate
- [ ] Create App Store provisioning profile
- [ ] Set DEVELOPMENT_TEAM in project.yml
- [ ] Verify code signing works: `xcodebuild archive`

### Screenshots (6.7" iPhone 16 Pro Max — 1290 x 2796)
1. Dashboard with macro rings showing progress
2. Onboarding goal calculation screen
3. Manual meal entry form
4. Insights tab with weekly chart
5. Meal detail view with items
6. Settings / subscription screen

### App Review Information
- [ ] Provide demo credentials or Sandbox Apple ID
- [ ] Write review notes explaining subscription requirement
- [ ] Attach screenshot showing core functionality

## Submission

### Build
- [ ] Set DEVELOPMENT_TEAM in project.yml
- [ ] Increment build number if needed
- [ ] Archive: `xcodebuild archive -scheme MACRA -archivePath MACRA.xcarchive`
- [ ] Export for App Store: `xcodebuild -exportArchive`
- [ ] Upload via Xcode Organizer or `xcrun altool`

### App Store Connect
- [ ] Fill in app description (from AppStore.md)
- [ ] Add keywords
- [ ] Upload screenshots for all required device sizes
- [ ] Set pricing (Free with IAP)
- [ ] Add privacy policy URL: https://tamras.co/macra/privacy
- [ ] Add support URL: https://tamras.co/macra/support
- [ ] Submit for review

## Post-Launch

### Website
- [ ] Deploy landing page to tamras.co/macra
- [ ] Deploy privacy policy page
- [ ] Deploy terms of service page
- [ ] Update App Store link in landing page with real URL
- [ ] Set up support@tamras.co and privacy@tamras.co email

### Marketing
- [ ] Post launch announcement on social media
- [ ] Consider ProductHunt launch
- [ ] Prepare press kit with screenshots and app description

### Monitoring
- [ ] Monitor App Store Connect for crash reports
- [ ] Monitor App Store reviews
- [ ] Track subscription metrics in App Store Connect
- [ ] Plan v1.1 with barcode scanning and camera features
