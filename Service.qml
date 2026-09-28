import Quickshell
import Quickshell.Io
import QtQuick
import QtMultimedia

// Odyssey Atmosphere — Phase 0+1 milestone.
//
// Audio only, on the existing Hydropunk visuals. Every track is a verified
// loop: -24 LUFS, true peak well under -3 dBTP, bar-snapped so the seam is
// musically invisible. See the design notes for provenance.
//
// Two deliberate departures from the base plugin:
//
//  1. MediaPlayer, not SoundEffect. SoundEffect is a low-latency API for
//     short sounds -- it is why the base plugin only ever feeds it 12-47s
//     ambient beds. It will not sustain a 32-59s piece of music; playback
//     ends after one pass and leaves the plugin believing it is still playing.
//
//  2. One track at a time, not the three-stem gain mixer. Those stems are
//     rain/water/wind, environmental beds built to layer. Three melodies at
//     once is mud. This also makes the base plugin's >=1.5s loop-length
//     spacing rule irrelevant, since no two loops ever sound together.

Item {
  id: root

  readonly property url assetBase: Qt.resolvedUrl("assets/audio/")

  // Ordered so the arc runs spare -> dark -> vast -> warm -> stark -> floating.
  readonly property var tracks: [
    "satie-gymnopedie-1-loop-32s.wav",
    "ia-suk-meditation-loop-36s.wav",
    "tchaikovsky-pp-1-loop-38s.wav",
    "albinoni-oboe-adagio-loop-41s.wav",
    "eroica-marcia-funebre-loop-46s.wav",
    "ia-mendelssohn-scottish-adagio-loop-59s.wav"
  ]

  // Never autoplays. Sound starts only when explicitly asked for.
  property bool playing: false
  property int index: 0
  property real master: 0.9
  // 0 = slotA at full, 1 = slotB at full.
  property real crossfade: 0
  property int repeatsPerTrack: 2
  property string lastError: ""

  readonly property string currentTrack: tracks.length ? tracks[index] : ""
  readonly property int trackCount: tracks.length

  function url_for(track) {
    return assetBase + track
  }

  function play() {
    if (trackCount === 0) return
    if (!playing) {
      slotA.source = url_for(currentTrack)
      crossfade = 0
      playing = true
    }
    slotA.play()
    armDwell()
  }

  function pause() {
    playing = false
    slotA.pause()
    slotB.pause()
    dwell.stop()
    fade.stop()
  }

  function toggle() {
    playing ? pause() : play()
  }

  // Crossfade into the next track. SlotB becomes the live player, so the
  // following call fades away from wherever we ended up.
  function next() {
    if (trackCount === 0) return
    index = (index + 1) % trackCount
    if (!playing) {
      slotA.source = url_for(currentTrack)
      return
    }
    if (fade.running) return
    slotB.source = url_for(currentTrack)
    slotB.play()
    dwell.stop()
    fade.restart()
  }

  function previous() {
    if (trackCount === 0) return
    index = (index - 1 + trackCount) % trackCount
    if (!playing) {
      slotA.source = url_for(currentTrack)
      return
    }
    if (fade.running) return
    slotB.source = url_for(currentTrack)
    slotB.play()
    dwell.stop()
    fade.restart()
  }

  // Each loop is seamless, so dwell for a couple of passes before moving on.
  function armDwell() {
    var seconds = slotA.duration / 1000
    if (!isFinite(seconds) || seconds <= 0) {
      // Duration not known yet; MediaPlayer.Loops covers us until it is.
      return
    }
    dwell.interval = Math.round(seconds * repeatsPerTrack * 1000)
    dwell.restart()
  }

  function completeFade() {
    slotA.stop()
    slotA.source = slotB.source
    slotA.play()
    crossfade = 0
    armDwell()
  }

  function noteError(which) {
    lastError = which + ": " + currentTrack
  }

  NumberAnimation {
    id: fade
    target: root
    property: "crossfade"
    from: 0
    to: 1
    duration: 4000
    onFinished: root.completeFade()
  }

  Timer {
    id: dwell
    repeat: false
    onTriggered: root.next()
  }

  AudioOutput {
    id: outA
    volume: root.master * (1 - root.crossfade)
  }

  AudioOutput {
    id: outB
    volume: root.master * root.crossfade
  }

  MediaPlayer {
    id: slotA
    audioOutput: outA
    // The loops are seamless, so looping is musically safe; it also covers the
    // window before duration is known and the dwell timer is armed.
    loops: MediaPlayer.Infinite
    onErrorOccurred: root.noteError("slotA")
    // Qt 6.8 dropped QMediaPlayer.status, so arm off duration instead, which
    // is the value the dwell timer actually needs.
    onDurationChanged: if (root.playing) root.armDwell()
  }

  MediaPlayer {
    id: slotB
    audioOutput: outB
    loops: MediaPlayer.Infinite
    onErrorOccurred: root.noteError("slotB")
  }

  IpcHandler {
    target: "odyssey"

    function play(): string {
      root.play()
      return "ok"
    }

    function pause(): string {
      root.pause()
      return "ok"
    }

    function toggle(): string {
      root.toggle()
      return "ok"
    }

    function next(): string {
      root.next()
      return "ok"
    }

    function previous(): string {
      root.previous()
      return "ok"
    }

    function status(): string {
      return JSON.stringify({
        playing: root.playing,
        index: root.index,
        track: root.currentTrack,
        trackCount: root.trackCount,
        duration: slotA.duration,
        position: slotA.position,
        error: root.lastError
      })
    }
  }

  Component.onCompleted: {
    slotA.source = url_for(currentTrack)
  }
}
