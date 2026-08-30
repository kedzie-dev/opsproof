# Deployment Safety

배포 중 애플리케이션의 핵심 기능을 검증하고, 문제가 생겼을 때 감지·복구하는 방법을 다루는 상위 모듈이다.

각 하위 Lab은 한 가지 배포 위험과 그 검증·판정·복구 범위를 독립적으로 다룬다. 이 디렉터리에서는 직접 실행하지 않는다.

## 하위 Lab

- [Schema Compatibility](./schema-compatibility/README.md): DB schema를 변경하는 RollingUpdate 중 구·신 revision이 핵심 기능을 함께 처리할 수 있는지 검증한다.

readiness와 실제 트래픽 검증, graceful termination, rollout availability처럼 별도 가설과 판정 기준이 필요한 주제는 각각 하위 Lab으로 추가한다.
