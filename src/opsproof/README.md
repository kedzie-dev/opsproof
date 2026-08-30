# `opsproof`

배포 안전성 실험에 쓰는 Python reference service다.

- `api.py`는 상태 확인, 준비 상태, 주문 생성, 주문 조회 API를 제공한다.
- `store.py`에는 PostgreSQL 데이터를 저장·조회하는 코드와 버전별 스키마 접근 방식을 둔다.
- `synthetic_check.py`는 클러스터 안에서 실행하는 테스트 클라이언트다. API Service로 Order를 생성한 뒤 다시 조회할 수 있는지 확인한다.

외부 요청 형식은 모든 버전에서 `customer_name`을 유지한다. 스키마 접근 방식만 Kubernetes 실험 overlay에서 의도적으로 바꾼다.
