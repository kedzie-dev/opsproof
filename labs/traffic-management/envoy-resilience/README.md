# Envoy: 결제 지연을 주문 서비스에서 격리하기

**상황:** 주문 서비스가 결제 상태를 조회한다. 결제 서비스가 느려지면, 주문 서비스의 요청이 오래 붙잡히거나 동시 요청이 쌓여 전체 장애로 번질 수 있다. 이 lab은 주문 Pod의 Envoy 사이드카가 짧은 타임아웃, 최대 1회 재시도, 작은 요청 한도로 그 영향을 제한하는 모습을 재현한다.

`GET /payment-status`만 재시도한다. 결제를 실행하는 `POST /payments` 같은 요청은 첫 요청이 성공했는지 알 수 없을 때 중복 결제가 될 수 있으므로 이 정책의 대상이 아니다.

## 준비

- Docker, kind, kubectl 필요.
- 프로젝트의 공유 `kind-opsproof` 클러스터를 사용.
- `opsproof-traffic` namespace로 격리

```bash
cd labs/traffic-management/envoy-resilience
make cluster-up
make build
make deploy
make check
```

첫 `make check` 출력의 `status_counts`는 모두 `200`이어야 한다.

## 사건 처리

1. 결제 서비스의 응답을 450ms로 늦춘다. Envoy의 요청 전체 제한은 300ms, 각 시도 제한은 150ms다.

   ```bash
   make incident
   make check
   make load
   ```

   `make check`의 `504`은 요청이 300ms 안에 끝나지 않아 빠르게 끊긴 결과다. `make load`의 `503`은 동시에 밀려든 요청이 Envoy의 작은 요청 한도를 넘어서며 차단된 결과다. 둘 다 실패를 숨기는 것이 아니라, 주문 서비스가 오래 기다리지 않게 한 결과다.

2. Envoy가 재시도·타임아웃·요청 한도를 실제로 기록했는지 확인한다.

   ```bash
   make logs
   make stats
   kubectl -n opsproof-traffic port-forward service/envoy-admin 19901:9901
   ```

   새 터미널에서 다음을 실행한다.

   ```bash
   curl -s http://localhost:19901/stats | rg 'cluster\.payment\.(upstream_rq_retry|upstream_rq_timeout|upstream_rq_pending_overflow)'
   ```

3. 결제 서비스가 회복됐다고 가정하고 정상 구성을 다시 적용한다.

   ```bash
   make recover
   make check
   ```

   check 결과가 다시 모두 `200`인지 확인한다. 포트 포워드는 `Ctrl+C`로 끝낸다.

4. lab namespace만 지운다.

   ```bash
   make clean
   ```

## 설정에서 볼 것

`k8s/base/envoy-config.yaml`의 `retry_policy`는 재시도 대상을 5xx·연결 실패·연결 재설정으로 제한하고 횟수를 1회로 고정한다. 같은 파일의 `circuit_breakers`는 느린 upstream으로 동시에 나가는 요청 수를 작게 제한한다. 이 값들은 예제용으로 매우 작다. 실무에서는 요청의 정상 지연, 동시성, idempotency, SLO를 근거로 정한다.
