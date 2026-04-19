---
title: 2FA Device Swap Investigation
kind: project-note
tags:
  - onboarding
  - work
  - investigation
  - 2fa
  - android
  - security
---

# 2FA Device Swap Investigation

## Snapshot
- Date: 2026-04-17
- Status: 已關單（Android 修復中，預計下週一發版）
- Jira: [SPLT-648](https://opennetltd.atlassian.net/browse/SPLT-648) — BE - Investigate app access failure for user R220202072200puid81682517 in Nigeria
- 研究材料 (本機):
  - `~/sportybet-patron/tmp/SPLT-648-debug-report.md`
  - `~/sportybet-patron/tmp/accessToken-flow.md`

## Background
兩位 user 都回報 Android app 無法登入。trace 後發現 root cause 都指向同一個結構性問題：
**用戶在 server 端記為「2FA enabled + check_new_device_enable」，但實際使用的 device 不在 `t_patron_authorized_device` → 每次 `POST /accessToken` 都會被擋在 `TWO_FACTOR_AUTH_NEED_VERIFY`，形成登入死循環。**

---

## User B: R220202072200puid81682517（SPLT-648, NG）

### 現象
- 自 2026-04-12 ~14:22 UTC 起 Android app 無法登入，畫面顯示
  > "Sorry, something went wrong. Please try again."
- Web 登入正常
- 4/13 09:41 後恢復正常（後述）

### 調查路徑
1. **DB → device 對應**：找到唯一 Android device `1805ee3a5ac60b3a2a86e2757a41c3db`
2. **OpenSearch nginx log**（`opensearch_export_2026-04-16.csv`）：4/12 14:22 起，所有需 auth 的 endpoint 全 401；public endpoint 正常 → session token 無效
3. **Loki app log**（`Logs-A-data-2026-04-16 03_22_02.csv`）：大量 `POST /accessToken` 重試，IP 集中在 `102.91.x.x` (NG)
4. **2FA 觸發 log**：多筆 `TwoFactorAuthServiceImpl:239`
   ```
   should verify 2FA, check device platform: android, deviceId: 1805ee3a...
   ```
5. **Trace 結果**（4/12 14:30 ~ 15:05，~8 個 trace ID）：
   - ~50% → `MSG_TWO_FACTOR_AUTH_NEED_VERIFY`
   - ~50% → `MSG_INVALID_CREDENTIALS`
   - 少數成功
6. **`t_patron_authorized_device`**：**查無紀錄** — 該 device 從未被授權
7. **`t_patron_user_two_factor_auth`**：當下 `enabled=false`、`check_new_device_enable=false`，但 `update_time = 2026-04-13 09:41:37`

### 關鍵推論
`t_patron_user_two_factor_auth.update_time` 在 incident 之後 → 事發時 user **是有開 2FA 的**，事後自己關掉。對照 4/13 之後 device 開始能成功打 auth endpoint，故事閉合。

### Root Cause
- 事發時 user 有開 2FA + check_new_device
- 該 Android device 沒在 `t_patron_authorized_device`
- 每次 `/accessToken` → `verifyUserNeed2FA()` → `TWO_FACTOR_AUTH_NEED_VERIFY`
- App 後續打 `/two-factor-auth` 又因為沒有有效 token 被 gateway 401
- 死循環持續 5.5 小時，直到 user 自己關 2FA

### 額外發現：Token 覆蓋
`LoginTokenService.loginToken():45` 每次登入會 `deleteRecordToken(userId, platform, deviceId)`，把該 device 上的舊 accessToken / refreshToken 從 Redis 刪掉。Trace 看到偶爾 2FA 通過後 2.7 秒 app 又打一次 `/accessToken` → 第二次成功的同時把第一次的 Token-A 刪了 → app 後續用 Token-A 打 API 全 401 → 又進死循環。

### Error message 不一致
- User 看到：`"Sorry, something went wrong. Please try again."`
- Server `MSG_SORRY_SOMETHING_WENT_WRONG` 只有 `"Sorry, something went wrong."`，沒有 "Please try again." 後綴
- CMS translation 也沒有
- 推測 "Please try again." 是 Android client 自己加的

---

## User A: p210327163826puid79861177（疑似同類）

### 現象
兩筆 trace 都導向 `MSG_TWO_FACTOR_AUTH_NEED_VERIFY`。

### 已知
- 該 user 沒有 4/11 活動紀錄，僅 4/12 有
- DB 中該 user 唯一 Android device `1d1274e8097c98c32ae0edf0bba8c43d` 無存取紀錄
- Log 中實際使用的 deviceId `ce86be528ce954826bad9aeba000253e` 不存在於 DB

### 待確認
原本判斷是「手機被偷換裝置」，但有了 User B 的 root cause 後要重看：
- 是否同樣為 device 不在 `t_patron_authorized_device` 導致 2FA 擋掉？
- 4/11 沒紀錄是因為 user 那天沒打開 app，還是被擋在更前面？
- 兩個 deviceId 對應同一支實體手機（重灌 / app 重裝會換 deviceId），還是真的換了一支手機？

---

## 給 Android 端的問題（更新版）
基於 SPLT-648 已知的 server 行為：

1. Client 收到 `MSG_TWO_FACTOR_AUTH_NEED_VERIFY` 時的具體流程是？
   - 是否導去 OTP 輸入頁，還是顯示 "Sorry, something went wrong. Please try again."？
   - "Please try again." 是 client 端追加的嗎？
2. 收到該 error 後 client 會不會自動 retry `POST /accessToken`？（log 看到密集重試的 root cause）
3. 為什麼有時候 2FA 通過、拿到 Token-A 後 ~2.7 秒會再打一次 `/accessToken`？是 client 內部 race / 重複觸發？
4. 收到 `GET /two-factor-auth` 401 時的 fallback 是什麼？

## 2FA flow 未觸及 server 的發現（2026-04-17）

Android 確認：收到 `12400`（`MSG_TWO_FACTOR_AUTH_NEED_VERIFY`）後會走 2FA 流程。

但 server 端完全找不到對應紀錄：
- `POST /two-factor-auth/code/send`：無 log
- `POST /two-factor-auth/verify`：無 log

同一 user 在 WAP 上有完整的 2FA verify 成功 log，可排除 log 遺失問題。

**推論**：Android 進入 2FA 頁面前需先通過 reCAPTCHA，reCAPTCHA 在 client 端就已失敗，導致後續 2FA API 從未被呼叫。死循環：`/accessToken` → `12400` → client 走 2FA → reCAPTCHA 失敗 → 無法送 OTP → 重試 `/accessToken`。

---

## 結案（2026-04-17）

- 2FA 屬 Fraud 團隊範疇，由他們確認 Android 端存在此 bug
- Android 修復單：[SPLT-659](https://opennetltd.atlassian.net/browse/SPLT-659)（by George Yu），預計下週一（2026-04-21）發版
- SPLT-648 / SPLT-687 已關單，OPS 回覆由原 reporter 處理

## Open Questions / Next Steps
- [x] 請 Android 確認 reCAPTCHA 失敗時的 error handling → 確認為 Android bug，SPLT-659 修復中
- [ ] 釐清為何 device 沒被加入 `t_patron_authorized_device`（理論上 2FA 通過後應該要登記）
- [ ] 評估 server 端是否要加 guard：deleteRecordToken 前先檢查間隔，避免短時間多 request 互砍 token

## Related
- [[INDEX]]
- [[domain-map]]
- [[question-log]]