# SCREEN INVENTORY — Qyra iOS App

---

## App Gate Screens

| Screen | File | Entry Point | States | Audit Status | Issues |
|--------|------|-------------|--------|-------------|--------|
| Launch Screen | App/LaunchScreenView | App launch | loading | Pending | — |
| Landing | UI/Landing/LandingView | needsAuth gate | unauthenticated | Pending | — |
| Sign In | UI/Auth/SignInView | Landing CTA | default, loading, error | Pending | Dev skip button, stub Google/Email |
| Paywall | UI/Paywall/PaywallView | needsSubscription gate | loading, products loaded, fallback, purchasing, error | Pending | MACRA URLs, static fallback |
| Paywall Feature List | Views/Paywall/PaywallFeatureListView | Paywall sub-view | default | Pending | MACRA URLs |

## Onboarding (33 Steps)

| Step | Screen | File | Issues |
|------|--------|------|--------|
| splash | SplashView | UI/Onboarding/ | Pending |
| welcome | WelcomeView | UI/Onboarding/ | Skipped in flow |
| signIn | SignInView | UI/Auth/ | Stub buttons |
| nameEntry | NameEntryView | UI/Onboarding/ | Pending |
| lastNameEntry | LastNameEntryView | UI/Onboarding/ | Pending |
| usernameEntry | UsernameEntryView | UI/Onboarding/ | Simulated availability check |
| gender | GenderSelectionView | UI/Onboarding/ | Pending |
| workouts | WorkoutFrequencyView | UI/Onboarding/ | Pending |
| attribution | AttributionSourceView | UI/Onboarding/ | Pending |
| previousApps | PreviousAppsView | UI/Onboarding/ | Pending |
| longTermResults | LongTermResultsView | UI/Onboarding/ | macraLine function names |
| heightWeight | HeightWeightView | UI/Onboarding/ | Pending |
| birthday | BirthdayView | UI/Onboarding/ | Pending |
| coach | CoachQuestionView | UI/Onboarding/ | Pending |
| goalSelection | GoalSelectionView | UI/Onboarding/ | Pending |
| gainComparison | GainComparisonView | UI/Onboarding/ | Skipped for cut/maintain |
| desiredWeight | DesiredWeightView | UI/Onboarding/ | Skipped for maintain |
| motivation | MotivationView | UI/Onboarding/ | Skipped for maintain |
| accomplishment | AccomplishView | UI/Onboarding/ | Pending |
| weightTransition | WeightTransitionView | UI/Onboarding/ | Pending |
| speedSelection | SpeedSelectionView | UI/Onboarding/ | Skipped for maintain |
| barriers | BarriersView | UI/Onboarding/ | Pending |
| dietType | DietTypeView | UI/Onboarding/ | Pending |
| caloriesBurned | CaloriesBurnedView | UI/Onboarding/ | Pending |
| trust | TrustView | UI/Onboarding/ | Pending |
| healthKitConnect | HealthKitConnectView | UI/Onboarding/ | Silent fail on denial |
| wearableConnect | WearableConnectOnboardingView | UI/Onboarding/ | Pending |
| calorieRollover | CalorieRolloverView | UI/Onboarding/ | Pending |
| allDone | AllDoneView | UI/Onboarding/ | Pending |
| planGeneration | PlanGenerationView | UI/Onboarding/ | Pending |
| planResults | PlanResultsView | UI/Onboarding/ | Pending |
| saveProgress | SaveProgressView | UI/Onboarding/ | Stub Google/Email buttons |
| onboardingPaywall | OnboardingPaywallView | UI/Onboarding/ | Pending |
| trialReminder | TrialReminderView | UI/Onboarding/ | Pending |
| referralCode | ReferralCodeView | UI/Onboarding/ | Skipped |
| ratingPrompt | RatingPromptView | UI/Onboarding/ | Pending |

## Main Tabs

| Screen | File | Entry Point | States | Audit Status | Issues |
|--------|------|-------------|--------|-------------|--------|
| Today Dashboard | Views/Main/Today/TodayDashboardView | Tab 1 | loaded, empty, loading | Pending | — |
| Today Macros Page | Views/Main/Today/TodayMacrosPageView | Carousel | default | Pending | — |
| Today Activity Page | Views/Main/Today/TodayActivityPageView | Carousel | default | Pending | — |
| Today Micronutrients | Views/Main/Today/TodayMicronutrientsPageView | Carousel | default | Pending | — |
| Progress Tab | Views/Main/Progress/ProgressTabView | Tab 2 | loaded, empty | Pending | — |
| Groups Tab | Views/Main/Groups/GroupsTabView | Tab 3 | loaded, empty, no groups | Pending | — |
| Profile Tab | Views/Main/Profile/ProfileTabView | Tab 4 | loaded | Pending | — |

## Sheets & Modals (from FAB)

| Screen | File | Presentation | Audit Status |
|--------|------|-------------|-------------|
| Camera (Food Scan) | UI/Camera/CameraView | fullScreenCover | Pending — no denial recovery |
| Barcode Scanner | UI/Scanner/BarcodeScannerView | sheet(.large) | Pending |
| Voice Log | UI/Voice/VoiceLogView | sheet | Pending |
| Exercise Type | UI/Exercise/ExerciseTypeView | sheet | Pending |
| Exercise Search | UI/Exercise/ExerciseSearchView | sheet | Pending |
| Workout Planner | UI/Exercise/WorkoutPlannerView | sheet | Pending |
| Log Food | UI/Search/LogFoodView | sheet(.large) | Pending |
| Quick Add | UI/Logging/QuickAddView | sheet | Pending |
| Create Versus | Views/Versus/CreateVersusView | sheet | Pending |
| FAB Menu | Components/FABMenuOverlay | overlay | Pending |

## Settings Hierarchy

| Screen | File | Audit Status |
|--------|------|-------------|
| Settings | UI/Settings/SettingsView | Pending — MACRA URLs |
| Profile Editor | UI/Settings/ProfileEditorView | Pending |
| Personal Details | UI/Settings/PersonalDetailsView | Pending |
| Goal Editor | UI/Settings/GoalEditorView | Pending |
| Preferences | UI/Settings/PreferencesView | Pending |
| Tracking Reminders | UI/Settings/TrackingRemindersView | Pending |
| Health Permissions | UI/Settings/HealthPermissionsView | Pending |
| Wearable Settings | UI/Settings/WearableSettingsView | Pending |
| My Subscription | UI/Settings/MySubscriptionView | Pending |
| Family Plan | UI/Settings/FamilyPlanView | Pending |
| Data Export | UI/Settings/DataExportView | Pending |
| AI Data Settings | UI/Settings/AIDataSettingsView | Pending |
| Weight History | UI/Settings/WeightHistoryView | Pending |
| PDF Report | UI/Settings/PDFReportView | Pending |
| Ring Colors | UI/Settings/RingColorsExplainedView | Pending |
| Widgets | UI/Settings/WidgetsView | Pending |
| Web Content | UI/Settings/WebContentView | Pending |

## Secondary Views

| Screen | File | Audit Status |
|--------|------|-------------|
| Intelligence Detail | Views/Intelligence/IntelligenceDetailView | Pending |
| Weekly Debrief | Views/Debrief/WeeklyDebriefView | Pending |
| Milestones | Views/Milestones/MilestonesView | Pending |
| Notifications | Views/Notifications/NotificationsView | Pending |
| Partner Code Entry | Views/Partner/PartnerCodeEntryView | Pending |
| Group Detail | Views/Groups/GroupDetailView | Pending |
| Group Leaderboard | Views/Groups/GroupLeaderboardView | Pending |
| Group Members | Views/Groups/GroupMembersView | Pending |
| Group Challenges | Views/Groups/GroupChallengesView | Pending |
| Group Chat | Views/Groups/GroupChatView | Pending |
| AI Coach | UI/Coach/ | Pending |
| Log Water Sheet | Views/Main/Today/LogWaterSheetView | Pending |
| Log Caffeine Sheet | Views/Main/Today/LogCaffeineSheetView | Pending |

---

*Total screens/states inventoried: 80+*
*Last updated: 2026-03-31*
