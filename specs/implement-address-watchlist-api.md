# Implement Address Watchlist API

## Goal
Implement comprehensive address watchlist management API that allows TRM compliance teams to track, categorize, and manage suspicious Ethereum addresses across multiple regions.

## Context
TRM compliance analysts need to maintain watchlists of suspicious cryptocurrency addresses that are accessible globally for real-time threat detection. This is the core functionality for anti-money laundering operations.

**Business Scenarios:**
- Analyst discovers suspicious address during investigation → adds to watchlist with risk assessment
- Address appears in new transaction → system can quickly check watchlist status
- Risk level changes based on new intelligence → analyst updates existing entry
- Compliance audit requires all watchlist entries by specific analyst or timeframe

**Technical Context:**
- Built on DynamoDB infrastructure layer for multi-region synchronization
- Following established DDD patterns from existing codebase
- API endpoints follow RESTful conventions with proper error handling

## Requirements

### Functional Requirements
- **Create watchlist entry**: Add new Ethereum address with risk assessment and metadata
- **Retrieve watchlist entry**: Get specific address details including audit trail
- **Update watchlist entry**: Modify risk level, notes, or other attributes
- **Remove watchlist entry**: Delete address from watchlist (soft delete for audit)
- **List watchlist entries**: Paginated listing with filtering by risk level, analyst, date range
- **Search functionality**: Find addresses by partial matches or related metadata
- **Bulk operations**: Support adding multiple addresses in single operation

### Non-Functional Requirements
- **Performance**: Single address lookups complete within 50ms
- **Pagination**: Handle large watchlists (10K+ addresses) efficiently
- **Validation**: Strict Ethereum address format validation
- **Audit trail**: All changes logged with timestamp and analyst identification
- **Consistency**: Handle eventual consistency in multi-region scenarios gracefully
- **Rate limiting**: Protect against excessive API usage

### Domain Model Requirements
- **EthereumAddress value object**: Validates hex format and checksum
- **WatchlistedAddress entity**: Core domain entity with business rules
- **RiskLevel enumeration**: Standard risk categories (HIGH, MEDIUM, LOW)
- **WatchlistReason enumeration**: Standardized reason codes
- **Domain events**: Emit events for watchlist changes for audit and notifications

## Acceptance Tests

### API Endpoint Tests
- `POST /api/v1/watchlist/addresses` with valid data returns 201 and creates entry
- `GET /api/v1/watchlist/addresses/{address}` returns 200 with watchlist details
- `PUT /api/v1/watchlist/addresses/{address}` updates existing entry and returns 200
- `DELETE /api/v1/watchlist/addresses/{address}` soft-deletes entry and returns 204
- `GET /api/v1/watchlist/addresses` returns paginated list with 200

### Validation Tests  
- Invalid Ethereum address format returns 400 with specific error message
- Duplicate address creation returns 409 conflict error
- Missing required fields return 422 with field-specific validation errors
- Invalid risk level values return 400 with allowed values listed

### Business Logic Tests
- WatchlistedAddress entity validates all required business rules
- Risk level changes trigger appropriate domain events
- Audit timestamps are automatically managed
- Soft delete preserves data but marks entry as inactive

### Integration Tests
- End-to-end test: Create → Read → Update → Delete → Verify audit trail
- Multi-region test: Create in one region → verify visibility in another region
- Pagination test: Large dataset properly paginated with stable ordering
- Concurrent updates: Handle simultaneous updates from different analysts

## Out of Scope
- **Advanced search**: Full-text search across notes and metadata (future enhancement)
- **Bulk import**: CSV/Excel file uploads (separate feature)
- **Real-time notifications**: Webhook/WebSocket notifications for watchlist changes
- **Data export**: Export functionality for compliance reporting (separate API)
- **Address relationships**: Graph-based relationship tracking between addresses

## Implementation Hints

### Domain Entities
```python
# src/domain/entities/watchlisted_address.py
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from src.domain.value_objects.ethereum_address import EthereumAddress
from src.domain.events.watchlist_events import AddressWatchlistedEvent

class RiskLevel(Enum):
    HIGH = "high"
    MEDIUM = "medium" 
    LOW = "low"

class WatchlistReason(Enum):
    SANCTIONS_LIST = "sanctions_list"
    MIXER_INTERACTION = "mixer_interaction"
    LARGE_TRANSACTIONS = "large_transactions"
    MANUAL_REVIEW = "manual_review"
    RANSOMWARE_LINKED = "ransomware_linked"

@dataclass
class WatchlistedAddress:
    address: EthereumAddress
    risk_level: RiskLevel
    reason: WatchlistReason
    added_by: str  # analyst email
    notes: str = ""
    id: UUID = field(default_factory=uuid4)
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None
    is_active: bool = True
    _events: list = field(default_factory=list, init=False, repr=False)
    
    @classmethod
    def create(cls, address: str, risk_level: RiskLevel, reason: WatchlistReason, 
               added_by: str, notes: str = "") -> "WatchlistedAddress":
        ethereum_address = EthereumAddress(address)
        watchlisted_address = cls(
            address=ethereum_address,
            risk_level=risk_level,
            reason=reason,
            added_by=added_by,
            notes=notes
        )
        watchlisted_address._add_event(
            AddressWatchlistedEvent(
                address=address,
                risk_level=risk_level.value,
                added_by=added_by
            )
        )
        return watchlisted_address
    
    def update_risk_level(self, new_risk_level: RiskLevel, updated_by: str) -> None:
        old_risk_level = self.risk_level
        self.risk_level = new_risk_level
        self.updated_at = datetime.utcnow()
        self._add_event(
            RiskLevelUpdatedEvent(
                address=self.address.value,
                old_risk_level=old_risk_level.value,
                new_risk_level=new_risk_level.value,
                updated_by=updated_by
            )
        )
    
    def soft_delete(self, deleted_by: str) -> None:
        self.is_active = False
        self.updated_at = datetime.utcnow()
        self._add_event(
            AddressRemovedFromWatchlistEvent(
                address=self.address.value,
                deleted_by=deleted_by
            )
        )
```

### Application Layer Use Cases
```python
# src/application/use_cases/manage_watchlist.py
from src.application.dtos.watchlist_dtos import CreateWatchlistRequest, WatchlistResponse
from src.domain.repositories.watchlist_repository import WatchlistRepository

class CreateWatchlistEntryUseCase:
    def __init__(self, watchlist_repo: WatchlistRepository):
        self._watchlist_repo = watchlist_repo
    
    async def execute(self, request: CreateWatchlistRequest) -> WatchlistResponse:
        # Check if address already exists
        existing = await self._watchlist_repo.get_by_address(
            EthereumAddress(request.address)
        )
        if existing and existing.is_active:
            raise WatchlistConflictError(f"Address {request.address} already watchlisted")
        
        # Create new watchlist entry
        watchlisted_address = WatchlistedAddress.create(
            address=request.address,
            risk_level=RiskLevel(request.risk_level),
            reason=WatchlistReason(request.reason),
            added_by=request.added_by,
            notes=request.notes
        )
        
        # Persist to repository
        await self._watchlist_repo.save(watchlisted_address)
        
        # Return response DTO
        return WatchlistResponse.from_entity(watchlisted_address)
```

### FastAPI Router
```python
# src/presentation/api/watchlist.py
from fastapi import APIRouter, HTTPException, status, Depends
from src.application.use_cases.manage_watchlist import CreateWatchlistEntryUseCase
from src.presentation.schemas.watchlist_schemas import CreateWatchlistRequest, WatchlistResponse

router = APIRouter(prefix="/api/v1/watchlist", tags=["watchlist"])

@router.post("/addresses", 
             response_model=WatchlistResponse,
             status_code=status.HTTP_201_CREATED)
async def create_watchlist_entry(
    request: CreateWatchlistRequest,
    use_case: CreateWatchlistEntryUseCase = Depends()
) -> WatchlistResponse:
    try:
        return await use_case.execute(request)
    except WatchlistConflictError as e:
        raise HTTPException(status.HTTP_409_CONFLICT, str(e))
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e))

@router.get("/addresses/{address}",
            response_model=WatchlistResponse)
async def get_watchlist_entry(
    address: str,
    use_case: GetWatchlistEntryUseCase = Depends()
) -> WatchlistResponse:
    try:
        result = await use_case.execute(address)
        if not result:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Address not found in watchlist")
        return result
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e))
```

### Request/Response DTOs
```python
# src/application/dtos/watchlist_dtos.py
from dataclasses import dataclass
from datetime import datetime
from typing import Optional
from uuid import UUID

@dataclass
class CreateWatchlistRequest:
    address: str
    risk_level: str  # "high", "medium", "low"
    reason: str
    added_by: str
    notes: str = ""

@dataclass  
class WatchlistResponse:
    id: UUID
    address: str
    risk_level: str
    reason: str
    added_by: str
    notes: str
    created_at: datetime
    updated_at: Optional[datetime]
    is_active: bool
    
    @classmethod
    def from_entity(cls, entity: WatchlistedAddress) -> "WatchlistResponse":
        return cls(
            id=entity.id,
            address=entity.address.value,
            risk_level=entity.risk_level.value,
            reason=entity.reason.value,
            added_by=entity.added_by,
            notes=entity.notes,
            created_at=entity.created_at,
            updated_at=entity.updated_at,
            is_active=entity.is_active
        )
```

### API Endpoints Summary
- `POST /api/v1/watchlist/addresses` - Create new watchlist entry
- `GET /api/v1/watchlist/addresses/{address}` - Get specific watchlist entry  
- `PUT /api/v1/watchlist/addresses/{address}` - Update existing watchlist entry
- `DELETE /api/v1/watchlist/addresses/{address}` - Remove from watchlist (soft delete)
- `GET /api/v1/watchlist/addresses` - List watchlist entries with pagination/filtering

### Error Handling Strategy
- **400 Bad Request**: Invalid Ethereum address format, invalid enum values
- **404 Not Found**: Address not found in watchlist
- **409 Conflict**: Attempt to add address that's already watchlisted  
- **422 Unprocessable Entity**: Missing required fields, validation errors
- **500 Internal Server Error**: DynamoDB connection issues, unexpected errors

This watchlist API provides the foundation for TRM's compliance operations with proper domain modeling, comprehensive validation, and multi-region synchronization capabilities.