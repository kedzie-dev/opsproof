# Deployment Safety 용어 조사

조사일: 2026-08-16
범위: 1차 자료(공식 Kubernetes·Google SRE/Cloud·Microsoft 문서)만 사용

## 결론

`운영 계약(operational contract)`은 DevOps/SRE에서 널리 정립된 표준 용어로 확인되지 않았다. 이 저장소의 로컬 용어로 정의해 쓸 수는 있다. 다만 Goal의 중심 문구로 쓰면 독자가 보편적인 SRE 용어로 오해할 수 있다.

Goal에는 사용자 관점의 핵심 사용자 흐름 또는 평이한 서비스의 정상 동작을 쓴다. `비즈니스 로직`은 Goal보다 구·신 revision이 같은 데이터에 동시에 접근할 때 생기는 schema 호환성 문제를 설명하는 문장에 쓴다.

권장 Goal 문구:

> Order API를 배포하는 중에도 주문 생성과 PostgreSQL 저장이 계속 성공하는지, 배포 중 서비스의 정상 동작을 보장하는 방법을 알아본다.

## 용어별 판단

| 표현 | 판단 | 이 Lab에서의 적절한 위치 |
| --- | --- | --- |
| 운영 계약 | 프로젝트 내부 용어로는 가능하지만 표준 용어로는 비권장 | 측정값·통과/실패 판정을 따로 정의하는 문서. 첫 사용 때 정의 필요 |
| 비즈니스 로직 | 적합하지만 사용자 성공 기준 자체를 뜻하지는 않음 | `구·신 버전의 비즈니스 로직이 같은 DB schema에 병렬로 접근한다`처럼 원인 설명 |
| 핵심 사용자 흐름 | SRE 문맥에 가장 적합 | Goal, synthetic check가 검증하는 대상 설명 |
| 서비스 정상 동작 | 가장 이해하기 쉬운 일반 표현 | Goal의 결과/학습 목적 |
| 배포 성공 기준 | 필요하면 사용 가능하지만 rollout 성공과 구분해야 함 | `rollout 성공`이 아닌 `실제 기능 검증`의 판정 기준 설명 |

## 근거

1. Google Cloud는 critical user journey (CUJ)를 사용자가 어떤 결과를 얻기 위해 서비스와 상호작용하는 과정으로 정의하고, 전자상거래 checkout을 예로 든다. 주문 생성·저장은 이 Lab에서 핵심 사용자 흐름으로 부르기에 적합하다. [Google Cloud: Learn how to set SLOs](https://cloud.google.com/blog/products/management-tools/practical-guide-to-setting-slos)

2. Google Cloud의 SLI 문서는 사용자에게 한 약속을 지켰는지로 SLI를 만들 수 있으며, HTTP 200 응답과 VM 생성 workflow의 성공을 예로 든다. 또한 인위적 요청을 보내는 black-box monitoring을 SLI 구현 방식으로 제시한다. 따라서 synthetic order creation은 `주문 생성 흐름의 성공`을 검증한다고 쓰는 편이 정확하다. [Google Cloud: SLI overview](https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/sli-metrics/overview)

3. Google SRE는 무중단 데이터 진화에서 서로 다른 버전의 business logic이 데이터에 병렬로 동작할 수 있다고 설명한다. 따라서 `비즈니스 로직`은 호환성 전환의 기술적 원인을 설명할 때 적합하다. 다만 사용자 요청의 성공·영속성을 뜻하지는 않는다. [Google SRE Book: Data Integrity](https://sre.google/sre-book/data-integrity/)

4. Kubernetes에서 Deployment의 완료/진행 상태는 ReplicaSet과 Pod 가용성에 관한 controller 상태다. readiness probe 역시 Pod가 트래픽을 받을 준비가 됐는지를 결정한다. 둘은 주문 생성 및 PostgreSQL 영속 성공을 보장하는 의미가 아니다. [Kubernetes: Deployment concepts](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#complete-deployment), [Kubernetes: Probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)

5. Microsoft Cloud Adoption Framework는 배포 후 critical user journey를 실제로 검증하라고 권고하고, 그 대상에 transaction과 data workflow를 포함한다. 이는 주문 생성과 저장을 `핵심 사용자 흐름`으로 확인하는 Lab의 방향과 맞는다. [Microsoft: Validate deployment success](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/cloud-native/deploy-cloud-native-solutions#validate-deployment-success)

## 문장 적용 원칙

- Goal: `주문 생성과 PostgreSQL 저장`, `핵심 사용자 흐름`, `서비스 정상 동작`처럼 사용자가 얻는 결과를 쓴다.
- 원인 설명: `구·신 버전의 비즈니스 로직이 같은 DB schema를 함께 사용한다`를 쓴다.
- 판정 설명: `실제 기능 검증의 성공 기준` 또는 `Deployment Gate의 판정 기준`을 쓴다. `rollout 성공`과 같은 뜻으로 쓰지 않는다.
- 운영 계약: 계속 사용한다면 이 저장소의 정의된 용어임을 명시한다. 일반적인 업계 표준 용어처럼 단독 사용하지 않는다.

## Goal 문장 교정 기록

| Original | Verdict | Replacement | Reason and source |
| --- | --- | --- | --- |
| `기능 장애를 감지해 호환 가능한 전환 또는 복구 절차로 대응하는 방법` | revise | `문제가 발생했을 때 감지하고 복구하는 방법` | `호환 가능한 전환`은 장애 발생 뒤의 대응이 아니라 배포 전 호환성을 확보하는 방식이다. Goal에는 문제 발생 뒤의 관찰·대응 흐름을 간단히 쓴다. Kubernetes는 배포 문제를 감지한 뒤 rollback할 수 있다고 설명하고, Google SRE는 바람직하지 않은 변화가 감지되면 이전 구성으로 빠르게 rollback하라고 설명한다. [Kubernetes: Deployment concepts](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment), [Google SRE: Testing Reliability](https://sre.google/sre-book/testing-reliability/) |
