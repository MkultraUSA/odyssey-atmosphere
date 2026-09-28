import Quickshell
import Quickshell.Io
import QtQuick
import qs.Commons
import qs.Ui as Ui
import "." as Odyssey

// Bar widget: opens the Odyssey Atmosphere panel.
//
// A single small red lens, matching the scene art. It is deliberately not a
// word: the bar slot is one icon wide and there is no room for a label. The
// lens dims when sound is stopped and brightens when it is running, so the one
// mark carries the only state anyone needs at a glance.

Ui.BarWidget {
  id: root
  moduleName: "io.github.mkultrausa.odyssey-atmosphere"

  // The bar lays widgets out by the ROOT's implicit width, and BarWidget is a
  // bare Item whose implicit width is zero. Setting fixedWidth on the button
  // inside does nothing, because the root never grows to contain it: verified
  // by instrumenting Component.onCompleted, which reported contentWidth 50.5
  // while width and implicitWidth were both 0, and nothing appeared on screen.
  implicitWidth: content.implicitWidth + Style.space(18)
  implicitHeight: root.vertical ? root.barSize : Style.bar.sizeHorizontal

  property bool playing: false
  property bool wanted: false
  property bool themeActive: true
  property string activeTheme: ""
  property string scene: "lens"
  property string lastError: ""

  readonly property color lensColor: lastError
    ? "#e2705a"
    : !themeActive ? "#5c5348"
    : playing ? "#e2703a" : "#5c5348"

  // The widget is always present whatever theme is active, so when the audio
  // gate is closed it has to say why rather than look broken.
  readonly property string tooltipText: lastError
    ? "Odyssey · " + lastError
    : !themeActive
      ? "Odyssey · needs the Odyssey theme · active is " + activeTheme
      : playing ? "Odyssey · " + scene + " · playing"
      : wanted ? "Odyssey · paused"
      : "Odyssey · open controls"

  function refresh() {
    poll.command = ["bash", "-c", "omarchy-shell odyssey status"]
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
          root.playing = d.playing === true
          root.wanted = d.wanted === true
          root.themeActive = d.themeActive !== false
          root.activeTheme = d.activeTheme || ""
          root.scene = d.scene || root.scene
          root.lastError = d.error || ""
        } catch (e) { }
      }
    }
  }

  Odyssey.Panel {
    id: odysseyPanel
    visible: false
    bar: root.bar
    settings: root.settings
  }

  Ui.WidgetButton {
    id: button
    objectName: "odysseyBarButton"
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    // Size to the content Row below. Without this the button keeps the default
    // fixedWidth of -1, and BarWidget is a bare Item whose implicit width is
    // zero, so the entire widget collapses to nothing and never appears.
    fixedWidth: root.vertical ? root.barSize : content.implicitWidth + scaledHorizontalMargin * 2
    activeFocusOnTab: true
    tooltipText: root.tooltipText
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }

    // Sized to its content, the way the base plugin's widget is: a Row whose
    // implicitWidth the button measures. Deriving the width from a missing
    // content item is what made this collapse to nothing.
    Row {
      id: content
      anchors.centerIn: parent
      spacing: Style.space(7)

      Ui.OpticalGlyph {
        anchors.verticalCenter: parent.verticalCenter
        text: "◉"
        color: root.lensColor
        fontSize: button.fontSize
      }

      Text {
        visible: root.setting("showLabel", true) && !root.vertical
        anchors.verticalCenter: parent.verticalCenter
        text: "Odyssey"
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: button.fontSize
        renderType: Text.NativeRendering
      }
    }
  }

  function toggle() { odysseyPanel.open() }

  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    repeat: true
    running: true
    onTriggered: root.refresh()
  }
}
