# Scripts

각 Lab은 자체 실행 스크립트를 둔다. Schema Compatibility 실행 진입점은
[`labs/deployment-safety/schema-compatibility/lab.sh`](../labs/deployment-safety/schema-compatibility/lab.sh)다.

## 로컬 Kubernetes CLI 설치

[`install-kind-kubectl.sh`](./install-kind-kubectl.sh)는 `kind`와 `kubectl`을 사용자
전용 `~/.local/bin`에 설치한다. `sudo`는 필요하지 않으며, 다운로드한 파일의
SHA-256을 확인한 뒤에만 설치한다.

```sh
./scripts/install-kind-kubectl.sh
export PATH="$HOME/.local/bin:$PATH" # 아직 PATH에 없다면
kind version
kubectl version --client
```

기본값은 각 도구의 최신 안정 버전이다. 재현이 필요하면 버전을 고정할 수 있다.

```sh
KIND_VERSION=v0.31.0 KUBECTL_VERSION=v1.34.0 ./scripts/install-kind-kubectl.sh
```

이미 `PATH`에 있는 도구는 다시 설치하지 않는다. 최신 파일로 다시 설치하려면
`FORCE=1`을 지정한다. 기본 설치 위치가 맞지 않으면 `INSTALL_DIR`을 지정할 수 있다.
