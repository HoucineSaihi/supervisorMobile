# VM submission comments — read / unread tracking

## Overview

Comment visibility is tracked **per user** and **per submission** (`VmExecutionSubmission` for a `campaignId` + `siteId` pair).

- Table: `VmSubmissionCommentReadStates` (`UserId`, `SubmissionId`, `LastReadAt`)
- A comment is **unread** for user `U` when `AuthorUserId != U` and (`LastReadAt` is null or `CreatedAt > LastReadAt`)
- Opening the comment thread marks it read automatically.

## Endpoints

### `GET /api/VmCompaign/comments/unread-summary`

Returns global badge count for the current user.

```json
{ "totalUnreadCount": 12 }
```

Same roles as submission comments.

### `GET /api/VmCompaign/{campaignId}/sites/{siteId}/submission-comments` (breaking change)

**Before:** `200` body = `VmSubmissionCommentDto[]`

**After:** `200` body =

```json
{
  "comments": [ { "id": 1, "isUnread": true, "...": "..." } ],
  "totalCount": 5,
  "unreadCount": 2
}
```

- `unreadCount` is the count **before** this request marks the thread as read.
- Side effect: upserts `LastReadAt` for the current user on this submission.

### Enriched responses (no mark-as-read)

| Endpoint | Field |
|----------|--------|
| `GET .../execution-details` | `unreadCommentCount` |
| `GET /api/VmCompaign` (filtered list) | `unreadCommentCount` per campaign; `kpis.totalUnreadComments` |
| `POST /api/VmCompaign/by-sites` | `unreadCommentCount` per row |

## Mobile workflow

1. Show badges from list / `unread-summary` without opening comments.
2. On comment screen: `GET submission-comments` → display `comments` and `unreadCount`; after response, badges for that site go to 0.
3. When another user posts a comment, counts increase again until the next `GET`.

## Migration

Apply `AddVmSubmissionCommentReadState`:

```bash
dotnet ef database update
```
