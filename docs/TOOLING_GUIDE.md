# OpsProof 도구·프레임워크 안내

이 문서는 이 저장소의 로컬 Experiment에 쓰는 도구만 설명한다.

## 전체 흐름

```text
루트 make → labs/deployment-safety/schema-compatibility/Makefile → lab.sh → Docker image build → kind node에 image 적재
                                                                        ↓
                                                                 kubectl/Kustomize로 배포
                                                                        ↓
                                                    FastAPI Order API ↔ PostgreSQL + migration/check Job
```

## 실행 도구

| 도구        | 역할                                                                                                  | 주 명령                                                       |
| ----------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `make` | 자주 쓰는 shell 명령의 짧은 별칭을 실행한다. 이 프로젝트에서는 build 도구보다 Experiment 명령 창구에 가깝다. | `make help`, `make baseline` |
| Docker | API 실행 image를 빌드한다. kind의 Kubernetes node도 Docker container다. | `docker ps`, `docker build -f labs/deployment-safety/schema-compatibility/Dockerfile -t opsproof/order-api:v1 .` |
| kind | Docker 위에서 로컬 Kubernetes cluster를 만들고 지운다. | `kind get clusters`, `kind get nodes --name opsproof` |
| `kubectl` | Kubernetes resource를 적용하고 관찰하는 CLI다. | `kubectl --context kind-opsproof -n opsproof get pods,jobs` |
| Kustomize | base YAML에 revision별 변경을 겹쳐 최종 manifest를 만든다. `kubectl apply -k`가 사용한다. | `kubectl kustomize labs/deployment-safety/schema-compatibility/k8s/overlays/v1` |
| Bash | Lab의 `lab.sh` 자동화 shell이다. Lab Makefile이 이 스크립트를 호출한다. | `cd labs/deployment-safety/schema-compatibility && ./lab.sh baseline` |

## `make`부터 이해하기

`Makefile`에는 **target(명령 별칭)** 과 target이 실행할 명령을 적는다. 이 저장소에서 `make`는 긴 Experiment 절차를 짧은 명령으로 묶는다.

```sh
make help          # 사용 가능한 target 나열
make cluster-up    # Lab Makefile → lab.sh cluster-up 실행
make build-images  # Lab Makefile → lab.sh build-images 실행
```

다음 두 명령의 결과는 같다.

```sh
make baseline
(cd labs/deployment-safety/schema-compatibility && ./lab.sh baseline)
```

루트 `make`는 호환용 단축 경로다. 하위 Lab 모듈은 `labs/deployment-safety/schema-compatibility/Makefile`과 `lab.sh`에서 확인한다.

## Experiment 명령

| 명령                       | 하는 일                                                                                   | 다음 관찰                                                            |
| -------------------------- | ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `make cluster-up` | `labs/deployment-safety/schema-compatibility/kind-config.yaml`로 `opsproof` cluster를 만든다. 이미 있으면 그대로 둔다. | `kind get clusters`, `kubectl --context kind-opsproof get nodes` |
| `make build-images` | API image를 Docker에서 빌드·tag하고 `kind load docker-image`로 node에 넣는다. | 출력의 `kind load docker-image` |
| `make baseline` | namespace, PostgreSQL, v1 migration Job, v1 API Deployment를 적용하고 준비될 때까지 기다린다. | `kubectl ... get pods,jobs,deployment,statefulset` |
| `make test` | 공용 Reference Service의 API 계약을 pytest로 확인한다. Lab Scenario나 cluster는 필요 없다. | pytest 통과 여부 |
| `make unsafe-transition` | 열 rename 뒤 v2를 배포한다. Synthetic Check 실패가 실험 재현 성공이다. | 5xx, `synthetic_check_failed` |
| `make safe-transition` | nullable 열을 추가한 뒤 호환 v2를 배포한다. Synthetic Check 통과가 기대값이다. | `"failures": 0` |
| `make rollback` | API Deployment만 v1 revision으로 되돌린다. safe transition 뒤에만 쓴다. | rollout, Synthetic Check |
| `make cluster-down` | `opsproof` cluster와 내부 resource를 삭제한다. PostgreSQL 데이터도 사라진다. | `kind get clusters` |

`cluster-down`은 환경을 지운다. 필요한 log·상태를 수집한 뒤 실행한다.

## 애플리케이션 구성요소

| 구성요소     | 역할                                                                   | 위치                                     |
| ------------ | ---------------------------------------------------------------------- | ---------------------------------------- |
| Python 3.12+ | API 구현과 테스트를 실행하는 언어다. | `src/`, `tests/`, `pyproject.toml` |
| FastAPI | `/health`, `/ready`, `/orders` HTTP API framework다. | `src/opsproof/` |
| Uvicorn | FastAPI를 실행하는 ASGI server다. Docker container 시작 명령에 쓴다. | `labs/deployment-safety/schema-compatibility/Dockerfile` |
| PostgreSQL | Order를 저장하는 관계형 database다. cluster 안 StatefulSet으로 1개 실행한다. | `labs/deployment-safety/schema-compatibility/k8s/base/postgres.yaml` |
| psycopg      | Python PostgreSQL driver.                                              | `pyproject.toml`                       |
| pytest       | Python 단위 테스트 실행기.                                             | `tests/`, `make test`                |
| httpx        | API 호출용 Python HTTP client.                                         | `pyproject.toml`                       |

## Kubernetes 최소 용어

| 용어        | 이 프로젝트에서의 뜻                                                        |
| ----------- | --------------------------------------------------------------------------- |
| Namespace | resource를 구분하는 논리 공간이다. 여기서는 `opsproof`다. |
| Pod | container를 실행하는 최소 Kubernetes 단위다. API Pod와 PostgreSQL Pod가 있다. |
| Deployment | API Pod를 2개 유지하고 RollingUpdate를 수행한다. |
| StatefulSet | PostgreSQL처럼 안정된 이름·저장소가 필요한 Pod를 관리한다. |
| Service | Pod에 고정 DNS 이름을 준다. API는 `order-api`, DB는 `postgres`다. |
| Job | 끝나면 종료되는 일회성 작업이다. migration과 synthetic check가 해당한다. |
| Manifest | 위 resource를 선언한 YAML이다. Lab의 `labs/deployment-safety/schema-compatibility/k8s/` 아래에 있다. |

## 처음 실행 순서

```sh
# 1. 도구와 현재 상태
make help
kind get clusters
kubectl --context kind-opsproof get nodes

# 2. image 준비와 기준선 배포
make build-images
make baseline

# 3. 기준선 확인
kubectl --context kind-opsproof -n opsproof get pods,jobs,deployment,statefulset
```

예상 상태: `postgres-0` Running, `migration-v1` Complete, `order-api` 2/2 Available.

## 자주 헷갈리는 구분

- `kind get clusters`: cluster 존재만 확인한다. 앱 배포 상태는 알 수 없다.
- `make build-images`: image만 준비한다. Pod는 만들지 않는다.
- `make baseline`: Kubernetes resource를 실제로 배포한다.
- `kubectl`: Kubernetes 안을 조작하고 관찰한다. `kind`: Kubernetes cluster 자체를 만들고 지운다.
- `make rollback`: API revision만 복구한다. destructive schema rename은 복구하지 못한다.

## 공식 참고

- [GNU Make Manual](https://www.gnu.org/software/make/manual/make.html)
- [Docker: What is a container?](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/)
- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubernetes: kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [Kustomize introduction](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- [FastAPI documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL documentation](https://www.postgresql.org/docs/current/)
