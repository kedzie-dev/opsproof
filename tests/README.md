# 테스트

단위 테스트는 외부에서 확인할 수 있는 Order API 동작만 검증한다.

- 상태 확인과 준비 상태 응답
- 공개 `customer_name` 형식으로 Order 생성
- API로 같은 Order를 다시 조회

Kubernetes 전환 검증은 이 디렉터리에서 하지 않는다. `labs/deployment-safety/schema-compatibility/k8s/jobs/`에 정의한 클러스터 내 Synthetic Check Job이 맡는다.
