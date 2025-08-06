from dataclasses import dataclass

from src.domain.entities.block import Block


@dataclass(frozen=True)
class GetBlockByHashRequest:
    """Request DTO for GetBlockByHashUseCase."""

    block_hash: str


@dataclass(frozen=True)
class GetBlockByHashResponse:
    """Response DTO for GetBlockByHashUseCase."""

    block: Block | None
