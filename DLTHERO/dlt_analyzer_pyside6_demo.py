# ============================================================
# DLT Log Analyzer - PySide6 샘플 3종 (CuRS/NFR 반영)
# A) 대시보드/분석 (FR-01/02/06/07/08/12, NFR-03/07)
# B) 규칙 관리자 (FR-03.1/03.2/03.3)
# C) AI 심층 분석 & 해결 가이드 (FR-04/05/06/08/09/10/11, NFR-05)
# ------------------------------------------------------------
# 실행 방법:
#   pip install PySide6
#   python dlt_analyzer_pyside6_demo.py
# ============================================================

from __future__ import annotations
import sys, csv, json, re
from dataclasses import dataclass
from typing import List, Any

from PySide6.QtCore import Qt, QAbstractTableModel, QModelIndex, QSortFilterProxyModel, QSize
from PySide6.QtGui import QAction, QPalette, QColor
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QGridLayout,
    QStackedWidget, QLabel, QPushButton, QCheckBox, QComboBox, QLineEdit, QTextEdit,
    QListWidget, QListWidgetItem, QGroupBox, QFormLayout, QProgressBar, QFileDialog,
    QFrame, QSplitter, QMessageBox, QTableView
)

# ----------------------------- 샘플 데이터 -----------------------------
SAMPLE_LOGS = [
    {"ts": "12:00:01.234", "ecu": "ICU", "app": "NAV", "ctx": "ROUTE", "lvl": "INFO",  "msg": "Route recalculation started"},
    {"ts": "12:00:03.101", "ecu": "ICU", "app": "BT",  "ctx": "CONN",  "lvl": "WARN",  "msg": "BT reconnect attempt #2"},
    {"ts": "12:00:03.450", "ecu": "CCU", "app": "NET", "ctx": "HTTP",  "lvl": "ERROR", "msg": "GET /v1/token 401 Unauthorized"},
    {"ts": "12:00:04.012", "ecu": "ICU", "app": "SYS", "ctx": "MEM",   "lvl": "ERROR", "msg": "malloc failed at mm.c:125"},
    {"ts": "12:00:04.500", "ecu": "CCU", "app": "NET", "ctx": "DNS",   "lvl": "WARN",  "msg": "resolve api.example.com timeout"},
    {"ts": "12:00:05.303", "ecu": "ICU", "app": "GUI", "ctx": "LAYOUT","lvl": "INFO",  "msg": "inflate panel OK"},
]

KPI = [
    ("Throughput", "1,284 /h", "+5.3%"),
    ("Latency (p95)", "142 ms", "-8.1%"),
    ("Errors", "0.23%", "-0.04%"),
    ("Uptime", "99.97%", "+0.01%"),
]

STEPS = [
    ("요구분석", "CuRS → IRE 정제", "done"),
    ("설계",   "SysRS/SAD/SDD",   "active"),
    ("구현",   "Module/Feature",  "pending"),
    ("검증",   "TS/GUI/통신",      "pending"),
    ("릴리스", "HIL/차량",         "pending"),
]

PLUGINS = [
    ("IParserPlugin", "1.0", True),
    ("IRulePlugin", "1.0", True),
    ("IVisualizationPlugin", "1.0", True),
    ("Exporter", "1.0", True),
]

# ----------------------------- 모델 -----------------------------
class LogTableModel(QAbstractTableModel):
    headers = ["Timestamp", "ECU", "APP", "CTX", "Level", "Message"]
    keys = ["ts", "ecu", "app", "ctx", "lvl", "msg"]

    def __init__(self, rows: List[dict]):
        super().__init__()
        self._rows = rows

    def rowCount(self, parent=QModelIndex()) -> int:
        return len(self._rows)

    def columnCount(self, parent=QModelIndex()) -> int:
        return len(self.keys)

    def data(self, index: QModelIndex, role=Qt.DisplayRole) -> Any:
        if not index.isValid():
            return None
        row = self._rows[index.row()]
        key = self.keys[index.column()]
        if role == Qt.DisplayRole:
            return str(row.get(key, ""))
        if role == Qt.BackgroundRole and key == "lvl":
            lvl = row.get("lvl", "")
            if lvl == "ERROR":
                return QColor(255, 0, 0, 30)
            elif lvl == "WARN":
                return QColor(255, 165, 0, 20)
        return None

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if role == Qt.DisplayRole and orientation == Qt.Horizontal:
            return self.headers[section]
        return super().headerData(section, orientation, role)


class LevelFilterProxy(QSortFilterProxyModel):
    def __init__(self):
        super().__init__()
        self.level = "ALL"

    def setLevel(self, level: str):
        self.level = level
        self.invalidateFilter()

    def filterAcceptsRow(self, source_row, source_parent) -> bool:
        if self.level == "ALL":
            return True
        idx = self.sourceModel().index(source_row, 4, source_parent)  # Level column
        return self.sourceModel().data(idx) == self.level


# ----------------------------- UI 빌더 -----------------------------
class DashboardView(QWidget):
    def __init__(self, model: LogTableModel, proxy: LevelFilterProxy):
        super().__init__()
        self.model = model
        self.proxy = proxy
        self._build()

    def _build(self):
        root = QVBoxLayout(self)

        # KPI 카드 (FR-07 일부 시각화)
        kpi_grid = QGridLayout()
        for i, (label, value, trend) in enumerate(KPI):
            box = QGroupBox(label)
            box.setAccessibleName(f"KPI {label}")
            v = QVBoxLayout(box)
            lbl_val = QLabel(f"<b style='font-size:18px'>{value}</b>")
            lbl_trend = QLabel(trend)
            lbl_trend.setStyleSheet("color: #66bb6a" if trend.startswith("+") else "color: #888")
            v.addWidget(lbl_val)
            v.addWidget(lbl_trend)
            kpi_grid.addWidget(box, 0, i)
        root.addLayout(kpi_grid)

        # 로그 테이블 (FR-02/07)
        controls = QHBoxLayout()
        controls.addWidget(QLabel("로그 테이블 (FR-02/07)"))
        controls.addStretch(1)
        level_cb = QComboBox(); level_cb.addItems(["ALL","INFO","WARN","ERROR"])  # 필터
        level_cb.currentTextChanged.connect(self.proxy.setLevel)
        controls.addWidget(level_cb)
        live_ck = QCheckBox("Live"); controls.addWidget(live_ck)  # 자리표시자
        root.addLayout(controls)

        table = QTableView()
        table.setModel(self.proxy)
        table.horizontalHeader().setStretchLastSection(True)
        table.horizontalHeader().setDefaultSectionSize(110)
        table.verticalHeader().setVisible(False)
        table.setAlternatingRowColors(True)
        table.setSortingEnabled(True)
        root.addWidget(table)

        # 시간대별 에러 분포 (자리표시자)
        chart_box = QGroupBox("시간대별 에러 분포 (FR-07)")
        hb = QVBoxLayout(chart_box)
        for i, t in enumerate(["12:00","12:01","12:02","12:03","12:04"]):
            row = QHBoxLayout()
            row.addWidget(QLabel(t))
            prog_bg = QProgressBar(); prog_bg.setRange(0, 100); prog_bg.setValue((i+1)*15)
            prog_bg.setTextVisible(False)
            row.addWidget(prog_bg)
            hb.addLayout(row)
        root.addWidget(chart_box)

        # 3단계 분석 진행도
        proc = QGroupBox("프로세스 진행도 (3단계 분석)")
        grid = QGridLayout(proc)
        for i, (title, desc, status) in enumerate(STEPS):
            box = QGroupBox(title)
            v = QVBoxLayout(box)
            v.addWidget(QLabel(f"<span style='color:#888'>{desc}</span>"))
            color = "#5ee098" if status=="done" else ("#7eb6ff" if status=="active" else "#aaa")
            v.addWidget(QLabel(f"<b><span style='color:{color}'>{status}</span></b>"))
            grid.addWidget(box, 0, i)
        root.addWidget(proc)

        # Export/세션 저장 버튼 (FR-06/08)
        btn_row = QHBoxLayout()
        btn_export = QPushButton("Export (FR-06)"); btn_export.clicked.connect(self.export_csv)
        btn_save = QPushButton("세션 저장 (FR-08)"); btn_save.clicked.connect(self.save_session)
        btn_row.addStretch(1); btn_row.addWidget(btn_export); btn_row.addWidget(btn_save)
        root.addLayout(btn_row)

        root.addWidget(QLabel("NFR-03 성능, NFR-07 접근성(고대비/스크린리더)"))

    # --------- 동작 스텁 ---------
    def export_csv(self):
        path, _ = QFileDialog.getSaveFileName(self, "Export CSV", "analysis.csv", "CSV Files (*.csv)")
        if not path:
            return
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(LogTableModel.headers)
            for r in range(self.proxy.rowCount()):
                row = []
                for c in range(self.proxy.columnCount()):
                    idx = self.proxy.index(r, c)
                    row.append(self.proxy.data(idx))
                writer.writerow(row)
        QMessageBox.information(self, "Export", "CSV 내보내기 완료")

    def save_session(self):
        # 간단 세션 JSON: 필터 상태/표시 열 등 (자리표시자)
        data = {
            "filters": {"level": self.proxy.level},
            "notes": "세션 저장 예시",
        }
        path, _ = QFileDialog.getSaveFileName(self, "Save Session", "session.json", "JSON Files (*.json)")
        if not path:
            return
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        QMessageBox.information(self, "Session", "세션 저장 완료")


class RuleManagerView(QWidget):
    def __init__(self):
        super().__init__()
        self._build()

    def _build(self):
        root = QVBoxLayout(self)

        grid = QGridLayout(); grid.setHorizontalSpacing(12); grid.setVerticalSpacing(8)
        # 규칙 생성 (FR-03.1)
        grp_rule = QGroupBox("규칙 생성 (FR-03.1)")
        form = QFormLayout(grp_rule)
        self.ed_name = QLineEdit("네트워크 인증 오류 탐지")
        self.cb_level = QComboBox(); self.cb_level.addItems(["INFO","WARN","ERROR"]) ; self.cb_level.setCurrentText("ERROR")
        self.ed_app = QLineEdit("NET")
        self.ed_keywords = QLineEdit("401, Unauthorized")
        self.ed_desc = QTextEdit("HTTP 401 패턴 포착 및 이전 DNS 오류 시퀀스 검사")
        form.addRow("규칙 이름", self.ed_name)
        form.addRow("로그 레벨", self.cb_level)
        form.addRow("APP ID", self.ed_app)
        form.addRow("키워드", self.ed_keywords)
        form.addRow("설명", self.ed_desc)
        btns = QHBoxLayout()
        btns.addStretch(1)
        btns.addWidget(QPushButton("규칙 저장"))
        btns.addWidget(QPushButton("가져오기"))
        btns.addWidget(QPushButton("내보내기"))
        v = QVBoxLayout(); v.addWidget(grp_rule); v.addLayout(btns)
        grid.addLayout(v, 0, 0)

        # 정규식 빌더 (FR-03.2)
        grp_regex = QGroupBox("정규표현식 빌더 (FR-03.2)")
        v2 = QVBoxLayout(grp_regex)
        self.ed_regex = QLineEdit("(ERROR|WARN) (.*)")
        v2.addWidget(self.ed_regex)
        self.list_preview = QListWidget(); self.refresh_preview()
        v2.addWidget(self.list_preview)
        self.ed_regex.textChanged.connect(self.refresh_preview)
        grid.addWidget(grp_regex, 0, 1)

        # 시퀀스 빌더 (FR-03.2/03.3)
        grp_seq = QGroupBox("시퀀스 빌더 (FR-03.2)")
        v3 = QVBoxLayout(grp_seq)
        self.seq_list = QListWidget(); self.seq_list.addItems(["NET: DNS timeout", "NET: HTTP 401"]) ; v3.addWidget(self.seq_list)
        btn_add = QPushButton("+ 단계 추가")
        def _add():
            self.seq_list.addItem("NEW STEP")
        btn_add.clicked.connect(_add)
        v3.addWidget(btn_add)

        root.addLayout(grid)
        root.addWidget(grp_seq)
        tip = QLabel("Excel → JSON 파이프라인으로 가져오기/내보내기 지원 (FR-03.3)")
        tip.setStyleSheet("color:#888")
        root.addWidget(tip)

    def refresh_preview(self):
        self.list_preview.clear()
        try:
            pat = re.compile(self.ed_regex.text())
        except re.error:
            item = QListWidgetItem("정규식 오류")
            item.setBackground(QColor(255,0,0,40))
            self.list_preview.addItem(item)
            return
        for r in SAMPLE_LOGS:
            s = f"{r['lvl']} · {r['msg']}"
            item = QListWidgetItem(s)
            if pat.search(f"{r['lvl']} {r['msg']}"):
                item.setBackground(QColor(0,255,0,40))
                item.setText(f"✓ {s}")
            self.list_preview.addItem(item)


class AIAnalysisView(QWidget):
    def __init__(self):
        super().__init__()
        self._build()

    def _build(self):
        root = QVBoxLayout(self)

        # 상단 2:1 레이아웃
        top = QHBoxLayout()

        # AI 대화형 분석 (FR-04)
        grp_chat = QGroupBox("AI 대화형 분석 (FR-04)")
        v1 = QVBoxLayout(grp_chat)
        self.chat_list = QListWidget()
        for role, text in [
            ("system", "1차 규칙매칭 결과 92건 요약 완료. 이상 패턴 3개 발견."),
            ("user", "HTTP 401 원인과 선행 이벤트를 요약해줘."),
            ("assistant", "전후 100라인 분석: 401 이전 DNS timeout 2회, 토큰 만료 징후. 인증 서버 clock skew 의심."),
        ]:
            self.add_chat(role, text)
        v1.addWidget(self.chat_list)
        chat_box = QHBoxLayout()
        self.ed_chat = QLineEdit(); self.ed_chat.setPlaceholderText("자연어로 질문… (민감정보 제외, 최소 스니펫 전송)")
        btn_send = QPushButton("전송")
        btn_send.clicked.connect(lambda: self.send_chat())
        chat_box.addWidget(self.ed_chat)
        chat_box.addWidget(btn_send)
        v1.addLayout(chat_box)
        v1.addWidget(QLabel("NFR-05 보안: 최소 스니펫 전송·로컬 키 암호화 저장"))

        # 실행 가능한 해결 가이드 (FR-05/06/08/09)
        grp_fix = QGroupBox("실행 가능한 해결 가이드 (FR-05)")
        v2 = QVBoxLayout(grp_fix)
        v2.addWidget(QLabel("1) 인증 토큰 재발급 로직 확인: auth_manager.cpp:125 (retry/backoff)"))
        v2.addWidget(QLabel("2) DNS 재시도 정책 상향: net_resolver.cpp timeout → 2s → 5s"))
        v2.addWidget(QLabel("3) 서버/클라이언트 NTP 동기화 상태 점검"))
        btns = QHBoxLayout(); btns.addWidget(QPushButton("리포트 내보내기 (FR-06)")); btns.addWidget(QPushButton("세션 저장 (FR-08)")); v2.addLayout(btns)
        v2.addWidget(QLabel("주석/태그는 로그 테이블 컨텍스트에서 (FR-09)"))

        top.addWidget(grp_chat, 2)
        top.addWidget(grp_fix, 1)
        root.addLayout(top)

        # 플러그인 매니저 (FR-10/11)
        grp_plug = QGroupBox("플러그인 매니저 (FR-10)")
        flow = QHBoxLayout(grp_plug)
        self.plugin_widgets: List[QGroupBox] = []
        for name, ver, enabled in PLUGINS:
            card = QGroupBox(name)
            v = QVBoxLayout(card)
            lbl = QLabel(f"버전 {ver} · {'활성' if enabled else '비활성'}"); lbl.setStyleSheet("color:#888")
            btn_toggle = QPushButton("비활성화" if enabled else "활성화")
            def make_handler(card=card, lbl=lbl, btn=btn_toggle, state=enabled):
                def _():
                    new_state = (btn.text() == "활성화")
                    btn.setText("비활성화" if new_state else "활성화")
                    lbl.setText(f"버전 {ver} · {'활성' if new_state else '비활성'}")
                return _
            btn_toggle.clicked.connect(make_handler())
            v.addWidget(lbl); v.addWidget(btn_toggle)
            flow.addWidget(card)
        flow.addWidget(QPushButton("+ 새 플러그인 설치"))
        root.addWidget(grp_plug)

    def add_chat(self, role: str, text: str):
        item = QListWidgetItem(f"{role}: {text}")
        if role == "user":
            item.setBackground(QColor(255,255,255,10))
        elif role == "assistant":
            item.setBackground(QColor(200,200,255,30))
        else:
            item.setBackground(QColor(220,220,220,30))
        self.chat_list.addItem(item)

    def send_chat(self):
        text = self.ed_chat.text().strip()
        if not text:
            return
        self.add_chat("user", text)
        self.ed_chat.clear()
        # 실제 LLM 연동은 별도 모듈로 (NFR-05: 최소 스니펫)


# ----------------------------- 메인 윈도우 -----------------------------
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("DLT Log Analyzer - PySide6 Demo")
        self.resize(1280, 800)

        # 다크모드 토글
        self.dark = True
        self.apply_palette()

        # 좌측 내비 + 우측 컨텐츠
        splitter = QSplitter()
        nav = self._build_nav()

        # 로그 테이블 모델/프록시
        self.log_model = LogTableModel(SAMPLE_LOGS)
        self.proxy = LevelFilterProxy(); self.proxy.setSourceModel(self.log_model)

        self.stack = QStackedWidget()
        self.stack.addWidget(DashboardView(self.log_model, self.proxy))  # A
        self.stack.addWidget(RuleManagerView())                           # B
        self.stack.addWidget(AIAnalysisView())                            # C

        splitter.addWidget(nav)
        splitter.addWidget(self.stack)
        splitter.setStretchFactor(1, 1)
        self.setCentralWidget(splitter)

        # 메뉴/툴바
        view_menu = self.menuBar().addMenu("보기")
        act_dark = QAction("다크 모드", self, checkable=True, checked=True)
        act_dark.triggered.connect(self.toggle_dark)
        view_menu.addAction(act_dark)

    def _build_nav(self) -> QWidget:
        w = QWidget(); v = QVBoxLayout(w)
        title = QLabel("샘플 선택"); title.setStyleSheet("font-weight:bold")
        v.addWidget(title)
        # 샘플 전환 버튼
        btn_a = QPushButton("A. 대시보드/분석"); btn_a.clicked.connect(lambda: self.stack.setCurrentIndex(0))
        btn_b = QPushButton("B. 규칙 관리자");   btn_b.clicked.connect(lambda: self.stack.setCurrentIndex(1))
        btn_c = QPushButton("C. AI 심층 분석");  btn_c.clicked.connect(lambda: self.stack.setCurrentIndex(2))
        for b in (btn_a, btn_b, btn_c):
            b.setMinimumHeight(32)
            v.addWidget(b)

        # 설정 (NFR-07)
        v.addWidget(self._hline())
        v.addWidget(QLabel("환경 설정"))
        ck_contrast = QCheckBox("고대비(AA)"); ck_contrast.setChecked(True)
        ck_aria = QCheckBox("스크린리더 힌트"); ck_aria.setChecked(True)
        v.addWidget(ck_contrast); v.addWidget(ck_aria)
        row1 = QHBoxLayout(); row1.addWidget(QLabel("밀도")); cb_density = QComboBox(); cb_density.addItems(["Comfort","Compact"]); row1.addWidget(cb_density)
        row2 = QHBoxLayout(); row2.addWidget(QLabel("Locale")); cb_locale = QComboBox(); cb_locale.addItems(["ko-KR","en-US","de-DE","vi-VN"]); row2.addWidget(cb_locale)
        v.addLayout(row1); v.addLayout(row2)

        v.addStretch(1)
        v.addWidget(QLabel("접근성: 탭 이동/단축키 지원"))
        return w

    def _hline(self):
        line = QFrame(); line.setFrameShape(QFrame.HLine); line.setFrameShadow(QFrame.Sunken)
        return line

    def toggle_dark(self, checked: bool):
        self.dark = checked
        self.apply_palette()

    def apply_palette(self):
        app = QApplication.instance()
        app.setStyle("Fusion")
        pal = QPalette()
        if self.dark:
            pal.setColor(QPalette.Window, QColor(25,25,25))
            pal.setColor(QPalette.WindowText, Qt.white)
            pal.setColor(QPalette.Base, QColor(30,30,30))
            pal.setColor(QPalette.AlternateBase, QColor(35,35,35))
            pal.setColor(QPalette.ToolTipBase, Qt.white)
            pal.setColor(QPalette.ToolTipText, Qt.white)
            pal.setColor(QPalette.Text, Qt.white)
            pal.setColor(QPalette.Button, QColor(45,45,45))
            pal.setColor(QPalette.ButtonText, Qt.white)
            pal.setColor(QPalette.Highlight, QColor(90,120,200))
            pal.setColor(QPalette.HighlightedText, Qt.black)
        else:
            pal = app.palette()  # 기본
        app.setPalette(pal)


def main():
    app = QApplication(sys.argv)
    win = MainWindow()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
