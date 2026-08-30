from uuid import UUID, uuid4

from fastapi.testclient import TestClient

from opsproof.api import create_app
from opsproof.store import Order, OrderStore


class MemoryStore(OrderStore):
    def __init__(self) -> None:
        self.orders: dict[UUID, Order] = {}

    def create(self, customer_name: str) -> Order:
        order = Order(id=uuid4(), customer_name=customer_name)
        self.orders[order.id] = order
        return order

    def get(self, order_id: UUID) -> Order | None:
        return self.orders.get(order_id)


def test_health_and_readiness_are_available_without_database_access() -> None:
    client = TestClient(create_app(MemoryStore()))

    assert client.get("/health").json() == {"status": "alive"}
    assert client.get("/ready").json() == {"status": "ready"}


def test_order_creation_and_read_are_public_contract() -> None:
    client = TestClient(create_app(MemoryStore()))

    created = client.post("/orders", json={"customer_name": "Ada"})

    assert created.status_code == 201
    assert created.json()["customer_name"] == "Ada"
    read = client.get(f"/orders/{created.json()['id']}")
    assert read.status_code == 200
    assert read.json() == created.json()

