# Kubernetes 매니페스트

로컬 kind 실험에 쓰는 Kustomize 매니페스트다.

- `base/`는 Order API Deployment와 Service, PostgreSQL StatefulSet·PVC·Service를 정의한다.
- `overlays/v1/`는 v1 API 배포를 정의한다.
- `overlays/unsafe-v2/`는 스키마 열 이름을 바로 바꾼 뒤 `buyer_name`만 쓰는 버전을 배포한다.
- `overlays/safe-v2/`는 호환성을 유지하도록 스키마를 확장한 뒤 두 열을 함께 처리하는 버전을 배포한다.
- `jobs/`는 별도로 실행하는 migration Job과 Synthetic Check Job을 정의한다.
- `migrations/`는 각 migration Job에 해당하는 SQL 원본을 보관한다.

API는 `maxUnavailable: 0`, `maxSurge: 1`로 복제본 2개를 사용한다. v2 overlay에서는 synthetic 요청이 v1과 v2가 함께 동작하는 구간을 관찰하도록 준비 상태를 일부러 늦춘다.
