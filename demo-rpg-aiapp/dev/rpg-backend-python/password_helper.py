"""Password hashing and verification using PBKDF2."""
from passlib.hash import pbkdf2_sha256


def hash_password(password: str) -> str:
    """
    Hash a password using PBKDF2-SHA256.
    
    Args:
        password: Plain text password
        
    Returns:
        str: Hashed password
        
    Raises:
        ValueError: If password is invalid
    """
    if not password or not isinstance(password, str):
        raise ValueError("Password must be a non-empty string")
    
    if len(password) > 128:
        raise ValueError("Password too long")
    
    # Use secure PBKDF2 configuration
    return pbkdf2_sha256.using(rounds=100000, salt_size=16).hash(password)


def verify_password(password: str, hashed: str) -> bool:
    """
    Verify a password against its hash.
    
    Args:
        password: Plain text password
        hashed: Hashed password
        
    Returns:
        bool: True if password matches, False otherwise
        
    Raises:
        ValueError: If inputs are invalid
    """
    if not password or not isinstance(password, str):
        raise ValueError("Password must be a non-empty string")
    
    if not hashed or not isinstance(hashed, str):
        raise ValueError("Hash must be a non-empty string")
    
    try:
        return pbkdf2_sha256.verify(password, hashed)
    except Exception:
        # Return False for any verification errors (timing attack protection)
        return False
