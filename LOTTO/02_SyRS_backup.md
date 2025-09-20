# 로또 프로그램 시스템 요구사항 명세서 (SyRS)
## System Requirements Specification for Lotto Program

**문서 버전**: 1.1  
**작성일**: 2025년 9월 19일  
**최종 수정일**: 2025년 9월 20일  
**프로젝트명**: QT/QML 기반 로또 프로그램  
**참조 문서**: CuRS v1.1

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 1.0 | 2025-09-19 | 초기 문서 작성 | 개발팀 |
| 1.1 | 2025-09-20 | SFR-004~006 적중률 분석 서브시스템 추가/강화, SFR 넘버링 재정렬 | 개발팀 |

---

## 1. 개요 (Overview)

본 문서는 CuRS에서 정의된 고객 요구사항을 바탕으로 시스템 레벨의 요구사항을 정의합니다.

### 1.1 목적
- CuRS의 고객 요구사항을 시스템 관점에서 세분화
- 시스템 컴포넌트 간의 인터페이스 정의
- 구현 가능한 기술적 요구사항 명시

### 1.2 시스템 개요
```
┌─────────────────────────────────────────────────────────────────────┐
│                       QT/QML 로또 프로그램                          │
├─────────────────────────────────────────────────────────────────────┤
│ GUI Client (독립실행)  │  Backend Service     │  External APIs      │
│ ─────────────────────  │  ─────────────────   │  ─────────────────  │
│ • QML UI Layer        │  • Rule Engine       │  • 동행복권 API      │
│ • Animation Engine    │  • Number Generator  │  • SMTP Server      │
│ • Client Controller   │  • Data Manager      │  • Update Server    │
│ • Settings Manager    │  • Scheduler Service │                     │
│ • Statistics View     │  • Email Service     │                     │
│ • Plugin Manager      │  ### SNFR-004: 보안 요구사항
- **데이터 암호화**: AES-256 (이메일 인증 정보)
- **패스워드 저장**: PBKDF2 해시
- **네트워크 통신**: TLS 1.2 이상
- **로그 보안**: 민감 정보 마스킹
- **플러그인 보안**: 디지털 서명 검증
- **API 인증**: JWT 토큰 기반

### SNFR-005: 배포 및 설치 요구사항
- **설치 시간**: 5분 이내 (모든 의존성 포함)
- **설치 성공률**: 99% 이상
- **포터블 패키지 크기**: 50MB 이하
- **설치 패키지 크기**: 100MB 이하
- **의존성 다운로드**: 병렬 처리로 시간 단축
- **업데이트 다운로드**: 백그라운드 처리
- **롤백 시간**: 2분 이내

### SNFR-006: 사용자 경험 요구사항
- **애니메이션 프레임률**: 60fps 유지
- **UI 응답 시간**: 100ms 이내
- **시각적 피드백**: 즉시 제공
- **페이지 전환**: 300ms 이내
- **로딩 표시**: 1초 이상 작업 시 필수
- **오류 복구**: 자동 재시도 3회    │                     │
│                       │  • Security Module   │                     │
├─────────────────────────────────────────────────────────────────────┤
│ Communication: Qt Remote Objects / RESTful API                     │
│ Deployment: MSI Installer / Portable Package                       │
└─────────────────────────────────────────────────────────────────────┘
```## System Requirements Specification for Lotto Program

**문서 버전**: 1.1  
**작성일**: 2025년 9월 19일  
**최종 수정일**: 2025년 9월 20일  
**프로젝트명**: QT/QML 기반 로또 프로그램  
**참조 문서**: CuRS v1.1

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 1.0 | 2025-09-19 | 초기 문서 작성 | 개발팀 |
| 1.1 | 2025-09-20 | SFR-004~006 적중률 분석 서브시스템 추가/강화, SFR 넘버링 재정렬 | 개발팀 |

---

## 1. 개요 (Overview)

본 문서는 CuRS에서 정의된 고객 요구사항을 바탕으로 시스템 레벨의 요구사항을 정의합니다.

### 1.1 목적
- CuRS의 고객 요구사항을 시스템 관점에서 세분화
- 시스템 컴포넌트 간의 인터페이스 정의
- 구현 가능한 기술적 요구사항 명시

### 1.2 시스템 개요
```
┌─────────────────────────────────────────────────────────┐
│                  QT/QML 로또 프로그램                    │
├─────────────────────────────────────────────────────────┤
│  QML UI Layer     │  C++ Backend     │  External APIs   │
│  - Main Window    │  - Number Gen    │  - 동행복권 API   │
│  - Settings       │  - Data Manager  │  - SMTP Server   │
│  - Statistics     │  - Scheduler     │                  │
│  - Email Config   │  - Email Service │                  │
└─────────────────────────────────────────────────────────┘
```

---

## 2. 시스템 기능 요구사항 (System Functional Requirements)

### SFR-001: 번호 생성 규칙 엔진
**추적성**: FR-001  
**설명**: 다양한 번호 생성 규칙을 구현하고 관리하는 핵심 서브시스템

#### SFR-001.1: 규칙 엔진 아키텍처
```cpp
class INumberGenerationRule {
public:
    virtual QString getRuleName() const = 0;
    virtual QString getDescription() const = 0;
    virtual QVector<int> applyRule(const GenerationContext& context) = 0;
    virtual bool validateParameters(const QVariantMap& params) = 0;
    virtual QVariantMap getDefaultParameters() = 0;
};

class NumberGenerationEngine {
public:
    void registerRule(std::shared_ptr<INumberGenerationRule> rule);
    void removeRule(const QString& ruleName);
    QVector<int> generateNumbers(const QStringList& ruleNames, 
                                const QVariantMap& parameters);
    QStringList getAvailableRules() const;
    bool validateRuleCombination(const QStringList& rules);
};
```

#### SFR-001.2: 기본 생성 규칙 구현
- **SimpleRandomRule**: Mersenne Twister 알고리즘 기반 순수 랜덤
- **UserInputRule**: 사용자 입력 번호 검증 및 적용
- **ExcludeNumbersRule**: 지정된 번호 제외 필터
- **IncludeNumbersRule**: 필수 포함 번호 강제 적용
- **RangeConstraintRule**: 번호 범위 제한 (min-max)

#### SFR-001.3: 고급 생성 규칙 구현
```cpp
class StatisticsBasedRule : public INumberGenerationRule {
private:
    QMap<int, double> frequencyWeights;
    StatisticsEngine* statsEngine;
public:
    QVector<int> applyRule(const GenerationContext& context) override;
    void updateStatistics(const QList<LottoDrawResult>& history);
};

class PatternBasedRule : public INumberGenerationRule {
private:
    double oddEvenRatio;
    double highLowRatio;
public:
    QVector<int> applyRule(const GenerationContext& context) override;
    void setOddEvenRatio(double ratio); // 3:3, 4:2 등
    void setHighLowRatio(double ratio); // 1-22 vs 23-45
};
```

#### SFR-001.4: 복합 규칙 처리기
```cpp
class CompositeRuleProcessor {
public:
    struct RuleWeight {
        QString ruleName;
        double weight;
        int priority;
    };
    
    QVector<int> processRules(const QList<RuleWeight>& rules,
                             const GenerationContext& context);
    bool resolveRuleConflicts(QVector<int>& candidates);
    QVector<int> applyFinalConstraints(const QVector<int>& numbers);
};
```

### SFR-002: 규칙 관리 서브시스템
**추적성**: FR-010  
**설명**: 사용자 정의 규칙과 규칙 조합을 관리하는 시스템

#### SFR-002.1: 규칙 저장소 관리자
```cpp
class RuleRepository {
public:
    struct CustomRule {
        QString id;
        QString name;
        QString description;
        QStringList baseRules;
        QVariantMap parameters;
        QDateTime created;
        QDateTime lastUsed;
        int usageCount;
    };
    
    bool saveCustomRule(const CustomRule& rule);
    bool deleteCustomRule(const QString& ruleId);
    QList<CustomRule> getUserRules();
    CustomRule getRuleById(const QString& ruleId);
    void updateUsageStatistics(const QString& ruleId);
};
```

#### SFR-002.2: 규칙 프리셋 관리자
- **기본 프리셋**: 미리 정의된 인기 규칙 조합
- **사용자 프리셋**: 개인화된 규칙 조합 저장
- **프리셋 공유**: 규칙 조합 내보내기/가져오기 (JSON)
- **성능 추적**: 프리셋별 당첨 통계 기록

#### SFR-002.3: 규칙 검증기
```cpp
class RuleValidator {
public:
    struct ValidationResult {
        bool isValid;
        QStringList warnings;
        QStringList errors;
        double estimatedPerformance;
    };
    
    ValidationResult validateRuleSet(const QStringList& rules,
                                   const QVariantMap& params);
    bool checkRuleCompatibility(const QString& rule1, const QString& rule2);
    QStringList suggestOptimizations(const QStringList& rules);
};
```

### SFR-003: 당첨번호 조회 서브시스템
**추적성**: FR-005  
**설명**: 외부 API를 통한 실제 당첨번호 조회 및 관리

#### SFR-003.1: HTTP 클라이언트
- **프로토콜**: HTTPS
- **엔드포인트**: 동행복권 공식 API
- **타임아웃**: 30초
- **재시도**: 3회 (지수 백오프)
- **응답 형식**: JSON

#### SFR-003.2: 데이터 파서
- **입력**: HTTP 응답 JSON
- **처리**: 당첨번호, 보너스번호, 당첨금액 파싱
- **검증**: 데이터 무결성 확인
- **출력**: 구조화된 당첨 정보 객체

#### SFR-003.3: 로컬 캐시 관리자
- **저장소**: SQLite 데이터베이스
- **스키마**: 회차, 당첨번호, 보너스번호, 당첨금액, 추첨일
- **인덱싱**: 회차별, 날짜별 인덱스
- **용량 관리**: 최대 1000회차 데이터

### SFR-004: 적중률 분석 및 성과 추적 서브시스템
**추적성**: FR-003, FR-005  
**설명**: 사용자 번호와 당첨번호 비교, 적중률 분석, 성과 추적 및 투자 수익률 분석

#### SFR-004.1: 번호 비교 및 적중 분석 엔진
```cpp
int calculateRank(vector<int> userNumbers, vector<int> winningNumbers, int bonusNumber) {
    int matchCount = 0;
    bool bonusMatch = false;
    
    for (int userNum : userNumbers) {
        if (find(winningNumbers.begin(), winningNumbers.end(), userNum) != winningNumbers.end()) {
            matchCount++;
        } else if (userNum == bonusNumber) {
            bonusMatch = true;
        }
    }
    
    // 등수 판정 로직
    if (matchCount == 6) return 1;
    if (matchCount == 5 && bonusMatch) return 2;
    if (matchCount == 5) return 3;
    if (matchCount == 4) return 4;
    if (matchCount == 3) return 5;
    return 0; // 당첨 없음
}
```cpp
class HitRateAnalysisEngine {
public:
    // 기본 번호 비교
    int calculateRank(vector<int> userNumbers, vector<int> winningNumbers, int bonusNumber);
    bool checkBonusMatch(vector<int> userNumbers, int bonusNumber);
    
    // 적중률 계산
    double calculateOverallHitRate(int userId, int periodDays = 365);
    QMap<int, int> getHitDistribution(int userId); // 0개~6개 적중 분포
    QMap<int, int> getRankDistribution(int userId); // 등수별 적중 분포
    
    // 번호별 적중 성공률
    QMap<int, double> getNumberHitSuccessRate(int userId);
    QVector<int> getBestPerformingNumbers(int userId, int count = 10);
    QVector<int> getWorstPerformingNumbers(int userId, int count = 10);
    
    // 시계열 적중률 분석
    QList<QPointF> getHitRateTrend(int userId, int periodDays = 365);
    QMap<QString, double> getMonthlyHitRate(int userId, int year);
    QMap<QString, double> getYearlyHitRate(int userId);
};

int calculateRank(vector<int> userNumbers, vector<int> winningNumbers, int bonusNumber) {
    int matchCount = 0;
    bool bonusMatch = false;
    
    for (int userNum : userNumbers) {
        if (find(winningNumbers.begin(), winningNumbers.end(), userNum) != winningNumbers.end()) {
            matchCount++;
        } else if (userNum == bonusNumber) {
            bonusMatch = true;
        }
    }
    
    // 등수 판정 로직
    if (matchCount == 6) return 1;
    if (matchCount == 5 && bonusMatch) return 2;
    if (matchCount == 5) return 3;
    if (matchCount == 4) return 4;
    if (matchCount == 3) return 5;
    return 0; // 당첨 없음
}
```

#### SFR-004.2: 투자 수익률 분석 엔진
```cpp
class ROIAnalysisEngine {
public:
    // ROI 계산
    double calculateROI(int userId, int periodDays = 365);
    double calculateBreakEvenPoint(int userId);
    QList<QPointF> getCumulativeProfitLoss(int userId);
    
    // 가상 투자 시뮬레이션
    struct SimulationResult {
        double totalInvestment;
        double totalWinnings;
        double netProfit;
        double roi;
        int totalDraws;
        QMap<int, int> rankDistribution;
    };
    
    SimulationResult runVirtualInvestment(const QStringList& rules, 
                                         int periodDays = 365,
                                         int numbersPerDraw = 5);
    
    // 비용 계산
    double calculateTotalCost(int userId, int periodDays = 365);
    double calculateTotalWinnings(int userId, int periodDays = 365);
    double calculateNetProfit(int userId, int periodDays = 365);
};
```

#### SFR-004.3: 당첨금 계산기
- **입력**: 당첨 등수, 회차 정보
- **처리**: 해당 회차의 등수별 당첨금 조회
- **출력**: 예상 당첨금액

### SFR-005: 성과 시각화 및 보고서 서브시스템
**추적성**: FR-004, FR-005  
**설명**: 적중률 통계 시각화, 성과 보고서 생성 및 규칙 성능 평가

#### SFR-005.1: 적중률 시각화 엔진
```cpp
class HitRateVisualizationEngine {
public:
    // 차트 데이터 생성
    QJsonObject generateHitRateChart(int userId, const QString& chartType);
    QJsonObject generateRankDistributionChart(int userId);
    QJsonObject generateRulePerformanceChart(const QStringList& rules);
    QJsonObject generateTimeSeriesChart(int userId, int periodDays = 365);
    
    // 대시보드 데이터
    QJsonObject generatePerformanceDashboard(int userId);
    QJsonObject generateSummaryMetrics(int userId);
    
    // 비교 차트
    QJsonObject generateRuleComparisonChart(const QStringList& rules);
    QJsonObject generateNumberPerformanceHeatmap(int userId);
    
    // 차트 타입
    enum ChartType {
        BAR_CHART,          // 막대그래프
        PIE_CHART,          // 원그래프  
        LINE_CHART,         // 선그래프
        AREA_CHART,         // 영역그래프
        SCATTER_CHART,      // 산점도
        HEATMAP,           // 히트맵
        RADAR_CHART        // 레이더차트
    };
};
```

#### SFR-005.2: 성과 보고서 생성기
```cpp
class PerformanceReportGenerator {
public:
    // 보고서 생성
    QString generateWeeklyReport(int userId);
    QString generateMonthlyReport(int userId, int year, int month);
    QString generateYearlyReport(int userId, int year);
    QString generateCustomReport(int userId, const QDate& startDate, const QDate& endDate);
    
    // PDF 보고서
    bool generatePDFReport(int userId, const QString& reportType, const QString& filePath);
    
    // 이메일 보고서
    struct EmailReport {
        QString subject;
        QString htmlContent;
        QString plainTextContent;
        QStringList attachments;
    };
    
    EmailReport prepareEmailReport(int userId, const QString& reportType);
    
    // 성과 개선 제안
    QStringList generateImprovementSuggestions(int userId);
    QStringList recommendBestRules(int userId);
    QString generatePerformanceAnalysis(int userId);
};
```

#### SFR-005.3: 규칙 성능 추적 및 분석기
```cpp
class AdvancedStatisticsEngine {
public:
    // 기본 통계
    QMap<int, int> getNumberFrequency(int periodDays = 365);
    QVector<int> getMostFrequentNumbers(int count = 10);
    QVector<int> getLeastFrequentNumbers(int count = 10);
    
    // 패턴 분석
    double getOddEvenRatio();
    double getHighLowRatio();
    QMap<QString, double> getIntervalDistribution();
    QList<QVector<int>> getConsecutivePatterns();
    
    // 규칙 성능 분석
    double calculateRuleSuccessRate(const QString& ruleName);
    QMap<QString, int> getRuleUsageStatistics();
    double predictRulePerformance(const QStringList& rules);
};
```cpp
class RulePerformanceTracker {
public:
    // 규칙별 성과 분석
    double calculateRuleSuccessRate(const QString& ruleName);
    double calculateRuleROI(const QString& ruleName, int periodDays = 365);
    QMap<QString, int> getRuleUsageStatistics();
    QMap<QString, double> getRuleWinRatios();
    
    // 성능 지표
    struct RulePerformanceMetrics {
        QString ruleName;
        int totalUsage;
        int totalHits;
        double hitRate;
        double averageRank;
        double roi;
        QDateTime lastUsed;
        QMap<int, int> rankDistribution; // 등수별 적중 분포
    };
    
    QList<RulePerformanceMetrics> getAllRulePerformances();
    RulePerformanceMetrics getRulePerformance(const QString& ruleName);
    
    // 규칙 추천 시스템
    QStringList recommendTopPerformingRules(int count = 5);
    QStringList recommendRulesForUser(int userId);
    double predictRulePerformance(const QStringList& rules);
    
    // 패턴 분석
    double getOddEvenRatio();
    double getHighLowRatio();
    QMap<QString, double> getIntervalDistribution();
    QList<QVector<int>> getConsecutivePatterns();
    
    // 기본 통계
    QMap<int, int> getNumberFrequency(int periodDays = 365);
    QVector<int> getMostFrequentNumbers(int count = 10);
    QVector<int> getLeastFrequentNumbers(int count = 10);
};
```

### SFR-006: 사용자 성과 데이터 저장소
**추적성**: FR-005  
**설명**: 적중률 분석을 위한 사용자별 성과 데이터 관리

#### SFR-006.1: 성과 데이터 모델
```cpp
class UserPerformanceData {
public:
    struct NumberGenerationRecord {
        int recordId;
        int userId;
        QVector<int> generatedNumbers;
        QStringList appliedRules;
        QDateTime generationTime;
        QString userNotes;
        
        // 적중 결과 (당첨번호 발표 후 업데이트)
        int drawNumber;
        QVector<int> winningNumbers;
        int bonusNumber;
        int matchCount;
        int rank;
        bool bonusMatch;
        double winningAmount;
        QDateTime resultUpdatedTime;
    };
    
    struct UserHitStatistics {
        int userId;
        int totalGenerations;
        QMap<int, int> hitDistribution; // 0~6개 적중 분포
        QMap<int, int> rankDistribution; // 등수별 분포
        double overallHitRate;
        double totalInvestment;
        double totalWinnings;
        double netProfit;
        double roi;
        QDateTime lastActivityTime;
    };
    
    // 데이터 저장 및 조회
    bool saveGenerationRecord(const NumberGenerationRecord& record);
    bool updateHitResult(int recordId, const HitResult& result);
    QList<NumberGenerationRecord> getUserRecords(int userId, int limit = 100);
    UserHitStatistics calculateUserStatistics(int userId);
};
```

#### SFR-006.2: 성과 데이터 캐시 관리자
```cpp
class PerformanceCacheManager {
public:
    // 캐시된 통계 관리
    void updateUserStatisticsCache(int userId);
    UserHitStatistics getCachedStatistics(int userId);
    bool isCacheValid(int userId);
    
    // 배치 업데이트
    void batchUpdateStatistics(const QList<int>& userIds);
    void scheduleStatisticsUpdate(int userId, const QDateTime& updateTime);
    
    // 메모리 관리
    void clearExpiredCache();
    void preloadFrequentUsers();
};
```

### SFR-007: 스케줄러 서브시스템
**추적성**: FR-008  
**설명**: 자동 예약 실행을 위한 작업 스케줄링

#### SFR-007.1: 강화된 작업 스케줄러
```cpp
class EnhancedTaskScheduler {
public:
    struct ScheduleTask {
        QString id;
        QString name;
        QDateTime nextExecution;
        RecurrenceType recurrence;
        TaskType type;
        QVariantMap parameters;
        QStringList selectedRules;    // 새로 추가: 적용할 규칙들
        QVariantMap ruleParameters;   // 새로 추가: 규칙별 파라미터
        int generationCount;          // 새로 추가: 생성할 번호 세트 수
    };
    
    void addTask(const ScheduleTask& task);
    void removeTask(const QString& taskId);
    void executeTaskWithRules(const QString& taskId);
    QList<ScheduleTask> getPendingTasks();
    void updateTaskRules(const QString& taskId, const QStringList& rules);
};
```

#### SFR-006.2: 반복 일정 관리자
- **반복 유형**: 
  - ONCE (한 번만)
  - DAILY (매일)
  - WEEKLY (매주)
  - MONTHLY (매월)
  - CUSTOM (사용자 정의)

#### SFR-006.3: 백그라운드 실행기
- **Windows 서비스 등록**: QSystemTrayIcon 활용
- **시스템 재부팅 후 복구**: Windows 레지스트리 활용
- **실행 로그**: 작업 실행 이력 관리
- **규칙 기반 실행**: 예약된 규칙에 따른 자동 번호 생성

### SFR-009: GUI 클라이언트 서브시스템
**추적성**: FR-010, FR-013  
**설명**: 독립 실행 가능한 GUI 클라이언트와 애니메이션 엔진

#### SFR-009.1: 클라이언트 아키텍처
```cpp
class LottoGUIClient : public QApplication {
    Q_OBJECT
public:
    bool connectToBackend(const QString& endpoint);
    bool startLocalBackend();
    void disconnectFromBackend();
    bool isConnected() const;
    
private:
    APIClient* apiClient;
    LocalBackendManager* localBackend;
    ConnectionManager* connectionManager;
};

class ConnectionManager : public QObject {
    Q_OBJECT
public:
    enum ConnectionMode {
        Local,
        Remote,
        Auto
    };
    
    bool establishConnection(ConnectionMode mode);
    void monitorConnection();
    
signals:
    void connectionEstablished();
    void connectionLost();
    void connectionRestored();
};
```

#### SFR-008.2: 애니메이션 엔진
```cpp
class AnimationEngine : public QObject {
    Q_OBJECT
public:
    // 로또 공 추첨 애니메이션
    void startLottoBallAnimation(const QVector<int>& numbers);
    
    // 번호 생성 과정 애니메이션
    void animateNumberGeneration(const QStringList& rules);
    
    // 차트 애니메이션
    void animateChartTransition(const QVariantMap& fromData, 
                              const QVariantMap& toData);
    
    // UI 전환 애니메이션
    void animatePageTransition(QQuickItem* from, QQuickItem* to);
    
    // 피드백 애니메이션
    void showSuccessAnimation();
    void showErrorAnimation();
    void showLoadingAnimation();
    
public slots:
    void setAnimationSpeed(double speed); // 0.5 ~ 2.0
    void enableAnimations(bool enabled);
    
private:
    QPropertyAnimation* createBallAnimation(int ballNumber);
    QSequentialAnimationGroup* createNumberSequence();
};
```

#### SFR-008.3: QML UI 컴포넌트
- **LottoBallView**: 로또 공 애니메이션 컴포넌트
- **RuleSelectionPanel**: 규칙 선택 인터페이스
- **StatisticsChart**: 애니메이션 지원 차트
- **NumberDisplayBoard**: 번호 표시 보드
- **ProgressIndicator**: 작업 진행 상태 표시

### SFR-009: 배포 및 설치 서브시스템
**추적성**: FR-011  
**설명**: 패키지 관리, 설치, 업데이트 시스템

#### SFR-009.1: 설치 관리자
```cpp
class InstallationManager {
public:
    struct InstallationConfig {
        QString installPath;
        bool createDesktopShortcut;
        bool createStartMenuEntry;
        bool autoStartService;
        QStringList selectedComponents;
    };
    
    bool validateSystemRequirements();
    bool installDependencies();
    bool installApplication(const InstallationConfig& config);
    bool createUninstaller();
    void registerFileAssociations();
};

// NSIS/MSI 스크립트 생성기
class InstallerGenerator {
public:
    QString generateNSISScript(const InstallationConfig& config);
    QString generateMSIConfig(const InstallationConfig& config);
    bool compileInstaller(const QString& script);
};
```

#### SFR-009.2: 패키지 관리자
```cpp
class PackageManager {
public:
    struct PackageInfo {
        QString name;
        QString version;
        QString description;
        qint64 size;
        QStringList dependencies;
        QString downloadUrl;
        QString checksum;
    };
    
    // 포터블 패키지 생성
    bool createPortablePackage(const QString& outputPath);
    
    // 단일 실행 파일 생성
    bool createSingleExecutable(const QString& outputPath);
    
    // 의존성 관리
    QList<PackageInfo> resolveDependencies();
    bool downloadDependency(const PackageInfo& package);
    
    // 크기 최적화
    void optimizePackageSize();
    void removeUnnecessaryFiles();
};
```

#### SFR-009.3: 업데이트 시스템
```cpp
class UpdateManager : public QObject {
    Q_OBJECT
public:
    struct UpdateInfo {
        QString version;
        QString releaseNotes;
        qint64 downloadSize;
        QString downloadUrl;
        bool isRequired;
        QDateTime releaseDate;
    };
    
    void checkForUpdates();
    void downloadUpdate(const UpdateInfo& update);
    void installUpdate();
    void rollbackToPreviousVersion();
    
signals:
    void updateAvailable(const UpdateInfo& info);
    void updateDownloaded();
    void updateInstalled();
    void updateFailed(const QString& error);
    
private:
    void backupCurrentVersion();
    void preserveUserSettings();
};
```

### SFR-008: 이메일 서브시스템
**추적성**: FR-009  
**설명**: SMTP를 통한 이메일 발송 기능

#### SFR-008.1: SMTP 클라이언트
```cpp
class SMTPClient {
public:
    struct SMTPConfig {
        QString server;
        int port;
        QString username;
        QString password;
        bool useSSL;
        bool useTLS;
    };
    
    bool sendEmail(const EmailMessage& message);
    bool testConnection();
    void setConfig(const SMTPConfig& config);
};
```

#### SFR-008.2: 강화된 이메일 템플릿 엔진
- **템플릿 형식**: HTML + 변수 치환
- **지원 변수**: 
  - {{numbers}} - 생성된 번호들
  - {{date}} - 생성 날짜
  - {{time}} - 생성 시간
  - {{rules}} - 적용된 규칙 목록 (새로 추가)
  - {{ruleDetails}} - 규칙별 상세 정보 (새로 추가)
  - {{statistics}} - 규칙 성능 통계 (새로 추가)
- **첨부파일**: PDF, PNG, JPG (최대 10MB)
- **규칙별 포맷팅**: 규칙에 따른 번호 하이라이팅

#### SFR-008.3: 발송 이력 관리자
- **저장 정보**: 발송일시, 수신자, 제목, 상태, 사용된 규칙
- **상태 코드**: 대기, 발송중, 성공, 실패
- **재발송 기능**: 실패한 이메일 재시도

### SFR-008: GUI 클라이언트 서브시스템
**추적성**: FR-009, FR-012  
**설명**: 독립 실행 가능한 GUI 클라이언트와 애니메이션 엔진

#### SFR-008.1: 클라이언트 아키텍처
```cpp
class LottoGUIClient : public QApplication {
    Q_OBJECT
public:
    bool connectToBackend(const QString& endpoint);
    bool startLocalBackend();
    void disconnectFromBackend();
    bool isConnected() const;
    
private:
    APIClient* apiClient;
    LocalBackendManager* localBackend;
    ConnectionManager* connectionManager;
};

class ConnectionManager : public QObject {
    Q_OBJECT
public:
    enum ConnectionMode {
        Local,
        Remote,
        Auto
    };
    
    bool establishConnection(ConnectionMode mode);
    void monitorConnection();
    
signals:
    void connectionEstablished();
    void connectionLost();
    void connectionRestored();
};
```

#### SFR-008.2: 애니메이션 엔진
```cpp
class AnimationEngine : public QObject {
    Q_OBJECT
public:
    // 로또 공 추첨 애니메이션
    void startLottoBallAnimation(const QVector<int>& numbers);
    
    // 번호 생성 과정 애니메이션
    void animateNumberGeneration(const QStringList& rules);
    
    // 차트 애니메이션
    void animateChartTransition(const QVariantMap& fromData, 
                              const QVariantMap& toData);
    
    // UI 전환 애니메이션
    void animatePageTransition(QQuickItem* from, QQuickItem* to);
    
    // 피드백 애니메이션
    void showSuccessAnimation();
    void showErrorAnimation();
    void showLoadingAnimation();
    
public slots:
    void setAnimationSpeed(double speed); // 0.5 ~ 2.0
    void enableAnimations(bool enabled);
    
private:
    QPropertyAnimation* createBallAnimation(int ballNumber);
    QSequentialAnimationGroup* createNumberSequence();
};
```

#### SFR-008.3: QML UI 컴포넌트
- **LottoBallView**: 로또 공 애니메이션 컴포넌트
- **RuleSelectionPanel**: 규칙 선택 인터페이스
- **StatisticsChart**: 애니메이션 지원 차트
- **NumberDisplayBoard**: 번호 표시 보드
- **ProgressIndicator**: 작업 진행 상태 표시

### SFR-009: 배포 및 설치 서브시스템
**추적성**: FR-011  
**설명**: 패키지 관리, 설치, 업데이트 시스템

#### SFR-009.1: 설치 관리자
```cpp
class InstallationManager {
public:
    struct InstallationConfig {
        QString installPath;
        bool createDesktopShortcut;
        bool createStartMenuEntry;
        bool autoStartService;
        QStringList selectedComponents;
    };
    
    bool validateSystemRequirements();
    bool installDependencies();
    bool installApplication(const InstallationConfig& config);
    bool createUninstaller();
    void registerFileAssociations();
};

// NSIS/MSI 스크립트 생성기
class InstallerGenerator {
public:
    QString generateNSISScript(const InstallationConfig& config);
    QString generateMSIConfig(const InstallationConfig& config);
    bool compileInstaller(const QString& script);
};
```

#### SFR-009.2: 패키지 관리자
```cpp
class PackageManager {
public:
    struct PackageInfo {
        QString name;
        QString version;
        QString description;
        qint64 size;
        QStringList dependencies;
        QString downloadUrl;
        QString checksum;
    };
    
    // 포터블 패키지 생성
    bool createPortablePackage(const QString& outputPath);
    
    // 단일 실행 파일 생성
    bool createSingleExecutable(const QString& outputPath);
    
    // 의존성 관리
    QList<PackageInfo> resolveDependencies();
    bool downloadDependency(const PackageInfo& package);
    
    // 크기 최적화
    void optimizePackageSize();
    void removeUnnecessaryFiles();
};
```

#### SFR-009.3: 업데이트 시스템
```cpp
class UpdateManager : public QObject {
    Q_OBJECT
public:
    struct UpdateInfo {
        QString version;
        QString releaseNotes;
        qint64 downloadSize;
        QString downloadUrl;
        bool isRequired;
        QDateTime releaseDate;
    };
    
    void checkForUpdates();
    void downloadUpdate(const UpdateInfo& update);
    void installUpdate();
    void rollbackToPreviousVersion();
    
signals:
    void updateAvailable(const UpdateInfo& info);
    void updateDownloaded();
    void updateInstalled();
    void updateFailed(const QString& error);
    
private:
    void backupCurrentVersion();
    void preserveUserSettings();
};
```

### SFR-010: 플러그인 시스템
**추적성**: FR-012  
**설명**: 확장 가능한 플러그인 아키텍처

#### SFR-010.1: 플러그인 인터페이스
```cpp
class ILottoPlugin {
public:
    virtual ~ILottoPlugin() = default;
    virtual QString getPluginName() const = 0;
    virtual QString getVersion() const = 0;
    virtual QString getDescription() const = 0;
    virtual bool initialize() = 0;
    virtual void cleanup() = 0;
};

class INumberGenerationPlugin : public ILottoPlugin {
public:
    virtual QVector<int> generateNumbers(const QVariantMap& params) = 0;
    virtual QVariantMap getDefaultParameters() const = 0;
    virtual bool validateParameters(const QVariantMap& params) const = 0;
};
```

#### SFR-010.2: 플러그인 매니저
```cpp
class PluginManager : public QObject {
    Q_OBJECT
public:
    bool loadPlugin(const QString& pluginPath);
    void unloadPlugin(const QString& pluginName);
    QStringList getLoadedPlugins() const;
    
    template<typename T>
    QList<T*> getPluginsOfType();
    
    bool enablePlugin(const QString& pluginName);
    bool disablePlugin(const QString& pluginName);
    
private:
    QMap<QString, QPluginLoader*> loadedPlugins;
    QMap<QString, bool> pluginStates;
    
    bool validatePlugin(QObject* plugin);
    void registerPluginTypes();
};
```

---

## 3. 시스템 비기능 요구사항 (System Non-Functional Requirements)

### SNFR-001: 성능 요구사항
- **번호 생성 시간**: 100ms 이내 (단일 규칙), 500ms 이내 (복합 규칙)
- **규칙 검증 시간**: 50ms 이내
- **데이터베이스 조회**: 500ms 이내 (1000건 기준)
- **HTTP 요청 응답**: 30초 이내
- **UI 반응성**: 16ms 이내 (60fps 유지)
- **애니메이션 성능**: 60fps 유지, 드롭 프레임 5% 이하
- **메모리 사용량**: 최대 512MB (GUI 클라이언트 256MB + 백엔드 256MB)
- **규칙 엔진 처리**: 동시 10개 규칙 조합 처리 가능
- **GUI 클라이언트 시작 시간**: 3초 이내
- **백엔드 연결 시간**: 1초 이내

### SNFR-002: 확장성 요구사항
- **데이터베이스**: 최대 100만 건 레코드 지원
- **동시 예약 작업**: 최대 100개
- **이메일 대기열**: 최대 1000개
- **사용자 번호 조합**: 무제한
- **사용자 정의 규칙**: 최대 1000개
- **규칙 조합**: 최대 20개 규칙 동시 적용
- **규칙 프리셋**: 최대 500개 저장
- **동시 GUI 클라이언트**: 최대 10개 연결
- **플러그인**: 최대 100개 동시 로드
- **애니메이션 객체**: 최대 1000개 동시 처리

### SNFR-003: 신뢰성 요구사항
- **시스템 가동률**: 99.9%
- **데이터 백업**: 일일 자동 백업
- **오류 복구**: 자동 재시작 (3회 실패 시 사용자 알림)
- **데이터 무결성**: 트랜잭션 기반 ACID 보장

### SNFR-004: 배포 및 설치 요구사항
- **설치 시간**: 5분 이내 (모든 의존성 포함)
- **설치 성공률**: 99% 이상
- **포터블 패키지 크기**: 50MB 이하
- **설치 패키지 크기**: 100MB 이하
- **의존성 다운로드**: 병렬 처리로 시간 단축
- **업데이트 다운로드**: 백그라운드 처리
- **롤백 시간**: 2분 이내

### SNFR-005: 사용자 경험 요구사항
- **애니메이션 프레임률**: 60fps 유지
- **UI 응답 시간**: 100ms 이내
- **시각적 피드백**: 즉시 제공
- **페이지 전환**: 300ms 이내
- **로딩 표시**: 1초 이상 작업 시 필수
- **오류 복구**: 자동 재시도 3회

---

## 4. 시스템 인터페이스 요구사항

### SIR-001: 사용자 인터페이스
- **프레임워크**: QML + Qt Quick Controls 2
- **해상도**: 최소 1024x768, 권장 1920x1080
- **반응형**: 창 크기 변경 대응
- **접근성**: WAI-ARIA 가이드라인 준수
- **애니메이션**: Qt Quick Animation 프레임워크
- **테마**: Material Design 또는 Universal Design

### SIR-002: 클라이언트-서버 통신
- **프로토콜**: Qt Remote Objects 또는 HTTP REST API
- **데이터 형식**: JSON
- **연결 방식**: TCP/IP (로컬) 또는 HTTPS (원격)
- **인증**: JWT 토큰 기반
- **압축**: gzip 압축 지원

### SIR-003: 외부 시스템 인터페이스
- **동행복권 API**: REST API, JSON 응답
- **SMTP 서버**: 표준 SMTP 프로토콜
- **운영체제**: Windows API (작업 스케줄러, 시스템 트레이)
- **업데이트 서버**: HTTPS 기반 파일 다운로드

### SIR-004: 내부 모듈 인터페이스
```cpp
// 주요 인터페이스 정의
class INumberGenerator {
public:
    virtual QVector<int> generateNumbers() = 0;
    virtual QVector<int> generateWithRules(const QStringList& rules, 
                                         const QVariantMap& params) = 0;
    virtual bool validateNumbers(const QVector<int>& numbers) = 0;
};

class IDataManager {
public:
    virtual bool saveNumbers(const QVector<int>& numbers, 
                           const QString& ruleInfo) = 0;
    virtual QList<LottoData> getHistory(int count = 100) = 0;
    virtual bool saveCustomRule(const CustomRule& rule) = 0;
    virtual QList<CustomRule> getCustomRules() = 0;
};

class IEmailService {
public:
    virtual bool sendEmail(const EmailMessage& message) = 0;
    virtual bool sendWithRuleInfo(const EmailMessage& message,
                                const QStringList& appliedRules) = 0;
    virtual bool testConnection() = 0;
};

class IRuleEngine {
public:
    virtual QVector<int> applyRules(const QStringList& ruleNames,
                                  const QVariantMap& parameters) = 0;
    virtual bool validateRuleSet(const QStringList& rules) = 0;
    virtual QStringList getAvailableRules() = 0;
    virtual QVariantMap getRuleStatistics(const QString& ruleName) = 0;
};

class IAnimationEngine {
public:
    virtual void startLottoBallAnimation(const QVector<int>& numbers) = 0;
    virtual void animateNumberGeneration(const QStringList& rules) = 0;
    virtual void animateChartTransition(const QVariantMap& data) = 0;
    virtual void setAnimationSpeed(double speed) = 0;
    virtual void enableAnimations(bool enabled) = 0;
};

class IPackageManager {
public:
    virtual bool createPortablePackage(const QString& outputPath) = 0;
    virtual bool createInstaller(const QString& outputPath) = 0;
    virtual bool validateDependencies() = 0;
    virtual qint64 calculatePackageSize() = 0;
};

class IPluginManager {
public:
    virtual bool loadPlugin(const QString& pluginPath) = 0;
    virtual void unloadPlugin(const QString& pluginName) = 0;
    virtual QStringList getLoadedPlugins() const = 0;
    virtual bool enablePlugin(const QString& pluginName) = 0;
};
```

---

## 5. 시스템 아키텍처 제약사항

### SAC-001: 기술 스택
- **UI 프레임워크**: Qt 6.2 이상, QML
- **백엔드 언어**: C++17 이상
- **데이터베이스**: SQLite 3.35 이상
- **네트워크**: Qt Network 모듈, Qt Remote Objects
- **빌드 시스템**: CMake 3.20 이상
- **애니메이션**: Qt Quick Animation, Qt Graphical Effects
- **패키징**: NSIS 3.08 이상 또는 WiX Toolset
- **플러그인**: Qt Plugin System

### SAC-002: 플랫폼 제약
- **대상 OS**: Windows 10/11 x64
- **최소 메모리**: 4GB RAM (8GB 권장)
- **최소 저장공간**: 1GB (임시 파일 포함)
- **네트워크**: 인터넷 연결 필요 (설치 및 업데이트)
- **그래픽**: DirectX 11 이상 (애니메이션 가속)
- **CPU**: 듀얼 코어 2GHz 이상

### SAC-003: 배포 제약
- **패키징**: Windows Installer (MSI) 또는 NSIS
- **포터블 버전**: 단일 폴더 구조
- **자동 업데이트**: v1.0에서는 수동 업데이트만 지원
- **다국어**: 한국어만 지원 (v1.0)
- **라이선스**: 개인 사용 목적
- **플러그인 배포**: 별도 패키지로 제공

### SAC-004: 아키텍처 제약
- **클라이언트-서버 분리**: 필수 구조
- **단일 사용자**: v1.0에서는 멀티 사용자 미지원
- **플러그인 보안**: 디지털 서명 필수
- **모듈 독립성**: 각 모듈 독립적 테스트 가능

---

## 6. 추적 매트릭스 (Traceability Matrix)

| CuRS ID | SyRS ID | 구현 모듈 | 검증 방법 |
|---------|---------|-----------|-----------|
| FR-001.1 | SFR-001.2 | BasicRules | 단위 테스트 |
| FR-001.2 | SFR-001.3 | AdvancedRules | 알고리즘 테스트 |
| FR-001.3 | SFR-001.4 | CompositeProcessor | 통합 테스트 |
| FR-002 | SFR-001 | RandomEngine | 통계 테스트 |
| FR-003 | SFR-004 | WinningChecker | 시나리오 테스트 |
| FR-004 | SFR-005 | StatisticsEngine | 성능 테스트 |
| FR-005 | SFR-003 | APIClient | 통합 테스트 |
| FR-006 | SFR-003.3 | DataManager | 데이터 테스트 |
| FR-007 | SFR-006 | TaskScheduler | 시스템 테스트 |
| FR-008 | SFR-007 | EmailService | 기능 테스트 |
| FR-009.1 | SFR-008.1 | GUIClient | 독립 실행 테스트 |
| FR-009.3 | SFR-008.2 | AnimationEngine | 성능 테스트 |
| FR-010 | SFR-002 | RuleRepository | 데이터 무결성 테스트 |
| FR-011.1 | SFR-009.1 | InstallationManager | 설치 테스트 |
| FR-011.2 | SFR-009.2 | PackageManager | 패키지 테스트 |
| FR-011.3 | SFR-009.3 | UpdateManager | 업데이트 테스트 |
| FR-012.1 | SFR-008.1 | ConnectionManager | 통신 테스트 |
| FR-012.2 | SFR-010 | PluginManager | 플러그인 테스트 |

---

## 7. 검증 및 확인 기준

### 7.1 시스템 테스트 레벨
- **단위 테스트**: 각 클래스/함수별 독립 테스트
- **통합 테스트**: 모듈 간 인터페이스 테스트
- **시스템 테스트**: 전체 시나리오 기반 테스트
- **성능 테스트**: 부하 및 스트레스 테스트
- **애니메이션 테스트**: 프레임률 및 부드러움 테스트
- **설치 테스트**: 다양한 환경에서의 설치 검증
- **플러그인 테스트**: 플러그인 호환성 및 보안 테스트

### 7.2 테스트 환경
- **개발 환경**: Windows 11, Qt 6.5
- **테스트 환경**: Windows 10, Qt 6.2 (최소 요구사항)
- **자동화**: Google Test 프레임워크, Qt Test
- **성능 측정**: Qt Quick Profiler, 커스텀 성능 모니터
- **설치 테스트**: 가상 머신 환경 (Clean Windows)

---

**검토자**: [시스템 설계자]  
**승인자**: [기술 책임자]  
**승인일**: [승인일]