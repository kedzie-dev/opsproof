# Local Cluster UI

`cluster-ui/`는 telemetry 관측 스택과 별개로 Headlamp을 설치한다. Headlamp은 Pod·Event·YAML 같은 Kubernetes 리소스를 탐색하는 UI다. metrics·logs·traces를 수집하거나 저장하지 않으며, 실험의 통과·실패는 Synthetic Check Job이 판정한다.

## 설치와 접속

빈 또는 실행 중인 `kind-opsproof` 클러스터에서 실행한다.

```sh
make cluster-ui-up
make cluster-ui-status
make headlamp-token
make headlamp
```

`make headlamp`는 `http://localhost:3302`으로 port-forward한다. Browser에서 이 주소를 열고 `make headlamp-token`의 출력값을 붙여넣어 로그인한다. 토큰은 기본 1시간 뒤 만료한다.

```sh
HEADLAMP_PORT=3303 make headlamp
HEADLAMP_TOKEN_TTL=30m make headlamp-token
```

로그인 토큰은 local kind 클러스터에서만 쓴다. 파일, 환경 파일, Git에 저장하거나 공유하지 않는다.

## 권한과 경계

Headlamp chart와 로그인용 `headlamp-local-user` ServiceAccount에는 이 로컬 단일 클러스터를 탐색·조작할 `cluster-admin` 권한을 준다. resource 편집·삭제와 Event 탐색이 가능한 Dashboard 대체 UI로 쓰기 위한 선택이다. production 또는 공유 클러스터에는 쓰지 않는다. 그런 환경에서는 최소 권한 RBAC와 OIDC를 따로 설계해야 한다.

Headlamp은 `opsproof-cluster-ui` namespace와 별도 Helm release 하나로 관리된다. Grafana·Prometheus·Loki·Tempo·Alloy가 있는 `opsproof-observability` namespace에는 의존하거나 변경하지 않는다.

| 명령 | 역할 |
| --- | --- |
| `make cluster-ui-up` | Headlamp 0.44.0과 로그인용 ServiceAccount/RBAC 설치 |
| `make cluster-ui-status` | Headlamp Deployment·Pod·Service 상태 확인 |
| `make headlamp` | local `3302`에서 Headlamp Service를 port-forward |
| `make headlamp-token` | 기본 1시간짜리 로그인 토큰 발급 |
| `make cluster-ui-down` | Headlamp release, 로그인용 RBAC, namespace 삭제 |

`make cluster-ui-down`은 이 UI 구성만 제거한다. observability 데이터에는 영향을 주지 않는다. `make cluster-down`은 kind 클러스터 전체를 삭제하므로 Headlamp을 포함한 모든 클러스터 resource를 삭제한다.

## 의도적으로 제외한 것

- ingress와 외부 노출
- OIDC 설정과 장기 토큰
- multi-cluster 연결
- Headlamp의 Helm 조작, debug container, node shell 기능
- Grafana plugin 또는 telemetry 저장소 연결
