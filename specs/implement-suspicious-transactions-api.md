# Implement Suspicious Transactions API

## Goal
Implement comprehensive suspicious transaction tracking API that allows TRM compliance analysts to flag, categorize, and analyze specific Ethereum transactions associated with watchlisted addresses.

## Context
Once an address is on the watchlist, analysts need to track specific suspicious transactions involving that address. This provides deeper intelligence for investigations and helps build cases for regulatory reporting.

**Business Scenarios:**
- Watchlisted address receives large transfer → analyst flags transaction as suspicious with details
- Pattern analysis reveals multiple small transactions to avoid detection → batch flag transactions
- Investigation reveals transaction connected to known criminal activity → update transaction risk assessment
- Compliance report requires all flagged transactions for specific time period → query and export data

**Technical Context:**
- Builds on watchlist infrastructure and DynamoDB Global Tables
- Transactions are linked to watchlisted addresses through foreign key relationships
- Support for complex transaction analysis patterns and bulk operations
- Integration with blockchain APIs for transaction detail enrichment

## Requirements

### Functional Requirements
- **Flag transaction**: Associate suspicious transaction with watchlisted address
- **Transaction details**: Store comprehensive transaction metadata (hash, block, amounts, counterparties)
- **Bulk operations**: Flag multiple transactions in single operation for pattern analysis
- **Transaction analysis**: Update suspicious indicators and risk assessments
- **Historical tracking**: Query transactions by address, time period, amount ranges
- **Cross-reference analysis**: Find connections between transactions and addresses
- **Export capabilities**: Generate transaction reports for compliance submissions

### Non-Functional Requirements  
- **Performance**: Transaction queries complete within 100ms
- **Data integrity**: Strong validation of transaction hashes and Ethereum addresses
- **Audit compliance**: Complete trail of who flagged what transaction when
- **Scalability**: Handle millions of transactions per address efficiently
- **Multi-region sync**: Transaction data synchronized globally within 1 second
- **Storage efficiency**: Optimize for large transaction datasets

### Domain Model Requirements
- **TransactionHash value object**: Validates Ethereum transaction hash format
- **SuspiciousTransaction entity**: Core domain entity with transaction analysis
- **TransactionType enumeration**: Incoming, outgoing, self-transfer classifications
- **SuspiciousIndicators**: Flags for money laundering patterns (mixer, large amount, etc.)
- **Domain events**: Transaction flagged events for real-time alerting and audit

## Acceptance Tests

### API Endpoint Tests
- `POST /api/v1/watchlist/addresses/{address}/transactions` creates transaction link and returns 201
- `GET /api/v1/watchlist/addresses/{address}/transactions` returns paginated transaction list with 200  
- `GET /api/v1/watchlist/addresses/{address}/transactions/{tx_hash}` returns specific transaction with 200
- `PUT /api/v1/watchlist/addresses/{address}/transactions/{tx_hash}` updates transaction analysis and returns 200
- `DELETE /api/v1/watchlist/addresses/{address}/transactions/{tx_hash}` removes transaction flag and returns 204

### Validation Tests
- Invalid transaction hash format returns 400 with specific error message
- Duplicate transaction flagging returns 409 conflict error
- Transaction for non-watchlisted address returns 404 error
- Missing required transaction fields return 422 with validation details
- Invalid suspicious indicators return 400 with allowed values

### Business Logic Tests
- SuspiciousTransaction entity enforces all business rules correctly
- TransactionHash validates 0x prefix and 64 hex character format
- Transaction amount validation handles wei/ETH conversion properly
- Suspicious indicators support multiple simultaneous flags
- Domain events triggered correctly for transaction flagging and updates

### Integration Tests
- End-to-end: Flag transaction → query → update analysis → verify audit trail
- Multi-region: Flag transaction in one region → verify visibility in other regions
- Bulk operations: Flag 100+ transactions efficiently with proper error handling
- Performance: Query large transaction datasets (1M+ records) within SLA

## Out of Scope
- **Real-time transaction monitoring**: Live blockchain scanning for new transactions
- **Transaction enrichment**: Automatic fetching of transaction details from blockchain APIs
- **Advanced analytics**: Machine learning pattern detection and risk scoring
- **Transaction graph analysis**: Network analysis of transaction relationships
- **Regulatory reporting**: Automated compliance report generation (separate feature)

## Implementation Hints

### Domain Entities
```python
# src/domain/value_objects/transaction_hash.py
@dataclass(frozen=True)
class TransactionHash:
    value: str
    
    def __post_init__(self):
        if not re.match(r'^0x[0-9a-fA-F]{64}$', self.value):
            raise ValueError("Invalid transaction hash format")

# src/domain/entities/suspicious_transaction.py
from enum import Enum
from decimal import Decimal
from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional
from uuid import UUID, uuid4

class TransactionType(Enum):
    INCOMING = "incoming"
    OUTGOING = "outgoing"
    SELF_TRANSFER = "self_transfer"

class SuspiciousIndicator(Enum):
    LARGE_AMOUNT = "large_amount"
    KNOWN_MIXER = "known_mixer"
    SANCTIONS_LIST = "sanctions_list"
    UNUSUAL_PATTERN = "unusual_pattern"
    RAPID_SUCCESSION = "rapid_succession"
    ROUND_AMOUNT = "round_amount"

@dataclass
class SuspiciousTransaction:
    address: EthereumAddress  # Associated watchlisted address
    transaction_hash: TransactionHash
    block_number: int
    amount_eth: Decimal
    counterparty_address: EthereumAddress
    transaction_type: TransactionType
    suspicious_indicators: List[SuspiciousIndicator]
    flagged_by: str  # analyst email
    notes: str = ""
    id: UUID = field(default_factory=uuid4)
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None
    _events: list = field(default_factory=list, init=False, repr=False)
    
    @classmethod
    def create(cls, address: str, transaction_hash: str, block_number: int,
               amount_eth: Decimal, counterparty_address: str, 
               transaction_type: TransactionType, suspicious_indicators: List[SuspiciousIndicator],
               flagged_by: str, notes: str = "") -> "SuspiciousTransaction":
        ethereum_address = EthereumAddress(address)
        tx_hash = TransactionHash(transaction_hash)
        counterparty = EthereumAddress(counterparty_address)
        
        transaction = cls(
            address=ethereum_address,
            transaction_hash=tx_hash,
            block_number=block_number,
            amount_eth=amount_eth,
            counterparty_address=counterparty,
            transaction_type=transaction_type,
            suspicious_indicators=suspicious_indicators,
            flagged_by=flagged_by,
            notes=notes
        )
        
        transaction._add_event(
            TransactionFlaggedEvent(
                address=address,
                transaction_hash=transaction_hash,
                amount_eth=amount_eth,
                indicators=suspicious_indicators,
                flagged_by=flagged_by
            )
        )
        return transaction
    
    def update_indicators(self, new_indicators: List[SuspiciousIndicator], updated_by: str) -> None:
        old_indicators = self.suspicious_indicators.copy()
        self.suspicious_indicators = new_indicators
        self.updated_at = datetime.utcnow()
        
        self._add_event(
            TransactionIndicatorsUpdatedEvent(
                address=self.address.value,
                transaction_hash=self.transaction_hash.value,
                old_indicators=old_indicators,
                new_indicators=new_indicators,
                updated_by=updated_by
            )
        )
```

### Application Layer Use Cases
```python
# src/application/use_cases/manage_suspicious_transactions.py
class FlagSuspiciousTransactionUseCase:
    def __init__(self, 
                 transactions_repo: SuspiciousTransactionsRepository,
                 watchlist_repo: WatchlistRepository):
        self._transactions_repo = transactions_repo
        self._watchlist_repo = watchlist_repo
    
    async def execute(self, request: FlagTransactionRequest) -> TransactionResponse:
        # Verify address is watchlisted
        watchlisted_address = await self._watchlist_repo.get_by_address(
            EthereumAddress(request.address)
        )
        if not watchlisted_address or not watchlisted_address.is_active:
            raise AddressNotWatchlistedError(f"Address {request.address} is not watchlisted")
        
        # Check for duplicate transaction flagging
        existing = await self._transactions_repo.get_by_address_and_hash(
            EthereumAddress(request.address),
            TransactionHash(request.transaction_hash)
        )
        if existing:
            raise TransactionAlreadyFlaggedError(
                f"Transaction {request.transaction_hash} already flagged for address {request.address}"
            )
        
        # Create suspicious transaction
        suspicious_transaction = SuspiciousTransaction.create(
            address=request.address,
            transaction_hash=request.transaction_hash,
            block_number=request.block_number,
            amount_eth=Decimal(request.amount_eth),
            counterparty_address=request.counterparty_address,
            transaction_type=TransactionType(request.transaction_type),
            suspicious_indicators=[SuspiciousIndicator(i) for i in request.suspicious_indicators],
            flagged_by=request.flagged_by,
            notes=request.notes
        )
        
        # Persist to repository
        await self._transactions_repo.save(suspicious_transaction)
        
        return TransactionResponse.from_entity(suspicious_transaction)

class QuerySuspiciousTransactionsUseCase:
    def __init__(self, transactions_repo: SuspiciousTransactionsRepository):
        self._transactions_repo = transactions_repo
    
    async def execute(self, address: str, filters: TransactionFilters) -> PaginatedTransactionResponse:
        ethereum_address = EthereumAddress(address)
        
        # Apply filters and pagination
        transactions = await self._transactions_repo.list_by_address(
            address=ethereum_address,
            transaction_type=filters.transaction_type,
            min_amount=filters.min_amount_eth,
            max_amount=filters.max_amount_eth,
            start_date=filters.start_date,
            end_date=filters.end_date,
            limit=filters.limit,
            offset=filters.offset
        )
        
        return PaginatedTransactionResponse(
            items=[TransactionResponse.from_entity(tx) for tx in transactions.items],
            total_count=transactions.total_count,
            has_next=transactions.has_next,
            next_offset=transactions.next_offset
        )
```

### FastAPI Router Implementation
```python
# src/presentation/api/suspicious_transactions.py
@router.post("/addresses/{address}/transactions",
             response_model=TransactionResponse,
             status_code=status.HTTP_201_CREATED)
async def flag_suspicious_transaction(
    address: str,
    request: FlagTransactionRequest,
    use_case: FlagSuspiciousTransactionUseCase = Depends()
) -> TransactionResponse:
    try:
        # Ensure address in path matches request body
        if address != request.address:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, 
                              "Address in path must match address in request body")
        
        return await use_case.execute(request)
    except AddressNotWatchlistedError as e:
        raise HTTPException(status.HTTP_404_NOT_FOUND, str(e))
    except TransactionAlreadyFlaggedError as e:
        raise HTTPException(status.HTTP_409_CONFLICT, str(e))
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e))

@router.get("/addresses/{address}/transactions",
            response_model=PaginatedTransactionResponse)
async def list_suspicious_transactions(
    address: str,
    transaction_type: Optional[str] = None,
    min_amount_eth: Optional[Decimal] = None,
    max_amount_eth: Optional[Decimal] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    use_case: QuerySuspiciousTransactionsUseCase = Depends()
) -> PaginatedTransactionResponse:
    try:
        filters = TransactionFilters(
            transaction_type=TransactionType(transaction_type) if transaction_type else None,
            min_amount_eth=min_amount_eth,
            max_amount_eth=max_amount_eth,
            start_date=start_date,
            end_date=end_date,
            limit=limit,
            offset=offset
        )
        
        return await use_case.execute(address, filters)
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e))
```

### DynamoDB Table Schema
```python
# DynamoDB Table Design for SuspiciousTransactions
{
    "TableName": "SuspiciousTransactions",
    "KeySchema": [
        {"AttributeName": "address", "KeyType": "HASH"},     # Partition key
        {"AttributeName": "tx_sort_key", "KeyType": "RANGE"} # Sort key: "TX#{transaction_hash}"
    ],
    "AttributeDefinitions": [
        {"AttributeName": "address", "AttributeType": "S"},
        {"AttributeName": "tx_sort_key", "AttributeType": "S"},
        {"AttributeName": "flagged_by", "AttributeType": "S"},
        {"AttributeName": "created_at", "AttributeType": "S"},
        {"AttributeName": "transaction_type", "AttributeType": "S"},
        {"AttributeName": "amount_eth", "AttributeType": "N"}
    ],
    "GlobalSecondaryIndexes": [
        {
            "IndexName": "flagged_by-created_at-index",
            "KeySchema": [
                {"AttributeName": "flagged_by", "KeyType": "HASH"},
                {"AttributeName": "created_at", "KeyType": "RANGE"}
            ]
        },
        {
            "IndexName": "transaction_type-amount_eth-index", 
            "KeySchema": [
                {"AttributeName": "transaction_type", "KeyType": "HASH"},
                {"AttributeName": "amount_eth", "KeyType": "RANGE"}
            ]
        }
    ]
}
```

### API Endpoints Summary
- `POST /api/v1/watchlist/addresses/{address}/transactions` - Flag new suspicious transaction
- `GET /api/v1/watchlist/addresses/{address}/transactions` - List transactions with filtering/pagination
- `GET /api/v1/watchlist/addresses/{address}/transactions/{tx_hash}` - Get specific transaction details
- `PUT /api/v1/watchlist/addresses/{address}/transactions/{tx_hash}` - Update transaction analysis
- `DELETE /api/v1/watchlist/addresses/{address}/transactions/{tx_hash}` - Remove transaction flag

### Query Patterns Supported
- All transactions for specific address (primary key query)
- Transactions by analyst who flagged them (GSI query)
- Transactions by type and amount range (GSI query)  
- Transactions within date range (sort key range query)
- Complex filtering with multiple criteria (scan with filter expressions)

This suspicious transactions API provides comprehensive transaction analysis capabilities for TRM compliance operations with efficient querying, multi-region synchronization, and complete audit trails.