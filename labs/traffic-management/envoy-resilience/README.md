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

make build # ./app/Dockerfile 을 이미지 빌드 후 kind 클러스터 노드에 주입.

make deploy

make check # http client로 order-api 서버 응답체크.
```

- `make check` 출력의 `status_counts`는 모두 `200`이어야 한다.

```bash
{"concurrency": 1, "requests": 10, "status_counts": {"200": 10}}
```

## 사건 처리

1. 결제 서비스의 응답을 450ms로 늦춘다. Envoy의 요청 전체 제한은 300ms, 각 시도 제한은 150ms다.

   ```bash
   make incident # kustomize로 패치(결제서비스의 응답을 의도적으로 늦추는 환경변수 주입) 후 kubectl rollout 재배포.

   make check

   make load # http client로 요청량 증가.
   ```

   ```bash
   {"concurrency": 1, "requests": 10, "status_counts": {"504": 10}}

   {"concurrency": 10, "requests": 20, "status_counts": {"503": 14, "504": 6}}
   ```

   - `make check`의 `504`은 요청이 300ms 안에 끝나지 않아 빠르게 끊긴 결과.
   - `make load`의 `503`은 upstream 동시 요청 상한에 막힌 결과.


2. Envoy가 재시도·타임아웃·요청 한도를 실제로 기록했는지 확인한다.

   ```bash
   make logs # envoy 로그 확인
   make stats # 별도의 터미널에서 포트포워딩 실행(직접 명령어 입력)
   ```

   `make stats`가 출력한 포트포워딩 명령은 **별도 터미널**에서 실행한다. 포트 포워딩은 터미널을 계속 점유하기 때문.

   ```bash
   kubectl -n opsproof-traffic port-forward service/envoy-admin 19901:9901
   ```

   포트 포워딩을 실행한 터미널과 다른 새 터미널에서 다음을 실행한다.

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
