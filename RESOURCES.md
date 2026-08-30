# OpsProof kind·관측 참고 자료

## Knowledge

- [kind: Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
  kind 공식 사용 안내다. 클러스터 생성·목록·삭제, kubeconfig context, 로컬 이미지 적재, 로그 내보내기를 확인할 때 참고한다.
- [Kubernetes: Cluster Access](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
  kubectl context 공식 안내다. `--context kind-opsproof`가 어떤 클러스터를 선택하는지 확인할 때 참고한다.
- [Kubernetes: Images](https://kubernetes.io/docs/concepts/containers/images/)
  이미지 이름·태그·pull policy를 설명한다. kind에 넣은 이미지와 Pod 이미지의 동작 차이를 확인할 때 참고한다.
- [GNU Make Manual](https://www.gnu.org/software/make/manual/make.html)
  Makefile과 target의 공식 정의다. `make`가 project 명령을 실행하는 방식을 확인할 때 참고한다.
- [Docker: What is a container?](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/)
  Docker image와 container의 기초다. kind node와 API image의 관계를 이해할 때 참고한다.
- [Kubernetes: kubectl](https://kubernetes.io/docs/reference/kubectl/)
  Kubernetes API CLI 공식 reference다. resource 관찰·적용·로그 조회에 참고한다.
- [Prometheus: Overview](https://prometheus.io/docs/introduction/overview/)
  Prometheus가 label이 붙은 시계열 metric을 저장·조회하는 방식을 설명한다. Kubernetes metric과 Tempo가 만든 trace 기반 metric을 구분할 때 쓴다.
- [Grafana Loki: Send log data](https://grafana.com/docs/loki/latest/send-data/)
  Loki에 log를 보내는 방법과 OpenTelemetry Collector 배포판인 Grafana Alloy의 역할을 설명한다. Pod stdout과 Kubernetes event 수집 경로를 확인할 때 쓴다.
- [OpenTelemetry: Python zero-code instrumentation](https://opentelemetry.io/docs/zero-code/python/)
  Python agent와 OTLP exporter 설정을 설명한다. 이 프로젝트의 `opentelemetry-instrument` wrapper와 `OTEL_*` 환경 변수를 이해할 때 참고한다.
- [Grafana Tempo: Metrics-generator](https://grafana.com/docs/tempo/latest/metrics-from-traces/metrics-generator/)
  Tempo가 받은 trace에서 span metric·service graph를 만들고 Prometheus 호환 backend로 remote-write하는 방식을 설명한다. `traces_spanmetrics_calls_total`의 출처를 확인할 때 쓴다.
- [Grafana: Kubernetes Monitoring Helm chart overview](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/)
  `k8s-monitoring` chart가 설정에 따라 여러 Alloy collector를 만드는 이유를 설명한다. Helm release 하나와 실제 Pod 수가 같지 않음을 확인할 때 쓴다.
- [Grafana: Alloy collector reference](https://grafana.com/docs/grafana-cloud/observe-and-act/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/collector-reference/)
  Collector는 Alloy Operator가 Deployment·DaemonSet·StatefulSet으로 만드는 workload라는 공식 설명이다. 이 프로젝트의 `app`·`logs`·`events` collector 책임을 구분할 때 쓴다.
- [OpenTelemetry: Signals](https://opentelemetry.io/docs/concepts/signals/)
  Trace·metric·log가 각각 무엇을 기록하는지의 표준 용어다. 한 요청을 세 신호로 나누어 설명할 때 쓴다.

## Wisdom (Communities)

- [Kubernetes Slack — #kind](https://kubernetes.slack.com/)
  kind 설치나 runtime 문제를 질문할 수 있는 공식 커뮤니티 채널이다. 가입이 필요하다.

## 추가 확인 자료

- 현재 목표에 필요한 공식 자료는 충분하다. Docker Desktop 자원 문제가 생기면 kind Quick Start의 Docker Desktop 항목부터 확인한다.
