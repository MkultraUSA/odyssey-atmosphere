import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as Ui

// Odyssey Atmosphere — the control surface.
//
// Scene selection changes the wallpaper and the music together, the way the
// base plugin couples a scene to an audio preset. A separate track selector
// keeps all six loops reachable, because three scenes cannot own six tracks.
//
// The service is driven over the `odyssey` IPC target rather than a direct
// object reference, so the panel reads its state from the same source of truth
// the CLI does.

Ui.Panel {
  id: root
  moduleName: "io.github.mkultrausa.odyssey-atmosphere"
  manageIpc: false

  property var sceneOptions: [
    { value: "lens", label: "Lens" },
    { value: "monolith", label: "Monolith" }
  ]

  property string scene: "lens"
  property bool playing: false
  property string track: ""
  property int trackCount: 0
  property int index: 0

  readonly property string trackLabel: trackCount > 0
    ? (index + 1) + " / " + trackCount + "   " + track.replace(/-loop-.*$/, "").replace(/-/g, " ")
    : "connecting"

  function odyssey(args) {
    poll.command = ["bash", "-c",
      "omarchy-shell odyssey " + args + " >/dev/null 2>&1; omarchy-shell odyssey status"]
    poll.running = true
  }

  Process {
    id: poll
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var s = String(text || "").trim()
        if (!s) return
        try {
          var d = JSON.parse(s)
          root.scene = d.scene
          root.playing = d.playing
          root.track = d.track
          root.trackCount = d.trackCount
          root.index = d.index
        } catch (e) { }
      }
    }
  }

  ColumnLayout {
    spacing: Style.space(12)
    width: Style.space(340)

    Text {
      text: "SCENE"
      color: Color.muted
      font.family: Style.font.caption
      font.pixelSize: Style.font.caption
    }

    Ui.ButtonGroup {
      Layout.fillWidth: true
      options: root.sceneOptions
      value: root.scene
      onChanged: function(value) { root.odyssey("setscene " + value) }
    }

    Ui.PanelSeparator {}

    Text {
      text: "SOUND"
      color: Color.muted
      font.family: Style.font.caption
      font.pixelSize: Style.font.caption
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)

      Ui.Button {
        Layout.fillWidth: true
        text: root.playing ? "Pause" : "Play"
        onClicked: root.odyssey(root.playing ? "pause" : "play")
      }
      Ui.Button {
        Layout.fillWidth: true
        text: "Prev"
        onClicked: root.odyssey("previous")
      }
      Ui.Button {
        Layout.fillWidth: true
        text: "Next"
        onClicked: root.odyssey("next")
      }
    }

    Text {
      Layout.fillWidth: true
      text: root.trackLabel
      color: Color.muted
      font.family: Style.font.caption
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }

  Component.onCompleted: root.odyssey("status")
}
