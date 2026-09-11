# Traffic Management Labs

실제 요청을 프록시 계층에서 안전하게 제어하는 짧은 운영 런북 모음이다. 두 lab은 같은 주문 도메인을 쓰지만 독립 실행된다.

## [nginx 카나리 배포와 롤백](./nginx-canary/README.md): Docker Compose에서 공개 주문 API의 신규 버전 오류를 발견하고 nginx reload로 되돌린다.

- 컨테이너 헬스체크만으로는 실제 기능장애를 놓칠 수 있다는 것을 시뮬레이션.

## [Envoy 결제 지연 격리](./envoy-resilience/README.md): `kind-opsproof`에서 주문 Pod의 Envoy 사이드카가 느린 결제 상태 조회를 제한하는 모습을 확인한다.
