# Profile assets

Two kinds of artwork live here, and they reach GitHub by two different routes.
That distinction is the reason this file exists: half of these files are
referenced by a URL you can follow, and half are uploaded by hand into a
settings page where nothing links to them.

## The mark — referenced from the profile

- `mark.svg` — light scheme.
- `mark-dark.svg` — dark scheme.

Both are pulled by [`profile/README.md`](../README.md) through a `<picture>`
element with a `prefers-color-scheme` source, using absolute
`raw.githubusercontent.com` URLs pinned to `main`. They render at 112px on the
org profile; the file is a 256×256 viewBox so it stays sharp above that.

Changing either file changes the org profile the moment it lands on `main` —
there is no build step and no cache to bust.

## The avatar — uploaded by hand

- `avatar.svg` / `avatar-dark.svg` — 256×256 viewBox, rendered at 1024×1024.
- `avatar.png` / `avatar-dark.png` — 1024×1024 raster, exported from the SVGs.

**Nothing in this repository references these four files, and that is expected.**
GitHub organization avatars are uploaded through
`Settings → Profile → Profile picture`, which takes an upload rather than a URL,
and accepts raster only — which is why the PNGs exist alongside the SVGs that
produced them.

So these files are the *source of truth* for an image that lives somewhere this
repo can't reach. If you change the avatar here, the org profile does not
change until someone re-uploads the PNG. If you change it in the settings page
without updating these files, this directory silently becomes wrong.

Keep them in sync, or delete them and accept that the avatar has no source.

## Palette

Both schemes use the same three values: paper `#F4F1EA` (light) / `#0d1117`
(dark, matching GitHub's dark canvas), ink `#182433`, and the sea-blue that
distinguishes the third bearing line. The mark is three lines crossing pairwise
around the small triangle they enclose — the cocked hat, where the fix lives.
