import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

// ============================================================
// DLT Log Analyzer - QML 샘플 3종 (CuRS/NFR 반영)
// A) 대시보드/분석 (FR-01/02/06/07/08/12, NFR-03/07)
// B) 규칙 관리자 (FR-03.1/03.2/03.3)
// C) AI 심층 분석 & 해결 가이드 (FR-04/05/06/08/09/10/11, NFR-05)
//
// 개선 사항:
// 1. 컴포넌트 분리: 반복 UI를 재사용 가능한 컴포넌트로 분리 (예: KpiCard, LogRow)
// 2. 상태 관리 개선: ButtonGroup을 사용하여 뷰 전환 로직 개선
// 3. 가독성 및 구조 개선: 인라인 코드를 줄이고 구조를 명확하게 변경
// ============================================================

ApplicationWindow {
    id: win
    width: 1280
    height: 800
    visible: true
    title: qsTr("DLT Log Analyzer")

    // --- 재사용 가능한 컴포넌트 정의 ---
    Component {
        id: kpiCard
        Rectangle {
            property string label
            property string value
            property string trend
            color: "#f5f5f5"
            border.color: "#cccccc"
            border.width: 1
            radius: 8
            Layout.fillWidth: true
            height: 80
            width: 220
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4
                Label { text: label; opacity: 0.7; font.pixelSize: 12 }
                RowLayout {
                    Label { text: value; font.pixelSize: 20; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Label { text: trend; font.pixelSize: 12; opacity: 0.8 }
                }
                Rectangle { height: 6; radius: 3; color: "#666"; width: parent.width * 0.66 }
            }
        }
    }

    Component {
        id: logRow
        Rectangle {
            property string ts
            property string ecu
            property string app
            property string ctx
            property string lvl
            property string msg
            height: 28; width: parent.width
            color: (lvl === "ERROR") ? Qt.rgba(1, 0, 0, 0.08) : (lvl === "WARN" ? Qt.rgba(1, 0.6, 0, 0.08) : "transparent")
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                Label { text: ts;  Layout.preferredWidth: 150; font.pixelSize: 12 }
                Label { text: ecu; Layout.preferredWidth: 60;  font.pixelSize: 12 }
                Label { text: app; Layout.preferredWidth: 60;  font.pixelSize: 12 }
                Label { text: ctx; Layout.preferredWidth: 70;  font.pixelSize: 12 }
                Label { text: lvl; Layout.preferredWidth: 70;  font.pixelSize: 12; font.bold: lvl !== "INFO" }
                Label { text: msg; Layout.fillWidth: true;     font.pixelSize: 12; elide: Text.ElideRight }
            }
        }
    }

    // 간단 테마 토글 (라이트/다크)
    property bool darkTheme: true
    Material.theme: darkTheme ? Material.Dark : Material.Light
    Material.accent: Material.Blue

    // --- 데이터 모델 정의 ---
    ListModel { id: logModel
        ListElement { ts: "12:00:01.234"; ecu: "ICU"; app: "NAV"; ctx: "ROUTE"; lvl: "INFO"; msg: "Route recalculation started" }
        ListElement { ts: "12:00:03.101"; ecu: "ICU"; app: "BT";  ctx: "CONN";  lvl: "WARN"; msg: "BT reconnect attempt #2" }
        ListElement { ts: "12:00:03.450"; ecu: "CCU"; app: "NET"; ctx: "HTTP";  lvl: "ERROR";msg: "GET /v1/token 401 Unauthorized" }
        ListElement { ts: "12:00:04.012"; ecu: "ICU"; app: "SYS"; ctx: "MEM";   lvl: "ERROR";msg: "malloc failed at mm.c:125" }
        ListElement { ts: "12:00:04.500"; ecu: "CCU"; app: "NET"; ctx: "DNS";   lvl: "WARN"; msg: "resolve api.example.com timeout" }
        ListElement { ts: "12:00:05.303"; ecu: "ICU"; app: "GUI"; ctx: "LAYOUT";lvl: "INFO"; msg: "inflate panel OK" }
    }

    ListModel { id: kpiModel
        ListElement { label: "Throughput"; value: "1,284 /h"; trend: "+5.3%" }
        ListElement { label: "Latency (p95)"; value: "142 ms";   trend: "-8.1%" }
        ListElement { label: "Errors";       value: "0.23%";     trend: "-0.04%" }
        ListElement { label: "Uptime";       value: "99.97%";    trend: "+0.01%" }
    }

    ListModel { id: stepModel
        ListElement { title: "요구분석"; desc: "CuRS → IRE 정제"; status: "done" }
        ListElement { title: "설계";   desc: "SysRS/SAD/SDD";   status: "active" }
        ListElement { title: "구현";   desc: "Module/Feature";  status: "pending" }
        ListElement { title: "검증";   desc: "TS/GUI/통신";      status: "pending" }
        ListElement { title: "릴리스"; desc: "HIL/차량";         status: "pending" }
    }

    ListModel { id: sequenceModel
        ListElement { text: "NET: DNS timeout" }
        ListElement { text: "NET: HTTP 401" }
    }

    ListModel { id: pluginModel
        ListElement { name: "IParserPlugin"; version: "1.0"; enabled: true }
        ListElement { name: "IRulePlugin"; version: "1.0"; enabled: true }
        ListElement { name: "IVisualizationPlugin"; version: "1.0"; enabled: true }
        ListElement { name: "Exporter"; version: "1.0"; enabled: true }
    }

    // 헤더 바 -----------------------------------------------------
    header: Frame {
        padding: 8
        RowLayout {
            anchors.fill: parent
            spacing: 16

            Label { text: "DLT Log Analyzer"; font.pixelSize: 18; Layout.alignment: Qt.AlignVCenter }
            Rectangle { width: 1; height: 20; color: Material.foreground; opacity: 0.2; Layout.alignment: Qt.AlignVCenter }

            RowLayout {
                spacing: 8
                Label { text: qsTr("반응형"); font.pixelSize: 12; opacity: 0.7 }
                Label { text: qsTr("고대비(AA)"); font.pixelSize: 12; opacity: 0.7 }
                Label { text: qsTr("키보드 접근성"); font.pixelSize: 12; opacity: 0.7 }
                Label { text: qsTr("다국어"); font.pixelSize: 12; opacity: 0.7 }
                Label { text: qsTr("플러그인"); font.pixelSize: 12; opacity: 0.7 }
            }

            Item { Layout.fillWidth: true }

            TextField {
                id: searchField
                placeholderText: qsTr("검색 (Ctrl+/)")
                Layout.preferredWidth: 260
                Accessible.name: qsTr("전체 로그 검색")
            }
            Button {
                icon.name: darkTheme ? "brightness-5" : "brightness-3"
                display: AbstractButton.IconOnly
                onClicked: darkTheme = !darkTheme
                Accessible.name: qsTr("라이트/다크 테마 전환")
                ToolTip.text: qsTr("테마 전환")
            }
            Button {
                icon.name: "notifications"
                display: AbstractButton.IconOnly
                Accessible.name: qsTr("알림 확인")
                ToolTip.text: qsTr("알림")
            }
        }
    }

    // 본문 --------------------------------------------------------
    RowLayout {
        anchors.fill: parent

        // 사이드바 (샘플 선택 + 설정)
        Frame {
            id: side
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            padding: 8
            background: Rectangle { color: Material.background }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Label { text: qsTr("샘플 선택"); font.bold: true }
                ButtonGroup {
                    id: viewButtonGroup
                    buttons: sideBarButtons.children
                    onClicked: stack.currentIndex = viewButtonGroup.checkedButton.index
                }
                Column {
                    id: sideBarButtons
                    spacing: 4
                    Button { text: qsTr("A. 대시보드/분석"); checkable: true; checked: true; property int index: 0 }
                    Button { text: qsTr("B. 규칙 관리자");   checkable: true; property int index: 1 }
                    Button { text: qsTr("C. AI 심층 분석");  checkable: true; property int index: 2 }
                }

                Rectangle { height: 1; width: parent.width; color: Material.foreground; opacity: 0.15; Layout.topMargin: 8; Layout.bottomMargin: 8 }

                Label { text: qsTr("환경 설정"); font.bold: true }
                // 접근성/테마 옵션 (NFR-07)
                GridLayout {
                    columns: 2
                    columnSpacing: 8
                    Label { text: qsTr("고대비(AA)"); Layout.alignment: Qt.AlignVCenter }
                    Switch { checked: true; Layout.alignment: Qt.AlignRight }

                    Label { text: qsTr("ARIA 힌트"); Layout.alignment: Qt.AlignVCenter }
                    Switch { checked: true; Layout.alignment: Qt.AlignRight }

                    Label { text: qsTr("밀도"); Layout.alignment: Qt.AlignVCenter }
                    ComboBox { model: ["Comfort", "Compact"]; currentIndex: 0; Layout.fillWidth: true }

                    Label { text: qsTr("Locale"); Layout.alignment: Qt.AlignVCenter }
                    ComboBox { model: ["ko-KR","en-US","de-DE","vi-VN"]; currentIndex: 0; Layout.fillWidth: true }
                }

                Item { Layout.fillHeight: true }
                Label { text: qsTr("접근성: 탭 이동/단축키 지원"); font.pixelSize: 11; opacity: 0.7 }
            }
        }

        // 컨텐츠 스택 (A/B/C)
        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            // ---------------- A) Dashboard / 분석 -----------------
            Flickable {
                clip: true
                contentWidth: parent.width
                contentHeight: dashCol.implicitHeight + 32
                ScrollBar.vertical: ScrollBar {}

                ColumnLayout {
                    id: dashCol; width: parent.width; spacing: 8

                    // KPI 카드 (자리표시자)
                    GridLayout {
                        columns: 4; columnSpacing: 8; rowSpacing: 8
                        Repeater {
                            model: kpiModel
                            Loader {
                                sourceComponent: kpiCard
                                onLoaded: {
                                    item.label = model.label
                                    item.value = model.value
                                    item.trend = model.trend
                                }
                            }
                        }
                    }

                    // 로그 테이블 및 컨트롤 (FR-02/07)
                    Frame {
                        Layout.fillWidth: true
                        padding: 8
                        ColumnLayout {
                            spacing: 6
                            RowLayout {
                                Label { text: qsTr("로그 테이블 (FR-02/07)"); font.bold: true }
                                Item { Layout.fillWidth: true }
                                ComboBox { id: levelFilter; model: ["ALL","INFO","WARN","ERROR"]; currentIndex: 0 }
                                Button { id: filterBtn; text: qsTr("필터") }
                                CheckBox { id: liveCheck; text: qsTr("Live"); checked: false }
                            }

                            // 헤더
                            Rectangle {
                                height: 28; color: Qt.rgba(1,1,1,0.06)
                                RowLayout { anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                                    Label { text: "Timestamp"; Layout.preferredWidth: 150; font.pixelSize: 12; font.bold: true }
                                    Label { text: "ECU";       Layout.preferredWidth: 60;  font.pixelSize: 12; font.bold: true }
                                    Label { text: "APP";       Layout.preferredWidth: 60;  font.pixelSize: 12; font.bold: true }
                                    Label { text: "CTX";       Layout.preferredWidth: 70;  font.pixelSize: 12; font.bold: true }
                                    Label { text: "Level";     Layout.preferredWidth: 70;  font.pixelSize: 12; font.bold: true }
                                    Label { text: "Message";   Layout.fillWidth: true;     font.pixelSize: 12; font.bold: true }
                                }
                            }

                            // 바디
                            ListView {
                                id: logView
                                implicitHeight: 360
                                model: logModel
                                clip: true
                                delegate: Loader {
                                    sourceComponent: logRow
                                    onLoaded: {
                                        item.ts = model.ts; item.ecu = model.ecu; item.app = model.app; item.ctx = model.ctx; item.lvl = model.lvl; item.msg = model.msg
                                        // 실제 구현에서는 SortFilterProxyModel을 사용하여 필터링합니다.
                                        item.visible = levelFilter.currentText === "ALL" || levelFilter.currentText === model.lvl
                                    }
                                }
                                ScrollBar.vertical: ScrollBar {}
                            }
                        }
                    }

                    // 시간대별 에러 분포 (자리표시자 차트)
                    Frame {
                        Layout.fillWidth: true
                        padding: 8
                        ColumnLayout { spacing: 6
                            Label { text: qsTr("시간대별 에러 분포 (FR-07)"); font.bold: true }
                            Repeater {
                                model: 5
                                RowLayout {
                                    property string t: (index+12).toString().padStart(2, '0') + ":0" + index
                                    Label { text: t; Layout.preferredWidth: 50; font.pixelSize: 12; opacity: 0.7 }
                                    Rectangle { Layout.fillWidth: true; height: 8; radius: 4; color: "#777" }
                                    Rectangle { width: (index+1)*40; height: 8; radius: 4; color: Material.primary }
                                }
                            }
                            Label { text: qsTr("※ 실제 구현 시 QtCharts/pyqtgraph 등으로 대체"); font.pixelSize: 11; opacity: 0.7 }
                        }
                    }

                    // 3단계 분석 프로세스 진행도
                    Frame {
                        Layout.fillWidth: true
                        padding: 8
                        ColumnLayout { spacing: 6
                            RowLayout {
                                Label { text: qsTr("프로세스 진행도 (3단계 분석)"); font.bold: true }
                                Item { Layout.fillWidth: true }
                                Label { text: "FR-03 ▶ FR-04 ▶ FR-05"; font.pixelSize: 12; opacity: 0.7 }
                            }
                            GridLayout { columns: 5; columnSpacing: 8; rowSpacing: 8
                                Repeater { model: stepModel
                                    Frame { Layout.fillWidth: true
                                        ColumnLayout {
                                            anchors.margins: 8
                                            spacing: 2
                                            Label { text: model.title; font.bold: true }
                                            Label { text: model.desc;  font.pixelSize: 12; opacity: 0.7 }
                                            Label {
                                                text: model.status.toUpperCase()
                                                font.pixelSize: 12; font.bold: true
                                                color: model.status==="done"? "#5ee098" : model.status==="active"? Material.accent : "#aaa"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Label { text: qsTr("단축키: Ctrl+/ 검색 · Ctrl+K 명령팔레트 · J/K 라인 이동"); font.pixelSize: 11; opacity: 0.7 }
                        Item { Layout.fillWidth: true }
                        Button { text: qsTr("Export (FR-06)") }
                        Button { text: qsTr("세션 저장 (FR-08)") }
                    }

                    Label { text: qsTr("NFR-03 성능, NFR-07 접근성(고대비/스크린리더)"); font.pixelSize: 11; opacity: 0.7 }
                }
            }

            // ---------------- B) 규칙 관리자 -----------------------
            Flickable {
                clip: true
                contentWidth: parent.width
                contentHeight: ruleCol.implicitHeight + 32
                ScrollBar.vertical: ScrollBar {}

                ColumnLayout {
                    id: ruleCol; width: parent.width; spacing: 8

                    GridLayout { columns: 2; columnSpacing: 8; rowSpacing: 8; Layout.fillWidth: true
                        // 규칙 생성 (FR-03.1)
                        Frame {
                            Layout.fillWidth: true
                            padding: 8
                            ColumnLayout { spacing: 6
                                Label { text: qsTr("규칙 생성 (FR-03.1)"); font.bold: true }
                                GridLayout { columns: 2; columnSpacing: 8; rowSpacing: 6
                                    Label { text: qsTr("규칙 이름") }
                                    TextField { id: ruleName; text: qsTr("네트워크 인증 오류 탐지"); Layout.fillWidth: true }

                                    Label { text: qsTr("로그 레벨") }
                                    ComboBox { id: ruleLevel; model: ["INFO","WARN","ERROR"]; currentIndex: 2; Layout.fillWidth: true }

                                    Label { text: qsTr("APP ID") }
                                    TextField { id: ruleApp; text: "NET"; placeholderText: qsTr("예: NET, GUI, SYS"); Layout.fillWidth: true }

                                    Label { text: qsTr("키워드") }
                                    TextField { id: ruleKeywords; text: "401, Unauthorized"; placeholderText: qsTr("comma,separated"); Layout.fillWidth: true }

                                    Label { text: qsTr("설명") }
                                    TextArea { id: ruleDesc; text: qsTr("HTTP 401 패턴 포착 및 이전 DNS 오류 시퀀스 검사"); wrapMode: TextArea.Wrap; Layout.fillWidth: true }
                                }
                                RowLayout { spacing: 8; Layout.alignment: Qt.AlignRight
                                    Button { text: qsTr("규칙 저장") }
                                    Button { text: qsTr("가져오기") }
                                    Button { text: qsTr("내보내기") }
                                }
                            }
                        }

                        // 정규식 빌더 (FR-03.2)
                        Frame {
                            Layout.fillWidth: true
                            padding: 8
                            ColumnLayout { spacing: 6
                                Label { text: qsTr("정규표현식 빌더 (FR-03.2)"); font.bold: true }
                                TextField { id: regexField; text: "(ERROR|WARN) (.*)"; Accessible.name: qsTr("정규식") }
                                Frame { Layout.fillWidth: true; implicitHeight: 200
                                    ListView {
                                        anchors.fill: parent
                                        model: logModel
                                        clip: true
                                        delegate: Rectangle {
                                            width: parent.width; height: 28
                                            color: {
                                                var re = new RegExp(regexField.text)
                                                var s = model.lvl + " " + model.msg
                                                return re.test(s) ? Qt.rgba(0,1,0,0.08) : "transparent"
                                            }
                                            RowLayout { anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                                                Label { text: model.lvl + " · " + model.msg; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Label { text: (new RegExp(regexField.text)).test(model.lvl+" "+model.msg) ? "MATCH" : "-" }
                                            }
                                        }
                                        ScrollBar.vertical: ScrollBar {}
                                    }
                                }
                            }
                        }
                    }

                    // 시퀀스 빌더 (FR-03.2/03.3)
                    Frame {
                        Layout.fillWidth: true
                        padding: 8
                        ColumnLayout { spacing: 6
                            RowLayout { spacing: 8
                                Label { text: qsTr("시퀀스 빌더 (FR-03.2)"); font.bold: true }
                                Label { text: qsTr("Excel → JSON 파이프라인으로 가져오기/내보내기 지원 (FR-03.3)"); font.pixelSize: 12; opacity: 0.7 }
                            }
                            Flow { spacing: 8; width: parent.width
                                Repeater { model: sequenceModel
                                    Frame {
                                        ColumnLayout { anchors.margins: 6; spacing: 4; width: 280
                                            TextField { text: model.text; Layout.fillWidth: true }
                                            Label { text: "STEP " + (index+1); font.pixelSize: 11; opacity: 0.7 }
                                        }
                                    }
                                }
                                Button { text: qsTr("+ 단계 추가"); onClicked: sequenceModel.append({text: "NEW STEP"}) }
                            }
                        }
                    }
                }
            }

            // ---------------- C) AI 심층 분석 & 해결 가이드 --------
            Flickable {
                clip: true
                contentWidth: parent.width
                contentHeight: aiCol.implicitHeight + 32
                ScrollBar.vertical: ScrollBar {}

                ColumnLayout {
                    id: aiCol; width: parent.width; spacing: 8

                    GridLayout { columns: 3; columnSpacing: 8; rowSpacing: 8; Layout.fillWidth: true
                        // AI 대화형 분석 (FR-04)
                        Frame { Layout.columnSpan: 2; Layout.fillWidth: true
                            padding: 8
                            ColumnLayout { spacing: 6
                                Label { text: qsTr("AI 대화형 분석 (FR-04)"); font.bold: true }
                                ListModel { id: chatModel
                                    ListElement { role: "system";    text: "1차 규칙매칭 결과 92건 요약 완료. 이상 패턴 3개 발견." }
                                    ListElement { role: "user";      text: "HTTP 401 원인과 선행 이벤트를 요약해줘." }
                                    ListElement { role: "assistant"; text: "전후 100라인 분석: 401 이전 DNS timeout 2회, 토큰 만료 징후. 인증 서버 clock skew 의심." }
                                }
                                ListView {
                                    id: chatList
                                    implicitHeight: 300
                                    model: chatModel
                                    delegate: Frame {
                                        width: parent.width
                                        background: Rectangle { color: model.role==="user"? Qt.rgba(1,1,1,0.02): Qt.rgba(1,1,1,0.06); radius: 6 }
                                        ColumnLayout { anchors.margins: 6; spacing: 2
                                            Label { text: model.role.toUpperCase(); font.pixelSize: 11; opacity: 0.7; font.bold: true }
                                            Label { text: model.text; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    ScrollBar.vertical: ScrollBar {}
                                }
                                RowLayout { spacing: 6
                                    TextField { id: chatInput; placeholderText: qsTr("자연어로 질문… (민감정보 제외, 최소 스니펫 전송)"); Layout.fillWidth: true }
                                    Button { text: qsTr("전송"); onClicked: if (chatInput.text.length>0) { chatModel.append({role:"user", text: chatInput.text}); chatInput.text=""; } }
                                }
                                Label { text: qsTr("NFR-05 보안: 최소 스니펫 전송·로컬 키 암호화 저장"); font.pixelSize: 11; opacity: 0.7 }
                            }
                        }

                        // 실행 가능한 해결 가이드 (FR-05/06/08/09)
                        Frame {
                            Layout.fillWidth: true
                            padding: 8
                            ColumnLayout { spacing: 12
                                Label { text: qsTr("실행 가능한 해결 가이드 (FR-05)"); font.bold: true }
                                ColumnLayout {
                                    spacing: 8
                                    Label { text: "1) 인증 토큰 재발급 로직 확인: auth_manager.cpp:125 (retry/backoff)"; wrapMode: Text.WordWrap }
                                    Label { text: "2) DNS 재시도 정책 상향: net_resolver.cpp timeout → 2s → 5s"; wrapMode: Text.WordWrap }
                                    Label { text: "3) 서버/클라이언트 NTP 동기화 상태 점검"; wrapMode: Text.WordWrap }
                                }
                                Item { Layout.fillHeight: true }
                                RowLayout { spacing: 6
                                    Button { text: qsTr("리포트 내보내기 (FR-06)") }
                                    Button { text: qsTr("세션 저장 (FR-08)") }
                                }
                                Label { text: qsTr("주석/태그는 로그 테이블 컨텍스트에서 (FR-09)"); font.pixelSize: 11; opacity: 0.7 }
                            }
                        }
                    }

                    // 플러그인 매니저 (FR-10/11)
                    Frame {
                        Layout.fillWidth: true
                        padding: 8
                        ColumnLayout { spacing: 6
                            Label { text: qsTr("플러그인 매니저 (FR-10)"); font.bold: true }
                            Flow { spacing: 8; width: parent.width
                                Repeater { model: pluginModel
                                    Frame {
                                        width: 280
                                        padding: 8
                                        ColumnLayout { spacing: 4
                                            Label { text: model.name; font.bold: true }
                                            Label { text: qsTr("버전 ") + model.version + qsTr(" · ") + (model.enabled? qsTr("활성"): qsTr("비활성")) }
                                            RowLayout { spacing: 6
                                                Button { text: model.enabled? qsTr("비활성화"): qsTr("활성화"); onClicked: pluginModel.setProperty(index, "enabled", !model.enabled) }
                                                Button { text: qsTr("제거") }
                                            }
                                        }
                                    }
                                }
                                Button { text: qsTr("+ 새 플러그인 설치") }
                            }
                            Label { text: qsTr("충돌 시 플러그인 격리/안전 로드 정책 · 자동 업데이트 체크(FR-11)"); font.pixelSize: 11; opacity: 0.7 }
                        }
                    }
                }
            }
        }
    }
}