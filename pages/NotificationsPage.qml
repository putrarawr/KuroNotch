pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../config"
import "../services"

Item {
    id: root

    function resolveIconPath(iconStr: string): string {
        return NotificationService.resolveIconPath(iconStr);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Top Toolbar: Header + DND toggle + Clear All
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "notifications"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: "#f4f4f6"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: countLabel.implicitWidth + 10
                    radius: 5
                    color: "#15151d"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        id: countLabel
                        anchors.centerIn: parent
                        text: {
                            const count = NotificationService.notifications ? NotificationService.notifications.length : 0;
                            return count === 1 ? "1 item" : `${count} items`;
                        }
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: "#8e8e98"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // DND Toggle Button
            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: dndRow.implicitWidth + 14
                radius: 6
                color: Config.dnd ? Qt.rgba(212 / 255, 132 / 255, 90 / 255, 0.18) : (dndMouse.containsMouse ? "#1c1c26" : "#15151d")
                border.width: 1
                border.color: Config.dnd ? "#d4845a" : Qt.rgba(1, 1, 1, 0.08)

                Row {
                    id: dndRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: Config.dnd ? "#d4845a" : (dndMouse.containsMouse ? "#f4f4f6" : "#8e8e98")
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.dnd ? "DND On" : "DND Off"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Config.dnd ? "#d4845a" : (dndMouse.containsMouse ? "#f4f4f6" : "#8e8e98")
                    }
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.toggleDnd()
                }
            }

            // Clear All Button
            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: clearRow.implicitWidth + 12
                radius: 6
                visible: NotificationService.notifications.length > 0
                color: clearMouse.containsMouse ? "#1c1c26" : "#15151d"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Row {
                    id: clearRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "delete_sweep"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: clearMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Clear"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: clearMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                    }
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.clearAll()
                }
            }
        }

        // Empty state view
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: NotificationService.notifications.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Config.dnd ? "notifications_paused" : "notifications_none"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 32
                    color: Config.dnd ? "#d4845a" : "#50505a"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Config.dnd ? "Do Not Disturb is active" : "No notifications"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#8e8e98"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Config.dnd ? "Incoming popups are silenced" : "You're all caught up"
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#50505a"
                }
            }
        }

        // Notification list
        ListView {
            id: notifList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            visible: NotificationService.notifications.length > 0
            model: NotificationService.notifications

            delegate: Rectangle {
                id: cardDelegate
                required property var modelData

                width: notifList.width
                implicitHeight: cardContent.implicitHeight + 12
                radius: 8
                color: cardHoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.045) : "transparent"
                border.width: 0

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.05)
                }

                HoverHandler {
                    id: cardHoverArea
                }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    // Header row: App icon, app name, urgency indicator, timestamp, dismiss button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // App icon / symbol
                        Rectangle {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            radius: 3
                            color: "transparent"

                            readonly property string resolvedIcon: NotificationService.resolveIconPath(
                                cardDelegate.modelData?.appIcon ?? "",
                                cardDelegate.modelData?.image ?? "",
                                cardDelegate.modelData?.appName ?? ""
                            )

                            Image {
                                id: cardNotifImg
                                anchors.fill: parent
                                source: parent.resolvedIcon
                                fillMode: Image.PreserveAspectFit
                                visible: parent.resolvedIcon.length > 0 && status === Image.Ready
                                asynchronous: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: parent.resolvedIcon.length === 0 || cardNotifImg.status !== Image.Ready
                                text: NotificationService.fallbackSymbol(
                                    cardDelegate.modelData?.appIcon ?? "",
                                    cardDelegate.modelData?.appName ?? "",
                                    cardDelegate.modelData?.summary ?? ""
                                )
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 13
                                color: "#8e8e98"
                            }
                        }

                        Text {
                            text: cardDelegate.modelData?.appName || "Notification"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: "#c8c8d2"
                            elide: Text.ElideRight
                            Layout.maximumWidth: 140
                        }

                        // Urgency badge if critical or low
                        Rectangle {
                            visible: cardDelegate.modelData?.urgency === 2
                            height: 14
                            width: critRow.implicitWidth + 8
                            radius: 3
                            color: Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.16)

                            Row {
                                id: critRow
                                anchors.centerIn: parent
                                spacing: 3
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: "#ef4444"
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Critical"
                                    font.family: "Rubik"
                                    font.pixelSize: 8
                                    font.weight: Font.Medium
                                    color: "#ef4444"
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: cardDelegate.modelData?.timeStr || ""
                            font.family: "Rubik"
                            font.pixelSize: 9
                            color: "#8e8e98"
                        }

                        // Dismiss button
                        Rectangle {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            radius: 4
                            color: dismissMouse.containsMouse ? "#1e1e28" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                color: dismissMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                            }

                            MouseArea {
                                id: dismissMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.dismiss(cardDelegate.modelData)
                            }
                        }
                    }

                    // Body row: Summary + message + optional image thumbnail
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: cardDelegate.modelData?.summary || ""
                                font.family: "Rubik"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: "#f4f4f6"
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                text: cardDelegate.modelData?.body || ""
                                font.family: "Rubik"
                                font.pixelSize: 10
                                color: "#a0a0ab"
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        // Attached notification image if present
                        Rectangle {
                            visible: Boolean(cardDelegate.modelData?.image && cardDelegate.modelData.image.length > 0)
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 4
                            color: "#181822"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: {
                                    const img = cardDelegate.modelData?.image ?? "";
                                    if (img.startsWith("/") || img.startsWith("file://"))
                                        return img.startsWith("file://") ? img : ("file://" + img);
                                    return img;
                                }
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }
                    }

                    // Actions row: buttons invoking notification actions
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: Boolean(cardDelegate.modelData?.actions && cardDelegate.modelData.actions.length > 0)

                        Repeater {
                            model: cardDelegate.modelData?.actions ?? []

                            delegate: Rectangle {
                                id: actionBtn
                                required property var modelData

                                Layout.preferredHeight: 22
                                Layout.preferredWidth: actionBtnText.implicitWidth + 14
                                radius: 5
                                color: actionMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08)
                                border.width: 1
                                border.color: Qt.rgba(255, 255, 255, 0.10)

                                Text {
                                    id: actionBtnText
                                    anchors.centerIn: parent
                                    text: actionBtn.modelData?.text || "Action"
                                    font.family: "Rubik"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: "#f4f4f6"
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.invokeAction(cardDelegate.modelData, actionBtn.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
