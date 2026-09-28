# Audio licensing and provenance

Every track in `assets/audio/` is a public-domain classical recording, redistributed from Wikimedia Commons or the Internet Archive's Musopen collection. The **compositions** are long out of copyright. The **recordings** are public-domain or CC0 transfers - a public-domain composition does not imply a public-domain recording, so each recording was checked individually.

This file is not covered by the MIT licence in `LICENSE`.

## Tracks

### `satie-gymnopedie-1-loop-32s.wav`

- **Source title:** Erik Satie - gymnopedies - la 1 ere. lent et douloureux.ogg
- **Licence:** Public domain
- **Source URL:** https://upload.wikimedia.org/wikipedia/commons/9/90/Erik_Satie_-_gymnopedies_-_la_1_ere._lent_et_douloureux.ogg
- **Derived loop:** 34.3s, 17 bars, -23.99 LUFS, -7.71 dBTP

### `ia-suk-meditation-loop-36s.wav`

- **Source title:** JosefSuk-Meditation
- **Licence:** Public Domain Mark 1.0
- **Licence URL:** https://creativecommons.org/publicdomain/mark/1.0/
- **Source URL:** https://archive.org/download/MusopenCollectionAsFlac/Suk_Meditation/JosefSuk-Meditation.flac
- **Derived loop:** 36.3s, 17 bars, -24.0 LUFS, -8.88 dBTP

### `tchaikovsky-pp-1-loop-38s.wav`

- **Source title:** Tchaikovsky, Symphony No. 6 In B Minor, Op. 74, 'Pathetique' - I. Adagio, Allegro Non Troppo.ogg
- **Licence:** Public domain
- **Source URL:** https://upload.wikimedia.org/wikipedia/commons/b/b7/Tchaikovsky%2C_Symphony_No._6_In_B_Minor%2C_Op._74%2C_%27Pathetique%27_-_I._Adagio%2C_Allegro_Non_Troppo.ogg
- **Derived loop:** 38.0s, 21 bars, -24.0 LUFS, -9.43 dBTP

### `albinoni-oboe-adagio-loop-41s.wav`

- **Source title:** Albinoni, Concerto for Oboe and Strings No. 2 in D minor, Op. 9, II. Adagio.ogg
- **Licence:** CC0 1.0
- **Licence URL:** http://creativecommons.org/publicdomain/zero/1.0/deed.en
- **Source URL:** https://upload.wikimedia.org/wikipedia/commons/d/da/Albinoni%2C_Concerto_for_Oboe_and_Strings_No._2_in_D_minor%2C_Op._9%2C_II._Adagio.ogg
- **Derived loop:** 40.9s, 16 bars, -24.0 LUFS, -10.7 dBTP

### `eroica-marcia-funebre-loop-46s.wav`

- **Source title:** Beethoven - Symphony No. 3 in E flat major, Op. 55 'Eroica' - II. Marcia funebre. Adagio assai (Musopen Symphony).flac
- **Licence:** Public domain
- **Derived loop:** metrics pending - not present in the current evaluation report
- **Note:** source URL absent from the current evaluation report; see `facts/candidate-manifest.json` in the project repository.

### `ia-mendelssohn-scottish-adagio-loop-59s.wav`

- **Source title:** FelixMendelssohn-SymphonyNo.3InAMinorscottishOp.56-03-Adagio
- **Licence:** Public Domain Mark 1.0
- **Licence URL:** https://creativecommons.org/publicdomain/mark/1.0/
- **Source URL:** https://archive.org/download/MusopenCollectionAsFlac/Mendelssohn_ScottishSymphony/FelixMendelssohn-SymphonyNo.3InAMinorscottishOp.56-03-Adagio.flac
- **Derived loop:** 59.4s, 16 bars, -24.0 LUFS, -5.61 dBTP

## Derivation

The bundled `.wav` files are derived works produced by the project's own pipeline, not the original recordings. The recipe is the same one the Hydropunk Atmosphere plugin uses for its ambient stems:

1. high-pass 60 Hz, low-pass 12 kHz
2. cut a window at a whole number of bars for the detected meter
3. equal-power crossfade the ends together (3 s)
4. static gain to -24 LUFS integrated
5. tanh peak knee

Acceptance criteria, verified for all 38 evaluated candidates:

- stereo PCM16 at 44.1 kHz
- integrated loudness -24 LUFS +/- 0.6
- true peak <= -3 dBTP
- loop seam step within the signal's own 99.9th-percentile intersample step
- |20*log10(rms(head 20ms) / rms(tail 20ms))| < 3 dB
- chroma join cosine >= 0.98, loop length a whole number of bars

## Attribution

Musopen recordings are in the public domain; the Internet Archive's `MusopenCollectionAsFlac` item is marked Public Domain Mark 1.0. Credit to the original performers is not recorded in the upstream manifests, so none is claimed here. Composers are named in the source titles above.

