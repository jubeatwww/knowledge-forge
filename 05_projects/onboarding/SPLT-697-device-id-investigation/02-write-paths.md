# SPLT-697: device_id Write Paths

---

## Core Mechanism (shared by all paths)

All writes go through the same async pipeline:

```mermaid
flowchart LR
    A["Entry Point\n(Controller / Service)"]
    B["UserDeviceService\n.sendRecordUserDevice()"]
    C["UserDeviceProducer\n.send()"]
    D["MQ"]
    E["UserDeviceService\n.handleRecordUserDevice()"]
    F{taskType?}
    G["handleRegister()\n→ createUserDevice()\n→ always INSERT"]
    H["handleLogin()\n→ findUserDevice()\n→ INSERT if not found"]
    I["handleRefreshToken()\n→ findUserDevice()\n→ INSERT if not found"]
    J["UserDeviceRepository\n.create()"]
    K["UserDeviceMapper\n.insert()"]
    L["t_patron_user_device"]

    A --> B --> C --> D --> E --> F
    F -->|REGISTER| G --> J
    F -->|LOGIN| H --> J
    F -->|REFRESH_TOKEN| I --> J
    J --> K --> L
```

---

## REGISTER path (handleRegister → always INSERT)

```mermaid
flowchart TD
    subgraph RegisterController ["RegisterController"]
        R1["POST /account\nregister()"]
        R2["POST /accountNoSendMsg\nregisterNoSendingMsg()"]
        R3["PUT /account/{id}/completeByOtp\nvalidateRegisterOtpCode()"]
        R4["PUT /account/{id}/complete\nvalidateRegisterPhoneVerifyCode()"]
        R5["PUT /account/{id}/completeBySms|completeByCall\ncompleteBySms()"]
        R6["POST /account/create\nregisterOneStep()"]
        RP["private registerProcess()"]
    end

    subgraph ThirdPartyLoginController ["ThirdPartyLoginController"]
        T1["POST /account/thirdParty\n(new user branch)"]
        T2["PUT /account/completeThirdParty"]
        T3["PUT /account/completeThirdPartyBySms"]
        T4["PUT /account/completeThirdPartyByVoiceOtp"]
    end

    subgraph OtherEntry ["Other entry points"]
        P1["POST /verifyCode/sms\nPhoneVerifyCodeController\n(OTP verify complete branch)"]
        P2["POST /ms/account/addAndActive\nUserSignMsController\n(internal MS API)"]
        P3["Email verification flow\nUserDevicePostActivateHandler\n(requires patron.service.email.registration.enable=true)"]
        P4["KycRegisterActivateStrategy /\nSimpleKycRegisterActivateStrategy\n→ UserActivityService.activity()"]
    end

    SEND["UserDeviceService\n.sendRecordUserDevice(REGISTER)"]
    DB["t_patron_user_device\n(INSERT)"]

    R1 --> RP --> SEND
    R2 --> RP
    R3 --> SEND
    R4 --> SEND
    R5 --> SEND
    R6 --> SEND
    T1 --> SEND
    T2 --> SEND
    T3 --> SEND
    T4 --> SEND
    P1 --> SEND
    P2 --> SEND
    P3 --> SEND
    P4 --> SEND
    SEND --> DB
```

---

## LOGIN path (handleLogin → INSERT if device_id not found)

> **Note:** `handleLogin()` contains fingerprint check logic. See [03-handleLogin-detail.md](./03-handleLogin-detail.md).

```mermaid
flowchart TD
    subgraph LoginFlow ["Phone login"]
        L1["POST /accessToken\nLoginController → LoginService.login()\n(no 2FA, or 2nd call after 2FA)"]
        L2["POST /bio/auth:login\nBioAuthController → LoginService.bioLogin()"]
        L3["POST /activity/reactivate\nUserActivityController → LoginService.login()"]
        LS["LoginService\n.recordUserDevice() (private, line 123/162)"]
        L1 --> LS
        L2 --> LS
        L3 --> LS
    end

    subgraph EmailFlow ["Email login"]
        E1["Email login flow\nEmailCredentialService (line 383)"]
        E2["Auto-login after password reset\nResetPasswordService (line 85)"]
    end

    subgraph ThirdPartyFlow ["Third-party login (existing user)"]
        T1["POST /account/thirdParty\nThirdPartyLoginController (line 304)"]
    end

    SEND["UserDeviceService\n.sendRecordUserDevice(LOGIN)"]
    FIND["handleLogin()\n→ findUserDevice(deviceId)\n→ if not found: createUserDevice()"]
    DB["t_patron_user_device\n(INSERT only if device_id not found)"]

    LS --> SEND
    E1 --> SEND
    E2 --> SEND
    T1 --> SEND
    SEND --> FIND --> DB
```

---

## REFRESH_TOKEN path (edge case)

```mermaid
flowchart LR
    L1["PUT /accessToken/refresh\nLoginController.refreshToken()"]
    SEND["UserDeviceService\n.sendRecordUserDevice(REFRESH_TOKEN)"]
    FIND["handleRefreshToken()\n→ findUserDevice(deviceId)\n→ if not found: createUserDevice()"]
    DB["t_patron_user_device\n(INSERT only if device_id missing)"]

    L1 --> SEND --> FIND --> DB
```

---

## When does a new device_id get written?

| Scenario                                | TaskType      | INSERT condition                  |
|-----------------------------------------|---------------|-----------------------------------|
| User completes registration             | REGISTER      | Always                            |
| User logs in (new device)               | LOGIN         | Only if device_id not found in DB |
| Token refresh (edge case)               | REFRESH_TOKEN | Only if device_id not found in DB |
| Logout / force logout / block / unblock | N/A           | UPDATE only, never INSERT         |