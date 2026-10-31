# Gym Log landing page

Static landing page for the Android app, served from this directory by the
`pages` GitHub Actions workflow. There is no build step at deploy time and no
runtime dependency: HTML, CSS, the small vanilla script, subset fonts, and
optimized screenshots are all committed.

- URL: <https://imdanialrashidi.github.io/gym-log/>
- Screenshots: optimized, committed derivatives in `assets/img/screens/`
  (rendered from the app; the original poster kit is local-only)
- Brand sources: `assets/branding/`
- App source: <https://github.com/imdanialrashidi/gym-log>

## Release updates

The release page is intentionally static. When a new APK ships, update the
version and asset values in `site/index.html`:

1. Search for `v0.2.1` and replace the two direct download links, the release
   page link, the displayed version, build number, date, size, and schema data.
2. Replace the SHA-256 value in the `data-copy` attribute and the visible
   checksum text from the release's `.sha256` asset.
3. Update `site/sitemap.xml` and the JSON-LD `softwareVersion` if the version
   changes.
4. Run `python3 tool/site/check_site.py` before committing.

## Image assets

The screenshots in `assets/img/screens/` are committed Web derivatives of the
app's poster captures. Each has 400 px and 800 px AVIF and WebP variants.
Existing assets were generated with ImageMagick, for example (run from a
checkout that has the local poster kit):

```sh
convert poster/screens/01_workout.png -resize 800x -strip -quality 58 \
  site/assets/img/screens/01_workout-800.avif
convert poster/screens/01_workout.png -resize 800x -strip -quality 82 \
  -define webp:method=6 site/assets/img/screens/01_workout-800.webp
```

The fonts in `assets/fonts/` are Vazirmatn Regular, Medium, and Bold subset to
the characters used by the page. The license is included in that directory.
When copy changes, regenerate the subsets with `pyftsubset` (fontTools) using
`--flavor=woff2` and a text file containing the page copy.

## Deployment

`.github/workflows/pages.yml` validates the local references and deploys this
directory to GitHub Pages on every push to `main` that changes `site/` or the
workflow itself. The workflow pins its actions by commit SHA.
