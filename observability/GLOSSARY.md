# 관측 용어집

이 문서는 OpsProof 관측 스택에서 비슷해 보이는 용어를 구분하기 위한 참고 자료다. 기본 표기는 한국어 뒤에 원어를 함께 쓴다.

## 한 장의 지도

~~~text
관측 가능성(observability)
 └─ 계측(instrumentation)
     └─ telemetry 생성
         ├─ metric: 시간에 따른 수치
         ├─ log: 시각이 찍힌 기록
         └─ trace: 요청의 전체 여정
              └─ span: 여정 안의 작업 하나

SDK / 자동 계측 → exporter / OTLP → receiver / collector → backend
                                                        ├─ 저장·query
                                                        └─ dashboard·alert
~~~

**telemetry**는 시스템이 내보낸 모든 관측 데이터의 총칭이다. **metric**은 telemetry의 한 종류이며 동의어가 아니다.

## 목적과 활동

| 용어 | 의미 | 구분 |
| --- | --- | --- |
| **관측 가능성 (observability)** | 시스템 내부를 미리 전부 알지 못해도 외부 신호로 질문하고, 새 문제의 원인을 이해할 수 있는 성질이다. | Grafana나 dashboard 하나의 이름이 아니다. |
| **모니터링 (monitoring)** | 미리 정한 신호·임계값·규칙을 계속 확인해 알려진 이상을 탐지하는 운영 활동이다. | 관측 가능성과 반대말이 아니다. alert는 monitoring의 대표적 결과다. |
| **계측 (instrumentation)** | 코드·라이브러리·에이전트·설정으로 telemetry를 내보내게 만드는 일이다. | 관측 자체가 아니라 관측 데이터를 만드는 수단이다. |
| **자동 계측** | framework와 라이브러리에 hook을 걸어 코드 변경을 최소화하는 계측이다. | HTTP·DB 같은 기술 경계는 잡지만, 업무 단계까지 자동으로 이해하지는 못한다. |
| **수동 계측** | 개발자가 코드에 span, metric, log metadata를 직접 추가하는 일이다. | 자동 계측을 대신하기보다 업무 의미를 보완하는 방법이다. |
| **telemetry** | 시스템과 그 동작에서 방출된 데이터의 총칭이다. | trace·metric·log를 포함한다. |
| **OpenTelemetry** | telemetry를 생성·처리·전송하기 위한 vendor-neutral 공개 사양, API·SDK, Collector, semantic convention, OTLP 생태계다. | telemetry 자체나 저장소 제품명이 아니다. |
| **signal** | telemetry를 분류한 신호 종류다. OpenTelemetry의 주 신호는 trace·metric·log다. | event라는 단어와 혼동하지 않는다. |

OpenTelemetry는 관측 가능성을 “미지의 문제에도 시스템에 질문할 수 있는 능력”으로, 계측을 trace·metric·log 같은 signal을 내보내게 하는 작업으로 설명한다. [Observability primer](https://opentelemetry.io/docs/concepts/observability-primer/) [Signals](https://opentelemetry.io/docs/concepts/signals/)

### telemetry와 OpenTelemetry

| 구분 | telemetry | OpenTelemetry |
| --- | --- | --- |
| 정체 | 시스템에서 나온 **관측 데이터** | 그 데이터를 다루기 위한 **표준·도구 생태계** |
| 질문 | 무엇이 나왔나? | 어떻게 일관되게 만들고 전달하나? |
| 예 | Pod stdout log, Kubernetes metric, trace | Python SDK, automatic instrumentation, OTLP, Collector, semantic conventions |
| 저장소인가? | 아니다. 데이터 자체다. | 아니다. Tempo·Loki·Prometheus 같은 backend와 별개다. |

OpenTelemetry가 만든 데이터는 telemetry이지만, 모든 telemetry가 OpenTelemetry인 것은 아니다. 예를 들어 이 Lab의 Pod stdout log와 Kubernetes Event는 telemetry지만 OTLP log로 export하지 않는다. 반면 order-api trace는 OpenTelemetry 자동 계측으로 만들고 OTLP로 Alloy에 보낸다.

## telemetry의 세 신호

| 단위 | 무엇인가 | 가장 잘 답하는 질문 | OpsProof 예 |
| --- | --- | --- | --- |
| **metric** | 시간에 따라 기록·집계되는 숫자 측정값이다. | 언제부터 얼마나 자주 실패·느려졌나? | 요청 수, 오류율, 지연, Kubernetes CPU·memory |
| **sample** | metric 한 번의 관측값이다. Prometheus에서는 timestamp와 value 쌍이다. | 이 시각의 값은 무엇인가? | 한 시각의 CPU 사용량 |
| **time series** | 같은 metric 이름과 같은 label 집합으로 식별되는 sample들의 흐름이다. | 이 조건의 값이 시간에 따라 어떻게 변했나? | service와 route가 같은 요청 수 |
| **log** | 서비스나 구성요소가 남긴 시각이 찍힌 기록이다. | 어떤 메시지·오류가 남았나? | API stdout의 JSON error |
| **trace** | 한 요청 또는 workflow가 여러 구성요소를 지난 전체 인과 경로다. 하나 이상의 span으로 구성된다. | 어느 단계에서 왜 실패·지연됐나? | POST /orders의 API → PostgreSQL 경로 |
| **span** | trace 안의 작업 하나다. HTTP 처리, SQL 실행, 외부 호출 등이 된다. | 요청 여정의 어느 작업이 문제인가? | FastAPI server span, psycopg SQL span |

trace는 요청 하나의 경로이고, metric은 많은 요청을 시간 구간으로 집계한 수치다. trace는 log 묶음이 아니며 metric도 log를 숫자로 바꾼 것만은 아니다. [OpenTelemetry observability primer](https://opentelemetry.io/docs/concepts/observability-primer/) [Prometheus data model](https://prometheus.io/docs/concepts/data_model/)

### event는 반드시 수식어를 붙인다

| 표현 | 뜻 | 이 프로젝트에서의 경로 |
| --- | --- | --- |
| **Kubernetes Event** | Kubernetes API가 resource 상태 변화에 관해 남기는 resource다. | Alloy events → Loki |
| **span event** | span 실행 중 특정 시점을 나타내는 trace 데이터다. 예: retry 시작. | trace와 함께 Tempo에 저장될 수 있다. |
| **log event / log record** | 시각이 찍힌 log 항목을 넓게 부르는 말이다. | stdout → Alloy logs → Loki |
| **business event** | OrderCreated처럼 도메인에서 일어난 사실이다. | 관측 signal이 아닐 수 있으며, 별도 DB record나 event stream일 수 있다. |

“event를 수집한다”라고만 쓰지 않는다. OpenTelemetry는 event를 log의 특정 유형으로 설명하며, span event는 span의 일부다. [OpenTelemetry signals](https://opentelemetry.io/docs/concepts/signals/) [Tempo glossary](https://grafana.com/docs/tempo/latest/introduction/glossary/)

event도 telemetry가 될 수 있다. 단, event라는 말만으로는 어느 signal인지 정해지지 않는다. Kubernetes Event는 이 stack에서 log 형태로 Loki에 저장되고, span event는 trace의 일부로 Tempo에 저장된다. business event는 주문·결제 같은 도메인 사실의 원본 data일 수 있다. log나 span event로 내보냈을 때에만 그 사본이 telemetry가 된다.

## trace를 잇는 단위

| 용어 | 의미 | 구분 |
| --- | --- | --- |
| **root span** | trace의 시작 작업이며 parent가 없다. | 대개 들어온 HTTP 요청이나 소비한 메시지다. |
| **parent / child span** | 상위 작업과 그 안에서 한 하위 작업의 관계다. | child도 다시 다른 child의 parent가 될 수 있다. |
| **trace ID** | 같은 trace의 span을 묶는 식별자다. | 사용자 ID나 요청 본문이 아니다. |
| **span ID** | trace 안에서 span 하나를 식별한다. | trace ID와 역할이 다르다. |
| **span context** | trace ID, span ID, trace flags처럼 다음 작업으로 전파할 trace 식별 정보다. | span의 전체 데이터가 전파되는 것은 아니다. |
| **context propagation** | HTTP header나 message metadata에 context를 넣고 다음 서비스가 꺼내 같은 요청의 관계를 잇는 과정이다. | OTLP로 telemetry를 보내는 것과 다르다. |
| **span link** | parent-child tree가 아닌 인과 관계를 연결한다. | batch가 여러 메시지를 처리한 관계 등에 맞는다. |
| **baggage** | 요청과 함께 전파할 임의 key-value 문맥이다. | span attribute와 별도 저장소다. attribute로 쓰려면 명시적으로 복사해야 하며 비밀값을 넣으면 안 된다. |

Context propagation이 끊기면 서비스별 span은 있어도 하나의 요청 trace로 이어지지 않는다. Baggage는 자동 전파될 수 있으므로 downstream이나 제3자에게 보일 수 있는 민감정보를 담지 않는다. [OpenTelemetry specification overview](https://opentelemetry.io/docs/specs/otel/overview/) [Baggage](https://opentelemetry.io/docs/concepts/signals/baggage/)

## metadata와 cardinality

| 용어 | 붙는 대상 | 예 | 주의점 |
| --- | --- | --- | --- |
| **attribute** | span·metric·log record 같은 OpenTelemetry 항목 | http.request.method=POST | 관측 데이터에 붙인 일반 metadata다. |
| **resource attribute** | telemetry를 낸 엔터티 | service.name, cluster, namespace, Pod | 요청마다 바뀌는 값보다 발생 주체를 설명하는 값에 맞는다. |
| **semantic convention** | attribute 이름과 의미의 표준 약속 | service.name, http.response.status_code | 서로 다른 언어·도구가 같은 의미의 key를 쓰게 한다. |
| **label** | Prometheus time series나 Loki log stream을 식별·색인하는 key-value | service_name, namespace, cluster | 고유값 조합이 너무 많으면 비용과 query 성능 문제가 생긴다. |
| **cardinality** | 한 차원 또는 label 조합이 갖는 고유값의 수다. | service는 낮고 trace ID는 매우 높다. | 값이 거의 매번 바뀌는 key를 label로 만들지 않는다. |
| **exemplar** | 집계된 metric 관측값 하나를 대표하는 상세 예시다. trace ID를 담아 metric에서 trace로 갈 수 있다. | latency histogram의 한 관측값 → trace | metric label이 아니므로 series 수를 늘리지 않는다. |

**attribute**는 OpenTelemetry의 일반 metadata이고 **label**은 Prometheus·Loki가 series·stream을 식별하는 색인 key다. order ID, trace ID, 사용자 ID처럼 값이 거의 매번 다른 것은 label로 넣지 않는다. Loki는 이런 값을 structured metadata 또는 query-time parsing에 두라고 권장한다. [OpenTelemetry resources](https://opentelemetry.io/docs/concepts/resources/) [Prometheus data model](https://prometheus.io/docs/concepts/data_model/) [Loki labels](https://grafana.com/docs/loki/latest/get-started/labels/)

## 생성, 수집, 저장

| 용어 | 하는 일 | OpsProof 예 |
| --- | --- | --- |
| **SDK** | 앱 코드가 telemetry를 만들고 처리·내보내게 하는 언어별 구현이다. | Python OpenTelemetry SDK |
| **instrumentation library** | 특정 framework·DB client에 계측을 붙이는 라이브러리다. | FastAPI, psycopg instrumentation |
| **exporter** | process 밖 endpoint로 telemetry를 직렬화해 보내는 출력 구성요소다. | 앱의 OTLP gRPC exporter |
| **OTLP** | OpenTelemetry telemetry를 전송하는 protocol이다. | app → Alloy app의 gRPC 4317 |
| **receiver** | 들어오는 telemetry를 받는 입력 구성요소다. | Alloy app의 OTLP receiver |
| **collector** | receiver·processor·exporter를 조합해 telemetry를 수집·가공·전달하는 독립 process다. | Alloy collector |
| **processor** | batch, filter, transform, sample, metric 생성 같은 중간 처리 단계다. | Tempo metrics-generator |
| **backend / storage** | telemetry를 보관하고 query에 답하는 목적지다. | Prometheus, Loki, Tempo |
| **ingestion** | backend가 telemetry를 받아 검사·색인·저장을 시작하는 과정이다. | Loki push, Tempo trace ingest |
| **retention** | backend가 데이터를 보관하는 기간이다. | Prometheus·Loki 7일, Tempo 3일 |

**Alloy는 collector 구현체**이고, collector는 보통 backend가 아니다. 반대로 Prometheus·Loki·Tempo는 이 Lab에서 각 signal을 저장·조회하는 backend다. [OpenTelemetry specification overview](https://opentelemetry.io/docs/specs/otel/overview/) [Grafana Alloy collector reference](https://grafana.com/docs/grafana-cloud/observe-and-act/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/collector-reference/)

### scrape, pull, push, remote write

| 용어 | 방향 | 뜻 |
| --- | --- | --- |
| **scrape / pull** | Prometheus → metric target | Prometheus가 HTTP endpoint에 가서 metric을 읽는다. |
| **export / push** | app 또는 collector → receiver/backend | sender가 telemetry를 목적지로 보낸다. OTLP가 대표적이다. |
| **remote write** | metric producer → Prometheus-compatible receiver | 이미 만들어진 metric series를 Prometheus 호환 endpoint로 보낸다. |

Prometheus의 기본 수집 모델은 HTTP pull이다. 하지만 이 Lab에서는 Tempo metrics-generator가 trace에서 만든 metric을 Prometheus remote-write receiver로 push한다. 이때 Prometheus는 전달자가 아니라 metric을 저장하고 PromQL로 query하는 목적지다. [Prometheus overview](https://prometheus.io/docs/introduction/overview/) [Tempo metrics-generator](https://grafana.com/docs/tempo/latest/metrics-from-traces/metrics-generator/)

## 읽기와 판정

| 용어 | 의미 | 구분 |
| --- | --- | --- |
| **query** | backend에 저장된 데이터에서 조건·집계·시간 범위를 지정해 읽는 요청이다. | PromQL, LogQL, TraceQL은 서로 다르다. |
| **data source** | Grafana가 query할 backend 연결이다. | Grafana 자체가 signal 저장소라는 뜻이 아니다. |
| **dashboard** | query 결과를 panel로 묶어 반복해 보는 화면이다. | 원인 분석의 유일한 방법도, signal 자체도 아니다. |
| **alert** | query 또는 rule이 조건을 만족할 때 알림·사건 처리를 시작하는 자동화다. | 단일 metric이나 dashboard의 빨간 선은 alert가 아니다. |
| **SLI** | 사용자가 체감하는 서비스 동작을 나타내는 측정값이다. | metric은 SLI 계산의 입력일 수 있지만 SLI와 항상 같지 않다. |
| **SLO** | 하나 이상의 SLI에 기간과 목표를 붙인 서비스 신뢰성 목표다. | alert threshold, readiness probe와 동의어가 아니다. |
| **synthetic check** | 의도적으로 만든 요청으로 사용자 흐름을 검증하는 check다. | 이 Lab에서는 telemetry를 만들기도 하지만 Deployment Gate의 직접 판정 근거이기도 하다. |

Grafana는 Loki·Tempo·Prometheus를 data source로 query해 화면을 만든다. 각 backend를 대신해 signal을 저장하지는 않는다. [Grafana dashboards](https://grafana.com/docs/grafana/latest/visualizations/dashboards/) [Grafana trace-to-logs correlation](https://grafana.com/docs/grafana/latest/datasources/tempo/configure-tempo-data-source/configure-trace-to-logs/)

## 이 프로젝트의 실제 경로

~~~text
앱 자동 계측 → OTLP exporter → Alloy app receiver/collector → Tempo backend
Pod stdout/stderr ─────────────────────→ Alloy logs collector → Loki backend
Kubernetes Event ──────────────────────→ Alloy events collector → Loki backend
Prometheus scrape target ──────────────→ Prometheus backend
Tempo metrics-generator → Prometheus remote-write receiver → Prometheus backend
Grafana → 위 세 backend를 query
Synthetic Check Job → Deployment Contract의 PASS / FAIL 판정
~~~

현재 Schema Compatibility Lab은 앱에서 **trace만** OTLP로 보낸다. 앱 log는 stdout → Alloy → Loki로 가며, Prometheus metric은 Kubernetes scrape와 Tempo metrics-generator의 remote write 경로로 온다. 따라서 Grafana 데이터가 비어 있거나 보인다는 사실만으로 Deployment Contract의 통과·실패를 정하지 않는다.

## 글을 쓸 때의 최소 규칙

1. “관측”만 쓰지 말고 **관측 가능성**, **모니터링 활동**, **계측** 중 무엇인지 쓴다.
2. event에는 Kubernetes, span, business 중 소속을 붙인다.
3. 새 metadata는 attribute, resource attribute, backend label 중 무엇인지 구분한다.
4. trace ID, order ID, 사용자 ID를 Loki·Prometheus label로 추가하기 전 cardinality 비용을 검토한다.
5. “Grafana가 수집한다”가 아니라 “Grafana가 backend를 query한다”라고 쓴다.
6. 이 Lab의 PASS/FAIL은 Grafana가 아니라 Synthetic Check Job이 판정한다고 쓴다.

## 1차 자료

- [OpenTelemetry Observability primer](https://opentelemetry.io/docs/concepts/observability-primer/)
- [OpenTelemetry signals](https://opentelemetry.io/docs/concepts/signals/)
- [OpenTelemetry specification overview](https://opentelemetry.io/docs/specs/otel/overview/)
- [OpenTelemetry Baggage](https://opentelemetry.io/docs/concepts/signals/baggage/)
- [Prometheus overview](https://prometheus.io/docs/introduction/overview/)
- [Prometheus data model](https://prometheus.io/docs/concepts/data_model/)
- [Grafana Tempo glossary](https://grafana.com/docs/tempo/latest/introduction/glossary/)
- [Grafana Loki labels](https://grafana.com/docs/loki/latest/get-started/labels/)
- [Tempo metrics-generator](https://grafana.com/docs/tempo/latest/metrics-from-traces/metrics-generator/)
