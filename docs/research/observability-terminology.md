# Observability 용어 조사

조사일: 2026-08-23
범위: OpenTelemetry, Prometheus, Grafana의 공식 문서·사양만 사용

## 먼저 잡을 경계

관측성(Observability)은 시스템 내부 구현을 미리 모두 알지 못해도 외부 데이터를 바탕으로 질문하고, 새롭거나 예상하지 못한 문제의 원인을 파악할 수 있는 성질이다. 모니터링(Monitoring)은 미리 정한 신호·조건을 계속 측정해 상태 변화를 찾는 운영 활동이다. 모니터링은 관측성을 쓰는 한 방법이지만, 관측성 전체와 동의어는 아니다. OpenTelemetry는 관측성을 위해 코드가 trace·metric·log 같은 signal을 내보내도록 계측해야 한다고 설명한다. [OpenTelemetry observability primer](https://opentelemetry.io/docs/concepts/observability-primer/)

```text
계측(instrumentation) → telemetry / signal 생성 → 수집·처리·전송 → backend 저장·조회
                                                                    ↘ dashboard / alert
```

이 흐름에서는 이름이 비슷한 역할을 섞지 않는다. Alloy Collector는 받아서 처리·전달하는 중간 노드다. Prometheus는 metric을 저장하고 PromQL로 조회하는 backend다. Grafana dashboard는 저장소가 아니라 여러 datasource의 결과를 표시하는 화면이다.

## 신호와 데이터 단위

| 용어 | 짧은 정의 | 흔한 혼동·판별법 |
| --- | --- | --- |
| 관측성 (observability) | 외부 출력으로 시스템에 질문해 내부 동작과 새 문제의 원인을 이해할 수 있는 성질. | 도구 이름이나 dashboard 하나가 아니다. signal, 상관관계, 저장·조회 경로가 함께 있어야 한다. [OTel primer](https://opentelemetry.io/docs/concepts/observability-primer/) |
| 모니터링 (monitoring) | 미리 정한 측정값·규칙을 계속 관찰해 알려진 이상을 탐지하는 운영 활동. | 관측성과 대립하지 않는다. “CPU 90% 초과” alert는 monitoring, “왜 특정 주문만 실패했나?”의 탐색은 observability가 더 잘 드러나는 질문이다. 이 대조는 OTel의 unknown-unknowns 설명에서 도출한 실무적 구분이다. [OTel primer](https://opentelemetry.io/docs/concepts/observability-primer/) |
| **텔레메트리 (telemetry)** | 시스템과 그 동작에서 방출된 데이터의 총칭. | signal과 일상적으로 섞어 말하지만, OTel에서 signal은 수집·처리·export 대상인 telemetry의 **종류**다. [OTel primer](https://opentelemetry.io/docs/concepts/observability-primer/), [OTel signals](https://opentelemetry.io/docs/concepts/signals/) |
| **신호 (signal)** | OS·애플리케이션의 기저 활동을 설명하는 시스템 출력. OTel의 안정된 주 신호는 traces, metrics, logs다. | `event`는 독립된 네 번째 pillar라고 단정하지 않는다. OTel 문서는 event를 log의 특정 유형으로 설명하며, event signal은 아직 개발/제안 단계로 표시한다. [OTel signals](https://opentelemetry.io/docs/concepts/signals/) |
| **계측 (instrumentation)** | 시스템 구성요소의 코드가 signal을 방출하게 만드는 일. API/SDK를 코드에 넣는 방식과 자동·zero-code 방식이 있다. | Collector를 설치하는 것만으로 앱 내부 업무 단계가 계측되지는 않는다. 자동 계측은 주로 라이브러리·환경 경계를, 수동 계측은 업무 의미를 보강한다. [OTel instrumentation](https://opentelemetry.io/docs/concepts/instrumentation/) |
| **trace** | 하나의 요청 또는 workflow가 여러 서비스·구성요소를 통과한 경로의 기록. 하나 이상의 span으로 이뤄진다. | trace는 “요청 하나의 이야기”이고 metric은 많은 요청을 시간 구간에 걸쳐 집계한 수치다. [OTel primer](https://opentelemetry.io/docs/concepts/observability-primer/) |
| **span** | trace 안의 단일 작업/연산 단위. 이름, 시작·종료 시각, 속성, parent 등의 정보를 가진다. | span 하나가 trace 하나가 아니다. HTTP server 처리나 DB query 같은 단계가 각각 span이 되고, 이들이 parent-child 관계로 trace를 이룬다. [OTel overview spec](https://opentelemetry.io/docs/specs/otel/overview/), [OTel primer](https://opentelemetry.io/docs/concepts/observability-primer/) |
| **metric** | 실행 중 포착한 수치 측정값. Prometheus에서는 같은 metric 이름·label 집합에 속한 timestamped value stream을 time series로 저장한다. | metric은 단일 sample과 동의어가 아니다. Prometheus의 sample은 `(timestamp, value)`이고, series는 label 집합으로 식별되는 sample들의 흐름이다. [OTel signals](https://opentelemetry.io/docs/concepts/signals/), [Prometheus data model](https://prometheus.io/docs/concepts/data_model/) |
| **log** | 서비스나 구성요소가 낸 timestamped message, 또는 OTel 관점에서는 event의 기록. | log는 특정 사용자 요청에 자동으로 속하지 않는다. `trace_id`/`span_id`나 같은 resource/time을 넣어야 trace와 강하게 연결된다. [OTel primer](https://opentelemetry.io/docs/concepts/observability-primer/), [OTel logs spec](https://opentelemetry.io/docs/specs/otel/logs/) |
| **event** | 시간에 발생한 일을 나타내는 기록. OTel signal 문맥에서는 특정 log 유형이다. span 안의 **span event**는 `(timestamp, name, attributes)`이고 span의 일부다. | Kubernetes Event, 애플리케이션 log event, span event는 모두 “사건”이지만 같은 데이터 모델·수명주기를 보장하지 않는다. 이름 앞에 소속을 붙인다. [OTel signals](https://opentelemetry.io/docs/concepts/signals/), [OTel overview spec](https://opentelemetry.io/docs/specs/otel/overview/) |
| **context propagation** | 논리적으로 연결된 실행 단위와 프로세스 경계를 넘어 실행 범위 값을 전달하는 메커니즘. | telemetry 자체를 보내는 OTLP 전송이 아니다. HTTP header 등의 carrier에 trace context/baggage를 inject하고 다음 서비스가 extract하여 같은 요청의 parent-child 관계를 잇는다. [OTel context spec](https://opentelemetry.io/docs/specs/otel/context/), [OTel propagators](https://opentelemetry.io/docs/specs/otel/context/api-propagators/) |
| **trace context / SpanContext** | span을 trace 안에서 식별하고 child·프로세스 경계로 전파해야 하는 식별자와 옵션. | `Context`는 여러 cross-cutting 값을 담는 실행 범위 컨테이너이고, `SpanContext`는 그 안의 trace 식별 부분이다. [OTel overview spec](https://opentelemetry.io/docs/specs/otel/overview/), [OTel context spec](https://opentelemetry.io/docs/specs/otel/context/) |
| **baggage** | 요청/workflow와 문맥적으로 연결된, 애플리케이션 정의 name/value의 전파용 저장소. downstream telemetry에 추가 문맥을 붙일 수 있다. | span attribute가 아니다. baggage는 별도 key-value store이며, attribute로 쓰려면 명시적으로 읽어 추가해야 한다. 자동 전파될 수 있으므로 PII·비밀값을 넣지 않는다. [OTel baggage](https://opentelemetry.io/docs/concepts/signals/baggage/) |
| **exemplar** | metric의 특정 관측값에 붙인 대표 표본·식별 metadata. Grafana/Prometheus 조합에서는 그래프의 한 점에서 `traceID`를 통해 trace로 drill-down하는 연결로 쓰인다. | exemplar는 metric label이 아니다. 모든 series 조합을 늘리지 않고, 선택된 측정값에서 고카디널리티 trace ID를 연결하는 용도다. [Grafana exemplars](https://grafana.com/docs/grafana/latest/basics/exemplars/) |

## 식별자와 차원: label, attribute, resource, cardinality

| 용어 | 짧은 정의 | 적용 범위와 주의 |
| --- | --- | --- |
| **label** | Prometheus metric의 key-value 차원. metric 이름과 label 집합이 time series를 유일하게 식별한다. | label 값이 달라지거나 label을 더하거나 빼면 새 series다. `method`, `route`, `status`처럼 제한된 값에 적합하다. [Prometheus data model](https://prometheus.io/docs/concepts/data_model/) |
| **attribute** | OTel span, metric, log, event, resource에 붙일 수 있는 구조화된 key-value metadata의 일반 이름. | OTel attribute와 Prometheus label은 둘 다 차원을 표현하지만 데이터 모델과 적용 위치가 다르다. OTel metric을 Prometheus backend로 변환할 때 attribute가 label로 나타날 수 있어도 두 규격의 일반 동의어는 아니다. [OTel semantic conventions](https://opentelemetry.io/docs/specs/semconv/), [OTel attribute requirements](https://opentelemetry.io/docs/specs/semconv/general/attribute-requirement-level/) |
| **resource** | telemetry를 낸 관측 대상 entity를 나타내는 정보와 그 resource attributes. 예: service, Kubernetes cluster/namespace/pod/container. | `span attribute`는 그 한 작업의 세부사항이고, `resource attribute`는 provider 초기화 후 그 provider가 만든 모든 signal의 출처를 설명한다. `service.name`은 resource attribute다. [OTel resources](https://opentelemetry.io/docs/concepts/resources/) |
| **cardinality (카디널리티)** | 하나의 차원에 가능한 서로 다른 값, 또는 label 조합으로 생기는 series 수의 규모. | Prometheus에서 각 고유 label 조합은 새 series다. user ID·email·request ID처럼 무한히 늘어나는 값을 metric label로 넣으면 저장·query 비용이 급증한다. 그런 식별은 trace/log 또는 exemplar 쪽이 적합하다. [Prometheus naming practices](https://prometheus.io/docs/practices/naming/) |
| **semantic conventions** | OTel이 정한 공통 이름·자료형·의미·허용값 규약. | `http.request.method`, `service.name`, `k8s.namespace.name`처럼 같은 개념을 같은 키로 기록하게 해 backend에서 상관·집계를 가능하게 한다. 임의 키를 만들기 전 확인한다. [OTel semantic conventions](https://opentelemetry.io/docs/specs/semconv/) |

## 수집·전송·저장 경로

| 용어 | 짧은 정의 | 흔한 혼동·판별법 |
| --- | --- | --- |
| **scrape / pull** | Prometheus가 주기적으로 target의 HTTP metrics endpoint에 가서 데이터를 읽는 방식. | 누가 연결을 시작하는지 본다. Prometheus/agent가 target을 호출하면 pull이다. Prometheus text exposition은 HTTP로 전송된다. [Prometheus exposition formats](https://prometheus.io/docs/instrumenting/exposition_formats/) |
| **export / push** | 생산자 또는 중간 노드가 telemetry를 목적지로 보내는 동작. OTLP exporter나 Prometheus remote-write sender가 예다. | push가 항상 나쁜 것은 아니다. Prometheus remote write는 일반적으로 scrape한 sender가 receiver로 samples를 보낼 용도이며, 앱이 receiver로 직접 push하는 용도는 아니라고 명시한다. [Prometheus remote write spec](https://prometheus.io/docs/specs/prw/remote_write_spec/) |
| **receiver** | 들어오는 telemetry를 받는 입력 경계/컴포넌트. | 제품 중립 단어가 아니다. OTLP에서는 Collector의 받는 쪽과 backend가 모두 server일 수 있고, Alloy에서는 `otelcol.receiver.*`가 application telemetry를 받는다. [OTLP spec](https://opentelemetry.io/docs/specs/otlp/), [Alloy component guide](https://grafana.com/docs/alloy/latest/collect/choose-component/) |
| **exporter** | telemetry를 외부 목적지로 보내는 출력 컴포넌트. | Prometheus **exporter**는 관례상 Prometheus가 scrape할 metrics endpoint를 노출하는 프로그램을 뜻하기도 한다. OTel의 exporter(목적지로 전송)와 이름은 같아도 흐름이 반대일 수 있다. 문서·설정의 문맥을 확인한다. [OTLP exporter spec](https://opentelemetry.io/docs/specs/otel/protocol/exporter/), [Alloy component guide](https://grafana.com/docs/alloy/latest/collect/choose-component/) |
| **collector** | 여러 source에서 telemetry를 받아 처리(변환·필터·집계·sampling 등)하고 하나 이상 backend로 내보내는 중간 서비스/배포 단위. | collector는 원칙적으로 저장소가 아니다. OTel Collector는 agent(앱 가까이) 또는 standalone service로 동작할 수 있다. [OTel overview spec](https://opentelemetry.io/docs/specs/otel/overview/) |
| **storage / backend** | 수집된 signal을 보존하고 그 signal의 query를 제공하는 목적지 시스템. | 이 Lab에서 Tempo=trace backend, Loki=log/event backend, Prometheus=metric backend다. Alloy는 보통 backend가 아니라 collector다. OTLP에서 collector는 들어오는 쪽에는 server, 나가는 쪽에는 client가 될 수 있다. [OTLP spec](https://opentelemetry.io/docs/specs/otlp/) |
| **OTLP** | OpenTelemetry Protocol. telemetry source, collector 같은 중간 노드, backend 사이에서 telemetry를 부호화·전송·전달하는 일반 목적 protocol. gRPC와 HTTP transport를 규정한다. | OTLP는 signal도, 저장소도, collector 제품명도 아니다. 기본 port는 gRPC `4317`, HTTP `4318`이다. [OTLP spec](https://opentelemetry.io/docs/specs/otlp/) |

### 이 Lab의 실제 경로

```text
앱 자동 계측 → OTLP exporter → Alloy app receiver/collector → Tempo backend
Pod stdout/stderr ─────────────────────→ Alloy logs collector → Loki backend
Kubernetes Event ──────────────────────→ Alloy events collector → Loki backend
Prometheus scrape target ──────────────→ Prometheus backend
Tempo metrics-generator → Prometheus remote-write receiver → Prometheus backend
```

따라서 `Alloy → Tempo → metrics-generator → Prometheus`에서 Alloy와 metrics-generator는 각각 전달/변환·전송 역할을 하지만, Prometheus는 받은 metric을 자신의 time-series storage에 저장하고 PromQL로 조회한다. Prometheus remote write의 sender/receiver 정의와 해당 Lab의 구현 경계는 [Prometheus remote write spec](https://prometheus.io/docs/specs/prw/remote_write_spec/) 및 [관측 스택 구현 구조](../observability-implementation.md)를 함께 본다.

## 읽기·표시·판정

| 용어 | 짧은 정의 | 흔한 혼동·판별법 |
| --- | --- | --- |
| **query** | backend에 저장된 데이터에서 조건에 맞는 결과를 선택·집계·변환해 읽는 표현/요청. | Prometheus의 query 언어는 PromQL이며 instant query와 range query가 있다. query는 데이터를 생성하거나 전송하지 않는다. [PromQL basics](https://prometheus.io/docs/prometheus/latest/querying/basics/) |
| **dashboard** | 하나 이상의 panel을 배열해 datasource를 query·변환·시각화한 화면. | Grafana는 여러 저장소의 결과를 통합해 보일 수 있지만 dashboard 자체가 telemetry를 저장·수집하지는 않는다. [Grafana dashboards](https://grafana.com/docs/grafana/latest/visualizations/dashboards/) |
| **alert** | 정해진 조건이 breach됐음을 알리는 판정 결과/통지. alert rule은 query·expression, firing condition, evaluation period 등을 가진다. | dashboard의 빨간 선이나 단일 metric은 alert가 아니다. 규칙이 주기적으로 평가되어 조건을 만족할 때 alert instance가 생긴다. [Grafana alert rules](https://grafana.com/docs/grafana/latest/alerting/alerting-rules/), [queries and conditions](https://grafana.com/docs/grafana/latest/alerting/fundamentals/alert-rules/queries-conditions/) |
| **SLI (Service Level Indicator)** | 서비스 동작을 나타내는 사용자 관점의 측정값. 예: 주문 생성 성공 비율, page load speed. | metric 자체와 같지 않다. metric은 SLI를 계산하는 입력이 될 수 있지만, SLI는 사용자에게 한 약속을 측정하도록 의미를 정한다. [OTel primer](https://opentelemetry.io/docs/concepts/observability-primer/) |
| **SLO (Service Level Objective)** | 하나 이상의 SLI에 목표·기간을 붙여 조직/팀에 신뢰성 기대치를 전달하는 목표. | threshold alert와 같지 않다. 예를 들어 “30일간 주문 생성 성공률 99.9%”가 SLO이고, 그 목표 소진 속도를 알리는 alert는 별도 규칙이다. Grafana도 SLO를 목표·error budget을 추적하는 방식으로 설명한다. [OTel primer](https://opentelemetry.io/docs/concepts/observability-primer/), [Grafana SLO guide](https://grafana.com/docs/learning-paths/create-availability-slo/) |

## 이 저장소에서 반드시 구분할 것

이 Lab의 MVP Deployment Contract / Deployment Gate는 “RollingUpdate 동안 synthetic order creation이 성공하고 PostgreSQL에 저장돼야 한다”는 통제된 실험의 pass/fail 기준이다. production에서 기간과 목표치를 둔 서비스 수준 SLO와는 다르다. Synthetic Check Job이 이 계약을 직접 판정하고, Grafana dashboard는 evidence를 조회한다. alert는 별도 규칙이 있어야 발생한다. 용어 범위는 [관측 스택 구현 구조](../observability-implementation.md)와 로컬 Lab 정의를 따른다.

## 기억용 최소 문장

1. **계측**이 telemetry를 만들고, telemetry의 종류가 **signal**이다.
2. **trace**는 요청 전체, **span**은 그 안의 한 작업, **metric**은 수치의 시간 흐름, **log/event**는 발생 기록이다.
3. **context propagation**은 요청의 식별을 잇고, **baggage**는 그 옆에 전파하는 추가 문맥이다.
4. **Alloy/Collector**는 전달·처리 경로, **Tempo·Loki·Prometheus**는 각 signal의 backend, **Grafana**는 조회·표시 층이다.
5. **SLI**는 사용자 관점의 측정, **SLO**는 그 측정에 기간·목표를 붙인 약속이다.
