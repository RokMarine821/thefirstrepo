import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 1000
    height: 700
    title: "LOTTO 번호 생성기"
    
    // Material 스타일 적용
    Material.theme: darkModeSwitch.checked ? Material.Dark : Material.Light
    Material.accent: Material.Blue
    Material.primary: Material.Blue

    // 번호 생성 결과를 저장할 프로퍼티
    property var generatedNumbers: []
    property bool isGenerating: false

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 좌측 패널 (규칙 설정)
        Pane {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            Material.elevation: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 20

                Label {
                    text: "설정"
                    font.pixelSize: 24
                    font.bold: true
                }

                // 다크모드 스위치
                Row {
                    spacing: 10
                    Switch {
                        id: darkModeSwitch
                        text: "다크 모드"
                    }
                }

                // 규칙 설정들
                GroupBox {
                    title: "번호 생성 규칙"
                    Layout.fillWidth: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        CheckBox {
                            id: evenOddCheck
                            text: "홀짝 비율 제한"
                        }

                        CheckBox {
                            id: sumCheck
                            text: "합계 범위 제한"
                        }

                        Slider {
                            enabled: sumCheck.checked
                            from: 0
                            to: 255
                            value: 127
                            Layout.fillWidth: true
                        }

                        CheckBox {
                            id: consecutiveCheck
                            text: "연속 번호 제한"
                        }
                    }
                }

                Item { Layout.fillHeight: true } // 스페이서
            }
        }

        // 우측 메인 영역
        Pane {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 20

            ColumnLayout {
                anchors.fill: parent
                spacing: 20

                Label {
                    text: "로또 번호 생성기"
                    font.pixelSize: 32
                    font.bold: true
                }

                // 생성 버튼
                Button {
                    text: "번호 생성"
                    Layout.preferredWidth: 200
                    highlighted: true
                    enabled: !isGenerating

                    onClicked: {
                        isGenerating = true;
                        // 번호 생성 애니메이션을 위한 타이머
                        generationTimer.start();
                    }
                }

                // 생성된 번호 표시 영역
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 3
                    rowSpacing: 20
                    columnSpacing: 20

                    Repeater {
                        model: 5 // 5세트 생성

                        delegate: Pane {
                            Layout.fillWidth: true
                            Material.elevation: 1

                            RowLayout {
                                spacing: 10

                                Repeater {
                                    model: 6 // 각 세트당 6개 번호
                                    delegate: Rectangle {
                                        width: 60
                                        height: 60
                                        radius: width/2
                                        color: Material.accent
                                        opacity: generatedNumbers[index] ? 1 : 0.3

                                        Label {
                                            anchors.centerIn: parent
                                            text: generatedNumbers[index] || "?"
                                            color: "white"
                                            font.bold: true
                                            font.pixelSize: 18
                                        }

                                        // 번호 변경 애니메이션
                                        Behavior on opacity {
                                            NumberAnimation { duration: 200 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 번호 생성 애니메이션을 위한 타이머
    Timer {
        id: generationTimer
        interval: 100
        repeat: true
        property int count: 0

        onTriggered: {
            if (count < 6) {
                // 1-45 사이의 랜덤 번호 생성
                var num = Math.floor(Math.random() * 45) + 1;
                generatedNumbers[count] = num;
                generatedNumbers = generatedNumbers.slice(); // 배열 업데이트 트리거
                count++;
            } else {
                count = 0;
                isGenerating = false;
                stop();
            }
        }
    }
}