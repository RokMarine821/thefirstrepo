# 로또 프로그램 시스템 요구사항 명세서 (SyRS)
## System Requirements Specification for Lotto Program

**문서 버전**: 1.0  
**작성일**: 2025년 9월 20일  
**프로젝트명**: QT/QML 기반 로또 프로그램
**관련 문서**: 로또 프로그램 고객 요구사항 명세서 (CuRS) v1.2

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 1.0 | 2025-09-20 | 초기 문서 작성 | 개발팀 |

---

## 1. 개요 (Overview)

본 문서는 'QT/QML 기반 로또 프로그램'의 시스템 요구사항을 기술한다. CuRS v1.2에 명시된 고객 요구사항을 만족시키기 위한 시스템 아키텍처, 기능별 기술 명세, 데이터베이스 설계, 외부 인터페이스 등을 정의하는 것을 목적으로 한다.

---

## 2. 시스템 아키텍처 (System Architecture)

### 2.1 아키텍처 모델
- **클라이언트-서비스 아키텍처**: GUI 클라이언트와 백엔드 서비스를 분리하여 모듈성과 확장성을 확보한다. (FR-013.1)
  - **GUI 클라이언트**: QML로 구현되며, 사용자 인터페이스와 사용자 입력을 처리한다. 독립 실행이 가능해야 한다.
  - **백엔드 서비스**: C++로 구현되며, 모든 비즈니스 로직(번호 생성, 통계 분석, 데이터 관리 등)을 담당하는 headless 서비스.
- **통신 방식**: Qt Remote Objects (QtRO)를 사용하여 클라이언트와 서비스 간의 통신을 구현한다. 로컬 IPC(Inter-Process Communication)를 기본으로 하며, 원격 접속을 위한 TCP 소켓 통신을 지원한다.
- **데이터 저장소**: 로컬 SQLite 데이터베이스를 사용하여 모든 영구 데이터를 관리한다.

### 2.2 기술 스택
- **언어**: C++20, QML
- **프레임워크**: Qt 6.x (C-01)
- **데이터베이스**: SQLite 3
- **설치 프로그램**: NSIS (FR-012.1)
- **플랫폼**: Windows 10/11 (64-bit) (C-4.6)

### 2.3 모듈 구성 (FR-013.2)
- **Core Service (백엔드)**
  - `NumberGenerationEngine`: 로또 번호 생성 로직 담당
  - `StatisticsEngine`: 통계 및 분석 데이터 처리
  - `DataManager`: DB CRUD 및 데이터 import/export 담당
  - `APIService`: 외부 API(동행복권) 연동 및 데이터 수집
  - `Scheduler`: 예약 작업 관리 및 실행
  - `NotificationService`: 이메일 발송 처리
- **GUI Client (프론트엔드)**
  - `MainApplication`: QML 엔진 및 윈도우 관리
  - `ViewModels`: C++로 구현되어 QML View와 Core Service를 연결하는 데이터 모델 (MVVM 패턴)
  - `Views`: QML로 작성된 각 화면 UI 컴포넌트
  - `Components`: 재사용 가능한 QML UI 컴포넌트 (버튼, 차트, 다이얼로그 등)
- **Plugin System**
  - `RulePluginInterface`: 번호 생성 규칙을 플러그인으로 확장하기 위한 C++ 인터페이스
  - `PluginManager`: 플러그인을 로드하고 관리하는 모듈

---

## 3. 시스템 기능 명세 (System Functional Specification)

CuRS의 기능 요구사항(FR)에 대한 시스템 레벨의 구현 명세.

### SYS-F-001: 번호 생성 엔진 (FR-001, FR-011)
- **입력**: 사용자가 선택한 규칙 조합(JSON 형식) 및 세부 파라미터.
- **처리**:
  - `QRandomGenerator::securelySeeded()`를 사용하여 암호학적으로 안전한 난수 생성. (NFR-004)
  - 각 규칙은 독립된 필터 클래스(e.g., `IncludeFilter`, `SumFilter`)로 구현.
  - `Chain of Responsibility` 패턴을 사용하여 복합 규칙을 순차적으로 적용. 우선순위는 설정에 따라 동적으로 결정.
  - 규칙 충돌(예: 포함 번호와 제외 번호가 동일) 시, `InvalidRuleException`을 발생시켜 GUI에 오류 전달.
  - 조합 생성이 불가능할 경우(예: 500ms 내 생성 실패), 타임아웃 처리 후 사용자에게 알림. (NFR-001)
  - 사용자 정의 규칙은 JSON 형식으로 직렬화하여 `GenerationRules` 테이블에 저장 및 관리.
- **출력**: 생성된 로또 번호 6개 세트 (`QVector<int>`).

### SYS-F-002: 추첨 시뮬레이션 시스템 (FR-002)
- **입력**: 추첨 시작 신호.
- **처리**:
  - 당첨 번호 6개와 보너스 번호 1개는 `QRandomGenerator`를 통해 1~45 범위에서 중복 없이 추출.
  - QML의 `SequentialAnimation`, `NumberAnimation`을 사용하여 공이 하나씩 추출되는 애니메이션 구현. (FR-010.3)
  - 추첨 결과는 `WinningNumbers` 테이블에 저장.
- **출력**: 당첨 번호 및 보너스 번호, QML 애니메이션 시각 효과.

### SYS-F-003: 당첨 확인 및 분석 시스템 (FR-003, FR-005)
- **입력**: 사용자 번호 세트, 특정 회차의 당첨 번호.
- **처리**:
  - C++ 함수 내에서 두 `std::set` 또는 `QSet`을 사용하여 일치하는 번호 개수 계산.
  - 당첨 등수 판정 로직 구현.
  - ROI 계산: `(총 가상 당첨금 - (구매 게임 수 * 1000)) / (구매 게임 수 * 1000)` (FR-005.4)
  - 모든 분석 결과는 `UserTickets` 테이블과 연계하여 DB에 기록.
- **출력**: 당첨 등수, 일치 번호 개수, 가상 당첨금, ROI 등 분석 데이터.

### SYS-F-004: 통계 분석 엔진 (FR-004)
- **입력**: 분석 대상 데이터 범위(회차, 기간 등).
- **처리**:
  - `WinningNumbers` 테이블에서 데이터를 조회하여 SQL 쿼리 또는 C++ 로직으로 통계 계산.
    - 번호별 출현 빈도: `COUNT`와 `GROUP BY` 사용.
    - 홀짝/고저 비율: C++ 로직으로 계산.
  - 계산된 통계 데이터는 `QAbstractItemModel`을 상속받는 C++ 모델 클래스에 저장.
  - `Qt Charts` 모듈을 사용하여 QML에서 막대그래프, 파이 차트, 라인 차트 등으로 시각화. (FR-004)
- **출력**: 차트 및 통계표에 표시될 데이터 모델.

### SYS-F-005: 외부 데이터 연동 (FR-006)
- **인터페이스**: 동행복권 당첨결과 조회 API (HTTP GET 요청)
  - URL: `https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo={회차}`
- **처리**:
  - `QNetworkAccessManager`를 사용하여 비동기 HTTP 요청.
  - 수신된 JSON 데이터를 `QJsonDocument`와 `QJsonObject`를 사용하여 파싱.
  - 파싱된 데이터를 `WinningNumbers` 테이블에 `INSERT` 또는 `UPDATE`.
  - `QTimer`를 사용하여 매주 토요일 22:00시에 자동 업데이트 스케줄 실행.
  - 인터넷 연결 상태는 `QNetworkConfigurationManager`로 확인. (NFR-006)
- **출력**: 로컬 DB에 최신 당첨 번호 저장.

### SYS-F-006: 데이터 관리 시스템 (FR-007)
- **처리**:
  - 백업/복원: SQLite DB 파일(`.db`)을 직접 복사/대체하는 방식으로 구현. `QFile::copy`.
  - 내보내기: `QFile`과 `QTextStream`을 사용하여 `UserTickets` 등의 테이블 데이터를 CSV 형식으로 저장.
- **출력**: CSV 파일 또는 백업 DB 파일.

### SYS-F-007: 예약 실행 및 알림 (FR-008, FR-009, FR-005.5)
- **처리**:
  - 예약 작업 정보(시간, 규칙, 이메일)는 DB 내 `ScheduledTasks` 테이블에 저장.
  - 백엔드 서비스는 시작 시 이 테이블을 읽어 `QTimer` 객체들을 설정.
  - 지정된 시간에 예약된 작업(번호 생성, 이메일 전송)을 트리거.
  - 이메일 전송은 `QSslSocket`을 사용하여 SMTP/SMTPS 서버와 통신.
    - 사용자 인증 정보(ID/PW)는 Windows DPAPI 또는 `QCryptographicHash`를 사용하여 암호화 후 `QSettings`에 저장. (NFR-008)
  - PDF 보고서 생성은 `QPdfWriter` 클래스 활용.
- **출력**: 생성된 번호가 포함된 이메일, PDF 보고서.

---

## 4. 데이터베이스 명세 (Database Specification)

- **DB 종류**: SQLite
- **파일 위치**: `%APPDATA%/LottoProgram/lotto.db`

### 4.1 테이블 정의
- **`WinningNumbers` (실제 당첨 번호)**
  - `round` (INTEGER, PRIMARY KEY): 회차
  - `draw_date` (TEXT): 추첨일 (YYYY-MM-DD)
  - `num1`, `num2`, `num3`, `num4`, `num5`, `num6` (INTEGER)
  - `bonus_num` (INTEGER)

- **`UserTickets` (사용자 생성 번호)**
  - `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
  - `created_at` (TEXT): 생성 시각 (ISO 8601)
  - `generation_rule_id` (INTEGER, FOREIGN KEY (`GenerationRules.id`)): 생성 시 사용된 규칙 ID
  - `num1`, `num2`, `num3`, `num4`, `num5`, `num6` (INTEGER)
  - `target_round` (INTEGER): 분석 대상 회차 (선택 사항)
  - `rank` (INTEGER): 당첨 등수 (NULLABLE)
  - `prize` (INTEGER): 가상 당첨금 (NULLABLE)

- **`GenerationRules` (사용자 정의 규칙)**
  - `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
  - `name` (TEXT, UNIQUE): 규칙 이름
  - `rule_data` (TEXT): 규칙 상세 내용 (JSON 형식)

- **`ScheduledTasks` (예약 작업)**
  - `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
  - `task_name` (TEXT)
  - `cron_expression` (TEXT): 실행 주기 (예: `0 22 * * 6` - 매주 토요일 22:00)
  - `rule_id` (INTEGER, FOREIGN KEY (`GenerationRules.id`)): 사용할 규칙 ID
  - `recipients` (TEXT): 수신자 이메일 목록 (쉼표로 구분)
  - `is_active` (INTEGER): 활성화 여부 (0 또는 1)

---

## 5. 비기능 요구사항 명세 (Non-Functional Requirements Specification)

CuRS의 비기능 요구사항(NFR)에 대한 시스템 레벨의 구현 방안.

- **NFR-001 (성능)**:
  - 번호 생성: 알고리즘 복잡도를 최소화하여 10,000개 조합 생성 시 1초 내 완료를 목표로 한다.
  - 애니메이션: QML의 렌더링 스레드를 활용하고, C++의 무거운 계산은 별도 스레드(`QtConcurrent`)에서 처리하여 UI 60fps 유지.
- **NFR-003 (사용성)**:
  - MVVM(Model-View-ViewModel) 패턴을 적용하여 UI와 로직을 분리. C++ ViewModel이 데이터와 커맨드를 QML View에 제공.
  - 즉각적 피드백: 버튼 클릭 등 사용자 입력에 대한 시각적 반응(애니메이션, 상태 변경)은 100ms 이내에 QML에서 직접 처리.
- **NFR-004 (신뢰성)**:
  - DB 트랜잭션을 사용하여 데이터 추가/수정 시 원자성을 보장.
  - `QRandomGenerator::securelySeeded()`를 사용하여 예측 불가능한 시드로 난수 생성기 초기화.
- **NFR-005 (보안)**:
  - 이메일 비밀번호 등 민감한 정보는 AES-256으로 암호화하여 로컬 파일(`QSettings`)에 저장. 암호화 키는 Windows DPAPI를 사용해 보호.
- **NFR-009 (배포)**:
  - NSIS 또는 Qt Installer Framework를 사용하여 설치 프로세스를 자동화. `windeployqt` 도구를 사용하여 필요한 Qt 라이브러리를 패키지에 포함.

---

## 6. 제약사항 (Constraints)

CuRS의 제약사항을 시스템 설계에 반영.

- **C-01 (기술)**: 모든 개발은 Qt 6/C++/QML을 기반으로 한다. 외부 라이브러리 사용은 최소화하며, 필요시 Qt 모듈을 우선적으로 고려한다.
- **C-02 (기능)**: 실제 화폐 거래 기능은 시스템 설계에서 완전히 배제한다. 모든 금액은 가상 수치로만 표시한다.
- **C-03 (환경)**: 핵심 기능(번호 생성, 저장된 데이터 분석)은 오프라인에서 동작해야 한다. 외부 API 연동 및 이메일 전송 기능은 네트워크 연결 상태를 확인한 후 시도한다.
- **C-04 (데이터)**: DB 파일의 최대 크기는 100MB를 초과하지 않도록 주기적인 데이터 관리(오래된 기록 아카이빙 등) 기능을 고려한다.
