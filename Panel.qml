import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as Ui

// Odyssey Atmosphere — the control surface.
//
// Ui.Panel is only a container: it holds open/close state and nothing more.
// The actual popup surface comes from a KeyboardPanel child that this file
// declares, exactly as every first-party panel does. Omitting it is why
// clicking set `opened` to true and produced no layer at all.
//
// The service is driven over the `odyssey` IPC target, so the panel reads the
// same state the CLI does rather than a second source of truth.

Ui.Panel {
  id: root
  moduleName: "io.github.mkultrausa.odyssey-atmosphere"
  manageIpc: false

  // The KeyboardPanel wrapper is a PanelWindow with `required property Item
  // anchorItem`; Widget.qml injects the button into this.
  property Item anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property var sceneOptions: [
    { value: "lens", label: "Lens" },
    { value: "panels", label: "Panels" },
    { value: "monolith", label: "Monolith" }
    { value: "saturn", label: "Saturn" },
    { value: "jupiter", label: "Jupiter" }
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

  Ui.KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    Ui.PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
    }

    ColumnLayout {
      id: content
      spacing: Style.space(12)

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

      // Plain rectangles with a MouseArea rather than Ui.Button. Ui.Button
      // declares a clicked() signal but no first-party panel uses it, and in
      // practice it never fired here: the scene selector worked, the transport
      // controls did not, and the same commands worked from the CLI.
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Repeater {
          model: [
            { label: root.playing ? "Pause" : "Play", arg: root.playing ? "pause" : "play" },
            { label: "Prev", arg: "previous" },
            { label: "Next", arg: "next" }
          ]

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: Style.space(34)
            radius: Style.radius.small
            color: tap.containsMouse ? Style.background.hover : Style.background.normal
            border.width: 1
            border.color: Style.border.normal

            Text {
              anchors.centerIn: parent
              text: modelData.label
              color: Style.foreground.normal
              font.family: Style.font.body
              font.pixelSize: Style.font.body
            }

            MouseArea {
              id: tap
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.odyssey(modelData.arg)
            }
          }
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
  }

  Component.onCompleted: root.odyssey("status")
}
