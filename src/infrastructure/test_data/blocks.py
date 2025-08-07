"""Shared test block data for consistent testing across all mock implementations."""

from datetime import datetime
from decimal import Decimal

from src.domain.entities.block import Block
from src.domain.value_objects.block_hash import BlockHash
from src.domain.value_objects.transaction import Transaction

# Well-known Ethereum blocks for testing
TEST_BLOCKS = {
    # Genesis block
    "0xd4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3": Block(
        hash=BlockHash("0xd4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3"),
        parent_hash=BlockHash("0x0000000000000000000000000000000000000000000000000000000000000000"),
        number=0,
        timestamp=datetime(1970, 1, 1, 0, 0, 0),
        transactions=[]
    ),
    
    # Block 1 - First real block
    "0x88e96d4537bea4d9c05d12549907b32561d3bf31f45aae734cdc119f13406cb6": Block(
        hash=BlockHash("0x88e96d4537bea4d9c05d12549907b32561d3bf31f45aae734cdc119f13406cb6"),
        parent_hash=BlockHash("0xd4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3"),
        number=1,
        timestamp=datetime(2015, 7, 30, 15, 26, 28),
        transactions=[]
    ),
    
    # Block 100 - Test block with transactions
    "0x4ff4a38b278ab49f7739d3a4ed4e12714386a9fdf72192f2e8893971a9c0cc15": Block(
        hash=BlockHash("0x4ff4a38b278ab49f7739d3a4ed4e12714386a9fdf72192f2e8893971a9c0cc15"),
        parent_hash=BlockHash("0xaf4efdbaa883967ba27b3e4a680bd8b5a32b773bb36a02a1166edd2486f93a87"),
        number=100,
        timestamp=datetime(2015, 7, 30, 16, 51, 51),
        transactions=[
            Transaction(hash="0xc3c5f700243de37ae986082fd2af88d2a7c2752a0c0f7b9d6ac47c729d45eeb"),
            Transaction(hash="0x73e85e4b79b9c67b218d2e887e6ee8c6ad3e4b341ec98c6263ce8e59e893e6c"),
        ]
    ),
    
    # Block 1000 - Another test block
    "0x7d5a4369273c723454ac137f48a4f142160f83c6e5e6e5e5d1d26f4b0bc6c8de": Block(
        hash=BlockHash("0x7d5a4369273c723454ac137f48a4f142160f83c6e5e6e5e5d1d26f4b0bc6c8de"),
        parent_hash=BlockHash("0xd5fd834247db35d9316ec0df608249e0f936b5d3b9f5431e8de7a86b0e8b5910"),
        number=1000,
        timestamp=datetime(2015, 7, 31, 0, 31, 58),
        transactions=[
            Transaction(hash="0x9b5c12e9be67c03e2f64e9dd72b48c04ce5bb31b99e0b85e12f0c6bbef5cf192"),
            Transaction(hash="0xb3d4d784e6cb3b6cbf7e1fa7f5e7345c4b2c09e4c4c1e44b4f5fb4cf7e6c8ac9"),
            Transaction(hash="0x5e1657ef0e9be9bc72efefe59a2528d0d730d478cfc9e6cdd09af9f997bb3ef4"),
        ]
    ),
    
    # Recent block (simulated) - Block 19000000
    "0xebc8b52fe42797e83cdc38c10d0475b2195a204635a5f246808e6f59f557e0b5": Block(
        hash=BlockHash("0xebc8b52fe42797e83cdc38c10d0475b2195a204635a5f246808e6f59f557e0b5"),
        parent_hash=BlockHash("0x3f34bf7e68bbf4b32c005bbea3e220b13d491be4e68b8b401054c0edd8fb3fc4"),
        number=19000000,
        timestamp=datetime(2024, 1, 15, 12, 0, 0),
        transactions=[
            Transaction(hash="0xfe42797e83cdc38c10d0475b2195a204635a5f246808e6f59f557e0b575e0b5"),
            Transaction(hash="0x83cdc38c10d0475b2195a204635a5f246808e6f59f557e0b575e0b5797efe42"),
            Transaction(hash="0x10d0475b2195a204635a5f246808e6f59f557e0b575e0b5797efe4283cdc38c"),
            Transaction(hash="0x2195a204635a5f246808e6f59f557e0b575e0b5797efe4283cdc38c10d0475b"),
            Transaction(hash="0x635a5f246808e6f59f557e0b575e0b5797efe4283cdc38c10d0475b2195a204"),
        ]
    ),
    
    # Test blocks for error scenarios
    "0x0000000000000000000000000000000000000000000000000000000000000000": None,  # Invalid all-zero hash
    "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef": None,  # Non-existent block
}

# Non-existent block hashes for testing 404 responses
NON_EXISTENT_BLOCKS = [
    "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
    "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
]

# Invalid block hash formats for testing validation
INVALID_BLOCK_HASHES = [
    "0x12345",  # Too short
    "0xinvalid",  # Invalid characters
    "not-a-hash",  # Wrong format
    "0x00000000219ab540356cBB839Cbe05303d7705FaXXXX",  # Too long
    "",  # Empty
]


def get_test_block(block_hash: str) -> Block | None:
    """Get a test block by hash, returns None if not found."""
    return TEST_BLOCKS.get(block_hash.lower())


def get_all_test_blocks() -> dict[str, Block | None]:
    """Get all test blocks for bulk loading."""
    return TEST_BLOCKS.copy()


def is_known_non_existent(block_hash: str) -> bool:
    """Check if a block hash is known to be non-existent for testing."""
    return block_hash.lower() in [h.lower() for h in NON_EXISTENT_BLOCKS]