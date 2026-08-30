# Schema Compatibility Lab

## Goal

Order API를 배포하는 중에도 주문 생성과 PostgreSQL 저장이 계속 성공하는지 확인한다. 실패를 감지하고 복구하는 절차도 함께 검증한다.

## 이 Lab에서 하는 일

Order API를 두 Pod로 실행하고, DB 스키마와 API 버전을 바꾸며 RollingUpdate를 수행한다. 별도 Job은 배포 중 API Service에 `POST /orders`를 반복 호출해 각 응답과 DB 저장 결과를 확인한다.

다음 세 단계로 실험한다.

| 단계                      | 바꾸는 것                                                      | 확인할 내용                                                                      | 기대 판정                                    |
| ------------------------- | -------------------------------------------------------------- | -------------------------------------------------------------------------------- | -------------------------------------------- |
| 정상 동작 확인            | v1 API와 기존`customer_name` 스키마                          | 평상시 주문 생성·저장이 정상인가                                                | 통과                                         |
| 호환되지 않는 변경        | `customer_name`을 `buyer_name`으로 즉시 rename하고 v2 배포 | 롤아웃이 완료되고 준비성 프로브가 통과해도 v1 Pod의 실제 요청이 실패하는가 | 요청 검증 실패를 감지하면 실험 성공 |
| 이전 버전과 호환되는 변경 | NULL을 허용하는`buyer_name` column을 추가하고 v2 배포        | v1·v2 Pod가 함께 있는 동안에도 주문 생성·저장이 유지되는가                     | 통과                                         |

호환되는 변경에서는 v2를 v1으로 롤백한 뒤에도 주문 생성이 계속되는지 확인한다. `buyer_name` column을 추가해도 v1은 기존 `customer_name` column을 계속 사용한다. 따라서 Deployment를 이전 리비전으로 롤백할 수 있다.

`customer_name` column을 `buyer_name`으로 rename한 경우에는 Deployment를 v1으로 롤백해도 v1이 사용할 `customer_name` column이 없다. 스키마도 되돌려야 한다. 이 Lab에서는 클러스터를 새로 만든 뒤 다음 시나리오를 시작한다.

### 무엇을 증거로 판정하나

서비스 통과·실패는 `Synthetic Check Job`의 종료 상태와 로그로 판정한다. Deployment의 `Available` 상태와 `kubectl rollout status` 결과는 보조 증거일 뿐, 단독으로 통과를 뜻하지 않는다.

- 통과: Job이 `Complete` 상태이고 마지막 로그 요약의 `"failures"`가 `0`이며, 생성한 Order가 PostgreSQL에 저장된다.
- 실패: Job이 `Failed` 상태이거나 로그에 `synthetic_check_failed` 또는 5xx가 기록된다.
- 호환되지 않는 변경에서는 Kubernetes 롤아웃이 성공해도 위 실패 조건이 나타날 수 있다.

이 Lab은 통제된 로컬 kind 클러스터에서 실행한다. CI와 자동 롤백은 포함하지 않으며, 프로덕션 SLO나 무중단 배포를 보장하지 않는다.

## 운영 계약

MVP Deployment Contract: RollingUpdate 동안 모든 synthetic `POST /orders` 요청은 성공 응답을 받고, 생성한 Order는 PostgreSQL에 저장되어야 한다.

통과 증거:

- Synthetic Check Job이 `Complete`
- 로그에 `"failures": 0`
- API Deployment가 원하는 replica 수만큼 `Available`

실패 증거:

- Synthetic Check Job이 `Failed`
- 로그에 `synthetic_check_failed` 또는 5xx가 존재
- Kubernetes 롤아웃은 성공해도 Deployment Contract는 실패로 판정

## 모듈 구성

이 디렉터리에서 Schema Compatibility Experiment를 실행한다.

- `Makefile`: 모듈 실행 진입점
- `lab.sh`: kind 클러스터 생성, 이미지 적재, 기준선 적용·변경·롤백 실행기
- `kind-config.yaml`: 이 Lab 전용 kind 클러스터 설정
- `Dockerfile`: Reference Service 이미지 정의. 빌드 context는 프로젝트 루트이며 `src/`와 `pyproject.toml`을 사용한다.
- `k8s/`: Kustomize base, revision overlay, Migration Job, Synthetic Check Job, SQL
- 프로젝트 루트의 `observability/`: 이 Lab과 이후 모듈이 함께 쓰는 Grafana·Prometheus·Loki·Tempo·Alloy 구성
- 프로젝트 루트의 `cluster-ui/`: Pod·Event·YAML 탐색용 Headlamp 구성

프로젝트 루트에서도 같은 `make` target을 실행할 수 있다. 루트 Makefile은 이 Makefile로 명령을 넘긴다.

## 실행 전 공통 준비

빈 또는 새 kind 클러스터에서 시작한다. 아래 명령은 이 디렉터리에서 실행한다.

```sh
cd labs/deployment-safety/schema-compatibility
make cluster-up
make build-images
make baseline
```

기준선 상태를 확인한다.

```sh
kubectl --context kind-opsproof -n opsproof get pods,jobs,deployment,statefulset
```

기대 상태:

- `postgres-0`이 `1/1 Running`
- `migration-v1` Job이 `Complete`
- `order-api` Deployment가 `2/2 Available`

## 선택: 실시간 관측

Lab의 직접 판정 근거는 Synthetic Check Job이다. Grafana는 이를 대신하지 않으며, API trace·Pod log·Kubernetes event를 살피는 보조 도구다.

```sh
make observability-up
make build-images
make baseline
```

자세한 설치·보관 정책·다른 모듈 연결 방법은 [공유 관측 README](../../../observability/README.md)를 참고한다.

## 선택: Kubernetes 리소스 UI

Headlamp은 telemetry를 수집하거나 실험을 판정하지 않는다. Pod 상태·Event·YAML을 확인하는 별도 로컬 UI다.

```sh
make cluster-ui-up
make headlamp-token
make headlamp
```

`make headlamp`가 연 `http://localhost:3302`에서 토큰을 붙여넣어 로그인한다. 토큰은 `HEADLAMP_TOKEN_TTL=30m make headlamp-token`처럼 필요한 시간만 발급하고, 파일이나 Git에 저장하지 않는다. lifecycle과 권한 범위는 [Local Cluster UI](../../../cluster-ui/README.md)를 참고한다.

## 실행 전 확인: 공용 Reference Service API 계약

이 Lab은 프로젝트 공통 `Reference Service`를 사용한다. 아래 검증은 Deployment Safety 시나리오가 아니다. Lab이 전제하는 Order API의 HTTP 계약을 확인하는 공통 단위 테스트다.

프로젝트 루트에서 실행한다.

```sh
make test
```

다음을 확인한다.

- `/health`와 `/ready`가 응답한다.
- `POST /orders`가 `customer_name`을 수락하고 `201`을 반환한다.
- 반환된 Order ID로 `GET /orders/{id}`를 호출하면 같은 `customer_name`을 반환한다.

pytest 전체가 `2 passed`처럼 통과하면 준비가 끝난다. 경고는 현재 통과·실패 판정에 영향을 주지 않는다.
이 검증은 DB 스키마 호환성이나 Kubernetes 롤아웃 자체를 검증하지 않는다.

---

## TS-01: v1 기준선의 실제 요청 검증

### 목적

v1 스키마와 API가 MVP Deployment Contract를 만족하는 기준선을 마련한다.

### 전제조건

공통 준비를 마쳤다.

### 절차

이 시나리오는 이미 배포된 v1 API에 대해 Synthetic Check Job을 새로 실행한다.
Job은 `order-api` Service로 주문 생성 요청을 30회 보내고, 각 Order가 PostgreSQL에
저장됐는지 확인한다.

1. **이전 판정 Job을 지운다.** 같은 이름의 Job은 다시 실행할 수 없으므로, 이전 실행 결과를
   지운다. Job이 없어도 정상이다.

   ```sh
   kubectl --context kind-opsproof -n opsproof delete job/synthetic-check --ignore-not-found
   ```
2. **새 판정 Job을 만든다.** 모듈의 Job manifest를 적용한다.

   ```sh
   kubectl --context kind-opsproof apply -f k8s/jobs/synthetic-check.yaml
   ```
3. **Job이 끝날 때까지 기다린다.** `Complete`가 나오면 요청과 저장 확인이 모두
   성공한 것이다. 90초 안에 `Failed` 또는 시간 초과가 발생하면 여기서 멈추고 다음
   시나리오로 진행하지 않는다.

   ```sh
   kubectl --context kind-opsproof -n opsproof wait --for=condition=complete job/synthetic-check --timeout=90s
   ```
4. **Job 로그로 실제 요청 결과를 확인한다.** Deployment의 Ready 상태가 아니라 이 로그가
   Deployment Contract의 직접 증거다.

   ```sh
   kubectl --context kind-opsproof -n opsproof logs job/synthetic-check
   ```

   마지막에 아래와 비슷한 요약이 보여야 한다.

   ```text
   {"event": "synthetic_check_complete", "attempts": 30, "failures": 0}
   ```

### 판정

다음 세 조건을 모두 만족하면 **통과**다.

- Job 상태가 `Complete`
- `synthetic_check_passed` event가 30개
- 마지막 요약의 `"failures": 0`

이 결과는 이후 변경 결과를 비교할 **기준선**이다. 하나라도 만족하지 않으면 다음
시나리오로 진행하지 않고 PostgreSQL, Migration Job, API 로그를 먼저 확인한다.

---

## TS-02: 호환되지 않는 변경에서 롤아웃과 실제 요청 결과가 다른지 검증

### 목적

Kubernetes 롤아웃이 완료되고 준비성 프로브가 통과해도 실제 Order 생성은 실패할 수 있음을 재현한다.

### 전제조건

- TS-01이 통과했다.
- 이 시나리오는 `customer_name` column의 이름을 변경한다. 완료 후 클러스터를 삭제한다.

### 실행

```sh
make unsafe-transition
kubectl --context kind-opsproof -n opsproof get pods,jobs,deployment
kubectl --context kind-opsproof -n opsproof logs job/synthetic-check
```

### 주입 조건

- Migration Job이 `orders.customer_name`을 `buyer_name`으로 즉시 rename한다.
- v2 API는 `buyer_name`만 사용한다.
- v2의 준비성 프로브를 10초 지연해, v1·v2가 실제 요청 경로에서 공존하도록 만든다.

### 기대 결과

- `order-api` 롤아웃은 `successfully rolled out`로 완료될 수 있다.
- Synthetic Check Job은 `Failed`다.
- 로그에는 `500 Internal Server Error`와 `synthetic_check_failed`가 있다.
- Deployment Contract는 실패다.

### 판정 및 한계

이 시나리오에서는 Synthetic Check Job의 실패가 기대 결과다. 이는 서비스가 정상이라는 뜻이 아니라, 호환되지 않는 변경으로 발생한 요청 실패를 검증했다는 뜻이다.

`kubectl rollout undo`로 Deployment를 v1으로 롤백해도 `customer_name` column은 복구되지 않는다. 이 명령은 Deployment의 Pod template만 이전 리비전으로 되돌리므로, 이 시나리오에서는 스키마를 별도로 복구해야 한다.

### 정리

```sh
make cluster-down
```

새 클러스터에서 다음 시나리오를 시작한다.

---

## TS-03: 이전 버전과 호환되는 변경 검증

### 목적

이전 버전과 호환되는 변경이 동일한 RollingUpdate 조건에서 MVP Deployment Contract를 유지하는지 검증한다.

### 전제조건

새 클러스터에서 공통 준비와 TS-01을 마쳤다.

### 실행

```sh
make safe-transition
kubectl --context kind-opsproof -n opsproof get pods,jobs,deployment
kubectl --context kind-opsproof -n opsproof logs job/synthetic-check
```

### 주입 조건

- Migration Job이 NULL을 허용하는 `buyer_name` column을 추가한다.
- v2 API는 `customer_name`과 `buyer_name`을 함께 처리한다.
- TS-02와 같은 10초 준비성 프로브 지연을 사용한다.

### 기대 결과

- v1·v2가 공존하는 동안 API 롤아웃이 완료된다.
- Synthetic Check Job이 `Complete`다.
- 마지막 로그 요약의 `"failures"`가 `0`이다.
- Deployment Contract는 통과다.

---

## TS-04: 이전 버전과 호환되는 변경 뒤 수동 롤백 검증

### 목적

추가 column이 있는 스키마에서는 Deployment를 이전 v1 리비전으로 롤백해도 주문 생성이 계속되는지 확인한다.

### 전제조건

TS-03이 통과했다.

### 실행

```sh
make rollback
kubectl --context kind-opsproof -n opsproof get deployment order-api

kubectl --context kind-opsproof -n opsproof delete job/synthetic-check --ignore-not-found
kubectl --context kind-opsproof apply -f k8s/jobs/synthetic-check.yaml
kubectl --context kind-opsproof -n opsproof wait --for=condition=complete job/synthetic-check --timeout=90s
kubectl --context kind-opsproof -n opsproof logs job/synthetic-check
```

### 기대 결과

- Deployment가 v1 리비전으로 롤아웃된다.
- v1은 추가된 `buyer_name` column을 무시하고 `customer_name`으로 Order를 생성한다.
- Synthetic Check Job이 `Complete` 상태이고, 마지막 로그 요약의 `"failures"`가 `0`이다.

### 판정

이 시나리오는 스키마가 v1과 호환될 때의 롤백 가능 범위를 확인한다. column 제거까지 안전하다는 주장은 하지 않는다.

### 정리

```sh
make cluster-down
```

## 증거 수집 체크리스트

각 시나리오에서 아래를 실험 기록에 보관한다.

- 실행한 명령과 실행 시각
- `kubectl get pods,jobs,deployment` 출력
- Migration Job 종료 상태와 로그
- Synthetic Check Job 로그 전문
- `kubectl rollout status` 결과
- API Pod의 `order_create_failed` 구조화 로그(실패 시나리오)
- 통과·실패 판정과 그 한계

## 범위 밖

- 다중 노드 장애, HPA, 트래픽 제어
- 자동 롤백, canary controller, GitHub Actions
- 프로덕션 데이터베이스 마이그레이션 및 프로덕션 SLO 보장
- `customer_name` column의 실제 제거(contract 단계)
