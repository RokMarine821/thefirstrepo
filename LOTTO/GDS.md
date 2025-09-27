# GUI 디자인 명세서 (GUI Design Specification)

## 1. 개요

이 문서는 로또 프로그램의 GUI 디자인에 대한 상세 명세를 제공합니다. Material Design을 기반으로 현대적이고 사용자 친화적인 인터페이스를 구현합니다.

## 2. 전체 레이아웃 구조

### 2.1 메인 윈도우 구성
```qml
ApplicationWindow {
    id: mainWindow
    width: 1280
    height: 800
    minimumWidth: 800
    minimumHeight: 600
}
```

- **상단 영역** (높이: 56dp)
  - 앱 타이틀 바
  - 메인 메뉴 버튼
  - 빠른 액션 버튼들
- **좌측 내비게이션 드로어** (너비: 280dp)
  - 메인 메뉴 항목들
  - 사용자 프로필 영역
- **메인 콘텐츠 영역**
  - StackView를 통한 화면 전환
  - 반응형 그리드 레이아웃
- **하단 상태 바** (높이: 24dp)
  - 연결 상태 표시
  - 현재 작업 진행률
  
### 2.2 컬러 팔레트
- **프라이머리 컬러**: #2196F3 (파란색)
  - 라이트 테마 변형: #64B5F6
  - 다크 테마 변형: #1976D2
- **세컨더리 컬러**: #FF4081 (핑크색)
  - 액션 및 강조 요소에 사용
- **백그라운드 컬러**:
  - 라이트 테마: #FFFFFF
  - 다크 테마: #121212
- **텍스트 컬러**:
  - 프라이머리: #000000 (87% opacity)
  - 세컨더리: #000000 (54% opacity)
  - 비활성화: #000000 (38% opacity)

## 3. 메인 화면 구성

### 3.1 번호 생성 화면
```qml
// NumberGenerationView.qml
ColumnLayout {
    spacing: 16

    // 빠른 생성 섹션
    Pane {
        Material.elevation: 1
        QuickGenerateSection {
            // 미리 정의된 규칙으로 빠른 번호 생성
        }
    }

    // 상세 규칙 설정 섹션
    Pane {
        Material.elevation: 1
        RuleConfigurationSection {
            // 규칙 조합 및 설정 UI
        }
    }

    // 생성 결과 표시 섹션
    Pane {
        Material.elevation: 2
        GeneratedNumbersSection {
            // 생성된 번호 표시 및 관리
        }
    }
}
```

#### 3.1.1 빠른 생성 섹션
- **컴포넌트**: MaterialButton, ComboBox
- **기능**:
  - 원터치 번호 생성
  - 프리셋 규칙 선택
  - 생성 개수 선택 (1~5게임)

#### 3.1.2 규칙 설정 섹션
- **컴포넌트**: CheckBox, Slider, TextField
- **레이아웃**: 그리드 형태 (2열 또는 3열)
- **규칙 카테고리**:
  - 번호 범위 설정
  - 합계 범위 설정
  - 패턴 기반 설정
  - 통계 기반 설정

#### 3.1.3 생성 결과 섹션
- **번호 표시**:
  - 원형 배지로 각 번호 표시
  - 정렬 옵션 (오름차순/생성순)
- **액션 버튼**:
  - 저장
  - 분석
  - 공유
  - 인쇄

### 3.2 통계 분석 화면
```qml
// StatisticsView.qml
GridLayout {
    columns: 2
    rowSpacing: 16
    columnSpacing: 16

    // 차트 영역
    ChartSection {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        // 다양한 통계 차트 표시
    }

    // 상세 데이터 테이블
    StatisticsTable {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        // 상세 통계 데이터 표시
    }
}
```

#### 3.2.1 차트 섹션
- **차트 종류**:
  - 번호별 출현 빈도 (막대 차트)
  - 당첨 패턴 분석 (파이 차트)
  - ROI 추이 (라인 차트)
  - 패턴 분포 (히트맵)

#### 3.2.2 데이터 테이블
- **정렬 가능한 컬럼**
- **필터링 기능**
- **데이터 내보내기**

### 3.3 설정 화면
```qml
// SettingsView.qml
ScrollView {
    ColumnLayout {
        spacing: 24

        // 일반 설정
        GeneralSettings { }

        // 규칙 관리
        RuleManagement { }

        // 알림 설정
        NotificationSettings { }

        // 데이터 관리
        DataManagement { }
    }
}
```

## 4. 사용자 경험 요소

### 4.1 애니메이션
- **화면 전환**: 부드러운 페이드 및 슬라이드
- **번호 생성**: 회전하는 공 애니메이션
- **데이터 업데이트**: 순차적 숫자 변경
- **로딩 상태**: 세련된 프로그레스 인디케이터

### 4.2 반응형 디자인
- **브레이크포인트**:
  - 모바일: < 600dp
  - 태블릿: 600dp - 1024dp
  - 데스크톱: > 1024dp
- **레이아웃 조정**:
  - 그리드 열 수 동적 변경
  - 사이드바 자동 숨김/표시
  - 컨텐츠 패딩 조정

### 4.3 접근성
- **키보드 내비게이션**
- **스크린 리더 지원**
- **고대비 모드**
- **글꼴 크기 조정**

## 5. 커스텀 컴포넌트

### 5.1 번호 선택기 (NumberPicker)
```qml
// NumberPicker.qml
Rectangle {
    property int number: 1
    property bool selected: false
    
    width: 40
    height: 40
    radius: width / 2
    
    color: selected ? Material.accent : Material.background
    border.color: Material.primary
    border.width: 1
    
    Label {
        anchors.centerIn: parent
        text: number
        color: selected ? Material.background : Material.foreground
    }
}
```

### 5.2 규칙 카드 (RuleCard)
```qml
// RuleCard.qml
Pane {
    Material.elevation: 1

    ColumnLayout {
        spacing: 8
        
        Label {
            text: rule.name
            font.bold: true
        }
        
        Label {
            text: rule.description
            wrapMode: Text.WordWrap
        }
        
        Row {
            spacing: 8
            RoundButton { text: "편집" }
            RoundButton { text: "삭제" }
        }
    }
}
```

## 6. 대화상자 디자인

### 6.1 번호 생성 결과
```qml
Dialog {
    title: "번호 생성 완료"
    
    GridLayout {
        columns: 2
        
        Repeater {
            model: generatedNumbers
            delegate: NumberSet {
                numbers: modelData
            }
        }
    }
    
    footer: DialogButtonBox {
        Button {
            text: "저장"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
        Button {
            text: "취소"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
    }
}
```

### 6.2 규칙 편집
```qml
Dialog {
    title: "규칙 편집"
    width: 400
    
    ColumnLayout {
        width: parent.width
        
        TextField {
            Layout.fillWidth: true
            placeholderText: "규칙 이름"
        }
        
        TextArea {
            Layout.fillWidth: true
            placeholderText: "규칙 설명"
        }
        
        // 규칙 파라미터 설정 UI
    }
}
```

## 7. 반응형 그리드 시스템

```qml
// ResponsiveGrid.qml
GridLayout {
    property int mobileColumns: 1
    property int tabletColumns: 2
    property int desktopColumns: 3
    
    columns: {
        if (width < 600) return mobileColumns
        if (width < 1024) return tabletColumns
        return desktopColumns
    }
    
    columnSpacing: 16
    rowSpacing: 16
}
```

## 8. 성능 최적화

### 8.1 지연 로딩
- QML 컴포넌트의 Loader 사용
- 대규모 데이터의 점진적 로딩
- 이미지 리소스의 지연 로딩

### 8.2 캐싱 전략
- 차트 데이터 캐싱
- 통계 결과 캐싱
- UI 상태 저장