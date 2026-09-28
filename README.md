# Odyssey Atmosphere

> **Adapted from [Hydropunk Atmosphere](https://github.com/terrizoaguimor/omarchy-hydropunk-atmosphere)
> by [terrizoaguimor](https://github.com/terrizoaguimor), MIT licensed.**
>
> The Hydropunk Atmosphere plugin is the original work: the concept, the panel
> and bar-widget architecture, the audio mixing model, the shader pipeline, and
> the seamless-loop acceptance criteria. Odyssey Atmosphere is an edited
> derivative of it, made by Kevin Watkins. All original credit for Hydropunk
> Atmosphere belongs to terrizoaguimor.
>
> What this derivative changes: long-form playback via `MediaPlayer`, a
> one-track-at-a-time crossfaded queue in place of the three-stem mixer, a
> public-domain classical tracklist, and a rebuilt manifest. Everything
> credited above is theirs.

Public-domain classical music for the Omarchy screensaver, crossfaded one track
at a time. A bar widget opens a small panel where a **scene** selector changes
the wallpaper and the music together.

This plugin adds a bar widget and a panel alongside its background service. It
has **no runtime dependencies** — no other plugin, no network access, no build
step, no shell-outs. If the Hydropunk Atmosphere plugin is also installed, the
two simply share the screen; Odyssey Atmosphere works on its own without it.

## Install

```bash
omarchy plugin add <this-repo-url>
omarchy plugin enable io.github.mkultrausa.odyssey-atmosphere
```

## Use

Sound **never autoplays**. It starts only when you ask for it.

Click the red lens in the bar for the panel:

- **SCENE** — switches wallpaper and music together, the way the base plugin
  couples a scene to an audio preset
- **SOUND** — play/pause, previous, next, with the current track shown

Or drive it from the command line:

```bash
omarchy-shell odyssey play       # start
omarchy-shell odyssey pause      # stop
omarchy-shell odyssey next       # crossfade to the next track
omarchy-shell odyssey previous   # crossfade to the previous track
omarchy-shell odyssey setscene lens
omarchy-shell odyssey status     # scene, track, position, duration
```

## Remove

```bash
omarchy plugin disable io.github.mkultrausa.odyssey-atmosphere
omarchy plugin remove io.github.mkultrausa.odyssey-atmosphere
```

To uninstall completely, delete the plugin directory as well:

```bash
rm -rf ~/.config/omarchy/plugins/io.github.mkultrausa.odyssey-atmosphere
```

The plugin stores no state outside its own directory. It reads no user
configuration and writes none, so removal leaves nothing behind. Audio is
bundled in the repository, so there is no cache to clear.

## Scenes

A scene pairs a picture with a track, so picking one changes both. Three scenes
cannot own six tracks, so a separate track selector keeps every loop reachable
and a scene is a starting point rather than a cage.

| Scene | Wallpaper | Starts on |
|---|---|---|
| `lens` | `01-lens.webp` | Satie, Gymnopédie No. 1 |
| `monolith` | `03-monolith.webp` | Beethoven, Eroica II, Marcia funebre |

## How it plays music

Two deliberate departures from the Hydropunk Atmosphere plugin, both forced by
the fact that this is music rather than ambience.

**`MediaPlayer`, not `SoundEffect`.** `SoundEffect` is QtMultimedia's
low-latency API for short sounds. The Hydropunk plugin only ever feeds it
12–47 s ambient beds, and it will not sustain a longer piece: playback ends
after one pass while the plugin still reports `playing: true` with no error. A
screensaver that silently stops is worse than one that never starts, so this
uses `MediaPlayer`, which is built for long-form playback and exposes real
`duration` and `position`.

**One track at a time, not three stems.** The base plugin's mixer is three
`SoundEffect` beds — rain, water, wind — with independent per-stem gain,
designed to layer. Three classical melodies at once is mud, not a mix. Playing
one at a time is both simpler and correct, and it has a useful side effect: the
base plugin's `>= 1.5 s` loop-length spacing rule exists only to stop three
stems falling back into phase on a shared period. With a single player, no two
loops ever sound together, so the constraint does not apply.

Each track plays for `duration × repeatsPerTrack` (default 2) and then
crossfades over 4 s into the next.

## The audio

Six tracks, ordered so the arc runs spare → dark → vast → warm → stark →
floating. All are public-domain classical recordings, redistributed from
Wikimedia Commons and the Internet Archive's Musopen collection.

Every track is a verified seamless loop: bar-snapped length, equal-power
crossfade, static gain to −24 LUFS integrated, true peak well under −3 dBTP, and
a chroma join cosine above 0.98 so the harmony matches across the wrap.

**The recordings are public domain. The compositions always were.** These are
different claims and only the first one is generous — a public-domain
composition does not imply a public-domain recording, so each recording was
checked individually. Per-track provenance, source URLs, and sha256 sums are in
[`AUDIO-LICENSING.md`](AUDIO-LICENSING.md), which is **not** covered by the MIT
licence in [`LICENSE`](LICENSE).

The bundled `.wav` files are derived works, not the original recordings. The
derivation recipe and the acceptance criteria are documented in
`AUDIO-LICENSING.md`.

## Credits and dependencies

**Runtime dependencies: none.** No other Omarchy plugin, no network service, no
external binary, no shell command. The plugin is a single QML service plus
bundled audio.

**Original work:** Hydropunk Atmosphere — concept, panel and bar-widget
architecture, audio mixing model, shader pipeline, and loop acceptance criteria
— © [terrizoaguimor](https://github.com/terrizoaguimor), MIT licensed.
Odyssey Atmosphere is an edited derivative and does not vendor or re-skin it; no
code, artwork, or audio from the original is redistributed here. The two can be
installed together or separately.

**This derivative:** `MediaPlayer` playback in place of `SoundEffect`, a
one-at-a-time crossfaded queue in place of the three-stem gain mixer, a
public-domain classical tracklist, a scene layer pairing wallpaper with music,
and a bar widget and panel whose structure follows the base plugin's — by
Kevin Watkins.

**Bundled third-party assets:** six public-domain classical recordings, carried in
`assets/audio/`. These are the only non-original files in the repository. Each
one's source URL, licence, and sha256 is recorded in
[`AUDIO-LICENSING.md`](AUDIO-LICENSING.md), which is **not** covered by the MIT
licence in [`LICENSE`](LICENSE).

## Marketplace listing

- **Category:** `Appearance`
- **Tags:** `media`, `quickshell`
