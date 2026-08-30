# OpsProof용 kind 실습

## 목적

OpsProof Deployment Safety Experiment를 실행하며 kind를 익힌다. 결과가 예상과 다르면 클러스터, 노드, 워크로드 상태를 나눠 확인한다.

## 완료 기준

- `opsproof` kind 클러스터의 존재 여부, 현재 Kubernetes context, 노드 상태를 각각 확인한다.
- 로컬 Docker 이미지를 클러스터에 넣는 이유와 확인 방법을 설명한다.
- TS-02~TS-05 전후에 필요한 kind와 kubectl 관측 명령을 골라 실행한다.

## 제약 조건

- macOS에서 Docker 기반 단일 control-plane 클러스터를 사용한다.
- 짧은 실습과 실제 OpsProof 명령 흐름으로 학습한다.

## 범위 밖

- 프로덕션 Kubernetes 운영
- 다중 노드·고가용성 클러스터, ingress, 레지스트리 운영
