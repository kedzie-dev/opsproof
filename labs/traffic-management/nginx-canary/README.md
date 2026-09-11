# nginx: 주문 API 카나리 배포와 롤백

**상황:** 공개 주문 API의 새 버전(`v2`)을 10%만 노출했지만, v2가 503을 반환한다. nginx에서 오류를 확인하고 안정 버전으로 되돌린다.

## 준비

- Docker와 Docker Compose 필요. 
- 이 lab은 다른 OpsProof lab이나 Kubernetes cluster를 바꾸지 않는다.

```bash
cd labs/traffic-management/nginx-canary
make up
curl -v http://localhost:18080/orders/42
```

- "served_by": "v1" 및 200 OK 출력시 성공

## 사건 처리

1. 카나리를 켠다. 이 단계는 의도적으로 실패하는 v2를 10% 비중으로 넣는다.
  - 장애 주입 로직은 [order-api](./app/server.py)

   ```bash
   make canary
   make requests COUNT=50
   ```

   - `200`과 약 10%의 `503`이 함께 보이면 장애가 재현된 것이다.
   e.g.
   ```bash
   …/traffic-management/nginx-canary main  ? ❯ make requests COUNT=50
     46 200
      4 503
   ```

2. nginx가 실제로 무엇을 보았는지 확인한다.

   ```bash
   make logs
   ```

  e.g.
  ```bash
  order-v2-1  | v2 127.0.0.1 "GET /health HTTP/1.1" 200 -
  order-v2-1  | v2 172.20.0.4 code 503, message simulated v2 failure
  order-v2-1  | v2 172.20.0.4 "GET /orders/42 HTTP/1.0" 503 -
  order-v2-1  | v2 127.0.0.1 "GET /health HTTP/1.1" 200 -
  order-v2-1  | v2 127.0.0.1 "GET /health HTTP/1.1" 200 -
  order-v2-1  | v2 127.0.0.1 "GET /health HTTP/1.1" 200 -
  order-v2-1  | v2 127.0.0.1 "GET /health HTTP/1.1" 200 -
  order-v2-1  | v2 127.0.0.1 "GET /health HTTP/1.1" 200 -
  ```

3. 신규 버전을 제거하고 nginx가 무중단으로 설정파일을 다시 읽어 적용하도록 한다.
(기존 nginx container를 재시작하지 않고 `nginx -t` 뒤 `nginx -s reload`만 수행한다.)

   ```bash
   make rollback
   make requests COUNT=50
   ```

   이제 50개 모두 `200`이어야 한다. 

4. 정리

   ```bash
   make down
   ```

## 설정 비교

`nginx/baseline.conf`에는 v1만 upstream으로 등록되어 있다. `nginx/canary.conf`에서는 `weight=9`와 `weight=1`로 v1과 v2의 트래픽 비율을 정한다. 이 방식은 요청 단위로 트래픽을 나누는 간단한 카나리 배포다. 사용자별로 트래픽을 고정하거나 배포 결과를 자동으로 판단하지는 않는다.
