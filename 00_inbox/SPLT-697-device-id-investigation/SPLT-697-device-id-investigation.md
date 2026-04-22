# SPLT-697: device_id Investigation — Index
> Investigate device_id generation logic and format discrepancies for Fraud tracking
> Due: End of April 2026

---

## File Structure

| File                                                   | Content                                                            |
|--------------------------------------------------------|--------------------------------------------------------------------|
| [01-overview.md](./01-overview.md)                     | Q1/Q2/Q3 answers with evidence, Fraud data reference               |
| [02-write-paths.md](./02-write-paths.md)               | Full device_id write code paths (REGISTER / LOGIN / REFRESH_TOKEN) |
| [03-handleLogin-detail.md](./03-handleLogin-detail.md) | handleLogin() internals: 2FA branch + fingerprint check detail     |

---

## Quick Summary

1. **Two formats** — Format is determined entirely by the client; the backend has zero validation. DB observation shows at least three patterns: iOS uppercase, Android lowercase, WAP containing `bdid`. Root cause requires frontend repo investigation.

2. **`device_id` vs `meta_info.deviceIdSc`** — Different sources: `device_id` from Header `DeviceId`, `deviceIdSc` from Cookie `device-id`. The backend never writes the `device-id` cookie (verified in code). Designed to be potentially different values. `deviceIdSc` has three backend uses:
   1. Alive WebSocket disconnection on logout/block
   2. 2FA device ID when `patron.2fa.use.persistent.device.id=true`
   3. Returned via MS device query API

3. **Fingerprint** — The backend does not calculate fingerprint; it only stores the value and uses it for: Mobile register account limit validation, Web login new-device notification suppression. Calculation logic requires frontend repo investigation.

4. **Fraud reference** — The backend's own `handleLogin()` treats matching fingerprint as evidence of the same device (code-verifiable). For Web users, `fingerprint` is a more reliable tracking field than `device_id`.

---

## Related Commits

| Commit      | Description                                                                |
|-------------|----------------------------------------------------------------------------|
| `51402e0af` | SPRTPLTFRM-9518: add `deviceIdSc`, disconnect both sockets on logout/block |
| `d7f82fd8c` | Add `deviceId` cookie (keepSignedIn feature)                               |
| `7809a7a05` | SPRTPLTFRM-13293: consider device-id when querying all user devices        |

---

## Pending — Requires Frontend Confirmation

1. Where does the Web platform store the `DeviceId` Header value? (localStorage / indexedDB / cookie?)
2. What library/method is used to calculate the `Fingerprint` Header value?
3. Who sets the `device-id` cookie, when is it set, and what is its TTL?