<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 28.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 28. Open Decisions and Required Inputs

Quick-answer format: reply with the number and your choice, or "take your recommendation".

| # | Decision | Options | My recommendation |
|---|---|---|---|
| D1 | **Workflow Guide** | Send it | Needed to finalize Section 24 |
| D2 | **Project name** | See Section 29.2 | Choose from shortlist after collision check |
| D3 | **License** | MIT, Apache-2.0, GPL-3.0, AGPL-3.0 | If you want anyone to reuse freely: MIT or Apache-2.0. If you want improvements to stay open: GPL-3.0. I am not a lawyer; check dependency licenses (Vazirmatn is OFL [S23], shamsi_date BSD-3 [S24]) |
| D4 | **Import mode** | Merge only; Merge and Replace | Both, Replace auto-snapshots first (`IO-003`) |
| D5 | **Reference test device** | Which phone | The oldest and slowest one a friend owns |
| D6 | **Target RIR in plan items** | Include or skip | Include as Could |
| D7 | **Muscle-group tag** | Include (cheap now) or skip | Include as Should |
| D8 | **Rest timer** | In-app only; plus background notification | In-app only first |
| D9 | **Weight storage** | Integer grams; or double kg | Integer grams |
| D10 | **e1RM thresholds** | Show ≤ 10, hint 11 to 12, hide above | As stated in `INT-003` |
| D11 | **Optional RIR gate** in progression | Off; on at RIR ≥ 4 | Off by default |
| D12 | **Distribution beyond GitHub** | F-Droid, Cafe Bazaar, Myket | GitHub first; add channels after verifying signing and policies |
| D13 | **Donation platform** | Depends on your situation | Decide with legal and practical constraints in mind |
| D14 | **Photos in export** | Never; separate ZIP | Separate ZIP (Could) |
| D15 | **Persian search normalization rules** | Define set | Normalize ي/ی and ك/ک, ignore ZWNJ |
| D16 | **Chart axis direction in RTL** | Left-to-right time; mirrored | Left-to-right; test with friends |
| D17 | **Photo count per session** | 1, 3, unlimited | 3 |
| D18 | **Allow Android backup setting** | Off by default and hidden; or visible toggle | Visible toggle, default off |

---
