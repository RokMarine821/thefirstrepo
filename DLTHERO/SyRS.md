# 시스템 요구사항 명세서 (SyRS) - DLT Log Analyzer

*   **문서 버전:** 1.1
*   **작성일:** 2025-09-25
*   **최종 수정일:** 2025-09-25
*   **프로젝트명:** DLT Log Analyzer (DLTHERO)
*   **관련 문서:** 고객 요구사항 명세서 (CuRS) v1.6

---

## 변경 이력

| 버전 | 날짜       | 변경 내용                               | 작성자 |
| :--- | :--------- | :-------------------------------------- | :----- |
| 1.1  | 2025-09-25 | 규칙 관리 시스템(SYS-F-02) 명세 구체화 (UI, 생성 지원, 일괄 가져오기/내보내기) | Gemini |
| 1.0  | 2025-09-25 | CuRS v1.6 기반으로 초기 SyRS 문서 작성 | Gemini |

---

## 1. 개요 (Overview)

본 문서는 'DLT Log Analyzer'의 시스템 요구사항을 기술한다. CuRS v1.6에 명시된 고객 요구사항을 만족시키기 위한 시스템 아키텍처, 기능별 기술 명세, 데이터 모델, 외부 인터페이스 등을 정의하는 것을 목적으로 한다.

## 2. 시스템 아키텍처 (System Architecture)

### 2.1 아키텍처 모델

*   **다중 프로세스 아키텍처 (Multi-Process Architecture)**: 고성능 처리가 필요한 백엔드와 사용자 인터페이스를 위한 프론트엔드를 별도의 프로세스로 분리하여 안정성과 반응성을 극대화한다.
    *   **프론트엔드 (UI Application)**: Python/PyQt로 구현되며, 사용자 인터페이스, 사용자 입력 처리, AI 연동 및 결과 시각화를 담당한다.
    *   **백엔드 (Core Engine)**: C++로 구현되며, 핵심 비즈니스 로직(DLT 로그 파싱, 규칙 적용)을 담당하는 Headless 서비스로 동작한다.
*   **통신 방식**: 로컬 IPC(Inter-Process Communication)를 사용하여 프론트엔드와 백엔드 간의 통신을 구현한다. 데이터 교환 형식은 JSON-RPC를 사용한다.
*   **플러그인 아키텍처**: 기능 확장을 위해 플러그인 시스템을 도입한다. (FR-10)

### 2.2 기술 스택

*   **프론트엔드**: Python 3.9+, PyQt6
*   **백엔드**: C++17
*   **AI 연동**: OpenAI/Google API (via Python `requests` or `google-generativeai` library)
*   **데이터 형식**: JSON, YAML (규칙 파일), CSV/TXT (내보내기)
*   **설치 프로그램**: NSIS (Nullsoft Scriptable Install System) 또는 Inno Setup
*   **플랫폼**: Windows 10/11 (64-bit) (NFR-01)

### 2.3 모듈 구성

*   **Core Engine (C++)**
    *   `LogParserModule`: DLT 로그 파일을 고속으로 파싱하여 구조화된 JSON 데이터로 변환.
    *   `RuleEngineModule`: JSON/YAML 형식의 규칙을 로드하여 파싱된 데이터에 적용하고 필터링.
    *   `IPCServerModule`: 프론트엔드로부터의 요청을 수신하고 처리 결과를 응답하는 IPC 서버.
*   **UI Application (Python)**
    *   `MainApplication`: PyQt 애플리케이션의 메인 루프 및 윈도우 관리.
    *   `UIManager`: 각종 위젯(로그 테이블, 차트, 대화창)을 관리하고 사용자 입력을 처리.
    *   `AIInteractionModule`: AI 서비스 API와 통신하며 프롬프트를 구성하고 응답을 파싱.
    *   `IPCClientModule`: Core Engine에 로그 처리 요청을 보내고 결과를 수신.
    *   `PluginManager`: 플러그인을 로드하고 관리하며, 플러그인과 메인 애플리케이션 간의 인터페이스를 제공.
    *   `SessionManager`: 분석 세션(로그, 주석, AI 대화)을 저장하고 불러오는 기능.

## 3. 시스템 기능 명세 (System Functional Specification)

CuRS의 기능 요구사항(FR)에 대한 시스템 레벨의 구현 명세.

### SYS-F-01: DLT 로그 처리 시스템 (FR-01, FR-02)
*   **입력**: DLT 로그 파일 경로.
*   **처리**:
    *   `UI Application`이 파일 경로를 `Core Engine`에 IPC로 전달.
    *   `Core Engine`의 `LogParserModule`은 파일을 스트리밍 방식으로 읽어 파싱하고, 각 로그 메시지를 JSON 객체로 변환하여 스트림으로 `UI Application`에 전송.
    *   `UI Application`은 수신된 JSON 객체를 `QTableView` 모델에 실시간으로 추가하여 표시.
*   **출력**: 구조화된 로그 데이터 (JSON 형식), UI 테이블 뷰에 표시.

### SYS-F-02: 규칙 기반 분석 시스템 (FR-03, FR-03.1, FR-03.2, FR-03.3)
*   **입력**: 사용자가 UI를 통해 입력한 규칙 정보, 현재 로드된 로그 데이터.
*   **처리**:
    *   **규칙 관리자 UI**: `UI Application`은 사용자가 규칙을 쉽게 생성, 편집, 관리할 수 있는 전용 UI를 제공한다. 이 UI는 다음 기능을 포함한다.
        *   **입력 필드**: 규칙 이름, 설명, 로그 레벨, APP ID, 키워드 등을 입력받는 위젯(QLineEdit, QComboBox 등)을 제공한다.
        *   **정규 표현식 빌더**: 정규 표현식의 유효성을 실시간으로 검사하고, 자주 사용하는 패턴을 템플릿으로 제공하는 빌더 UI를 구현한다.
        *   **시퀀스 빌더**: 드래그 앤 드롭 인터페이스를 통해 여러 규칙을 순차적으로 연결하여 'A 발생 후 B 발생'과 같은 시퀀스 규칙을 시각적으로 생성할 수 있게 한다.
    *   **규칙 파일 생성**: 규칙 관리자 UI에서 입력된 내용은 `UIManager`에 의해 검증되고, `RuleEngineModule`이 이해할 수 있는 구조의 YAML 파일로 직렬화(serialize)되어 로컬에 저장된다.
    *   분석 요청 시, 규칙 파일의 내용과 로그 데이터 식별자를 `Core Engine`에 전달.
    *   **규칙 일괄 관리**: `UIManager`는 다음의 일괄 처리 기능을 제공한다.
        *   **가져오기**: 사용자가 Excel 파일을 선택하면, `pandas` 라이브러리를 사용하여 파일을 읽고, 정의된 템플릿에 따라 각 행을 파싱하여 규칙 객체로 변환한 후, 기존 규칙 목록에 추가하거나 덮어쓴다.
        *   **내보내기**: 현재 로드된 규칙 목록(전체 또는 선택)을 단일 JSON 또는 YAML 파일로 직렬화하여 사용자가 지정한 경로에 저장한다.
    *   `Core Engine`의 `RuleEngineModule`은 규칙을 적용하여 필터링/그룹화된 로그의 인덱스 목록을 `UI Application`에 반환.
    *   `UI Application`은 반환된 인덱스 목록을 사용하여 `QTableView`의 표시를 업데이트.
*   **출력**: 필터링된 로그 뷰, 로컬에 저장된 규칙 파일(YAML).

### SYS-F-03: AI 분석 및 해결책 제시 시스템 (FR-04, FR-05)
*   **입력**: 사용자의 자연어 질문, 분석 대상 로그 라인 및 컨텍스트 범위.
*   **처리**:
    *   `UI Application`의 `AIInteractionModule`이 입력과 사전 정의된 프롬프트 템플릿을 결합하여 최종 프롬프트를 생성.
    *   보안 요구사항(NFR-05)에 따라 로그 데이터에서 민감 정보를 제거하고 최소한의 스니펫만 포함.
    *   구성된 프롬프트를 Google/OpenAI API로 전송하고 응답을 수신.
    *   수신된 텍스트 응답을 파싱하여 구조화된 데이터(원인, 해결책, 관련 링크 등)로 변환하고 대화형 UI에 표시.
*   **출력**: AI의 분석 결과 및 해결 방안 제안.

### SYS-F-04: 시각화 및 리포트 생성 시스템 (FR-06, FR-07)
*   **입력**: 분석된 로그 데이터, 시각화/내보내기 요청.
*   **처리**:
    *   **시각화**: `pandas` 라이브러리를 사용하여 데이터를 집계하고, `pyqtgraph` 또는 `matplotlib`을 통해 차트(막대, 파이 등)를 생성하여 UI에 표시.
    *   **내보내기**: `pandas` DataFrame을 사용하여 데이터를 CSV 형식으로 변환하거나, `reportlab` 라이브러리를 사용하여 PDF 리포트를 생성.
*   **출력**: 차트 이미지, CSV/TXT/PDF 파일.

### SYS-F-05: 협업 지원 시스템 (FR-08, FR-09)
*   **처리**:
    *   **세션 관리**: `SessionManager`는 현재 열린 로그 파일 경로, 적용된 규칙, 필터, 주석, AI 대화 기록 등을 포함하는 JSON 파일을 생성. 이 JSON 파일과 관련 파일을 `.zip` 아카이브로 묶어 세션 파일(`.dlt_session`)로 저장.
    *   **주석/태그**: 주석과 태그는 로그 라인 번호를 키로 하는 JSON 객체로 관리되며 세션 파일에 함께 저장.
*   **출력**: 세션 파일(`.dlt_session`).

### SYS-F-06: 플러그인 시스템 (FR-10)
*   **처리**:
    *   `PluginManager`는 시작 시 지정된 폴더에서 플러그인(Python 파일 또는 패키지)을 로드.
    *   각 플러그인은 사전에 정의된 인터페이스(예: `AbstractRulePlugin`, `AbstractParserPlugin`)를 구현한 클래스를 포함.
    *   `PluginManager`는 플러그인이 제공하는 기능을 메뉴나 UI에 동적으로 추가.
    *   플러그인 관리자 UI를 통해 플러그인 활성화/비활성화 상태를 설정 파일에 저장.
*   **출력**: 동적으로 확장된 애플리케이션 기능.

### SYS-F-07: 배포 및 운영 시스템 (FR-11, FR-12)
*   **처리**:
    *   **배포**: NSIS 스크립트를 사용하여 Python 인터프리터, 라이브러리, C++ 엔진 실행 파일, 리소스 등을 포함하는 단일 설치 파일(.exe)을 생성.
    *   **업데이트**: 프로그램 시작 시 GitHub Releases API 등을 조회하여 최신 버전을 확인하고 사용자에게 알림.
    *   **운영/진단**: Python의 `logging` 모듈을 사용하여 파일 기반 로깅을 구현. 설정은 INI 또는 JSON 파일 형식으로 `%APPDATA%` 폴더에 저장.
*   **출력**: 설치 프로그램, 로그 파일.

## 4. 데이터 명세 (Data Specification)

*   **로그 메시지 모델 (JSON)**: `Core Engine`과 `UI Application` 간에 교환되는 단일 로그 메시지의 데이터 구조.
    ```json
    {
      "index": 101,
      "timestamp": "2025-09-25T10:30:01.123Z",
      "ecu_id": "ECU1",
      "app_id": "APP1",
      "context_id": "CTX1",
      "log_level": "ERROR",
      "payload_type": "string",
      "payload": "Memory allocation failed."
    }
    ```
*   **규칙 파일 모델 (YAML)**: 사용자가 정의하는 필터링 규칙의 데이터 구조.
    ```yaml
    rules:
      - name: "Memory Errors"
        enabled: true
        conditions:
          - field: "log_level"
            operator: "equals"
            value: "ERROR"
          - field: "payload"
            operator: "contains"
            value: "memory"
    ```
*   **세션 파일 (.dlt_session)**: ZIP 아카이브 형식.
    ```
    - original_log.dlt (optional, for portability)
    - session_data.json
      - log_file_path
      - applied_rules
      - annotations
      - ai_chat_history
    ```

## 5. 외부 인터페이스 명세 (External Interface Specification)

*   **AI 서비스 API**:
    *   **인터페이스**: Google Gemini API 또는 OpenAI Chat Completions API.
    *   **프로토콜**: HTTPS (REST)
    *   **데이터 형식**: JSON
    *   **인증**: 사용자가 제공한 API 키를 HTTP 헤더(Authorization: Bearer <API_KEY>)에 포함하여 전송.

## 6. 비기능 요구사항 시스템 명세

*   **NFR-03 (성능)**: `Core Engine`은 C++로 구현하여 I/O 및 파싱 성능을 최적화한다. 대용량 파일 처리를 위해 메모리 맵(mmap) 또는 스트리밍 방식을 사용한다.
*   **NFR-05 (보안)**: API 키는 Windows DPAPI(Data Protection API)를 통해 암호화하여 로컬 설정 파일에 저장한다.
*   **NFR-07 (접근성)**: PyQt의 내장 접근성 기능(Accessible Name, Description)을 활용하고, 모든 UI 컨트롤에 대해 키보드 포커스 순서를 명시적으로 정의한다.
*   **NFR-08 (테스트 용이성)**: `UI Application`의 비즈니스 로직(AI 연동, 세션 관리 등)을 UI 코드와 분리된 클래스로 구현한다. `Core Engine`은 `gtest` 등을 사용하여 단위 테스트를 작성한다.
*   **NFR-09 (유지보수성)**: C++ 코드는 Google C++ Style Guide, Python 코드는 PEP 8 스타일 가이드를 준수한다.