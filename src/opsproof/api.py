from __future__ import annotations

import logging
from uuid import UUID

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field

from opsproof.store import Order, OrderStore, store_from_environment

logger = logging.getLogger("opsproof.api")


class CreateOrderRequest(BaseModel):
    customer_name: str = Field(min_length=1, max_length=120)


class OrderResponse(BaseModel):
    id: UUID
    customer_name: str


def create_app(store: OrderStore | None = None) -> FastAPI:
    app = FastAPI(title="OpsProof Order API", version="0.1.0")
    app.state.store = store or store_from_environment()

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "alive"}

    @app.get("/ready")
    def ready() -> dict[str, str]:
        # Intentional: this shallow probe exposes the rollout/service-success gap.
        return {"status": "ready"}

    @app.post("/orders", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
    def create_order(request: CreateOrderRequest) -> OrderResponse:
        try:
            order = app.state.store.create(request.customer_name)
        except Exception:
            logger.exception("order_create_failed")
            raise HTTPException(status_code=500, detail="order persistence failed") from None
        logger.info('{"event":"order_created","order_id":"%s"}', order.id)
        return OrderResponse.model_validate(order, from_attributes=True)

    @app.get("/orders/{order_id}", response_model=OrderResponse)
    def get_order(order_id: UUID) -> OrderResponse:
        try:
            order = app.state.store.get(order_id)
        except Exception:
            logger.exception("order_read_failed id=%s", order_id)
            raise HTTPException(status_code=500, detail="order persistence failed") from None
        if order is None:
            raise HTTPException(status_code=404, detail="order not found")
        return OrderResponse.model_validate(order, from_attributes=True)

    return app

