<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, sections 29-32.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 29. Branding and Visual Identity

### 29.1 Brand concept (Recommendation)

- **Personality:** calm, precise, quietly confident, like a well-kept training notebook.
- **Target impression:** "This is fast, serious, and it respects me."
- **Voice:** short, plain sentences; no hype; no exclamation marks in core UI; no gym-bro slang.
- **Never claim:** "AI-powered", "scientifically optimal", "guaranteed results", "the only Persian app".

### 29.2 Naming

**Status: Needs Decision.** No name has been cleared. Only the collisions below were actually found in this research pass, so a full clearance (GitHub, Google Play, Cafe Bazaar, Myket, domains, social handles, trademark databases) is still required.

**Criteria (Recommendation):** short (2 to 3 syllables); easy to type in Latin letters; works in Persian script and English; no meaning problems in Persian; not a generic phrase like "workout log" (poor discoverability); not confusable with existing apps.

**Collisions already found (avoid or differentiate):** Setgraph, Tamrena, TrackSet, One Set, Gym Log+, Workout Logger, RepCount, Stronger [S28]. Note that "Tamrena" is close to the Persian word for "exercise", so plain "Tamrin"-style names are crowded.

**Draft shortlist (all uncleared; my judgment, not data):**

| Candidate | Persian | Idea | Risks |
|---|---|---|---|
| **Ahanyar** | آهن‌یار | "Iron companion"; gym culture reference | The "-yar" suffix is very common in Iranian app names; clearance unchecked |
| **Bardar** | بردار | "Lift!" (imperative) | Also a mathematical term in Persian ("vector"); possible search noise |
| **Pelle** | پله | "Step": progression step by step | Generic word; likely crowded |
| **Repir** | ری‌پیر | Coined from "rep" and "RIR" | Pronunciation unclear to Persian readers; clearance unchecked |
| **Setyar** | ست‌یار | "Set companion" | Same "-yar" caveat; mixes English "set" with Persian |

**Process (Recommendation):** pick 3, run the clearance checklist (Section 37.3), test pronunciation with five friends, then decide. **Choose the name before the first public release because the applicationId depends on it** (Section 23.5).

### 29.3 Name visibility plan ("so the project becomes known")

Everything here is honest, opt-in, and low-cost. None of it is forced on users.

| Touchpoint | Action |
|---|---|
| GitHub | Repo name equals product name; clear one-line description; topics (e.g. workout, flutter, offline); social-preview image; README in English and Persian; screenshots in both languages |
| Releases | APK named `<name>-vX.Y.Z.apk`; release notes with plain-language changes; checksums |
| In app | Native launch screen with logo; About screen; no forced splash |
| Exported files | JSON includes a `generator` field with name and version; optional CSV header comment |
| Shareable summary card (Future Phase) | Opt-in image of a session or PR with a small wordmark; off by default; never auto-posted |
| Stores (if added) | Consistent name, icon, short description, screenshots |
| Website | Landing page with download, how-data-safety-works, donate link |
| Social | Same handle across platforms; **verify which platforms are accessible and used in your target community**, as I did not verify this |
| Friends | A 30-second screen-recorded demo is the best invitation |
| Avoid | Forced watermarks, fake reviews, spammy posting, unverifiable claims |

### 29.4 Visual identity (Recommendation)

> **Implementation note (2026-10-28):** the visual identity below is the
> original specification recommendation and is retained as historical input.
> The implemented contract is the achromatic Obsidian Telemetry system in
> [DESIGN.md](../DESIGN.md) and [PALETTE.md](../PALETTE.md); do not add a
> second palette from this table.

**Principles:** dark-first, high contrast, generous spacing, large touch targets, numbers as the hero, minimal chrome.

| Token | HEX | Use |
|---|---|---|
| Background | `#0E1116` | App background |
| Surface | `#161B22` | Cards, set rows |
| Surface 2 | `#1F2630` | Raised surfaces, input fields |
| Outline | `#2A3340` | Dividers, borders |
| Text primary | `#E8EDF2` | Main text, numbers |
| Text secondary | `#9AA7B5` | Labels, hints |
| Accent | `#3DDC97` | Primary actions, active tab |
| On-accent | `#06251A` | Text on accent buttons |
| Highlight (PR) | `#FFC44D` | PR badge, key stat |
| Danger | `#FF6B6B` | Delete, errors |
| Info | `#6AA9FF` | Hints, links |

All text and key controls must be checked against WCAG AA contrast (`NFR-A11Y-001`) with a contrast tool before the palette is locked. **Never use color alone to carry meaning** (for example RIR chips always show the number).

**Typography:** Vazirmatn for both Persian and Latin text (license in [S23]). Weights limited to Regular, Medium, Bold. Large numerals in set rows. Verify digit alignment (`L10N-003`).

**Layout and shape:** 8 dp spacing grid; 12 to 16 dp corner radii; 48 dp minimum touch targets; set rows tall enough for one-handed use.

**Motion:** short and purposeful (about 150 to 200 ms); a subtle highlight on PR; no confetti spam.

**Iconography:** rounded outline icons, one consistent set.

**Imagery:** none supplied by the app. The only photos are the user's own.

**Avoid:** neon overload, stock bodybuilder imagery, gamification clutter, red/green as the only signal.

---

## 30. Copywriting and Messaging System (drafts)

All copy is a **Recommendation**. Persian copy must be written or reviewed by a native speaker (`L10N-010`); Persian lines below are drafts.

**Positioning line:** A free, offline workout log for lifters who train by rep ranges and RIR.

**Headline options (EN):** "Every set, remembered." / "Log the set. Keep the rhythm." / "Your training notebook, upgraded." (Avoid phrases too close to existing taglines.)

**Headline options (FA, draft):** «هر ست، ثبت‌شده و در دسترس.» / «ثبت تمرین، بی‌حاشیه.»

**Supporting line:** "No account. No internet. No ads. Your data stays on your phone."

**Calls to action:** Download APK · View source · Export my data.

**Benefit statements:** Prefilled from last session · Add weight when it's time, with the reason shown · Records and estimated 1RM · Works fully offline · Export your data anytime.

**Trust signals:** Open source · No account · No ads · Works offline · Export and import · Release checksums.

**Objections and honest responses:**

| Objection | Response |
|---|---|
| "Why not Hevy or Strong?" | "They're good. This one is open source, fully offline, has no account, and is designed Persian-first. If you want social features or a large program library, those apps are a better fit." |
| "Is my data safe when I update?" | "Updates run tested migrations and take a snapshot first. You can also export a backup file at any time." |
| "Is it really free?" | "Yes. No ads, no subscription. There's a donation link if you want to support it." |
| "What does 'smart' mean?" | "Simple rules: it shows last session's numbers, tells you when your reps say it's time to add weight, and flags records. Each suggestion explains why. There is no AI." |
| "What if I change phones?" | "Export a backup file and import it on the new phone. Android's cloud backup is off by default to keep your data local." |

**GitHub README structure (primary landing page):** hero line + screenshot → three feature highlights → "How your data stays safe" → download and verify → quick start → FAQ → contribute → license → donate.

**Short description draft (store listing, 80 characters or fewer):** "Fast offline workout log with reps, RIR, rep ranges, and progress charts."

---

## 31. Go-to-Market and Distribution

### 31.1 Launch sequence (Recommendation)

1. **Stage 0, dogfood:** you use it for every session.
2. **Stage 1, friends (pre-release):** 3 to 5 friends install the pre-release APK from GitHub.
3. **Stage 2, public on GitHub:** polished README, screenshots, release notes, checksums.
4. **Stage 3, optional channels** (after verifying each channel's policy and signing behavior): F-Droid, Cafe Bazaar, Myket.

### 31.2 Channel notes

| Channel | What is known | Open items |
|---|---|---|
| **GitHub Releases** | Free for public repos. GitHub states it holds a U.S. government license to provide cloud services to developers in Iran [S25]. Earlier sanctions-related restrictions had blocked or limited Iranian developers' accounts [S25]. | **Verify the current terms and your account status.** Keep a local copy of the repo and keystore backups regardless. |
| **F-Droid** | Builds apps from source and publishes them; it rejects apps using Google Play Services or proprietary tracking such as Firebase or Crashlytics; the Flutter SDK is an accepted known binary source [S26]. | Verify Flutter build recipe requirements and the signing-key implications (23.5). F-Droid already lists a Flutter-based workout app, wger [S8]. |
| **Cafe Bazaar / Myket** | Large Persian-language Android stores. | **Unverified:** developer requirements, review rules, whether the store re-signs APKs, update behavior. Research before committing. |
| **Direct APK sharing** | Works for friends. | Users must allow installation from unknown sources (general Android behavior). Document it. |

### 31.3 Donation (Confirmed concept)

Link in About and on the website only. No pop-ups, no nag screens, no in-app payment code.

---

## 32. Acquisition, Activation, Retention, Referral

| Stage | Plan |
|---|---|
| **Acquisition** | Friends first via a 30-second demo; then GitHub README discoverability (clear description, topics, screenshots); optional store listings later |
| **Activation** | First set logged within 60 seconds; empty-state prompts; no sign-up |
| **Retention** | The product's own value: history, charts, PRs, suggestions. No push notifications; the export reminder is an in-app banner |
| **Referral** | Friends tell friends; the opt-in shareable card (Future Phase) |

Because there is **no analytics by design**, measurement is manual: friend interviews, a short feedback form, and GitHub issues.

---
