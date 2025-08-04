# Implement Investigation Notes API

## Goal
Implement collaborative investigation notes API that enables TRM analysts across multiple regions to share insights, analysis, and findings related to watchlisted addresses and suspicious activities.

## Context
Investigation work requires collaboration between analysts in different regions and time zones. Notes provide context, analysis, and institutional knowledge that supports compliance decisions and regulatory reporting.

**Business Scenarios:**
- NYC analyst discovers suspicious pattern → adds detailed note for London team to review
- London analyst updates investigation with new intelligence → SF team sees update immediately  
- High-priority addresses need immediate attention → analyst adds urgent note visible globally
- Compliance audit requires investigation trail → export all notes with analyst attribution
- Pattern analysis reveals connections → analyst tags notes for easy cross-referencing

**Technical Context:**
- Multi-region collaboration requires real-time synchronization via DynamoDB Global Tables
- Rich metadata and tagging system for note organization and discovery
- Integration with watchlist and transaction systems for contextual information
- Audit trail requirements for compliance and regulatory purposes

## Requirements

### Functional Requirements
- **Create investigation note**: Add structured note with metadata and tags
- **Update investigation note**: Edit existing notes with version history
- **List notes by address**: Retrieve all investigation notes for specific address
- **Search and filter**: Find notes by analyst, priority, tags, or content
- **Note threading**: Reply to existing notes for conversation-style collaboration
- **Bulk operations**: Add multiple notes or update note metadata in batch
- **Export capabilities**: Generate formatted reports of investigation notes

### Non-Functional Requirements
- **Real-time collaboration**: Notes visible across regions within 1 second
- **Rich metadata**: Support tags, priority levels, note types, and analyst attribution
- **Search performance**: Note searches complete within 100ms
- **Version history**: Track all changes to notes for audit compliance
- **Scalability**: Handle thousands of notes per address efficiently
- **Content validation**: Prevent malicious content and enforce formatting standards

### Domain Model Requirements
- **InvestigationNote entity**: Core domain entity with collaboration features
- **NotePriority enumeration**: HIGH, MEDIUM, LOW priority classification
- **NoteType enumeration**: ANALYSIS, UPDATE, ALERT, CONCLUSION types
- **Tag value object**: Structured tagging system for note organization
- **Domain events**: Note creation and update events for real-time notifications

## Acceptance Tests

### API Endpoint Tests
- `POST /api/v1/watchlist/addresses/{address}/notes` creates note and returns 201
- `GET /api/v1/watchlist/addresses/{address}/notes` returns paginated notes list with 200
- `GET /api/v1/watchlist/addresses/{address}/notes/{note_id}` returns specific note with 200
- `PUT /api/v1/watchlist/addresses/{address}/notes/{note_id}` updates note and returns 200
- `DELETE /api/v1/watchlist/addresses/{address}/notes/{note_id}` soft-deletes note and returns 204

### Validation Tests
- Missing required note content returns 422 with validation details
- Invalid priority or note type returns 400 with allowed values
- Empty or malicious content rejected with appropriate error messages
- Note for non-watchlisted address returns 404 error
- Update to non-existent note returns 404 error

### Business Logic Tests
- InvestigationNote entity validates all business rules correctly
- Note priority and type enumerations enforce valid values
- Tags support multiple simultaneous values with proper validation
- Version history preserved for all note updates
- Domain events triggered for note creation and updates

### Collaboration Tests
- Note created in one region visible in other regions within 1 second
- Concurrent note updates handled with optimistic locking
- Note threading maintains proper parent-child relationships
- Bulk operations handle partial failures gracefully

## Out of Scope
- **Real-time messaging**: Chat-like instant messaging between analysts
- **Rich text editing**: Advanced formatting, images, or attachments
- **Automated analysis**: AI-powered note generation or content suggestions
- **Integration APIs**: Direct integration with external investigation tools
- **Advanced search**: Full-text search across note content (separate feature)

## Implementation Hints

### Domain Entities
```python
# src/domain/entities/investigation_note.py
from enum import Enum
from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional
from uuid import UUID, uuid4

class NotePriority(Enum):
    HIGH = "high"
    MEDIUM = "medium" 
    LOW = "low"

class NoteType(Enum):
    ANALYSIS = "analysis"
    UPDATE = "update"
    ALERT = "alert"
    CONCLUSION = "conclusion"

@dataclass(frozen=True)
class Tag:
    value: str
    
    def __post_init__(self):
        if not self.value or len(self.value.strip()) == 0:
            raise ValueError("Tag value cannot be empty")
        if len(self.value) > 50:
            raise ValueError("Tag value cannot exceed 50 characters")
        if not re.match(r'^[a-zA-Z0-9_-]+$', self.value):
            raise ValueError("Tag value can only contain alphanumeric characters, hyphens, and underscores")

@dataclass
class InvestigationNote:
    address: EthereumAddress
    content: str
    analyst_id: str  # analyst email
    priority: NotePriority
    note_type: NoteType
    tags: List[Tag]
    id: UUID = field(default_factory=uuid4)
    parent_note_id: Optional[UUID] = None  # For threaded conversations
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None
    version: int = field(default=1)
    is_active: bool = True
    _events: list = field(default_factory=list, init=False, repr=False)
    
    def __post_init__(self):
        if not self.content or len(self.content.strip()) == 0:
            raise ValueError("Note content cannot be empty")
        if len(self.content) > 10000:
            raise ValueError("Note content cannot exceed 10,000 characters")
    
    @classmethod
    def create(cls, address: str, content: str, analyst_id: str, 
               priority: NotePriority, note_type: NoteType, 
               tags: List[str], parent_note_id: Optional[UUID] = None) -> "InvestigationNote":
        ethereum_address = EthereumAddress(address)
        tag_objects = [Tag(tag) for tag in tags]
        
        note = cls(
            address=ethereum_address,
            content=content.strip(),
            analyst_id=analyst_id,
            priority=priority,
            note_type=note_type,
            tags=tag_objects,
            parent_note_id=parent_note_id
        )
        
        note._add_event(
            InvestigationNoteCreatedEvent(
                note_id=note.id,
                address=address,
                analyst_id=analyst_id,
                priority=priority.value,
                note_type=note_type.value,
                tags=[tag.value for tag in tag_objects],
                parent_note_id=parent_note_id
            )
        )
        return note
    
    def update_content(self, new_content: str, updated_by: str) -> None:
        if not new_content or len(new_content.strip()) == 0:
            raise ValueError("Note content cannot be empty")
        if len(new_content) > 10000:
            raise ValueError("Note content cannot exceed 10,000 characters")
            
        old_content = self.content
        self.content = new_content.strip()
        self.updated_at = datetime.utcnow()
        self.version += 1
        
        self._add_event(
            InvestigationNoteUpdatedEvent(
                note_id=self.id,
                address=self.address.value,
                old_content=old_content,
                new_content=new_content,
                updated_by=updated_by,
                version=self.version
            )
        )
    
    def update_priority(self, new_priority: NotePriority, updated_by: str) -> None:
        old_priority = self.priority
        self.priority = new_priority
        self.updated_at = datetime.utcnow()
        self.version += 1
        
        self._add_event(
            NotePriorityUpdatedEvent(
                note_id=self.id,
                address=self.address.value,
                old_priority=old_priority.value,
                new_priority=new_priority.value,
                updated_by=updated_by
            )
        )
    
    def add_tags(self, new_tags: List[str], updated_by: str) -> None:
        new_tag_objects = [Tag(tag) for tag in new_tags]
        existing_tag_values = {tag.value for tag in self.tags}
        
        # Only add truly new tags
        added_tags = [tag for tag in new_tag_objects if tag.value not in existing_tag_values]
        
        if added_tags:
            self.tags.extend(added_tags)
            self.updated_at = datetime.utcnow()
            self.version += 1
            
            self._add_event(
                NoteTagsAddedEvent(
                    note_id=self.id,
                    address=self.address.value,
                    added_tags=[tag.value for tag in added_tags],
                    updated_by=updated_by
                )
            )
```

### Application Layer Use Cases
```python
# src/application/use_cases/manage_investigation_notes.py
class CreateInvestigationNoteUseCase:
    def __init__(self, 
                 notes_repo: InvestigationNotesRepository,
                 watchlist_repo: WatchlistRepository):
        self._notes_repo = notes_repo
        self._watchlist_repo = watchlist_repo
    
    async def execute(self, request: CreateNoteRequest) -> NoteResponse:
        # Verify address is watchlisted
        watchlisted_address = await self._watchlist_repo.get_by_address(
            EthereumAddress(request.address)
        )
        if not watchlisted_address or not watchlisted_address.is_active:
            raise AddressNotWatchlistedError(f"Address {request.address} is not watchlisted")
        
        # Verify parent note exists if threading
        if request.parent_note_id:
            parent_note = await self._notes_repo.get_by_id(request.parent_note_id)
            if not parent_note or parent_note.address.value != request.address:
                raise ParentNoteNotFoundError("Parent note not found for this address")
        
        # Create investigation note
        investigation_note = InvestigationNote.create(
            address=request.address,
            content=request.content,
            analyst_id=request.analyst_id,
            priority=NotePriority(request.priority),
            note_type=NoteType(request.note_type),
            tags=request.tags,
            parent_note_id=request.parent_note_id
        )
        
        # Persist to repository
        await self._notes_repo.save(investigation_note)
        
        return NoteResponse.from_entity(investigation_note)

class QueryInvestigationNotesUseCase:
    def __init__(self, notes_repo: InvestigationNotesRepository):
        self._notes_repo = notes_repo
    
    async def execute(self, address: str, filters: NoteFilters) -> PaginatedNoteResponse:
        ethereum_address = EthereumAddress(address)
        
        # Apply filters and pagination
        notes = await self._notes_repo.list_by_address(
            address=ethereum_address,
            analyst_id=filters.analyst_id,
            priority=filters.priority,
            note_type=filters.note_type,
            tags=filters.tags,
            start_date=filters.start_date,
            end_date=filters.end_date,
            limit=filters.limit,
            offset=filters.offset
        )
        
        return PaginatedNoteResponse(
            items=[NoteResponse.from_entity(note) for note in notes.items],
            total_count=notes.total_count,
            has_next=notes.has_next,
            next_offset=notes.next_offset
        )
```

### DynamoDB Table Schema
```python
# DynamoDB Table Design for InvestigationNotes
{
    "TableName": "InvestigationNotes",
    "KeySchema": [
        {"AttributeName": "address", "KeyType": "HASH"},          # Partition key
        {"AttributeName": "note_sort_key", "KeyType": "RANGE"}    # Sort key: "NOTE#{timestamp}#{note_id}"
    ],
    "AttributeDefinitions": [
        {"AttributeName": "address", "AttributeType": "S"},
        {"AttributeName": "note_sort_key", "AttributeType": "S"},
        {"AttributeName": "analyst_id", "AttributeType": "S"},
        {"AttributeName": "created_at", "AttributeType": "S"},
        {"AttributeName": "priority", "AttributeType": "S"}
    ],
    "GlobalSecondaryIndexes": [
        {
            "IndexName": "analyst_id-created_at-index",
            "KeySchema": [
                {"AttributeName": "analyst_id", "KeyType": "HASH"},
                {"AttributeName": "created_at", "KeyType": "RANGE"}
            ]
        },
        {
            "IndexName": "priority-created_at-index",
            "KeySchema": [
                {"AttributeName": "priority", "KeyType": "HASH"},
                {"AttributeName": "created_at", "KeyType": "RANGE"}
            ]
        }
    ]
}
```

### FastAPI Router
```python
# src/presentation/api/investigation_notes.py
@router.post("/addresses/{address}/notes",
             response_model=NoteResponse,
             status_code=status.HTTP_201_CREATED)
async def create_investigation_note(
    address: str,
    request: CreateNoteRequest,
    use_case: CreateInvestigationNoteUseCase = Depends()
) -> NoteResponse:
    try:
        if address != request.address:
            raise HTTPException(status.HTTP_400_BAD_REQUEST,
                              "Address in path must match address in request body")
        
        return await use_case.execute(request)
    except AddressNotWatchlistedError as e:
        raise HTTPException(status.HTTP_404_NOT_FOUND, str(e))
    except ParentNoteNotFoundError as e:
        raise HTTPException(status.HTTP_404_NOT_FOUND, str(e))
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e))

@router.get("/addresses/{address}/notes",
            response_model=PaginatedNoteResponse)
async def list_investigation_notes(
    address: str,
    analyst_id: Optional[str] = None,
    priority: Optional[str] = None,
    note_type: Optional[str] = None,
    tags: Optional[str] = Query(None, description="Comma-separated list of tags"),
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    use_case: QueryInvestigationNotesUseCase = Depends()
) -> PaginatedNoteResponse:
    try:
        filters = NoteFilters(
            analyst_id=analyst_id,
            priority=NotePriority(priority) if priority else None,
            note_type=NoteType(note_type) if note_type else None,
            tags=tags.split(',') if tags else None,
            start_date=start_date,
            end_date=end_date,
            limit=limit,
            offset=offset
        )
        
        return await use_case.execute(address, filters)
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e))
```

### API Endpoints Summary
- `POST /api/v1/watchlist/addresses/{address}/notes` - Create investigation note
- `GET /api/v1/watchlist/addresses/{address}/notes` - List notes with filtering/pagination
- `GET /api/v1/watchlist/addresses/{address}/notes/{note_id}` - Get specific note details
- `PUT /api/v1/watchlist/addresses/{address}/notes/{note_id}` - Update note content/metadata
- `DELETE /api/v1/watchlist/addresses/{address}/notes/{note_id}` - Soft-delete note

### Collaboration Features
- **Note Threading**: Parent-child relationships for conversation-style collaboration
- **Real-time Sync**: Global Tables ensure notes visible across regions within 1 second
- **Version History**: Complete audit trail of all note changes with analyst attribution
- **Rich Tagging**: Flexible tagging system for note organization and discovery
- **Priority Management**: HIGH/MEDIUM/LOW priority system for urgent investigations

This investigation notes API enables global analyst collaboration with comprehensive note management, real-time synchronization, and audit compliance for TRM's compliance operations.