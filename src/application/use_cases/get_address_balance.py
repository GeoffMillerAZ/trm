import uuid

from src.application.dtos.blockchain_dtos import BalanceRequest, BalanceResponse
from src.domain.interfaces.logger import LoggerInterface
from src.domain.interfaces.tracing import TraceStatus, TracingInterface
from src.domain.services.blockchain_service import BlockchainService


class GetAddressBalanceUseCase:
    """
    Use case for retrieving Ethereum address balance.
    Orchestrates the domain service call and handles response formatting.
    """

    def __init__(
        self,
        blockchain_service: BlockchainService,
        logger: LoggerInterface,
        tracer: TracingInterface,
    ) -> None:
        self._blockchain_service = blockchain_service
        self._logger = logger
        self._tracer = tracer

    async def execute(self, request: BalanceRequest) -> BalanceResponse | None:
        """
        Execute the balance retrieval use case.

        Args:
            request: BalanceRequest containing the address to check

        Returns:
            BalanceResponse if successful, None if address invalid or retrieval failed
        """
        correlation_id = str(uuid.uuid4())[:8]

        async with await self._tracer.start_trace(
            "execute_balance_use_case",
            metadata={"address": request.address, "correlation_id": correlation_id},
        ) as span:
            try:
                await span.set_attribute("address", request.address)
                await span.set_attribute("correlation_id", correlation_id)
                await span.set_attribute("use_case", "GetAddressBalanceUseCase")

                await self._logger.info(
                    "Starting balance retrieval use case",
                    correlation_id=correlation_id,
                    metadata={"address": request.address},
                )

                async with await self._tracer.start_span(
                    "call_blockchain_service", metadata={"address": request.address}
                ) as service_span:
                    await service_span.set_attribute("service", "BlockchainService")

                    address_balance = (
                        await self._blockchain_service.get_address_balance(
                            request.address
                        )
                    )

                    if not address_balance:
                        await service_span.set_attribute("result", "null")
                        await service_span.add_event("null_result_from_service")

                        await span.set_attribute("result", "null")
                        await span.add_event("balance_retrieval_returned_null")

                        await self._logger.info(
                            "Balance retrieval returned null result",
                            correlation_id=correlation_id,
                            metadata={"address": request.address},
                        )
                        return None

                    await service_span.set_attribute(
                        "balance", float(address_balance.balance_eth)
                    )
                    await service_span.add_event(
                        "balance_retrieved",
                        {"balance": float(address_balance.balance_eth)},
                    )

                async with await self._tracer.start_span(
                    "format_response", metadata={"address": request.address}
                ) as format_span:
                    response = BalanceResponse.from_address_balance(
                        address_balance, address_balance.source
                    )

                    await format_span.set_attribute(
                        "balance", float(response.balance_eth)
                    )
                    await format_span.set_attribute("source", response.source)
                    await format_span.add_event("response_formatted")

                await span.set_attribute("balance", float(response.balance_eth))
                await span.set_attribute("source", response.source)
                await span.set_attribute("result_status", "success")
                await span.add_event(
                    "use_case_completed_successfully",
                    {
                        "address": request.address,
                        "balance": float(response.balance_eth),
                        "source": response.source,
                    },
                )

                await self._logger.info(
                    "Balance retrieval use case completed successfully",
                    correlation_id=correlation_id,
                    metadata={
                        "address": request.address,
                        "balance": float(response.balance_eth),
                        "source": response.source,
                    },
                )

                return response

            except Exception as e:
                await span.set_status(TraceStatus.ERROR, str(e))
                await span.set_attribute("error", str(e))
                await span.set_attribute("result_status", "error")
                await span.add_event("use_case_failed", {"exception": str(e)})

                await self._logger.error(
                    "Balance retrieval use case failed",
                    correlation_id=correlation_id,
                    metadata={"address": request.address},
                    exception=e,
                )
                return None
