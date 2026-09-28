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
  //
  // `wanted` is what the user asked for; `playing` is what is actually
  // running. They differ when the active theme is not Odyssey: the request is
  // remembered and honoured as soon as the Odyssey theme comes back, which is
  // the behaviour the base plugin gets for free by being theme-scoped.
  property bool wanted: false
  property string activeTheme: ""
  readonly property bool themeActive: activeTheme === "odyssey"
  readonly property bool playing: wanted && themeActive

  property int index: 0
  property real master: 0.9
  // 0 = slotA at full, 1 = slotB at full.
  property real crossfade: 0
  property int repeatsPerTrack: 2
  property string lastError: ""

  readonly property string stateHome: (Quickshell.env("XDG_STATE_HOME")
    || Quickshell.env("HOME") + "/.local/state") + "/omarchy/current"

  // Reconcile actual playback with the request and the theme gate. Called on
  // every transition, so it is safe to call redundantly.
  function applyState() {
    if (playing) {
      if (slotA.status !== MediaPlayer.PlayingState) {
        if (slotA.source === "") slotA.source = url_for(currentTrack)
        slotA.play()
        armDwell()
      }
    } else {
      slotA.pause()
      dwell.stop()
      fade.stop()
    }
  }

  function readActiveTheme() {
    themeProc.running = true
  }

  readonly property string currentTrack: tracks.length ? tracks[index] : ""
  readonly property int trackCount: tracks.length

  // Scenes pair a picture with a track. Picking one changes both together,
  // the way the base plugin couples a scene to an audio preset. next() still
  // reaches all six tracks, so the scene is a starting point, not a cage.
  readonly property var scenes: [
    { name: "lens",     label: "Lens",     background: "01-lens.webp",     track: "satie-gymnopedie-1-loop-32s.wav" },
    { name: "monolith", label: "Monolith", background: "03-monolith.webp", track: "eroica-marcia-funebre-loop-46s.wav" }
  ]
  property string scene: "lens"

  // Wallpapers are bundled with the plugin rather than read from the active
  // theme. Reaching into ~/.local/state/omarchy/current/theme meant scene
  // selection silently did nothing for anyone whose theme did not happen to
  // contain a file of the same name — which is everyone but the author.
  // Qt.resolvedUrl gives a file:// URL; the shell command needs a path.
  function localBackground(name) {
    var u = String(Qt.resolvedUrl("assets/backgrounds/" + name))
    return u.indexOf("file://") === 0 ? u.slice(7) : u
  }

  function sceneIndex(name) {
    for (var i = 0; i < scenes.length; i++)
      if (scenes[i].name === name) return i
    return -1
  }

  // Change picture and music together.
  function setScene(name) {
    var i = sceneIndex(name)
    if (i < 0) return
    scene = name
    run("omarchy-theme-bg-set " + localBackground(scenes[i].background))
    var t = tracks.indexOf(scenes[i].track)
    if (t >= 0) {
      index = t
      if (playing) {
        slotA.stop()
        slotA.source = url_for(currentTrack)
        slotA.play()
        armDwell()
      } else {
        slotA.source = url_for(currentTrack)
      }
    }
  }

  function run(cmd) {
    proc.command = ["bash", "-c", cmd + " >/dev/null 2>&1"]
    proc.running = true
  }

  function url_for(track) {
    return assetBase + track
  }

  function play() {
    if (trackCount === 0) return
    if (!wanted) {
      slotA.source = url_for(currentTrack)
      crossfade = 0
    }
    wanted = true
    applyState()
  }

  function pause() {
    wanted = false
    slotA.pause()
    slotB.pause()
    dwell.stop()
    fade.stop()
  }

  function toggle() {
    wanted ? pause() : play()
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

  Process {
    id: proc
  }

  // Theme gate. The base plugin stops with its theme; this reads the same
  // theme.name omarchy-theme-set writes, and reconciles playback when it moves.
  Process {
    id: themeProc
    command: ["bash", "-c", "cat '" + root.stateHome + "/theme.name' 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var name = String(text || "").trim()
        if (name && name !== root.activeTheme) {
          root.activeTheme = name
          root.applyState()
        }
      }
    }
  }

  FileView {
    path: root.stateHome
    watchChanges: true
    printErrors: false
    onFileChanged: root.readActiveTheme()
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

    function setscene(name: string): string {
      root.setScene(name)
      return "ok"
    }

    function status(): string {
      return JSON.stringify({
        playing: root.playing,
        wanted: root.wanted,
        themeActive: root.themeActive,
        activeTheme: root.activeTheme,
        scene: root.scene,
        scenes: root.scenes.map(function(s) { return s.name }),
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
