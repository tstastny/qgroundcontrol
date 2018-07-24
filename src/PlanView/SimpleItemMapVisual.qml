/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 1.2
import QtLocation       5.3
import QtPositioning    5.3

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.FlightMap     1.0

/// Simple Mission Item visuals
Item {
    id: _root

    property var map        ///< Map control to place item in
    property var qgcView    ///< QGCView to use for popping dialogs

    property var    _missionItem:       object
    property var    _itemVisuals:       [ ]
    property var    _dragArea
    property bool   _dragAreaShowing:   false


    readonly property int _indicatorIndex:   0
    readonly property int _radiusIndex:   1

    signal clicked(int sequenceNumber)

    function hideItemVisuals() {
        for (var i=0; i<_itemVisuals.length; i++) {
            _itemVisuals[i].destroy()
        }
        _itemVisuals = [ ]
    }

    function showItemVisuals() {
        if  (_itemVisuals.length === 0) {
            var _itemVisual = indicatorComponent.createObject(map)
            map.addMapItem(_itemVisual)
            _itemVisuals[_indicatorIndex] = _itemVisual
            _itemVisual = radiusComponent.createObject(map)
            map.addMapItem(_itemVisual)
            _itemVisuals[_radiusIndex] = _itemVisual
        }
    }

    function hideDragArea() {
        if (_dragAreaShowing) {
            _dragArea.destroy()
            _dragAreaShowing = false
        }
    }

    function showDragArea() {
        if (!_dragAreaShowing && _missionItem.specifiesCoordinate) {
            _dragArea = dragAreaComponent.createObject(map)
            _dragAreaShowing = true
        }
    }

    Component.onCompleted: {
        showItemVisuals()
        if (_missionItem.isCurrentItem && map.planView) {
            showDragArea()
        }
    }

    Component.onDestruction: {
        hideDragArea()
        hideItemVisuals()
    }


    Connections {
        target: _missionItem

        onIsCurrentItemChanged: {
            if (_missionItem.isCurrentItem) {
                showDragArea()
            } else {
                hideDragArea()
            }
        }

        onCircleRadiusChanged: {
            showItemVisuals()
        }
    }

    // Control which is used to drag items
    Component {
        id: dragAreaComponent

        MissionItemIndicatorDrag {
            mapControl:     _root.map
            itemIndicator:  _itemVisuals[_indicatorIndex]
            itemCoordinate: _missionItem.coordinate

            onItemCoordinateChanged: _missionItem.coordinate = itemCoordinate
        }
    }

    Component {
        id: indicatorComponent

        MissionItemIndicator {
            coordinate:     _missionItem.coordinate
            visible:        _missionItem.specifiesCoordinate
            z:              QGroundControl.zOrderMapItems
            missionItem:    _missionItem
            sequenceNumber: _missionItem.sequenceNumber

            onClicked: _root.clicked(_missionItem.sequenceNumber)

            // These are the non-coordinate child mission items attached to this item
            Row {
                anchors.top:    parent.top
                anchors.left:   parent.right

                Repeater {
                    model: _missionItem.childItems

                    delegate: MissionItemIndexLabel {
                        z:                      2
                        label:                  object.abbreviation.length === 0 ? object.sequenceNumber : object.abbreviation.charAt(0)
                        checked:                object.isCurrentItem
                        child:                  true
                        specifiesCoordinate:    false

                        onClicked: _root.clicked(object.sequenceNumber)
                    }
                }
            }
        }
    }

    // circle visual
    Component {
        id: radiusComponent

        MapCircle {
            z:              QGroundControl.zOrderMapItems
            center:         _missionItem.coordinate
            radius:         _missionItem.circleRadius
            border.width:   _missionItem.circleWidth
            border.color:   _missionItem.circleColor
            color:          "transparent"
        }
    }
}
