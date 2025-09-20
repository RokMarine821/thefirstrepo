# 로또 프로그램 시스템 아키텍처 설계서 (SAD)
## System Architecture Design for Lotto Program

**문서 버전**: 1.2  
**작성일**: 2025년 9월 20일  
**최종 수정일**: 2025년 9월 20일  
**프로젝트명**: QT/QML 기반 로또 프로그램  
**참조 문서**: CuRS v1.2, SyRS v1.1

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 1.0 | 2025-09-20 | 초기 문서 작성 | 개발팀 |
| 1.1 | 2025-09-20 | 적중률 분석 기능 아키텍처 반영, GUI/Backend 컴포넌트 확장, 데이터베이스 스키마 확장 | 개발팀 |
| 1.2 | 2025-09-20 | DB 스키마 동기화, IPC 통신 방식 및 플러그인 인터페이스 명세 구체화 | Gemini |

---

## 1. 개요 (Overview)

본 문서는 QT/QML 기반 로또 프로그램의 전체 시스템 아키텍처를 정의합니다.

### 1.1 목적
- 시스템의 전반적인 구조와 컴포넌트 간의 관계 정의
- 기술적 의사결정과 아키텍처 패턴 문서화
- 개발팀의 구현 가이드라인 제공

### 1.2 아키텍처 원칙
- **모듈화**: 독립적이고 재사용 가능한 컴포넌트
- **확장성**: 플러그인 기반 확장 구조
- **분리**: GUI와 비즈니스 로직의 명확한 분리
- **유지보수성**: 느슨한 결합과 높은 응집도
- **성능**: 반응성과 효율성 최적화

---

## 2. 시스템 전체 아키텍처

### 2.1 아키텍처 패턴
**클라이언트-서버 아키텍처** + **플러그인 아키텍처** + **레이어드 아키텍처**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           QT/QML 로또 프로그램                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────┐           ┌─────────────────────┐                      │
│  │   GUI CLIENT        │◄─────────►│   BACKEND SERVICE   │                      │
│  │   (독립 실행)        │    IPC    │   (Core Engine)     │                      │
│  └─────────────────────┘           └─────────────────────┘                      │
│  │                                 │                                            │
│  │ ┌─────────────────┐             │ ┌─────────────────┐                        │
│  │ │ Presentation    │             │ │ Business Logic  │                        │
│  │ │ Layer           │             │ │ Layer           │                        │
│  │ │ - QML Views     │             │ │ - Rule Engine   │                        │
│  │ │ - Controllers   │             │ │ - Number Gen    │                        │
│  │ │ - View Models   │             │ │ - Hit Analysis  │                        │
│  │ │ - Analytics UI  │             │ │ - Statistics    │                        │
│  │ └─────────────────┘             │ └─────────────────┘                        │
│  │                                 │                                            │
│  │ ┌─────────────────┐             │ ┌─────────────────┐                        │
│  │ │ Animation       │             │ │ Service Layer   │                        │
│  │ │ Layer           │             │ │ - Email Service │                        │
│  │ │ - Animation Eng │             │ │ - Schedule Svc  │                        │
│  │ │ - Effects Eng   │             │ │ - API Gateway   │                        │
│  │ │ - Chart Anim    │             │ │ - Analytics Svc │                        │
│  │ └─────────────────┘             │ └─────────────────┘                        │
│  │                                 │                                            │
│  │ ┌─────────────────┐             │ ┌─────────────────┐                        │
│  │ │ Communication   │             │ │ Data Layer      │                        │
│  │ │ Layer           │             │ │ - Data Manager  │                        │
│  │ │ - API Client    │             │ │ - SQLite DB     │                        │
│  │ │ - Connection    │             │ │ - File System   │                        │
│  │ └─────────────────┘             │ └─────────────────┘                        │
│                                    │                                            │
│                                    │ ┌─────────────────┐                        │
│                                    │ │ Plugin System   │                        │
│                                    │ │ - Plugin Mgr    │                        │
│                                    │ │ - Rule Plugins  │                        │
│                                    │ └─────────────────┘                        │
└─────────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────────────────────────┐
                    │         EXTERNAL SYSTEMS               │
                    │ ┌─────────────┐ ┌─────────────────────┐ │
                    │ │ 동행복권 API │ │ SMTP Servers        │ │
                    │ │ (Lottery)   │ │ (Email Services)    │ │
                    │ └─────────────┘ └─────────────────────┘ │
                    └─────────────────────────────────────────┘
```

### 2.2 주요 컴포넌트 개요

| 컴포넌트 | 역할 | 기술 스택 |
|---------|------|-----------|
| **GUI Client** | 사용자 인터페이스 및 프레젠테이션 | QML, Qt Quick, C++ |
| **Backend Service** | 비즈니스 로직 및 데이터 처리 | C++17, Qt Core |
| **Hit Analysis Engine** | 적중률 분석 및 성과 추적 | C++17, Qt SQL, Charts |
| **Communication Layer** | 클라이언트-서버 간 통신 | Qt Remote Objects |
| **Plugin System** | 확장 가능한 규칙 엔진 | Qt Plugin Framework |
| **Data Layer** | 데이터 저장 및 관리 | SQLite, Qt SQL |
| **External APIs** | 외부 서비스 연동 | HTTP REST, SMTP |

---

## 3. GUI Client 아키텍처

### 3.1 프레젠테이션 레이어
```
┌─────────────────────────────────────────────────────────────┐
│                    GUI CLIENT ARCHITECTURE                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                QML VIEW LAYER                           │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ MainWindow  │ │ RulePanel   │ │ StatisticsView      │ │ │
│  │ │ .qml        │ │ .qml        │ │ .qml                │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ NumberBoard │ │ EmailView   │ │ SettingsView        │ │ │
│  │ │ .qml        │ │ .qml        │ │ .qml                │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ HitAnalysis │ │ Performance │ │ ReportView          │ │ │
│  │ │ View.qml    │ │ Dashboard   │ │ .qml                │ │ │
│  │ │             │ │ .qml        │ │                     │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │ Data Binding                    │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │               VIEW MODEL LAYER                          │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ MainViewModel│ │RuleViewModel│ │StatisticsViewModel  │ │ │
│  │ │ (C++)       │ │ (C++)       │ │ (C++)               │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ HitAnalysis │ │Performance  │ │ ReportViewModel     │ │ │
│  │ │ ViewModel   │ │ ViewModel   │ │ (C++)               │ │ │
│  │ │ (C++)       │ │ (C++)       │ │                     │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │ Commands/Queries               │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              CONTROLLER LAYER                           │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ AppController│ │UIController │ │ DataController      │ │ │
│  │ │ (C++)       │ │ (C++)       │ │ (C++)               │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Analytics   │ │ Report      │ │ Performance         │ │ │
│  │ │ Controller  │ │ Controller  │ │ Controller          │ │ │
│  │ │ (C++)       │ │ (C++)       │ │ (C++)               │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 애니메이션 아키텍처
```cpp
class AnimationArchitecture {
    // 애니메이션 엔진
    AnimationEngine {
        - LottoBallAnimator
        - ChartTransitionAnimator  
        - PerformanceChartAnimator
        - HitRateVisualizationAnimator
        - UITransitionAnimator
        - ParticleEffectEngine
    }
    
    // 렌더링 파이프라인
    RenderingPipeline {
        - SceneGraph (Qt Quick)
        - GPU Acceleration
        - 60fps Target Rendering
        - Chart Animation Optimization
    }
}
```

---

## 4. Backend Service 아키텍처

### 4.1 서비스 레이어 구조
```
┌─────────────────────────────────────────────────────────────┐
│                 BACKEND SERVICE ARCHITECTURE                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   API GATEWAY                           │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ REST API    │ │ RPC Handler │ │ WebSocket Handler   │ │ │
│  │ │ Controller  │ │ (Qt RO)     │ │ (Future)            │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 BUSINESS LOGIC LAYER                    │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Rule Engine │ │ Number Gen  │ │ Statistics Engine   │ │ │
│  │ │ Service     │ │ Service     │ │ Service             │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Hit Analysis│ │ Performance │ │ Report Generation   │ │ │
│  │ │ Service     │ │ Tracking    │ │ Service             │ │ │
│  │ │             │ │ Service     │ │                     │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Lottery API │ │ Email       │ │ Schedule            │ │ │
│  │ │ Service     │ │ Service     │ │ Service             │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   DATA ACCESS LAYER                     │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Repository  │ │ Cache       │ │ File System         │ │ │
│  │ │ Pattern     │ │ Manager     │ │ Manager             │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 핵심 서비스 구조
```cpp
// 서비스 레이어 인터페이스
class IService {
public:
    virtual bool initialize() = 0;
    virtual void shutdown() = 0;
    virtual QString getServiceName() const = 0;
};

// 서비스 컨테이너
class ServiceContainer {
private:
    QMap<QString, std::shared_ptr<IService>> services;
    
public:
    template<typename T>
    void registerService(const QString& name);
    
    template<typename T>
    std::shared_ptr<T> getService(const QString& name);
    
    void initializeAll();
    void shutdownAll();
};
```

---

## 5. 통신 아키텍처

### 5.1 Inter-Process Communication (IPC)
```
┌─────────────────────────────────────────────────────────────┐
│                   COMMUNICATION ARCHITECTURE                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  GUI CLIENT                    BACKEND SERVICE              │
│  ┌─────────────────┐          ┌─────────────────────────┐   │
│  │                 │          │                         │   │
│  │ ┌─────────────┐ │   IPC    │ ┌─────────────────────┐ │   │
│  │ │ API Client  │◄┼──────────┼►│ Qt Remote Objects   │ │   │
│  │ │ (Proxy)     │ │          │ │ Registry            │ │   │
│  │ └─────────────┘ │          │ └─────────────────────┘ │   │
│  │                 │          │                         │   │
│  │ ┌─────────────┐ │          │ ┌─────────────────────┐ │   │
│  │ │ Connection  │ │          │ │ Service Endpoints   │ │   │
│  │ │ Manager     │ │          │ │ - NumberGenService  │ │   │
│  │ └─────────────┘ │          │ │ - RuleService       │ │   │
│  │                 │          │ │ - StatisticsService │ │   │
│  │ ┌─────────────┐ │          │ │ - EmailService      │ │   │
│  │ │ Local Mode  │ │          │ └─────────────────────┘ │   │
│  │ │ Detector    │ │          │                         │   │
│  │ └─────────────┘ │          │ ┌─────────────────────┐ │   │
│  │                 │          │ │ Authentication      │ │   │
│  └─────────────────┘          │ │ & Authorization     │ │   │
│                               │ └─────────────────────┘ │   │
│                               └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

로컬 통신 시에는 TCP/IP 소켓의 오버헤드를 줄이고 더 높은 성능을 제공하는 `QLocalSocket`(Windows의 경우 Named Pipe, Unix 계열의 경우 Unix Domain Socket 기반)을 우선적으로 사용합니다. 원격 통신 시에는 `TCP/IP Socket`을 사용합니다.

프로토콜 스택:
┌──────────────────┐
│ Application Data │  ← QVariant, JSON
├──────────────────┤
│ Qt Remote Objects│  ← Object Serialization
├──────────────────┤
│ QLocalSocket/TCP │  ← Local(Named Pipe) / Remote
├──────────────────┤
│ Operating System │  ← Windows IPC
└──────────────────┘
```

### 5.2 외부 API 통신
```cpp
class ExternalAPIArchitecture {
    // HTTP 클라이언트
    HTTPClient {
        - QNetworkAccessManager
        - SSL/TLS Support
        - Connection Pooling
        - Request/Response Queue
    }
    
    // API 어댑터
    LotteryAPIAdapter {
        - 동행복권 API 래퍼
        - 데이터 파싱 및 검증
        - 캐싱 전략
        - 에러 처리
    }
    
    SMTPAdapter {
        - 이메일 서버 연결
        - 멀티파트 메시지
        - 첨부파일 처리
        - 발송 대기열
    }
}
```

---

## 6. 데이터 아키텍처

### 6.1 데이터 저장 계층
```
┌─────────────────────────────────────────────────────────────┐
│                    DATA ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                  APPLICATION LAYER                      │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Business    │ │ Services    │ │ Controllers         │ │ │
│  │ │ Logic       │ │             │ │                     │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │ Repository Pattern             │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 REPOSITORY LAYER                        │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Number      │ │ Rule        │ │ Statistics          │ │ │
│  │ │ Repository  │ │ Repository  │ │ Repository          │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ HitAnalysis │ │ Performance │ │ Report              │ │ │
│  │ │ Repository  │ │ Repository  │ │ Repository          │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Email       │ │ Schedule    │ │ Configuration       │ │ │
│  │ │ Repository  │ │ Repository  │ │ Repository          │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │ Data Access                    │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 PERSISTENCE LAYER                       │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ SQLite      │ │ JSON Files  │ │ Configuration       │ │ │
│  │ │ Database    │ │ (Cache)     │ │ Files (.ini/.json)  │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 데이터베이스 스키마 개요
```sql
-- 통합 데이터베이스 스키마 (SyRS v1.1 기준)

-- `WinningNumbers` (실제 당첨 번호)
CREATE TABLE WinningNumbers (
    draw_number INTEGER PRIMARY KEY,      -- 회차
    draw_date TEXT,                       -- 추첨일 (YYYY-MM-DD)
    winning_numbers TEXT,                 -- 당첨 번호 6개 (JSON 배열)
    bonus_number INTEGER,                 -- 보너스 번호
    prize_amounts TEXT,                   -- 등수별 당첨금 정보 (JSON 객체)
    cached_at TEXT                        -- 데이터 캐시 시각 (ISO 8601)
);

-- `UserTickets` (사용자 생성 번호)
CREATE TABLE UserTickets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER DEFAULT 1,            -- 사용자 식별자 (향후 다중 사용자 지원 대비)
    numbers TEXT,                         -- 생성된 번호 6개 (JSON 배열)
    rules_applied TEXT,                   -- 적용된 규칙 상세 정보 (JSON)
    generation_time TEXT,                 -- 생성 시각 (ISO 8601)
    draw_number INTEGER,                  -- 분석 대상 회차
    match_count INTEGER DEFAULT -1,       -- 일치 번호 개수 (-1: 미확인)
    rank INTEGER DEFAULT 0,               -- 당첨 등수 (0: 낙첨)
    bonus_match INTEGER DEFAULT 0,        -- 보너스 번호 일치 여부 (0: 불일치, 1: 일치)
    winning_amount REAL DEFAULT 0,        -- 가상 당첨금
    result_updated_at TEXT                -- 당첨 결과 업데이트 시각 (ISO 8601)
);

-- `GenerationRules` (사용자 정의 규칙)
CREATE TABLE GenerationRules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,            -- 규칙 이름
    description TEXT,                     -- 규칙 설명
    rule_config TEXT,                     -- 규칙 상세 설정 (JSON)
    created_at TEXT,                      -- 생성 시각 (ISO 8601)
    usage_count INTEGER DEFAULT 0         -- 사용 횟수
);

-- `ScheduledTasks` (예약 작업)
CREATE TABLE ScheduledTasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,                   -- 작업 이름
    task_type TEXT,                       -- 작업 종류 ('number_generation', 'email_send' 등)
    schedule_config TEXT,                 -- 실행 주기 설정 (JSON, cron 표현식 등)
    rule_config TEXT,                     -- 적용할 규칙 설정 (JSON)
    recipients TEXT,                      -- 수신자 이메일 목록 (JSON 배열)
    is_active INTEGER DEFAULT 1,          -- 활성화 여부 (0 또는 1)
    next_execution TEXT,                  -- 다음 실행 예정 시각 (ISO 8601)
    last_execution TEXT                   -- 마지막 실행 시각 (ISO 8601)
);

-- `RulePerformance` (규칙별 성과)
CREATE TABLE RulePerformance (
    user_id INTEGER,
    rule_name TEXT,
    usage_count INTEGER DEFAULT 0,        -- 사용 횟수
    total_hits INTEGER DEFAULT 0,         -- 총 적중 횟수 (예: 3개 이상 일치)
    hit_rate REAL DEFAULT 0.0,            -- 적중률
    roi REAL DEFAULT 0.0,                 -- 투자 수익률
    rank_distribution TEXT,               -- 등수별 당첨 분포 (JSON)
    last_used TEXT,                       -- 마지막 사용 시각 (ISO 8601)
    PRIMARY KEY (user_id, rule_name)
);

-- `NumberPerformance` (번호별 성과)
CREATE TABLE NumberPerformance (
    user_id INTEGER,
    number INTEGER,
    usage_count INTEGER DEFAULT 0,        -- 생성 시 포함된 횟수
    hit_count INTEGER DEFAULT 0,          -- 당첨 번호로 적중한 횟수
    hit_rate REAL DEFAULT 0.0,            -- 적중률
    last_hit_date TEXT,                   -- 마지막으로 적중된 날짜 (ISO 8601)
    PRIMARY KEY (user_id, number)
);

-- `UserHitStatistics` (사용자 종합 통계)
CREATE TABLE UserHitStatistics (
    user_id INTEGER PRIMARY KEY,
    total_generations INTEGER DEFAULT 0,  -- 총 생성 게임 수
    total_investment REAL DEFAULT 0.0,    -- 총 투자 비용
    total_winnings REAL DEFAULT 0.0,      -- 총 당첨금
    net_profit REAL DEFAULT 0.0,          -- 순수익
    roi REAL DEFAULT 0.0,                 -- 투자 수익률
    hit_distribution TEXT,                -- 적중 개수별 분포 (JSON, 예: `{"3": 10, "4": 2}`)
    rank_distribution TEXT,               -- 등수별 분포 (JSON, 예: `{"1": 0, "5": 5}`)
    last_updated TEXT                     -- 마지막 업데이트 시각 (ISO 8601)
);

-- `SystemLogs` (시스템 로그)
CREATE TABLE SystemLogs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT,                       -- 로그 생성 시각 (ISO 8601)
    level TEXT,                           -- 로그 레벨 (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    category TEXT,                        -- 로그 카테고리 (UI, Database, Network 등)
    message TEXT,                         -- 로그 메시지
    thread_id TEXT,                       -- 스레드 식별자
    performance_data TEXT                 -- 성능 관련 데이터 (JSON, NULLABLE)
);

-- `UserSettings` (사용자 설정)
CREATE TABLE UserSettings (
    category TEXT,
    key TEXT,                             -- 설정 키
    value TEXT,                           -- 설정 값 (JSON 형식 권장)
    is_encrypted INTEGER DEFAULT 0,       -- 암호화 여부 (0 또는 1)
    modified_at TEXT,                     -- 마지막 수정 시각 (ISO 8601)
    PRIMARY KEY (category, key)
);

-- `EmailHistory` (이메일 발송 내역)
CREATE TABLE EmailHistory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipient TEXT NOT NULL,
    subject TEXT,
    sent_at TEXT,                         -- 발송 시각 (ISO 8601)
    status TEXT,                          -- 상태 ('sent', 'failed')
    error_message TEXT                    -- 오류 메시지 (실패 시)
);
```

---

## 7. 보안 아키텍처

### 7.1 보안 레이어
```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                APPLICATION SECURITY                     │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Input       │ │ SQL         │ │ XSS Prevention      │ │ │
│  │ │ Validation  │ │ Injection   │ │ (QML)               │ │ │
│  │ │             │ │ Prevention  │ │                     │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 COMMUNICATION SECURITY                  │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ TLS 1.3     │ │ Certificate │ │ Message             │ │ │
│  │ │ Encryption  │ │ Validation  │ │ Authentication      │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   DATA SECURITY                         │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ AES-256     │ │ Secure      │ │ Data                │ │ │
│  │ │ Encryption  │ │ Key Storage │ │ Sanitization        │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 인증 및 권한 관리
```cpp
class SecurityArchitecture {
    // 플러그인 보안
    PluginSecurity {
        - Digital Signature Verification
        - Sandboxed Execution
        - Permission System
        - Code Signing Validation
    }
    
    // 데이터 보안
    DataSecurity {
        - Email Credential Encryption (AES-256)
        - Local Database Encryption
        - Secure File Storage
        - Memory Protection
    }
    
    // 네트워크 보안
    NetworkSecurity {
        - HTTPS Only Communication
        - Certificate Pinning
        - Request/Response Validation
        - Rate Limiting
    }
}
```

---

## 8. 플러그인 아키텍처

### 8.1 플러그인 시스템 구조
```
┌─────────────────────────────────────────────────────────────┐
│                   PLUGIN ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   PLUGIN HOST                           │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Plugin      │ │ Plugin      │ │ Plugin              │ │ │
│  │ │ Manager     │ │ Registry    │ │ Loader              │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Security    │ │ Lifecycle   │ │ Dependency          │ │ │
│  │ │ Validator   │ │ Manager     │ │ Resolver            │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │ Interface                      │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 PLUGIN INTERFACES                       │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ ILottoPlugin│ │ INumberGen  │ │ IStatistics         │ │ │
│  │ │ (Base)      │ │ Plugin      │ │ Plugin              │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ IUI         │ │ IEmail      │ │ IValidation         │ │ │
│  │ │ Plugin      │ │ Plugin      │ │ Plugin              │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │ Implementation                 │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │               CONCRETE PLUGINS                          │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Advanced    │ │ ML Based    │ │ Pattern             │ │ │
│  │ │ Random      │ │ Prediction  │ │ Analyzer            │ │ │
│  │ │ Plugin.dll  │ │ Plugin.dll  │ │ Plugin.dll          │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 플러그인 인터페이스 정의
```cpp
// 기본 플러그인 인터페이스
class ILottoPlugin {
public:
    virtual ~ILottoPlugin() = default;
    
    // 메타데이터
    virtual QString getPluginName() const = 0;
    virtual QString getVersion() const = 0;
    virtual QString getDescription() const = 0;
    virtual QStringList getDependencies() const = 0;
    
    // 라이프사이클
    virtual bool initialize(const QVariantMap& config) = 0;
    virtual void cleanup() = 0;
    virtual bool isValid() const = 0;
    
    // 권한
    virtual QStringList getRequiredPermissions() const = 0;
};

// 번호 생성 플러그인 인터페이스
class INumberGenerationPlugin : public ILottoPlugin {
public:
    virtual QVector<int> generateNumbers(const QVariantMap& params) = 0;
    virtual QVariantMap getDefaultParameters() const = 0;
    virtual bool validateParameters(const QVariantMap& params) const = 0;
    virtual QString getRuleDescription() const = 0;
    
    // 성능 메트릭
    /**
     * @brief 이 규칙의 예상 성능 지표를 반환합니다. (예: 예상 적중률, 실행 시간 등)
     * @return 0.0 ~ 1.0 사이의 예상 적중률 또는 기타 성능 지표.
     */
    virtual double getExpectedPerformance() const = 0;

    /**
     * @brief 이 규칙의 과거 통계 데이터를 반환합니다.
     * @return QVariantMap 형태의 통계 데이터.
     *         예: {"averageRank": 3.5, "hitCount": 15, "usageCount": 100}
     */
    virtual QVariantMap getStatistics() const = 0;
};
```

---

## 9. 배포 아키텍처

### 9.1 패키징 구조
```
┌─────────────────────────────────────────────────────────────┐
│                  DEPLOYMENT ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                  BUILD PIPELINE                         │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Source Code │ │ CMake       │ │ Qt Creator          │ │ │
│  │ │ (Git)       │ │ Build       │ │ IDE                 │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │         │               │               │               │ │
│  │         ▼               ▼               ▼               │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Compilation │ │ Testing     │ │ Quality             │ │ │
│  │ │ (MSVC)      │ │ (Qt Test)   │ │ Assurance           │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 PACKAGING LAYER                         │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ MSI         │ │ Portable    │ │ Plugin              │ │ │
│  │ │ Installer   │ │ Package     │ │ Packages            │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Dependencies│ │ Qt Runtime  │ │ Digital             │ │ │
│  │ │ Bundle      │ │ Libraries   │ │ Signatures          │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │               DISTRIBUTION LAYER                        │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ GitHub      │ │ Local       │ │ Update              │ │ │
│  │ │ Releases    │ │ Installation│ │ Server              │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 설치 패키지 구조
```
LottoProgram_v1.0.0_Setup.msi
├── Application Files/
│   ├── bin/
│   │   ├── LottoGUI.exe          (GUI Client)
│   │   ├── LottoService.exe      (Backend Service)
│   │   └── LottoInstaller.exe    (Setup Helper)
│   ├── lib/
│   │   ├── Qt6Core.dll
│   │   ├── Qt6Quick.dll
│   │   ├── Qt6RemoteObjects.dll
│   │   └── [Other Qt Libraries]
│   ├── qml/
│   │   ├── LottoApp/
│   │   │   ├── MainWindow.qml
│   │   │   ├── Components/
│   │   │   └── Views/
│   │   └── animations/
│   ├── plugins/
│   │   ├── rules/
│   │   │   ├── BasicRules.dll
│   │   │   └── AdvancedRules.dll
│   │   └── manifest.json
│   ├── data/
│   │   ├── database/
│   │   │   └── schema.sql
│   │   └── templates/
│   └── config/
│       ├── app.ini
│       └── rules.json
├── Documentation/
│   ├── UserManual.pdf
│   ├── README.txt
│   └── LICENSE.txt
└── Dependencies/
    ├── VC_Redist.x64.exe
    └── [Other Dependencies]
```

---

## 10. 성능 아키텍처

### 10.1 성능 최적화 전략
```
┌─────────────────────────────────────────────────────────────┐
│                 PERFORMANCE ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   UI PERFORMANCE                        │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ 60fps       │ │ GPU         │ │ Lazy Loading        │ │ │
│  │ │ Animation   │ │ Acceleration│ │ (QML)               │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Scene Graph │ │ Texture     │ │ Component           │ │ │
│  │ │ Optimization│ │ Caching     │ │ Pooling             │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                COMPUTATION PERFORMANCE                  │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Multi-      │ │ Async       │ │ Algorithm           │ │ │
│  │ │ Threading   │ │ Operations  │ │ Optimization        │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Thread Pool │ │ Worker      │ │ SIMD                │ │ │
│  │ │ Management  │ │ Threads     │ │ Instructions        │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            ▲                                │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 MEMORY PERFORMANCE                      │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Object      │ │ Memory      │ │ Smart Pointer       │ │ │
│  │ │ Pooling     │ │ Pooling     │ │ Management          │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│  │ │ Cache       │ │ Data        │ │ Garbage             │ │ │
│  │ │ Optimization│ │ Compression │ │ Collection          │ │ │
│  │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 10.2 성능 모니터링
```cpp
class PerformanceMonitor {
    // 메트릭 수집
    MetricsCollector {
        - CPU Usage
        - Memory Usage  
        - Frame Rate (FPS)
        - Response Time
        - Network Latency
    }
    
    // 프로파일링
    Profiler {
        - Function Call Timing
        - Memory Allocation Tracking
        - Animation Performance
        - Database Query Performance
    }
    
    // 최적화 힌트
    OptimizationAdvisor {
        - Performance Bottleneck Detection
        - Resource Usage Analysis
        - Optimization Recommendations
    }
}
```

---

## 11. 확장성 및 유지보수성

### 11.1 확장성 설계
- **수평적 확장**: 플러그인 시스템을 통한 기능 확장
- **수직적 확장**: 서비스 레이어의 독립적 확장
- **모듈러 설계**: 각 컴포넌트의 독립적 개발 및 배포

### 11.2 유지보수성
- **로깅 시스템**: 구조화된 로그 수집 및 분석
- **에러 처리**: 계층별 예외 처리 및 복구
- **모니터링**: 실시간 시스템 상태 모니터링
- **업데이트 메커니즘**: 안전한 업데이트 및 롤백

---

## 12. 아키텍처 의사결정 기록 (ADR)

### ADR-001: 클라이언트-서버 분리 아키텍처 채택
**결정**: GUI와 비즈니스 로직을 별도 프로세스로 분리
**이유**: 독립적 실행, 확장성, 유지보수성 향상
**결과**: 복잡성 증가, 통신 오버헤드 발생

### ADR-002: Qt Remote Objects 선택
**결정**: IPC 메커니즘으로 Qt Remote Objects 사용
**이유**: Qt 생태계 통합, 타입 안전성, 자동 프록시 생성
**대안**: REST API, WebSocket, Named Pipes

### ADR-003: SQLite 데이터베이스 채택
**결정**: 로컬 데이터 저장소로 SQLite 사용
**이유**: 경량, 설치 불필요, 트랜잭션 지원
**제약**: 동시성 제한, 대용량 데이터 처리 한계

### ADR-004: 플러그인 아키텍처 도입
**결정**: 규칙 엔진을 플러그인 형태로 설계
**이유**: 확장성, 재사용성, 써드파티 통합
**비용**: 보안 복잡성, 의존성 관리

---

## 13. 리스크 및 완화 방안

### 13.1 기술적 리스크
| 리스크 | 확률 | 영향도 | 완화 방안 |
|--------|------|---------|-----------|
| Qt Remote Objects 성능 문제 | 중간 | 높음 | 대안 통신 방식 준비, 성능 테스트 |
| 플러그인 보안 취약점 | 낮음 | 높음 | 디지털 서명, 샌드박스 실행 |
| 메모리 누수 | 중간 | 중간 | RAII 패턴, 스마트 포인터 사용 |
| 네트워크 연결 실패 | 높음 | 낮음 | 오프라인 모드, 재시도 로직 |

### 13.2 완화 전략
- **점진적 개발**: 핵심 기능부터 단계적 구현
- **테스트 자동화**: 지속적 통합 및 테스트
- **모니터링**: 실시간 성능 및 오류 모니터링
- **백업 계획**: 각 컴포넌트별 대안 솔루션 준비

---

**검토자**: [시스템 아키텍트]  
**승인자**: [기술 책임자]  
**승인일**: [승인일]