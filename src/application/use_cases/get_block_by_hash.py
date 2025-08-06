from src.application.dtos.block_dtos import (
    GetBlockByHashRequest,
    GetBlockByHashResponse,
)
from src.domain.repositories.blockchain_repository import BlockchainRepository
from src.domain.value_objects.block_hash import BlockHash


class GetBlockByHashUseCase:
    """Use case for retrieving a block by its hash."""

    def __init__(self, blockchain_repository: BlockchainRepository):
        self.blockchain_repository = blockchain_repository

    async def execute(
        self, request: GetBlockByHashRequest
    ) -> GetBlockByHashResponse:
        """
        Executes the use case.

        Args:
            request: The request DTO containing the block hash.

        Returns:
            The response DTO containing the block or None if not found.
        """
        block_hash = BlockHash(request.block_hash)
        block = await self.blockchain_repository.get_block_by_hash(block_hash)
        return GetBlockByHashResponse(block=block)
