import QtQuick
import QtQuick.Shapes
import "../services"

Item {
    id: root

    property string surfaceState: NotchController.surfaceState
    property var targetGeometry: NotchController.geometry
    property color accentColor: "#f4f4f6"
    property bool accentActive: false

    default property alias contentData: contentLayer.data

    readonly property bool isTopFlush: surfaceState === "notch" || surfaceState === "strip" || surfaceState === "sensor"
    readonly property real targetEarWidth: surfaceState === "notch" ? 12 : 0
    readonly property real targetTopRadius: (surfaceState === "notch" || surfaceState === "strip")
        ? 0
        : Math.min((targetGeometry?.height ?? 32) / 2, targetGeometry?.radius ?? 16)
    readonly property real targetBottomRadius: Math.min(
        (targetGeometry?.height ?? 32) / 2,
        targetGeometry?.radius ?? 16
    )

    readonly property real shapePadX: 16
    readonly property real bezierK: 0.55228475

    // Clamped silhouette radii keep paths non-self-intersecting mid-spring (e.g. 4px sensor <-> 245px card)
    readonly property real effEar: Math.min(earWidth, Math.max(0, height * 0.4))
    readonly property real effTopR: Math.min(topRadius, height / 2, width / 2)
    readonly property real effBottomR: Math.min(bottomRadius, Math.max(0, height - effTopR - effEar), width / 2)

    property real earWidth: targetEarWidth
    property real topRadius: targetTopRadius
    property real bottomRadius: targetBottomRadius

    readonly property color targetFillColor: surfaceState === "sensor" ? "#0d0d12" : "#050507"
    readonly property color targetRimColor: surfaceState === "sensor"
        ? Qt.rgba(1, 1, 1, 0.24)
        : Qt.rgba(1, 1, 1, 0.10)
    readonly property color targetTopRimColor: isTopFlush ? Qt.rgba(1, 1, 1, 0) : targetRimColor
    readonly property real targetGlowOpacity: {
        if (surfaceState === "sensor" || surfaceState === "strip")
            return 0.0;
        if (accentActive)
            return surfaceState === "expanded" ? 0.16 : 0.12;
        return surfaceState === "expanded" ? 0.035 : 0.0;
    }

    property color fillColor: targetFillColor
    property color rimColor: targetRimColor
    property color topRimColor: targetTopRimColor
    property real glowOpacity: targetGlowOpacity

    x: Math.round(((parent ? parent.width : NotchController.screenWidth) - width) / 2)
    y: Math.max(0, targetGeometry?.y ?? 0)
    width: targetGeometry?.width ?? 220
    height: targetGeometry?.height ?? 32

    Behavior on width {
        SpringAnimation {
            spring: 4.8
            damping: 0.42
            epsilon: 0.25
        }
    }

    Behavior on height {
        SpringAnimation {
            spring: 4.8
            damping: 0.42
            epsilon: 0.25
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Behavior on earWidth {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Behavior on topRadius {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on bottomRadius {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on fillColor {
        ColorAnimation {
            duration: 180
        }
    }

    Behavior on rimColor {
        ColorAnimation {
            duration: 180
        }
    }

    Behavior on topRimColor {
        ColorAnimation {
            duration: 160
        }
    }

    Behavior on glowOpacity {
        NumberAnimation {
            duration: 240
        }
    }

    component SilhouettePath: ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"

        startX: root.shapePadX + root.effTopR - root.effEar
        startY: 0

        PathLine {
            x: root.shapePadX + root.width - root.effTopR + root.effEar
            y: 0
        }
        PathCubic {
            control1X: root.shapePadX + root.width - (1 - root.bezierK) * (root.effTopR - root.effEar)
            control1Y: 0
            control2X: root.shapePadX + root.width
            control2Y: (root.effTopR + root.effEar) * (1 - root.bezierK)
            x: root.shapePadX + root.width
            y: root.effTopR + root.effEar
        }
        PathLine {
            x: root.shapePadX + root.width
            y: root.height - root.effBottomR
        }
        PathCubic {
            control1X: root.shapePadX + root.width
            control1Y: root.height - root.effBottomR * (1 - root.bezierK)
            control2X: root.shapePadX + root.width - root.effBottomR * (1 - root.bezierK)
            control2Y: root.height
            x: root.shapePadX + root.width - root.effBottomR
            y: root.height
        }
        PathLine {
            x: root.shapePadX + root.effBottomR
            y: root.height
        }
        PathCubic {
            control1X: root.shapePadX + root.effBottomR * (1 - root.bezierK)
            control1Y: root.height
            control2X: root.shapePadX
            control2Y: root.height - root.effBottomR * (1 - root.bezierK)
            x: root.shapePadX
            y: root.height - root.effBottomR
        }
        PathLine {
            x: root.shapePadX
            y: root.effTopR + root.effEar
        }
        PathCubic {
            control1X: root.shapePadX
            control1Y: (root.effTopR + root.effEar) * (1 - root.bezierK)
            control2X: root.shapePadX + (root.effTopR - root.effEar) * (1 - root.bezierK)
            control2Y: 0
            x: root.shapePadX + root.effTopR - root.effEar
            y: 0
        }
    }

    Shape {
        id: silhouetteShape

        readonly property real leftEdge: root.shapePadX + 0.5
        readonly property real rightEdge: root.shapePadX + root.width - 0.5
        readonly property real topEdge: 0.5
        readonly property real botEdge: Math.max(0.5, root.height - 0.5)
        readonly property real rimBotR: Math.max(0, root.effBottomR - 0.5)
        readonly property real rimTopSpanY: Math.min(botEdge, Math.max(topEdge, root.effTopR + root.effEar))

        x: -root.shapePadX
        y: 0
        width: root.width + root.shapePadX * 2
        height: root.height + 2
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true

        // 1. Primary obsidian surface silhouette
        SilhouettePath {
            fillColor: root.fillColor
        }

        // 2. Adaptive ambient halo clipped cleanly inside the silhouette
        SilhouettePath {
            fillGradient: RadialGradient {
                centerX: root.shapePadX + root.width * 0.24
                centerY: root.height * 0.34
                focalX: centerX
                focalY: centerY
                centerRadius: Math.max(60, Math.max(root.width, root.height) * 0.68)

                GradientStop {
                    position: 0.0
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, root.glowOpacity)
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }

        // 3. Crisp 1px inner rim along ears, sides, and bottom
        ShapePath {
            fillColor: "transparent"
            strokeWidth: 1
            strokeColor: root.rimColor
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            startX: silhouetteShape.rightEdge - root.effTopR + root.effEar
            startY: silhouetteShape.topEdge

            PathCubic {
                control1X: silhouetteShape.rightEdge - (1 - root.bezierK) * (root.effTopR - root.effEar)
                control1Y: silhouetteShape.topEdge
                control2X: silhouetteShape.rightEdge
                control2Y: Math.max(silhouetteShape.topEdge, (root.effTopR + root.effEar) * (1 - root.bezierK))
                x: silhouetteShape.rightEdge
                y: silhouetteShape.rimTopSpanY
            }
            PathLine {
                x: silhouetteShape.rightEdge
                y: Math.max(silhouetteShape.topEdge, silhouetteShape.botEdge - silhouetteShape.rimBotR)
            }
            PathCubic {
                control1X: silhouetteShape.rightEdge
                control1Y: Math.max(silhouetteShape.topEdge, silhouetteShape.botEdge - silhouetteShape.rimBotR * (1 - root.bezierK))
                control2X: silhouetteShape.rightEdge - silhouetteShape.rimBotR * (1 - root.bezierK)
                control2Y: silhouetteShape.botEdge
                x: silhouetteShape.rightEdge - silhouetteShape.rimBotR
                y: silhouetteShape.botEdge
            }
            PathLine {
                x: silhouetteShape.leftEdge + silhouetteShape.rimBotR
                y: silhouetteShape.botEdge
            }
            PathCubic {
                control1X: silhouetteShape.leftEdge + silhouetteShape.rimBotR * (1 - root.bezierK)
                control1Y: silhouetteShape.botEdge
                control2X: silhouetteShape.leftEdge
                control2Y: Math.max(silhouetteShape.topEdge, silhouetteShape.botEdge - silhouetteShape.rimBotR * (1 - root.bezierK))
                x: silhouetteShape.leftEdge
                y: Math.max(silhouetteShape.topEdge, silhouetteShape.botEdge - silhouetteShape.rimBotR)
            }
            PathLine {
                x: silhouetteShape.leftEdge
                y: silhouetteShape.rimTopSpanY
            }
            PathCubic {
                control1X: silhouetteShape.leftEdge
                control1Y: Math.max(silhouetteShape.topEdge, (root.effTopR + root.effEar) * (1 - root.bezierK))
                control2X: silhouetteShape.leftEdge + (root.effTopR - root.effEar) * (1 - root.bezierK)
                control2Y: silhouetteShape.topEdge
                x: silhouetteShape.leftEdge + root.effTopR - root.effEar
                y: silhouetteShape.topEdge
            }
        }

        // 4. Top rim line (transparent when top-flush at y=0, visible in floating pill/peek/expanded)
        ShapePath {
            fillColor: "transparent"
            strokeWidth: 1
            strokeColor: root.topRimColor

            startX: silhouetteShape.leftEdge + root.effTopR - root.effEar
            startY: silhouetteShape.topEdge

            PathLine {
                x: silhouetteShape.rightEdge - root.effTopR + root.effEar
                y: silhouetteShape.topEdge
            }
        }
    }

    Item {
        id: contentLayer

        anchors.fill: parent
        anchors.margins: root.surfaceState === "sensor" ? 0 : 1
        clip: true
    }
}
