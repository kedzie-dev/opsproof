# OpsProof

프로덕션에 배포하기 전에 Kubernetes 워크로드가 실제 조건에서 안전하게 동작하는지 확인하는 재현 가능한 실험 모음이다.

첫 MVP는 데이터를 저장하는 Order API의 배포 안전성 실험이다. 호환되지 않는 PostgreSQL 스키마를 적용했을 때, Kubernetes 롤아웃과 준비 상태 프로브는 성공하지만 실제 주문 생성은 실패할 수 있음을 재현한다.

## 현재 상태

MVP는 kind, 클러스터 안의 PostgreSQL, 복제본 2개의 FastAPI 서비스, 버전별 SQL 마이그레이션 Job, Synthetic Check Job, 수동 롤백으로 구성한다. 필요하면 Helm으로 Grafana·Prometheus·Loki·Tempo·Alloy를 설치해 로컬에서 관측할 수 있다. Kubernetes 리소스는 별도 Headlamp UI로 탐색할 수 있다. CI와 원격 레지스트리는 이번 단계의 범위가 아니다.

## 운영 계약

RollingUpdate 중 모든 synthetic `POST /orders` 요청은 성공해야 하며, 생성한 Order는 저장되어야 한다. 요청이나 저장 확인에 실패하면 Deployment Gate는 실패다. 운영자가 수동으로 롤백한다.

## Labs

`labs/`에는 실행할 수 있는 운영 검증 단위를 둔다. 각 Lab의 `README.md`에는 목적, 운영 계약, 실행 절차, 판정 기준, 증거, 한계를 기록한다.

- [Deployment Safety](./labs/deployment-safety/README.md): 배포 중 핵심 기능을 검증하고 문제를 감지·복구하는 Lab 모음.
  - [Schema Compatibility](./labs/deployment-safety/schema-compatibility/README.md): RollingUpdate 중 DB schema 호환성을 검증한다.

## 로컬 실행 순서

```sh
make cluster-up          # kind 기반 로컬 Kubernetes 클러스터 생성
make observability-up    # 선택: Grafana/Prometheus/Loki/Tempo/Alloy 설치
make cluster-ui-up       # 선택: Headlamp Kubernetes 리소스 탐색 UI 설치
make build-images        # API 이미지를 빌드하고 kind 클러스터에 적재
make baseline            # PostgreSQL·v1 스키마·v1 API의 기준 환경 구성
make unsafe-transition   # 열 이름을 즉시 변경; 예상: synthetic check 실패
make cluster-down        # 실험 클러스터와 그 안의 리소스 삭제
```

호환 가능한 전환은 새 클러스터에서 실행한다.

```sh
make cluster-up        # kind 기반 로컬 Kubernetes 클러스터 생성
make build-images      # API 이미지를 빌드하고 kind 클러스터에 적재
make baseline          # PostgreSQL·v1 스키마·v1 API의 기준 환경 구성
make safe-transition   # 호환 가능한 열 추가; 예상: synthetic check 통과
make rollback          # API Deployment를 이전 revision(v1)으로 되돌림
make cluster-down      # 실험 클러스터와 그 안의 리소스 삭제
```

`customer_name` 열 이름을 바로 바꾸면 image만 롤백해서 v1을 복구할 수 없다. 위험한 전환에서 의도적으로 확인하는 결과이며, 복구 절차는 아니다.

관측 스택은 특정 Lab이 소유하지 않는 클러스터 공용 구성이다. 보관 기간, 실행 구조, Grafana 확인 절차는 [Shared Local Observability Stack](./observability/README.md)을 참고한다.

Headlamp은 telemetry를 수집·저장하지 않는 별도 cluster UI다. 설치·접속·로그인 토큰·삭제 절차는 [Local Cluster UI](./cluster-ui/README.md)를 참고한다.
