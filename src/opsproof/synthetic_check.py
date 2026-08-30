from __future__ import annotations

import json
import os
import sys
import time
from uuid import UUID

import httpx


def main() -> int:
    base_url = os.getenv("ORDER_API_URL", "http://order-api:8000")
    attempts = int(os.getenv("CHECK_ATTEMPTS", "30"))
    interval_seconds = float(os.getenv("CHECK_INTERVAL_SECONDS", "0.5"))
    failures: list[dict[str, object]] = []

    with httpx.Client(timeout=3.0) as client:
        for attempt in range(1, attempts + 1):
            customer_name = f"synthetic-{attempt}"
            try:
                create = client.post(f"{base_url}/orders", json={"customer_name": customer_name})
                create.raise_for_status()
                order_id = UUID(create.json()["id"])
                read = client.get(f"{base_url}/orders/{order_id}")
                read.raise_for_status()
                if read.json()["customer_name"] != customer_name:
                    raise ValueError("persisted customer_name differs")
                print(json.dumps({"event": "synthetic_check_passed", "attempt": attempt}))
            except Exception as error:
                failure = {"event": "synthetic_check_failed", "attempt": attempt, "error": str(error)}
                failures.append(failure)
                print(json.dumps(failure), file=sys.stderr)
            time.sleep(interval_seconds)

    print(json.dumps({"event": "synthetic_check_complete", "attempts": attempts, "failures": len(failures)}))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())

