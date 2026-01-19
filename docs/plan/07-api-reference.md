# 07 - API Reference

## Authentication Endpoints

### POST /api/auth/register
Create new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "fullName": "John Doe"
}
```

**Response (201):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "fullName": "John Doe",
    "role": "VIEWER"
  },
  "accessToken": "jwt-token..."
}
```

---

### POST /api/auth/login
Authenticate and get JWT token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "fullName": "John Doe",
    "role": "VIEWER"
  },
  "accessToken": "jwt-token..."
}
```

---

### GET /api/auth/me
Get current user profile. **Requires Auth.**

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Response (200):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "fullName": "John Doe",
  "role": "VIEWER"
}
```

---

## User Management Endpoints

### GET /api/users
List all users. **Requires: ADMIN or ANALYST role.**

**Response (200):**
```json
[
  {
    "id": "uuid",
    "email": "user@example.com",
    "fullName": "John Doe",
    "role": "VIEWER",
    "isActive": true,
    "lastLoginAt": "2026-01-19T10:00:00Z",
    "createdAt": "2026-01-01T00:00:00Z"
  }
]
```

---

### PATCH /api/users/:id/role
Update user role. **Requires: ADMIN role.**

**Request:**
```json
{
  "role": "ANALYST"
}
```

**Role Options:** `ADMIN`, `ANALYST`, `VIEWER`

---

## Asset Management Endpoints

### GET /api/assets
List assets with search and pagination.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| skip | number | Offset for pagination |
| take | number | Limit (default: 50, max: 100) |
| search | string | Search in domain, IP, owner |
| orderBy | string | `riskScore`, `lastSeenAt`, `createdAt` |
| order | string | `asc` or `desc` |

**Response (200):**
```json
{
  "data": [
    {
      "id": "uuid",
      "domain": "example.com",
      "ipAddress": "192.168.1.1",
      "ipOwner": "Example Corp",
      "assetType": "DOMAIN",
      "status": "ACTIVE",
      "riskScore": 45.5,
      "firstSeenAt": "2026-01-01T00:00:00Z",
      "lastSeenAt": "2026-01-19T00:00:00Z",
      "riskTags": [],
      "_count": {
        "reconResults": 5,
        "attackResults": 0
      }
    }
  ],
  "meta": {
    "total": 100,
    "skip": 0,
    "take": 50
  }
}
```

---

### GET /api/assets/stats
Get asset statistics.

**Response (200):**
```json
{
  "total": 1000,
  "byStatus": {
    "ACTIVE": 800,
    "INACTIVE": 150,
    "SUSPICIOUS": 45,
    "CONFIRMED_MALICIOUS": 5
  },
  "avgRiskScore": 32.5
}
```

---

### POST /api/assets
Create new asset. **Requires: ADMIN or ANALYST role.**

**Request:**
```json
{
  "domain": "example.com",
  "ipAddress": "192.168.1.1",
  "ipOwner": "Example Corp",
  "assetType": "DOMAIN",
  "metadata": {
    "source": "manual",
    "notes": "Main website"
  }
}
```

**Asset Types:** `DOMAIN`, `SUBDOMAIN`, `IP`, `CNAME`

---

### GET /api/assets/:id
Get asset details with relations.

**Response (200):**
```json
{
  "id": "uuid",
  "domain": "example.com",
  "ipAddress": "192.168.1.1",
  "riskScore": 45.5,
  "riskTags": [
    {
      "tagName": "suspicious-behavior",
      "tagCategory": "SUSPICIOUS",
      "confidence": 0.75
    }
  ],
  "reconResults": [
    {
      "id": "uuid",
      "scanType": "PORT_SCAN",
      "port": 443,
      "service": "https",
      "scannedAt": "2026-01-19T00:00:00Z"
    }
  ],
  "attackResults": [],
  "externalIntels": [
    {
      "source": "VIRUSTOTAL",
      "reputationScore": 0.1,
      "isMalicious": false,
      "fetchedAt": "2026-01-19T00:00:00Z"
    }
  ]
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "statusCode": 400,
  "message": ["email must be an email"],
  "error": "Bad Request"
}
```

### 401 Unauthorized
```json
{
  "statusCode": 401,
  "message": "Unauthorized"
}
```

### 403 Forbidden
```json
{
  "statusCode": 403,
  "message": "Forbidden resource"
}
```

### 404 Not Found
```json
{
  "statusCode": 404,
  "message": "Asset not found",
  "error": "Not Found"
}
```
