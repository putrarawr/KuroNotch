pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../config"
import "../services"

PopupWindow {
    id: root

    required property var parentWindow
    property int anchorX: 0
    property int anchorY: 0

    visible: NotchController.menuOpen
    color: "transparent"
    implicitWidth: menuCard.implicitWidth
    implicitHeight: menuCard.implicitHeight

    anchor.window: root.parentWindow
    anchor.rect: Qt.rect(root.anchorX, root.anchorY, 1, 1)
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip

    function openAt(wx: real, wy: real): void {
        root.anchorX = Math.max(0, Math.round(wx));
        root.anchorY = Math.max(0, Math.round(wy));
        NotchController.menuOpen = true;
    }

    function closeMenu(): void {
        NotchController.menuOpen = false;
    }

    function triggerAction(actionId: string): void {
        switch (actionId) {
        case "mode_notch":
            Config.setMode("notch");
            break;
        case "mode_pill":
            Config.setMode("pill");
            break;
        case "mode_strip":
            Config.setMode("strip");
            break;
        case "toggle_pin":
            NotchController.togglePin();
            break;
        case "toggle_autohide":
            Config.autoHide.enabled = !Config.autoHide.enabled;
            Config.save();
            break;
        case "toggle_dnd":
            NotchController.toggleDnd();
            break;
        case "open_settings":
            root.closeMenu();
            Qt.callLater(() => NotchController.openSettings());
            return;
        case "reload":
            root.closeMenu();
            Qt.callLater(() => Quickshell.reload(true));
            return;
        }
        root.closeMenu();
    }

    readonly property var menuModel: [
        { type: "item", id: "mode_notch", label: "Notch", icon: "page_header", kind: "radio", active: Config.mode === "notch" },
        { type: "item", id: "mode_pill", label: "Pill", icon: "web_asset", kind: "radio", active: Config.mode === "pill" },
        { type: "item", id: "mode_strip", label: "Micro-Strip", icon: "remove", kind: "radio", active: Config.mode === "strip" },
        { type: "divider", id: "div_1", label: "", icon: "", kind: "", active: false },
        { type: "item", id: "toggle_pin", label: Config.pinned ? "Unpin" : "Pin", icon: "keep", kind: "toggle", active: Config.pinned },
        { type: "item", id: "toggle_autohide", label: "Auto-Hide", icon: "visibility_off", kind: "toggle", active: Config.autoHide.enabled },
        { type: "item", id: "toggle_dnd", label: "DND", icon: "notifications_off", kind: "toggle", active: Config.dnd },
        { type: "divider", id: "div_2", label: "", icon: "", kind: "", active: false },
        { type: "item", id: "open_settings", label: "Settings...", icon: "tune", kind: "action", active: false },
        { type: "item", id: "reload", label: "Reload", icon: "refresh", kind: "action", active: false }
    ]

    HyprlandFocusGrab {
        id: menuFocusGrab

        active: NotchController.menuOpen
        windows: [root.parentWindow, root]
        onCleared: root.closeMenu()
    }

    FocusScope {
        anchors.fill: parent
        focus: NotchController.menuOpen

        Keys.onEscapePressed: root.closeMenu()

        Rectangle {
            id: menuCard

            implicitWidth: 186
            implicitHeight: menuColumn.implicitHeight + 12
            radius: 12
            color: "#09090d"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)

            ColumnLayout {
                id: menuColumn

                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                Repeater {
                    model: root.menuModel

                    delegate: Item {
                        id: entryDelegate

                        required property var modelData
                        readonly property bool isDivider: modelData.type === "divider"

                        Layout.fillWidth: true
                        implicitHeight: isDivider ? 7 : 28

                        // Divider line
                        Rectangle {
                            visible: entryDelegate.isDivider
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.08)
                        }

                        // Actionable row
                        Rectangle {
                            visible: !entryDelegate.isDivider
                            anchors.fill: parent
                            radius: 7
                            color: rowMouse.containsMouse ? "#171720" : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: entryDelegate.modelData.icon
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 15
                                    color: entryDelegate.modelData.active ? "#f4f4f6" : "#8e8e98"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: entryDelegate.modelData.label
                                    font.family: "Rubik"
                                    font.pixelSize: 12
                                    font.weight: entryDelegate.modelData.active ? Font.Medium : Font.Normal
                                    color: entryDelegate.modelData.active
                                        ? "#f4f4f6"
                                        : (rowMouse.containsMouse ? "#f4f4f6" : "#c8c8d2")
                                }

                                // Radio / Toggle status indicator
                                Text {
                                    visible: entryDelegate.modelData.kind === "radio" && entryDelegate.modelData.active
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "check"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 14
                                    color: "#f4f4f6"
                                }

                                Rectangle {
                                    visible: entryDelegate.modelData.kind === "toggle"
                                    Layout.alignment: Qt.AlignVCenter
                                    width: 24
                                    height: 14
                                    radius: 7
                                    color: entryDelegate.modelData.active ? "#f4f4f6" : "#1c1c24"
                                    border.width: 1
                                    border.color: entryDelegate.modelData.active
                                        ? "transparent"
                                        : Qt.rgba(1, 1, 1, 0.12)

                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 5
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: entryDelegate.modelData.active ? parent.width - width - 2 : 2
                                        color: entryDelegate.modelData.active ? "#050507" : "#8e8e98"

                                        Behavior on x {
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: rowMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.triggerAction(entryDelegate.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
