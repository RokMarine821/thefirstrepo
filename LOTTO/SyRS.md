# 로또 프로그램 시스템 요구사항 명세서 (SyRS)
## System Requirements Specification for Lotto Program

**문서 버전**: 1.0  
**작성일**: 2025년 9월 20일  
**최종 수정일**: 2025년 9월 20일  
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
  - `LoggingService`: 시스템 로깅 및 디버깅 정보 관리
  - `ConfigurationManager`: 사용자 설정 저장/복원 및 관리
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

### SYS-F-008: 로깅 시스템 (NFR-007)
- **입력**: 시스템 전반의 이벤트, 오류, 사용자 액션 등.
- **처리**:
  - `QLoggingCategory`를 사용하여 로그 카테고리별 분류 (UI, Database, Network, Security 등).
  - 로그 레벨: DEBUG, INFO, WARNING, ERROR, CRITICAL의 5단계로 구분.
  - 로그 파일 관리:
    - 일별 로그 파일 생성: `%APPDATA%/LottoProgram/logs/lotto_YYYYMMDD.log`
    - 최대 파일 크기 10MB, 30일간 보관 후 자동 삭제
    - 로그 순환(log rotation) 기능으로 디스크 용량 관리
  - 성능 로깅: 번호 생성 시간, DB 쿼리 실행 시간, API 응답 시간 측정
  - 보안 로깅: 로그인 시도, 설정 변경, 데이터 내보내기 등 민감한 작업 기록
  - `QMutex`를 사용한 멀티스레드 환경에서의 안전한 로그 쓰기
- **출력**: 구조화된 로그 파일, 개발자 콘솔 출력.

### SYS-F-009: 설정 관리 시스템
- **입력**: 사용자 설정 변경 요청, 설정 파일 로드/저장 요청.
- **처리**:
  - `QSettings`를 사용하여 Windows 레지스트리 또는 INI 파일에 설정 저장.
  - 설정 카테고리:
    - **UI 설정**: 윈도우 크기/위치, 테마, 언어, 폰트 크기
    - **생성 설정**: 기본 생성 규칙, 자동 저장 여부, 생성 개수 기본값
    - **알림 설정**: 이메일 서버 정보, 수신자 목록, 알림 활성화 여부
    - **데이터 설정**: 백업 경로, 자동 백업 주기, 데이터 보관 기간
    - **보안 설정**: 자동 로그인, 세션 타임아웃, 암호화 옵션
  - 설정 검증: 입력 값의 유효성 검사 및 기본값 복원 기능
  - 설정 마이그레이션: 버전 업그레이드 시 기존 설정의 호환성 보장
  - 설정 내보내기/가져오기: JSON 형식으로 설정을 파일로 저장/복원
  - 실시간 설정 적용: 재시작 없이 변경된 설정을 즉시 반영 (가능한 항목에 한해)
- **출력**: 저장된 설정 값, 설정 파일 (JSON 형식).

---

## 4. 데이터베이스 명세 (Database Specification)

- **DB 종류**: SQLite
- **파일 위치**: `%APPDATA%/LottoProgram/lotto.db`

### 4.1 테이블 정의 (통합안)

`SAD.md`의 상세한 분석용 스키마와 `SyRS.md`의 운영 스키마를 통합하여 아래와 같이 최종 스키마를 제안합니다.

- **`WinningNumbers` (실제 당첨 번호)**
  - `draw_number` (INTEGER, PRIMARY KEY): 회차
  - `draw_date` (TEXT): 추첨일 (YYYY-MM-DD)
  - `winning_numbers` (TEXT): 당첨 번호 6개 (JSON 배열)
  - `bonus_number` (INTEGER): 보너스 번호
  - `prize_amounts` (TEXT): 등수별 당첨금 정보 (JSON 객체)
  - `cached_at` (TEXT): 데이터 캐시 시각 (ISO 8601)

- **`UserTickets` (사용자 생성 번호)**
  - `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
  - `user_id` (INTEGER, DEFAULT 1): 사용자 식별자 (향후 다중 사용자 지원 대비)
  - `numbers` (TEXT): 생성된 번호 6개 (JSON 배열)
  - `rules_applied` (TEXT): 적용된 규칙 상세 정보 (JSON)
  - `generation_time` (TEXT): 생성 시각 (ISO 8601)
  - `draw_number` (INTEGER): 분석 대상 회차
  - `match_count` (INTEGER, DEFAULT -1): 일치 번호 개수 (-1: 미확인)
  - `rank` (INTEGER, DEFAULT 0): 당첨 등수 (0: 낙첨)
  - `bonus_match` (INTEGER, DEFAULT 0): 보너스 번호 일치 여부 (0: 불일치, 1: 일치)
  - `winning_amount` (REAL, DEFAULT 0): 가상 당첨금
  - `result_updated_at` (TEXT): 당첨 결과 업데이트 시각 (ISO 8601)

- **`GenerationRules` (사용자 정의 규칙)**
  - `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
  - `name` (TEXT, UNIQUE NOT NULL): 규칙 이름
  - `description` (TEXT): 규칙 설명
  - `rule_config` (TEXT): 규칙 상세 설정 (JSON)
  - `created_at` (TEXT): 생성 시각 (ISO 8601)
  - `usage_count` (INTEGER, DEFAULT 0): 사용 횟수

- **`ScheduledTasks` (예약 작업)**
  - `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
  - `name` (TEXT NOT NULL): 작업 이름
  - `task_type` (TEXT): 작업 종류 ('number_generation', 'email_send' 등)
  - `schedule_config` (TEXT): 실행 주기 설정 (JSON, cron 표현식 등)
  - `rule_config` (TEXT): 적용할 규칙 설정 (JSON)
  - `recipients` (TEXT): 수신자 이메일 목록 (JSON 배열)
  - `is_active` (INTEGER, DEFAULT 1): 활성화 여부 (0 또는 1)
  - `next_execution` (TEXT): 다음 실행 예정 시각 (ISO 8601)
  - `last_execution` (TEXT): 마지막 실행 시각 (ISO 8601)

- **`RulePerformance` (규칙별 성과)**
  - `user_id` (INTEGER)
  - `rule_name` (TEXT)
  - `usage_count` (INTEGER, DEFAULT 0): 사용 횟수
  - `total_hits` (INTEGER, DEFAULT 0): 총 적중 횟수 (예: 3개 이상 일치)
  - `hit_rate` (REAL, DEFAULT 0.0): 적중률
  - `roi` (REAL, DEFAULT 0.0): 투자 수익률
  - `rank_distribution` (TEXT): 등수별 당첨 분포 (JSON)
  - `last_used` (TEXT): 마지막 사용 시각 (ISO 8601)
  - PRIMARY KEY (`user_id`, `rule_name`)

- **`NumberPerformance` (번호별 성과)**
  - `user_id` (INTEGER)
  - `number` (INTEGER)
  - `usage_count` (INTEGER, DEFAULT 0): 생성 시 포함된 횟수
  - `hit_count` (INTEGER, DEFAULT 0): 당첨 번호로 적중한 횟수
  - `hit_rate` (REAL, DEFAULT 0.0): 적중률
  - `last_hit_date` (TEXT): 마지막으로 적중된 날짜 (ISO 8601)
  - PRIMARY KEY (`user_id`, `number`)

- **`UserHitStatistics` (사용자 종합 통계)**
  - `user_id` (INTEGER, PRIMARY KEY)
  - `total_generations` (INTEGER, DEFAULT 0): 총 생성 게임 수
  - `total_investment` (REAL, DEFAULT 0.0): 총 투자 비용
  - `total_winnings` (REAL, DEFAULT 0.0): 총 당첨금
  - `net_profit` (REAL, DEFAULT 0.0): 순수익
  - `roi` (REAL, DEFAULT 0.0): 투자 수익률
  - `hit_distribution` (TEXT): 적중 개수별 분포 (JSON, 예: `{"3": 10, "4": 2}`)
  - `rank_distribution` (TEXT): 등수별 분포 (JSON, 예: `{"1": 0, "5": 5}`)
  - `last_updated` (TEXT): 마지막 업데이트 시각 (ISO 8601)

- **`SystemLogs` (시스템 로그)**
  - `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
  - `timestamp` (TEXT): 로그 생성 시각 (ISO 8601)
  - `level` (TEXT): 로그 레벨 (DEBUG, INFO, WARNING, ERROR, CRITICAL)
  - `category` (TEXT): 로그 카테고리 (UI, Database, Network 등)
  - `message` (TEXT): 로그 메시지
  - `thread_id` (TEXT): 스레드 식별자
  - `performance_data` (TEXT): 성능 관련 데이터 (JSON, NULLABLE)

- **`UserSettings` (사용자 설정)**
  - `category` (TEXT)
  - `key` (TEXT): 설정 키
  - `value` (TEXT): 설정 값 (JSON 형식 권장)
  - `is_encrypted` (INTEGER, DEFAULT 0): 암호화 여부 (0 또는 1)
  - `modified_at` (TEXT): 마지막 수정 시각 (ISO 8601)
  - PRIMARY KEY (`category`, `key`)

- **`EmailHistory` (이메일 발송 내역)**
  - `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
  - `recipient` (TEXT NOT NULL): 수신자
  - `subject` (TEXT): 제목
  - `sent_at` (TEXT): 발송 시각 (ISO 8601)
  - `status` (TEXT): 상태 ('sent', 'failed')
  - `error_message` (TEXT): 오류 메시지 (실패 시)

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
- **NFR-006 (로깅 및 모니터링)**:
  - 모든 중요한 시스템 이벤트와 사용자 액션을 로그로 기록하여 디버깅과 문제 해결을 지원.
  - 로그 기록이 시스템 성능에 미치는 영향을 최소화하기 위해 비동기 로깅 처리.
  - 민감한 정보(비밀번호, 개인정보 등)는 로그에서 마스킹 처리하여 보안 유지.
- **NFR-007 (설정 관리)**:
  - 사용자 설정 변경 시 즉시 저장하여 데이터 손실 방지.
  - 잘못된 설정으로 인한 시스템 오작동을 방지하기 위한 설정 검증 및 기본값 복원 기능.
  - 설정 파일 손상 시 자동 복구 메커니즘 제공.
- **NFR-009 (배포)**:
  - NSIS 또는 Qt Installer Framework를 사용하여 설치 프로세스를 자동화. `windeployqt` 도구를 사용하여 필요한 Qt 라이브러리를 패키지에 포함.

---

## 6. 제약사항 (Constraints)

CuRS의 제약사항을 시스템 설계에 반영.

- **C-01 (기술)**: 모든 개발은 Qt 6/C++/QML을 기반으로 한다. 외부 라이브러리 사용은 최소화하며, 필요시 Qt 모듈을 우선적으로 고려한다.
- **C-02 (기능)**: 실제 화폐 거래 기능은 시스템 설계에서 완전히 배제한다. 모든 금액은 가상 수치로만 표시한다.
- **C-03 (환경)**: 핵심 기능(번호 생성, 저장된 데이터 분석)은 오프라인에서 동작해야 한다. 외부 API 연동 및 이메일 전송 기능은 네트워크 연결 상태를 확인한 후 시도한다.
- **C-04 (데이터)**: DB 파일의 최대 크기는 100MB를 초과하지 않도록 주기적인 데이터 관리(오래된 기록 아카이빙 등) 기능을 고려한다.
