# SPLT-697: handleLogin() Internals

---

## 2FA Branch

`LoginService.login()` calls `verifyUserNeed2FA()` at line 106. If 2FA is required, it throws an exception immediately and **`recordUserDevice()` is never reached**. The device record is only written on the **second call to `/accessToken`** after the user completes 2FA verification.

```mermaid
sequenceDiagram
    participant C as Client
    participant LC as LoginController
    participant LS as LoginService
    participant TF as TwoFactorAuthController

    C->>LC: POST /accessToken (1st call)
    LC->>LS: login(credential, headerVO)
    LS->>LS: line 106: verifyUserNeed2FA()
    Note over LS: 2FA required → throw TWO_FACTOR_AUTH_NEED_VERIFY
    LS-->>LC: exception
    LC-->>C: 2FA error code (recordUserDevice not called)

    C->>TF: POST /two-factor-auth/code/send
    C->>TF: POST /two-factor-auth/code/verify
    Note over TF: setVerified() → shouldVerifyTwoFactorAuth() returns false
    Note over TF: ⚠️ no sendRecordUserDevice here

    C->>LC: POST /accessToken (2nd call)
    LC->>LS: login(credential, headerVO)
    LS->>LS: line 106: verifyUserNeed2FA() → passes
    LS->>LS: line 123: recordUserDevice()
    LS->>LS: line 234: sendRecordUserDevice(LOGIN)
    LC-->>C: access token
```

---

## handleLogin() Fingerprint Check

**Code location:** `UserDeviceService.java:147-185`, `UserDeviceService.java:394-411`

```mermaid
flowchart TD
    START["handleLogin(userDeviceTO)"]
    FIND["findUserDevice(userId, deviceId)"]
    FOUND{device_id\nin DB?}

    subgraph NEW ["device_id not found (new device)"]
        FP_CHECK["isCheckFingerprintEnabled\n&& isExistSameFingerprintDevice()"]
        FP_INNER{"Platform is WEB/WAP/LITE\nand fingerprint not blank?"}
        FP_QUERY["Query DB:\nuserId + fingerprint\n+ status IN (LOGIN, LOGOUT)"]
        CREATE["createUserDevice() → INSERT"]
        NOTIFY_CHECK{"!isExistSameFingerprint\n&& isCreate?"}
        NOTIFY["userNewDeviceService\n.handleNewLogin()\nsend new device notification"]
        SKIP["No notification\n(treated as same device, cookie cleared)"]
    end

    subgraph EXIST ["device_id found (known device)"]
        UPDATE["UPDATE existing record\nrefresh fingerprint, meta_info\nstatus = LOGIN"]
        FORCE_CHECK{"Previous status\nwas FORCE_LOGOUT?"}
        NOTIFY2["userNewDeviceService\n.handleNewLogin()"]
        NOOP["No notification"]
    end

    START --> FIND --> FOUND
    FOUND -->|null| FP_CHECK
    FP_CHECK --> FP_INNER
    FP_INNER -->|yes| FP_QUERY
    FP_INNER -->|no| CREATE
    FP_QUERY --> CREATE
    CREATE --> NOTIFY_CHECK
    NOTIFY_CHECK -->|true| NOTIFY
    NOTIFY_CHECK -->|false| SKIP

    FOUND -->|found| UPDATE
    UPDATE --> FORCE_CHECK
    FORCE_CHECK -->|yes| NOTIFY2
    FORCE_CHECK -->|no| NOOP
```

---

## Outcome Summary

| Scenario                                                                | INSERT?          | New device notification?             |
|-------------------------------------------------------------------------|------------------|--------------------------------------|
| New device_id, fingerprint is new                                       | Yes              | Yes                                  |
| New device_id, fingerprint already exists (re-login after cookie clear) | Yes              | No — suppressed to avoid false alert |
| New device_id, platform is not WEB/WAP/LITE (App)                       | Yes              | Yes (fingerprint check skipped)      |
| Known device_id, normal login                                           | No — UPDATE only | No                                   |
| Known device_id, previous status was FORCE_LOGOUT                       | No — UPDATE only | Yes                                  |

> **Fingerprint's role in handleLogin:** does not affect whether a record is written — only used to **prevent Web users from being flagged as a brand new device after clearing cookies**, avoiding unnecessary new device login notifications.