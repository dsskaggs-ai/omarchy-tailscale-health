import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "dsskaggs.tailscale-health"

  property string state: "checking"
  readonly property bool connected: state === "up"
  readonly property color statusColor: connected ? "#22c55e" : (state === "down" ? "#ef4444" : "#eab308")
  readonly property string statusLabel: connected ? "Tailscale connected" : (state === "down" ? "Tailscale unavailable" : "Checking Tailscale…")

  implicitWidth: indicator.implicitWidth
  implicitHeight: indicator.implicitHeight

  function refresh() {
    if (!statusProcess.running) statusProcess.running = true
  }

  Process {
    id: statusProcess
    command: ["tailscale", "status", "--json"]
    stdout: StdioCollector { id: statusOutput; waitForEnd: true }
    onExited: function(exitCode) {
      var isUp = false
      if (exitCode === 0) {
        try {
          var report = JSON.parse(statusOutput.text || "{}")
          isUp = report.BackendState === "Running"
        } catch (error) {
          isUp = false
        }
      }
      root.state = isUp ? "up" : "down"
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: indicator
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: root.statusLabel + " — refreshes every 10 seconds"
    onPressed: root.refresh()
    iconComponent: Component {
      Item {
        Rectangle {
          anchors.centerIn: parent
          width: Style.space(11)
          height: width
          radius: width / 2
          color: root.statusColor
          border.width: 1
          border.color: root.connected ? "#bbf7d0" : "#fecaca"
        }
      }
    }
  }
}
