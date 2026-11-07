try:
    from PySide6 import QtCore, QtWidgets
except ImportError:
    from PySide2 import QtCore, QtWidgets

import qtmax


def dock_torn_off_menu():
    main_window = qtmax.GetQMaxMainWindow()
    title, accepted = QtWidgets.QInputDialog.getText(
        main_window,
        "Dock Torn-Off Menu",
        "Dialog title:",
    )
    if not accepted or not title.strip():
        return None

    matches = [
        widget
        for widget in QtWidgets.QApplication.topLevelWidgets()
        if widget.metaObject().className() == "QTornOffMenu"
        and widget.windowTitle() == title.strip()
        and widget.isVisible()
    ]

    if len(matches) != 1:
        QtWidgets.QMessageBox.warning(
            main_window,
            "Dock Torn-Off Menu",
            "Expected one visible torn-off menu titled {!r}; found {}.".format(
                title.strip(), len(matches)
            ),
        )
        return None

    menu = matches[0]
    dock = QtWidgets.QDockWidget(title.strip(), main_window)
    dock.setObjectName("TornOffMenuDock")
    dock.setWidget(menu)

    widget_type = getattr(QtCore.Qt, "Widget", None)
    if widget_type is None:
        widget_type = QtCore.Qt.WindowType.Widget
    menu.setWindowFlags(widget_type)

    main_window.addDockWidget(
        QtCore.Qt.DockWidgetArea.LeftDockWidgetArea,
        dock,
    )
    dock.show()
    return dock


dock_torn_off_menu()