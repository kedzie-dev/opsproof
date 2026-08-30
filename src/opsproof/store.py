from __future__ import annotations

import os
from dataclasses import dataclass
from enum import StrEnum
from uuid import UUID, uuid4

import psycopg
from psycopg.rows import dict_row


class StorageMode(StrEnum):
    CUSTOMER = "customer"
    BUYER = "buyer"
    DUAL = "dual"


@dataclass(frozen=True)
class Order:
    id: UUID
    customer_name: str


class OrderStore:
    def create(self, customer_name: str) -> Order:
        raise NotImplementedError

    def get(self, order_id: UUID) -> Order | None:
        raise NotImplementedError


class PostgresOrderStore(OrderStore):
    def __init__(self, database_url: str, mode: StorageMode) -> None:
        self.database_url = database_url
        self.mode = mode

    def create(self, customer_name: str) -> Order:
        order_id = uuid4()
        query, values = self._create_query(order_id, customer_name)
        with psycopg.connect(self.database_url, row_factory=dict_row) as connection:
            with connection.cursor() as cursor:
                cursor.execute(query, values)
            connection.commit()
        return Order(id=order_id, customer_name=customer_name)

    def get(self, order_id: UUID) -> Order | None:
        query = self._get_query()
        with psycopg.connect(self.database_url, row_factory=dict_row) as connection:
            with connection.cursor() as cursor:
                cursor.execute(query, (order_id,))
                row = cursor.fetchone()
        if row is None:
            return None
        return Order(id=row["id"], customer_name=row["customer_name"])

    def _create_query(self, order_id: UUID, customer_name: str) -> tuple[str, tuple[object, ...]]:
        if self.mode is StorageMode.CUSTOMER:
            return (
                "INSERT INTO orders (id, customer_name) VALUES (%s, %s)",
                (order_id, customer_name),
            )
        if self.mode is StorageMode.BUYER:
            return (
                "INSERT INTO orders (id, buyer_name) VALUES (%s, %s)",
                (order_id, customer_name),
            )
        return (
            "INSERT INTO orders (id, customer_name, buyer_name) VALUES (%s, %s, %s)",
            (order_id, customer_name, customer_name),
        )

    def _get_query(self) -> str:
        if self.mode is StorageMode.CUSTOMER:
            return "SELECT id, customer_name FROM orders WHERE id = %s"
        if self.mode is StorageMode.BUYER:
            return "SELECT id, buyer_name AS customer_name FROM orders WHERE id = %s"
        return "SELECT id, COALESCE(buyer_name, customer_name) AS customer_name FROM orders WHERE id = %s"


def store_from_environment() -> PostgresOrderStore:
    database_url = os.environ["DATABASE_URL"]
    mode = StorageMode(os.getenv("ORDER_STORAGE_MODE", StorageMode.CUSTOMER))
    return PostgresOrderStore(database_url, mode)

