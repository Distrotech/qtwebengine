/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the QtWebEngine module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.1
import QtWebEngine 1.1
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.1
import QtQuick.Controls.Private 1.0
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.0

ApplicationWindow {
    id: browserWindow
    property QtObject applicationRoot
    property Item currentWebView: tabs.currentIndex < tabs.count ? tabs.getTab(tabs.currentIndex).item : null
    property int previousVisibility: Window.Windowed

    property bool isFullScreen: visibility == Window.FullScreen
    onIsFullScreenChanged: {
        // This is for the case where the system forces us to leave fullscreen.
        if (currentWebView && !isFullScreen) {
            currentWebView.state = ""
            if (currentWebView.isFullScreen)
                currentWebView.fullScreenCancelled()
        }
    }

    width: 1300
    height: 900
    visible: true
    title: currentWebView && currentWebView.title

    // Make sure the Qt.WindowFullscreenButtonHint is set on OS X.
    Component.onCompleted: flags = flags | Qt.WindowFullscreenButtonHint

    // Create a styleItem to determine the platform.
    // When using style "mac", ToolButtons are not supposed to accept focus.
    StyleItem { id: styleItem }
    property bool platformIsMac: styleItem.style == "mac"

    Settings {
        id : appSettings
        property alias autoLoadImages: loadImages.checked;
        property alias javaScriptEnabled: javaScriptEnabled.checked;
        property alias errorPageEnabled: errorPageEnabled.checked;
    }

    WebEngineProfile {
        id: defaultProfile
        storageName: "Default"
        httpCacheType: httpDiskCacheEnabled.checked ? WebEngineProfile.DiskHttpCache : WebEngineProfile.MemoryHttpCache;
        onDownloadRequested: {
            downloadView.visible = true
            downloadView.append(download)
            download.accept()
        }
    }

    WebEngineProfile {
        id: otrProfile
        offTheRecord: true
    }

    Action {
        shortcut: "Ctrl+D"
        onTriggered: {
            downloadView.visible = !downloadView.visible
        }
    }
    Action {
        id: focus
        shortcut: "Ctrl+L"
        onTriggered: {
            addressBar.forceActiveFocus();
            addressBar.selectAll();
        }
    }
    Action {
        shortcut: "Ctrl+R"
        onTriggered: {
            if (currentWebView)
                currentWebView.reload()
        }
    }
    Action {
        shortcut: "Ctrl+T"
        onTriggered: {
            tabs.createEmptyTab()
            tabs.currentIndex = tabs.count - 1
            addressBar.forceActiveFocus();
            addressBar.selectAll();
        }
    }
    Action {
        shortcut: "Ctrl+W"
        onTriggered: {
            if (tabs.count == 1)
                browserWindow.close()
            else
                tabs.removeTab(tabs.currentIndex)
        }
    }
    Action {
        shortcut: "Escape"
        onTriggered: {
            if (browserWindow.isFullScreen)
                browserWindow.visibility = browserWindow.previousVisibility
        }
    }
    Action {
        shortcut: "Ctrl+0"
        onTriggered: currentWebView.zoomFactor = 1.0;
    }
    Action {
        shortcut: "Ctrl+-"
        onTriggered: currentWebView.zoomFactor -= 0.1;
    }
    Action {
        shortcut: "Ctrl+="
        onTriggered: currentWebView.zoomFactor += 0.1;
    }

    toolBar: ToolBar {
        id: navigationBar
            RowLayout {
                anchors.fill: parent;
                ToolButton {
                    enabled: currentWebView && (currentWebView.canGoBack || currentWebView.canGoForward)
                    menu:Menu {
                        id: historyMenu

                        Instantiator {
                            model: currentWebView && currentWebView.navigationHistory.items
                            MenuItem {
                                text: model.title
                                onTriggered: currentWebView.goBackOrForward(model.offset)
                                checkable: !enabled
                                checked: !enabled
                                enabled: model.offset
                            }

                            onObjectAdded: historyMenu.insertItem(index, object)
                            onObjectRemoved: historyMenu.removeItem(object)
                        }
                    }
                }

                ToolButton {
                    id: backButton
                    iconSource: "icons/go-previous.png"
                    onClicked: currentWebView.goBack()
                    enabled: currentWebView && currentWebView.canGoBack
                    activeFocusOnTab: !browserWindow.platformIsMac
                }
                ToolButton {
                    id: forwardButton
                    iconSource: "icons/go-next.png"
                    onClicked: currentWebView.goForward()
                    enabled: currentWebView && currentWebView.canGoForward
                    activeFocusOnTab: !browserWindow.platformIsMac
                }
                ToolButton {
                    id: reloadButton
                    iconSource: currentWebView && currentWebView.loading ? "icons/process-stop.png" : "icons/view-refresh.png"
                    onClicked: currentWebView && currentWebView.loading ? currentWebView.stop() : currentWebView.reload()
                    activeFocusOnTab: !browserWindow.platformIsMac
                }
                TextField {
                    id: addressBar
                    Image {
                        anchors.verticalCenter: addressBar.verticalCenter;
                        x: 5
                        z: 2
                        id: faviconImage
                        width: 16; height: 16
                        source: currentWebView && currentWebView.icon
                    }
                    style: TextFieldStyle {
                        padding {
                            left: 26;
                        }
                    }
                    focus: true
                    Layout.fillWidth: true
                    text: currentWebView && currentWebView.url
                    onAccepted: currentWebView.url = utils.fromUserInput(text)
                }
                ToolButton {
                    id: settingsMenuButton
                    menu: Menu {
                        MenuItem {
                            id: loadImages
                            text: "Autoload images"
                            checkable: true
                            checked: WebEngine.settings.autoLoadImages
                        }
                        MenuItem {
                            id: javaScriptEnabled
                            text: "JavaScript On"
                            checkable: true
                            checked: WebEngine.settings.javascriptEnabled
                        }
                        MenuItem {
                            id: errorPageEnabled
                            text: "ErrorPage On"
                            checkable: true
                            checked: WebEngine.settings.errorPageEnabled
                        }
                        MenuItem {
                            id: offTheRecordEnabled
                            text: "Off The Record"
                            checkable: true
                            checked: false
                        }
                        MenuItem {
                            id: httpDiskCacheEnabled
                            text: "HTTP Disk Cache"
                            checkable: true
                            checked: (defaultProfile.httpCacheType == WebEngineProfile.DiskHttpCache)
                        }
                    }
                }
            }
            ProgressBar {
                id: progressBar
                height: 3
                anchors {
                    left: parent.left
                    top: parent.bottom
                    right: parent.right
                    leftMargin: -parent.leftMargin
                    rightMargin: -parent.rightMargin
                }
                style: ProgressBarStyle {
                    background: Item {}
                }
                z: -2;
                minimumValue: 0
                maximumValue: 100
                value: (currentWebView && currentWebView.loadProgress < 100) ? currentWebView.loadProgress : 0
            }
    }

    TabView {
        id: tabs
        function createEmptyTab() {
            var tab = addTab("", tabComponent)
            // We must do this first to make sure that tab.active gets set so that tab.item gets instantiated immediately.
            tab.active = true
            tab.title = Qt.binding(function() { return tab.item.title })
            return tab
        }

        anchors.fill: parent
        Component.onCompleted: createEmptyTab()

        Component {
            id: tabComponent
            WebEngineView {
                id: webEngineView
                focus: true
                profile: offTheRecordEnabled.checked ? otrProfile : defaultProfile

                onLinkHovered: {
                    if (hoveredUrl == "")
                        resetStatusText.start()
                    else {
                        resetStatusText.stop()
                        statusText.text = hoveredUrl
                    }
                }

                states: [
                    State {
                        name: "FullScreen"
                        PropertyChanges {
                            target: tabs
                            frameVisible: false
                            tabsVisible: false
                        }
                        PropertyChanges {
                            target: navigationBar
                            visible: false
                        }
                    }
                ]
                settings.autoLoadImages: appSettings.autoLoadImages
                settings.javascriptEnabled: appSettings.javaScriptEnabled
                settings.errorPageEnabled: appSettings.errorPageEnabled

                onCertificateError: {
                    error.defer()
                    sslDialog.enqueue(error)
                }

                onNewViewRequested: {
                    if (!request.userInitiated)
                        print("Warning: Blocked a popup window.")
                    else if (request.destination == WebEngineView.NewViewInTab) {
                        var tab = tabs.createEmptyTab()
                        tabs.currentIndex = tabs.count - 1
                        request.openIn(tab.item)
                    } else if (request.destination == WebEngineView.NewViewInBackgroundTab) {
                        var tab = tabs.createEmptyTab()
                        request.openIn(tab.item)
                    } else if (request.destination == WebEngineView.NewViewInDialog) {
                        var dialog = applicationRoot.createDialog()
                        request.openIn(dialog.currentWebView)
                    } else {
                        var window = applicationRoot.createWindow()
                        request.openIn(window.currentWebView)
                    }
                }

                onFullScreenRequested: {
                    if (request.toggleOn) {
                        webEngineView.state = "FullScreen"
                        browserWindow.previousVisibility = browserWindow.visibility
                        browserWindow.showFullScreen()
                    } else {
                        webEngineView.state = ""
                        browserWindow.visibility = browserWindow.previousVisibility
                    }
                    request.accept()
                }
            }
        }
    }
    MessageDialog {
        id: sslDialog

        property var certErrors: []
        icon: StandardIcon.Warning
        standardButtons: StandardButton.No | StandardButton.Yes
        title: "Server's certificate not trusted"
        text: "Do you wish to continue?"
        detailedText: "If you wish so, you may continue with an unverified certificate. " +
                      "Accepting an unverified certificate means " +
                      "you may not be connected with the host you tried to connect to.\n" +
                      "Do you wish to override the security check and continue?"
        onYes: {
            certErrors.shift().ignoreCertificateError()
            presentError()
        }
        onNo: reject()
        onRejected: reject()

        function reject(){
            certErrors.shift().rejectCertificate()
            presentError()
        }
        function enqueue(error){
            certErrors.push(error)
            presentError()
        }
        function presentError(){
            visible = certErrors.length > 0
        }
    }
    DownloadView {
        id: downloadView
        visible: false
        anchors.fill: parent
    }
    Rectangle {
        id: statusBubble
        color: "oldlace"
        property int padding: 8

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: statusText.paintedWidth + padding
        height: statusText.paintedHeight + padding

        Text {
            id: statusText
            anchors.centerIn: statusBubble
            elide: Qt.ElideMiddle

            Timer {
                id: resetStatusText
                interval: 750
                onTriggered: statusText.text = ""
            }
        }
    }
}