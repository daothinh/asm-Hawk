"""
Redis Queue Client for Python Workers
"""
import os
import redis
from rq import Queue

def get_redis_connection():
    """Create Redis connection from environment"""
    return redis.Redis(
        host=os.getenv("REDIS_HOST", "localhost"),
        port=int(os.getenv("REDIS_PORT", 6379)),
        password=os.getenv("REDIS_PASSWORD"),
        decode_responses=True
    )

def get_queue(name: str = "default") -> Queue:
    """Get RQ queue instance"""
    return Queue(name, connection=get_redis_connection())
