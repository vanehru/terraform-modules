"""Password hashing and verification using PBKDF2 - Compatible with C# backend."""
import hashlib
import os
import secrets


# Constants matching C# implementation
SALT_SIZE = 16
KEY_SIZE = 32
ITERATIONS = 100000


def hash_password(password: str) -> bytes:
    """
    Hash a password using PBKDF2-SHA256, compatible with C# PBKDF2Hash.HashPasswordAsBytes.
    
    Args:
        password: Plain text password
        
    Returns:
        bytes: Salt (16 bytes) + Key (32 bytes) = 48 bytes total
        
    Raises:
        ValueError: If password is invalid
    """
    if not password or not isinstance(password, str):
        raise ValueError("Password must be a non-empty string")
    
    if len(password) > 128:
        raise ValueError("Password too long")
    
    # Generate secure random salt
    salt = secrets.token_bytes(SALT_SIZE)
    
    # Generate key using PBKDF2-HMAC-SHA256
    key = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode('utf-8'),
        salt,
        ITERATIONS,
        dklen=KEY_SIZE
    )
    
    # Return salt + key concatenated (matches C# implementation)
    return salt + key


def verify_password(password: str, stored_bytes: bytes) -> bool:
    """
    Verify a password against its hash, compatible with C# PBKDF2Hash.VerifyPassword.
    
    Args:
        password: Plain text password
        stored_bytes: Stored hash (salt + key as bytes)
        
    Returns:
        bool: True if password matches, False otherwise
        
    Raises:
        ValueError: If inputs are invalid
    """
    if not password or not isinstance(password, str):
        raise ValueError("Password must be a non-empty string")
    
    if not stored_bytes or not isinstance(stored_bytes, bytes):
        raise ValueError("Stored hash must be bytes")
    
    if len(stored_bytes) < SALT_SIZE + KEY_SIZE:
        return False
    
    try:
        # Extract salt and stored key
        salt = stored_bytes[:SALT_SIZE]
        stored_key = stored_bytes[SALT_SIZE:SALT_SIZE + KEY_SIZE]
        
        # Generate key from input password using same salt
        key = hashlib.pbkdf2_hmac(
            'sha256',
            password.encode('utf-8'),
            salt,
            ITERATIONS,
            dklen=KEY_SIZE
        )
        
        # Constant-time comparison
        return secrets.compare_digest(key, stored_key)
    except Exception:
        # Return False for any verification errors (timing attack protection)
        return False
