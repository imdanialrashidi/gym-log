<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, sections 1-11.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 1. Executive Summary

**What it is (Confirmed).** A local-first Android app for logging resistance training. It is simple enough that anyone understands it immediately, fast enough to feel instant, and designed dark-first with a modern, professional look. Users log **weight, reps, and RIR** in numeric fields, define **rep ranges** per exercise, see **progress charts**, and get a small set of **explainable, rule-based suggestions** (prefill from last session, double progression, and personal-record detection).

**What it is not (Confirmed).** No backend, no account, no cloud, no LLM, no free-text parsing of sets, no bundled exercise images, no ads, no subscription.

**Who it is for (Confirmed).** You and your friends first. It will be published on GitHub, free, with a donation link. Persian is the primary UI language; English is also supported.

**How it will be built (Confirmed).** Flutter (Android only, phones), using agentic AI tools, in a codebase designed so that adding features is cheap and updates never damage user data.

**Assessment (Recommendation).** **Go** for the stated purpose (a high-quality personal and community tool). **Conditional Go** if the goal later becomes broad public adoption, because the market is crowded and growth would need evidence. Details in Section 9.

**The three things that will decide whether this succeeds:**

1. **Data safety across updates.** Migrations, signing-key custody, and import/export must be treated as the core engineering problem, not an afterthought (Section 23).
2. **Speed of logging.** The product wins or loses on how few taps it takes to record a set (Section 17).
3. **Scope discipline.** The confirmed feature list is already large for an MVP. The roadmap includes a de-scope gate (Section 33).

### 1.1 One-page project snapshot

| Item | Value |
|---|---|
| Platform | Android phones, Flutter [Confirmed] |
| Minimum Android | API 24 (Android 7.0), the current Flutter floor [S14] [Assumption] |
| Data | On-device SQLite via Drift; no server [Recommendation] |
| Languages | Persian (primary, RTL), English [Confirmed] |
| Theme | Dark by default [Confirmed] |
| Price | Free; donation link in About only [Confirmed] |
| Distribution | GitHub Releases (signed APK) [Confirmed: GitHub]; F-Droid, Cafe Bazaar, Myket [Needs Decision] |
| Intelligence | Rule-based, offline, explainable. No LLM [Confirmed] |
| MVP smart features | Prefill from last session, double progression, PR and e1RM detection [Confirmed] |
| Export format | JSON (full backup and restore) [Confirmed] |
| Network | Only an optional hand-off to the browser for exercise lookup and donation link [Confirmed concept] |
| Recurring cost | $0 required [Recommendation] |

### 1.2 How your replies were interpreted (please verify)

| Your reply | Interpretation used in this spec | Status |
|---|---|---|
| 1. Remove LLM; add first three Level-1 items | LLM is **Out of Scope**. In MVP: prefill from last session, double progression, PR detection with e1RM. | Confirmed |
| 2. No text entry; numeric/selectable fields | Structured numeric inputs and chips. The earlier "text-based logging" idea and the text parser are dropped. | Confirmed |
| 3. Tap exercise, open Google Images for its name | Exercise lookup opens a Google image search for the exercise name (e.g. "bench press"). | Confirmed |
| 4. "Add all" (data safety section) | All six data-safety measures are included as Must (Section 23). | Confirmed |
| 5. JSON | JSON is the backup/restore format. CSV history export is an optional extra. | Confirmed (JSON); CSV is Could |
| 6. "OK, all of it" (Persian section) | RTL, Vazirmatn, digit setting, Jalali calendar display, kg/lb, string resources. | Confirmed |
| 7. "OK, all of it, but Flutter" | Agent-friendly architecture, tests, CI, `AGENTS.md`, adapted to Flutter. | Confirmed |
| Name not decided; wants name visible in many places | Naming and "name visibility" plan in Section 29. | Confirmed (goal); name is Needs Decision |
| Optional per-session progress photo | Optional photos attached to a session. | Confirmed |
| Optional per-exercise photo; but prefer search | Optional user-picked image per exercise; search is the primary way to see the movement. | Confirmed |
| Muscle-group label, target-vs-actual RIR, rest timer, notes, warm-up flag, min Android version | Not explicitly answered. Included as **Assumptions** adopting my recommendations. | Assumption |

---

## 2. Product Vision

> **Open the app, do the set, tap once, move on.**

The app is a training notebook that remembers everything and quietly helps you progress. It never nags, never asks you to sign in, never sends your body or training data anywhere.

**Design principles (Recommendation, derived from your requirements):**

1. **One screen, one job.** The workout screen is for logging. Nothing else competes with it.
2. **Prefilled by default.** The user should usually only confirm, not type.
3. **Offline is a feature.** There is no spinner anywhere because nothing waits on a network.
4. **Explainable intelligence.** Every suggestion states its reason in one sentence.
5. **Your data is yours, and it survives updates.** Export is always one tap away; updates never wipe data.
6. **Quiet confidence in tone.** No hype, no "AI" claims for rule-based features.

---

## 3. Problem Definition and Evidence

**Problem (Assumption, based on your brief):** Lifters who want to apply progressive overload and rep-range training need to remember last session's numbers while their phone is in hand between sets. Notebooks and spreadsheets are slow. Many apps are heavy, account-based, ad-supported, or paywalled, and Persian-first experiences appear rare (to be verified).

**Evidence collected in this research pass:**

- Mainstream trackers commonly gate features: Hevy's free tier caps routines, custom exercises, and graph history [S2]; Strong's free tier caps custom routines [S3]; JEFIT's free tier is ad-supported with paid tiers [S1][S4]; Fitbod has no free tier [S3]. These caps are exactly the friction an unlimited, free, offline tool can avoid. (Several sources are published by competitors or app vendors, so treat them as indicative. Prices were quoted as of mid-to-late 2026.)
- A free, ad-free, offline Android-only logger already exists (FitNotes) and is praised for minimal friction [S5]. This validates demand for the "simple offline log" niche and also means the niche is not empty.
- Rep-range progression ("add reps, then add weight") is a widely used, simple, explainable method [S22] and is already implemented in at least one major app's auto-progression feature [S10]. It is a proven pattern, not a novelty.
- **Persian-first gap: Unverified.** A search of Cafe Bazaar developer pages returned mostly generic home-workout apps [S29], which is inconclusive. A manual store survey is required (Experiment E0, Section 36).

**Honest limitation:** I found no reliable independent data on how many people would use a Persian-first lifting log. No market-size figure is given, because any number would be invented. For a personal, free, open-source project, market size is not the deciding variable; usefulness to you and your friends is.

---

## 4. Target Market, Segments, Personas, and Jobs to Be Done

### 4.1 Beachhead (Recommendation)

**You plus your gym friends**, then Persian-speaking lifters who find the project on GitHub or a local store. There is no growth target. Success is that the circle actually uses it every session.

### 4.2 Ideal user profile (Assumption)

Intermediate-level lifter, trains 3 to 6 days per week, follows a split or program, understands sets, reps, and RIR, owns a mid-range Android phone, and is frustrated with paywalls or heavy apps.

### 4.3 Personas (Assumption)

| Persona | Description | Key need |
|---|---|---|
| **Ali, the program follower** | Runs a push/pull/legs split with fixed rep ranges | See last session's numbers instantly; know when to add weight |
| **Sara, the RIR-minded lifter** | Trains by effort and logs RIR | Log RIR without friction; see RIR trends |
| **Reza, the sharer** | Shares programs with friends | Export a program or backup file and import it elsewhere |
| **Maryam, the visual tracker** | Wants to see physical change | Optional session photos; private by default |

### 4.4 Jobs to Be Done

1. *When I'm between sets,* **I want my last numbers shown and one tap to log,** so I don't lose rhythm.
2. *When I finish a session,* **I want to know if I progressed,** so I can adjust next time.
3. *When I forget what a movement is,* **I want to see it quickly,** so I perform it correctly (via image search).
4. *When I change phones or reinstall,* **I want my history back,** so years of training aren't lost.
5. *When a friend asks for my program,* **I want to send it as a file.**

---

## 5. Customer Journey and Main Use Cases

**First run (target: under 60 seconds to first logged set):**
Open app → no sign-in → choose language (Persian default if device is Persian) → create or pick an exercise → log a set.

**Typical session:**

1. Open app. The Workout tab shows the next planned day (or "Start empty workout").
2. Tap **Start**. Exercises appear in order, each with its target (sets × rep range, optional target RIR) and a one-line suggestion.
3. For each set, weight, reps, and RIR are **prefilled** from last time (or from the suggestion). Adjust with steppers or tap-to-type, then tap ✓.
4. A rest timer starts (optional). A PR badge appears if a record was set.
5. Tap **Finish**. Optionally attach a session note or photo.
6. History and charts update immediately.

**Use cases (Must unless noted):** log a session; build a program (days → exercises → target sets and rep range); view history; view per-exercise progress; look up an exercise image; export/import backup; change language/units/theme. **Should:** rest timer, notes, warm-up flag, photos.

---

## 6. Market Demand and Opportunity Assessment

- **Demand signal (Verified, indirect):** Multiple large vendors compete on pricing tiers, and free tiers are consistently capped or ad-supported [S1][S2][S3][S4]. A segment of users seeks free, no-ads, offline logging [S5].
- **Adoption barriers:** Switching cost (existing history in another app), habit, and trust in a new tiny project. The JSON and CSV import story partly mitigates this, but importing from other apps is **Out of Scope** for now.
- **Realistic opportunity:** A high-quality, open-source, Persian-first logger for a niche community. **Not** a plan to displace Hevy or Strong.
- **Market size:** Not estimated (no reliable data; see Section 3). A bottom-up proxy for success is "number of friends who log at least 3 sessions per week for 8 weeks."

---

## 7. Competitor and Substitute Analysis

All prices are as quoted by the cited pages in mid-to-late 2026. Verify before quoting publicly.

| Product | Model | Relevant facts | Gap relative to this project |
|---|---|---|---|
| **Hevy** | Freemium, social | Free tier: unlimited logging but capped at 4 routines, 7 custom exercises, 3 months of graph history; Pro $2.99/mo, $23.99/yr, or $74.99 lifetime [S2] | Account and cloud oriented; caps on free tier; social focus |
| **Strong** | Freemium, minimalist | Free tier: unlimited logs and full history, no ads, 3 custom routines; Pro $29.99/yr or $99.99 lifetime [S3] | Routine cap; not Persian-first (Unverified) |
| **JEFIT** | Freemium, ad-supported | Free ad-supported tier; Elite $12.99/mo or $69.99/yr [S1][S4] | Heavier, ads, paid plans |
| **Fitbod** | Subscription | $15.99/mo or $95.99/yr; no free tier [S3] | Paid, generated workouts (different job) |
| **FitNotes** | Free, Android-only | Ad-free, offline, calendar log, CSV export [S5][S7]; listed as proprietary and English-only [S6] (sources conflict on whether a paid upgrade exists) | **Closest direct competitor.** Not open source; no Persian (Unverified); older design |
| **Boostcamp** | Free app with program library | Auto-progression using double progression for rep-range sets [S10] | Program-library oriented; account-based |
| **wger (Flutter app)** | Open source | Talks to a server over REST [S8] | Needs a server; broader scope (nutrition, weight) |
| **Liftosaur** | Open source, scriptable | Reported by community users as open source with scripting [S9] (low-reliability source) | Power-user scripting; different audience |
| **Notebook / spreadsheet** | Substitute | Free, flexible, slow to use mid-workout | Main substitute for friends |

**Competitive takeaway (Inference):** The closest competitor is FitNotes. The meaningful differentiators available to you are: **open source, modern dark UI, Persian-first with RTL and Jalali dates, rep-range plus RIR as first-class concepts, explainable progression, and a verified data-safety story.** "Unlimited and free" is **not** a differentiator against FitNotes or Strong's generous free tier, so do not lead with it.

---

## 8. Competitive Positioning and Differentiation

**Positioning statement (Recommendation):**
*For lifters who train by rep ranges and RIR, [NAME] is a free, offline Android workout log that remembers your last session, tells you when to add weight, and keeps your data on your phone. Unlike account-based apps, it never needs the internet, and unlike notebooks, it never loses a number.*

**Defensibility:** Low in the commercial sense (features are copyable). The real moat for an open-source project is **trust and craft**: reliability across updates, speed, and polished Persian UX. That is why Sections 22 and 23 are given so much weight.

**Claims to avoid (Constraint):** "Only Persian lifting app", "AI-powered", "scientifically optimal", "guaranteed progress", "best". None can be verified.

---

## 9. Go / Conditional Go / Pivot / No-Go

| Objective | Assessment | Reason |
|---|---|---|
| Personal and friends tool, open source, free | **GO** | Technically low-risk, no recurring cost, clear scope, high learning value |
| Public growth objective (stars, downloads, stores) | **CONDITIONAL GO** | Crowded market; depends on conditions below |

**Conditions (Recommendation):**

1. **C1:** Signing-key custody plan exists *before* the first public APK (Section 23).
2. **C2:** Migration tests run in CI from the first schema version (Section 23).
3. **C3:** Friend test shows logging a set is at least as fast as a notebook (Section 36).
4. **C4:** E0 store survey does not reveal a mature, free, open-source, Persian-first equivalent. If it does, **Pivot** toward contributing or differentiating on a specific strength.
5. **C5:** License chosen (Section 28).

**Stop conditions:** If after the logging milestone (M3) the friend test shows the app is slower than a notebook, pause all new features until the logging flow is redesigned. If data-safety tests cannot be made to pass in CI, do not release publicly.

---

## 10. Business Model and Revenue Logic

- **Model (Confirmed):** Free. Donation link displayed in the About screen and the project website. No ads, no subscription, no in-app purchase.
- **Revenue goal (Assumption):** None. Donations are a thank-you, not a plan.
- **Donation mechanics (Needs Decision):** Which donation platform to use depends on where you and your supporters can legally and practically send and receive money. I did not verify which platforms are available to you. Seek local legal advice. The app only opens an external link; it contains no payment code.
- **Cost to run (Recommendation):** $0 recurring. Optional costs are listed in Section 34.
- **Sustainability risk:** Maintenance burden grows with users. Mitigation: keep scope small, document well, accept contributions via small issues.

---

## 11. Pricing and Packaging

Single free package. There is no paid tier, trial, or feature lock. **Recommendation:** never add one without revisiting the positioning; the "no paywall" promise is part of the brand.

---
