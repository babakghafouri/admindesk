# AdminDesk Ads API — v1

Status: **design only**. The hostname and service are not deployed by this document.

Base URL: `https://ads.admin98.ir/api/v1`

## Public client endpoint

`GET /ads?placement=windows-home-sidebar&client_version=1.0.0`

- Public read-only endpoint. Do not send device ID, one-time password, remote ID, session information, or user identifiers.
- Server returns `Cache-Control: public, max-age=300` for active content.
- On no eligible ad, return HTTP 200 with `{"is_active":false}`.
- Clients must use a short network timeout and fail closed (hide the ad) on errors.
- An ad must not affect connection setup, session windows, or the remote-control UI.

Example response:

```json
{
  "is_active": true,
  "id": "ad-1001",
  "image_url": "https://ads.admin98.ir/media/banner-1001.webp",
  "target_url": "https://admin98.ir",
  "refresh_seconds": 300
}
```

- `image_url` and `target_url` must be absolute HTTPS URLs.
- `refresh_seconds` is advisory; clients should clamp to a safe range (e.g. 60–3600 seconds).
- The server should validate image dimensions, file type and size, destination URLs, campaign dates and active status before publishing.

## Optional anonymous event endpoints

`POST /ads/{id}/impression` — record a visible impression.

`POST /ads/{id}/click` — record a click.

- Return HTTP 204 on success.
- Event collection is optional; failures must not affect the client.
- Use rate limiting and aggregate metrics. Do not transmit or store device identifiers, passwords, connection metadata, or user fingerprints.
- Prefer opening `target_url` in the system browser only after an explicit click.

## Placement and UI

- Placement key: `windows-home-sidebar`.
- Show only in the main Windows home window, below the local ID and one-time password.
- Preserve existing controls and remote session layout.
- If there is no valid active ad, use no ad space.
- Keep existing light/dark theme capability, with a new Admin98 light theme as the design priority.

## Operations and security

- Serve via HTTPS with a valid certificate; provision DNS for `ads.admin98.ir` separately.
- Host the ad service independently of hbbs/hbbr and avoid changes to the production remote desktop server.
- Add API admin authentication for campaign management in a later, separate design; the public GET endpoint does not grant write access.
- Use request timeouts, caching, input validation, safe URL handling, logging without secrets, and rate limits.
- Do not treat this specification as proof that the DNS, API, media storage, or analytics are live.
