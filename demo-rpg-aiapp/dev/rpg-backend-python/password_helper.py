"""Password hashing and verification using PBKDF2."""
from passlib.hash import pbkdf2_sha256


def hash_password(password: str) -> str:
    """
    Hash a password using PBKDF2-SHA256.
    
    Args:
        password: Plain text password
        
    Returns:
        str: Hashed password
    """
    return pbkdf2_sha256.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    """
    Verify a password against its hash.
    
    Args:
        password: Plain text password
        hashed: Hashed password
        
    Returns:
        bool: True if password matches, False otherwise
    """
    return pbkdf2_sha256.verify(password, hashed)
