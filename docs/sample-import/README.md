# Sample import file

`program-sample.json` is a complete, valid Gym Log backup that contains
exercises and a two-day program but no workout history. It exists for two
reasons:

1. you can import it as-is to see how a program looks in the app, and
2. you can hand it to an AI assistant as the exact shape to copy when you want a
   custom program generated.

## Import it

1. Save the file on the phone (Downloads is fine).
2. Open Gym Log → **Settings** → **Data and backup** → **Import data**.
3. Pick the file, review the preview, and confirm.

The import validates everything before it writes: a typo in an id, a broken
reference, or an out-of-range rep count is rejected with a field name, and the
current data is left untouched.

## Ask an AI for a program

Paste the whole `program-sample.json` into the chat together with something
like:

> This is a Gym Log backup file. Keep the exact JSON shape and all required
> fields. Replace the exercises and the program with a 4-day upper/lower split
> for an intermediate lifter, 3 sets per exercise, 6–10 reps, 2.5 kg
> increments, kg units. Keep `sessions` empty and keep every id unique and
> lowercase. Return only the JSON, with no explanation and no code fence.

Then save the answer as a `.json` file and import it. If the assistant drops or
renames a field, the app rejects the file and names the field.

## The format in one page

Top level (all required unless noted):

| Field | Type | Notes |
|---|---|---|
| `schemaVersion` | integer | Must be `1`. Bump only if the format is redesigned. |
| `appVersion` | string | Free-form version that created the file, e.g. `"0.2.1"`. |
| `exportedAt` | string | UTC ISO-8601 timestamp, e.g. `"2026-01-05T09:00:00.000Z"`. |
| `generator` | string | `"gym-log"`. |
| `exercises` | array | See below. |
| `programs` | array | See below. |
| `sessions` | array | `[]` for a program-only file. |
| `settings` | object | See below. |
| `bodyWeights` | array | Optional; omit when empty. |

Exercise:

```json
{
  "id": "exercise-bench-press",
  "name": "Bench Press",
  "searchTerm": "bench",
  "muscleGroup": "chest",
  "defaultRepMin": 8,
  "defaultRepMax": 12,
  "incrementGrams": 2500,
  "archivedAt": null,
  "createdAt": "2026-01-03T09:00:00.000Z"
}
```

- `id`: `A–Z a–z 0–9 . _ -`, starts with a letter or digit, unique across
  exercises, programs, days, plan items, sessions, and body-weight entries.
- `name`: up to 120 characters.
- `searchTerm`: optional, up to 200 characters.
- `muscleGroup`: optional; one of `chest`, `back`, `shoulders`, `biceps`,
  `triceps`, `forearms`, `quadriceps`, `hamstrings`, `glutes`, `calves`,
  `abdominals`, `full_body`.
- `defaultRepMin` / `defaultRepMax`: optional, `1 <= min <= max <= 100`.
- `incrementGrams`: positive; weights are always integer grams.
- `archivedAt`: `null` or a timestamp.

Program, day, plan item:

```json
{
  "id": "program-upper-lower",
  "name": "Upper / Lower",
  "createdAt": "2026-01-04T09:00:00.000Z",
  "archivedAt": null,
  "days": [
    {
      "id": "day-upper",
      "name": "Upper",
      "sortOrder": 0,
      "items": [
        {
          "id": "item-upper-bench",
          "exerciseId": "exercise-bench-press",
          "targetSets": 3,
          "repMin": 8,
          "repMax": 12,
          "sortOrder": 0
        }
      ]
    }
  ]
}
```

- `exerciseId` must exist in `exercises`.
- `targetSets`: `1…100`; `repMin`/`repMax`: `1…100` with `repMin <= repMax`.
- `sortOrder`: integer, distinct within its list.

Settings:

```json
{
  "weightUnit": "kilograms",
  "restTimerEnabled": true,
  "restTimerDurationSeconds": 120
}
```

- `weightUnit`: `"kilograms"` or `"pounds"`. Increments and weights are always
  integer grams.
- `restTimerDurationSeconds`: `5…3600`.
- Optional: `weeklySessionGoal` (`1…14`), `weeklySetGoal` (`1…200`),
  `defaultIncrementGrams` (`1…1000000`), `digitStyle` (`"persian"` /
  `"latin"`).

Limits: the whole file must stay under 32 MB, nest at most 64 levels, and use
at most 500,000 containers. An import never merges by overwriting: same-id,
same-content records are duplicates, and same-id, different-content records keep
the local version (Replace is the explicit alternative).
