# API Documentation: Campaigns by Sites & Boutiques by Users

## Overview

This document describes two REST API endpoints:
1. **Get Campaigns by Site IDs** - Retrieves campaigns with execution statistics for specified sites
2. **Get Boutiques by User IDs** - Retrieves boutiques based on the authenticated user's role and permissions

---

## Table of Contents

1. [Get Campaigns by Site IDs](#1-get-campaigns-by-site-ids)
2. [Get Boutiques by User IDs](#2-get-boutiques-by-user-ids)
3. [Data Models](#data-models)
4. [Error Responses](#error-responses)
5. [Status Codes](#status-codes)

---

## 1. Get Campaigns by Site IDs

Retrieves campaigns with execution statistics for campaigns associated with the specified site IDs. Only returns campaigns with status `Planified` (0) or `InProgress` (1).

### Endpoint

```
POST /api/VmCompaign/by-sites
```

### Authentication

Not required (public endpoint)

### Request Body

The request body should be a JSON array of site IDs (integers).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `siteIds` | `int[]` | Yes | Array of boutique/site IDs to filter campaigns |

### Example Request

```http
POST /api/VmCompaign/by-sites
Content-Type: application/json

[1, 2, 3, 5]
```

### Success Response (200 OK)

Returns an array of `CompaignsWithStatsDto` objects containing campaign information and execution statistics.

```json
[
  {
    "compaignId": 1,
    "status": 1,
    "endDate": "2024-12-31T23:59:59Z",
    "libelle": "Campagne Noël 2024",
    "zoneCount": 5,
    "containsGuideline": true,
    "executionsStats": {
      "guidelineId": 10,
      "guidelineName": "Guideline Vitrine Principale",
      "guidelineDescription": "Instructions pour la mise en place de la vitrine principale",
      "zoneStats": [
        {
          "zoneId": 1,
          "zoneName": "Vitrine Principale",
          "zoneCode": "VP001",
          "imagesCount": 3,
          "isFinished": true
        },
        {
          "zoneId": 2,
          "zoneName": "Vitrine Latérale",
          "zoneCode": "VL002",
          "imagesCount": 2,
          "isFinished": true
        },
        {
          "zoneId": 3,
          "zoneName": "Zone Entrée",
          "zoneCode": "ZE003",
          "imagesCount": 0,
          "isFinished": false
        }
      ]
    }
  },
  {
    "compaignId": 2,
    "status": 0,
    "endDate": "2025-01-15T23:59:59Z",
    "libelle": "Campagne Nouvel An 2025",
    "zoneCount": 3,
    "containsGuideline": true,
    "executionsStats": {
      "guidelineId": 15,
      "guidelineName": "Guideline Décoration Nouvel An",
      "guidelineDescription": "Mise en place des décorations pour le Nouvel An",
      "zoneStats": [
        {
          "zoneId": 1,
          "zoneName": "Vitrine Principale",
          "zoneCode": "VP001",
          "imagesCount": 0,
          "isFinished": false
        }
      ]
    }
  }
]
```

### Response Fields

#### CompaignsWithStatsDto

| Field | Type | Description |
|-------|------|-------------|
| `compaignId` | `int` | Unique identifier of the campaign |
| `status` | `VmCompaignStatus` | Campaign status: `0` (Planified), `1` (InProgress), `2` (Completed), `3` (Cancelled) |
| `endDate` | `DateTime` | Campaign end date (ISO 8601 format) |
| `libelle` | `string` | Campaign label/name |
| `zoneCount` | `int` | Total number of zones in the campaign |
| `containsGuideline` | `bool` | Indicates if the campaign has associated guidelines |
| `executionsStats` | `guidelineExecutionStatDto` | Execution statistics for the campaign's guideline |

#### guidelineExecutionStatDto

| Field | Type | Description |
|-------|------|-------------|
| `guidelineId` | `int` | Unique identifier of the guideline |
| `guidelineName` | `string?` | Title/name of the guideline |
| `guidelineDescription` | `string?` | Description of the guideline |
| `zoneStats` | `ZoneStatDto[]` | Array of zone execution statistics |

#### ZoneStatDto

| Field | Type | Description |
|-------|------|-------------|
| `zoneId` | `int` | Unique identifier of the zone |
| `zoneName` | `string` | Name of the zone |
| `zoneCode` | `string` | Code of the zone |
| `imagesCount` | `int` | Number of execution photos for this zone |
| `isFinished` | `bool` | Computed property: `true` if `imagesCount > 0`, `false` otherwise |

### Error Responses

#### 400 Bad Request

Returned when the request body is invalid or empty.

```json
{
  "message": "At least one site ID is required."
}
```

#### 500 Internal Server Error

Returned when an unexpected error occurs.

```json
{
  "message": "An error occurred while retrieving campaigns by sites.",
  "detail": "Error details..."
}
```

### Notes

- Only campaigns with status `Planified` (0) or `InProgress` (1) are returned
- The endpoint filters campaigns that are associated with at least one of the provided site IDs
- Each campaign includes execution statistics grouped by guideline and zone
- The `executionsStats` contains data for the campaign's guideline(s) with zone-level execution counts

---

## 2. Get Boutiques by User IDs

Retrieves boutiques (sites) based on the authenticated user's role and permissions. The response depends on the current user's role:
- **Admin**: Returns all boutiques
- **Area Manager**: Returns boutiques from groups the user belongs to
- **Single Boutique Manager**: Returns only the boutique directly associated with the user
- **Other roles**: Returns empty list

### Endpoint

```
POST /api/Boutiques/getBoutiquesByUserIDs
```

### Authentication

**Required** - Bearer token with `UserID` claim

### Request Headers

```
Authorization: Bearer <token>
Content-Type: application/json
```

### Request Body

The request body should be a JSON array of user IDs (integers). **Note:** Currently, this parameter is not used in the implementation - the endpoint uses the authenticated user's ID from the token instead.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `userIds` | `int[]` | Yes | Array of user IDs (currently not used - endpoint uses token user ID) |

### Example Request

```http
POST /api/Boutiques/getBoutiquesByUserIDs
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

[1, 2, 3]
```

### Success Response (200 OK)

Returns an array of `Boutique` objects.

```json
[
  {
    "id": 1,
    "code": "BTQ001",
    "libelle": "Boutique Paris Centre",
    "city": "Paris",
    "region": "Île-de-France",
    "country": "France",
    "adress": "123 Rue de la Paix",
    "datecreation": "2024-01-15T00:00:00Z",
    "adresseIp": "192.168.1.100",
    "storeId": "STORE001",
    "warehouseId": "WH001",
    "dbId": "DB001",
    "env": "production",
    "usernameCegid": "user1",
    "passwordCegid": "encrypted_password",
    "cluster": "Cluster1"
  },
  {
    "id": 2,
    "code": "BTQ002",
    "libelle": "Boutique Lyon",
    "city": "Lyon",
    "region": "Auvergne-Rhône-Alpes",
    "country": "France",
    "adress": "456 Avenue des Champs",
    "datecreation": "2024-02-20T00:00:00Z",
    "adresseIp": "192.168.1.101",
    "storeId": "STORE002",
    "warehouseId": "WH002",
    "dbId": "DB002",
    "env": "production",
    "usernameCegid": "user2",
    "passwordCegid": "encrypted_password",
    "cluster": "Cluster2"
  }
]
```

### Response Fields

#### Boutique

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Unique identifier of the boutique |
| `code` | `string` | Boutique code |
| `libelle` | `string` | Boutique name/label |
| `city` | `string?` | City where the boutique is located |
| `region` | `string?` | Region where the boutique is located |
| `country` | `string?` | Country where the boutique is located |
| `adress` | `string?` | Physical address of the boutique |
| `datecreation` | `DateTime?` | Date when the boutique was created |
| `adresseIp` | `string?` | IP address for Cegid integration |
| `storeId` | `string?` | Store ID for Cegid integration |
| `warehouseId` | `string?` | Warehouse ID for Cegid integration |
| `dbId` | `string?` | Database ID for Cegid integration |
| `env` | `string?` | Environment (e.g., "production", "staging") |
| `usernameCegid` | `string?` | Username for Cegid system |
| `passwordCegid` | `string?` | Password for Cegid system (encrypted) |
| `cluster` | `string?` | Cluster identifier |

### Role-Based Behavior

#### Admin (`isAdmin = true`)
- Returns **all boutiques** in the system
- No filtering applied

#### Area Manager (`isAreaManager = true`)
- Returns boutiques from groups the user belongs to
- Boutiques are retrieved through `GroupCaisse` → `Group` → `GroupeBoutique` relationships
- Duplicates are automatically removed

#### Single Boutique Manager (`isSingleBoutiqueManager = true`)
- Returns only the boutique directly associated with the user (`IdBoutique`)
- If no boutique is associated, returns an empty array

#### Other Roles
- Returns an empty array

### Error Responses

#### 400 Bad Request

Returned when the request is invalid.

```json
{
  "message": "Error message details..."
}
```

#### 401 Unauthorized

Returned when authentication fails or user ID is missing/invalid in token.

```json
{
  "message": "Invalid or missing User ID in token."
}
```

#### 404 Not Found

Returned when the user is not found in the system.

```json
{
  "message": "User not found."
}
```

### Notes

- The endpoint requires authentication via Bearer token
- The user ID is extracted from the `UserID` claim in the JWT token
- The `userIds` parameter in the request body is currently **not used** - the endpoint always uses the authenticated user's ID
- Results are filtered based on the authenticated user's role and permissions
- For Area Managers, boutiques are retrieved through group associations

---

## Data Models

### VmCompaignStatus Enum

| Value | Name | Description |
|-------|------|-------------|
| `0` | `Planified` | Campaign is planned but not yet started |
| `1` | `InProgress` | Campaign is currently active |
| `2` | `Completed` | Campaign has been completed |
| `3` | `Cancelled` | Campaign has been cancelled |

---

## Error Responses

### Common Error Format

All error responses follow this structure:

```json
{
  "message": "Human-readable error message",
  "detail": "Technical error details (optional)"
}
```

### Error Types

| Status Code | Description | When It Occurs |
|-------------|-------------|----------------|
| `400` | Bad Request | Invalid request body, missing required parameters |
| `401` | Unauthorized | Missing or invalid authentication token |
| `404` | Not Found | Resource not found (user, boutique, etc.) |
| `500` | Internal Server Error | Unexpected server error |

---

## Status Codes

| Code | Description |
|------|-------------|
| `200` | OK - Request succeeded |
| `400` | Bad Request - Invalid input |
| `401` | Unauthorized - Authentication required or failed |
| `404` | Not Found - Resource not found |
| `500` | Internal Server Error - Server error occurred |

---

## Examples

### Example 1: Get Campaigns for Multiple Sites

**Request:**
```http
POST /api/VmCompaign/by-sites
Content-Type: application/json

[1, 5, 10]
```

**Response:**
```json
[
  {
    "compaignId": 1,
    "status": 1,
    "endDate": "2024-12-31T23:59:59Z",
    "libelle": "Summer Campaign",
    "zoneCount": 3,
    "containsGuideline": true,
    "executionsStats": {
      "guidelineId": 10,
      "guidelineName": "Main Display Guidelines",
      "guidelineDescription": "Guidelines for main display setup",
      "zoneStats": [
        {
          "zoneId": 1,
          "zoneName": "Main Window",
          "zoneCode": "MW001",
          "imagesCount": 5,
          "isFinished": true
        }
      ]
    }
  }
]
```

### Example 2: Get Boutiques as Admin

**Request:**
```http
POST /api/Boutiques/getBoutiquesByUserIDs
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

[]
```

**Response:**
```json
[
  {
    "id": 1,
    "code": "BTQ001",
    "libelle": "Boutique Paris",
    "city": "Paris",
    "region": "Île-de-France",
    "country": "France"
  },
  {
    "id": 2,
    "code": "BTQ002",
    "libelle": "Boutique Lyon",
    "city": "Lyon",
    "region": "Auvergne-Rhône-Alpes",
    "country": "France"
  }
]
```

### Example 3: Get Boutiques as Area Manager

**Request:**
```http
POST /api/Boutiques/getBoutiquesByUserIDs
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

[]
```

**Response:**
```json
[
  {
    "id": 5,
    "code": "BTQ005",
    "libelle": "Boutique Marseille",
    "city": "Marseille",
    "region": "Provence-Alpes-Côte d'Azur",
    "country": "France"
  }
]
```

---

## Integration Notes

### Campaigns by Sites API

- Use this endpoint to retrieve active campaigns for specific sites
- Useful for displaying campaign progress and execution statistics
- The endpoint automatically filters to only return `Planified` and `InProgress` campaigns
- Execution statistics are grouped by guideline and zone for easy visualization

### Boutiques by User IDs API

- Use this endpoint to retrieve boutiques based on user permissions
- The endpoint respects role-based access control (RBAC)
- Always include the `Authorization` header with a valid Bearer token
- The response will vary based on the authenticated user's role
- Currently, the `userIds` parameter in the request body is not used - the endpoint uses the token's user ID

---

## Changelog

### Version 1.0.0 (Current)
- Initial documentation for both endpoints
- Added role-based access control documentation for boutiques endpoint
- Added comprehensive examples and error handling documentation
