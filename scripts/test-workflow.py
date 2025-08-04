"""Test file to validate PR workflow"""

def calculate_sum(a: int, b: int) -> int:
    """Calculate sum of two numbers"""
    return a + b

def test_calculate_sum():
    """Test the calculate_sum function"""
    assert calculate_sum(2, 3) == 5
    assert calculate_sum(-1, 1) == 0
    assert calculate_sum(0, 0) == 0

if __name__ == "__main__":
    print(f"2 + 3 = {calculate_sum(2, 3)}")
    print("All tests would pass!")