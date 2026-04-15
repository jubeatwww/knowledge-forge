---
title: Home Automation Project
kind: project
topic: life
tags:
  - home-automation
  - home-assistant
  - zigbee
  - project
---

# Home Automation Project

放家裡 Home Assistant / Zigbee2MQTT 的具體配置：實體按鈕 → 燈光狀態機、group 命名、YAML 片段。
重點是「已部署的這一套」，不是通用 HA 教學。

## Infra
- Home Assistant 跑在 k3s 裡（非 HAOS，不能裝 add-on；`/config` 要 `kubectl exec` 進 pod 存取）
- Zigbee2MQTT 與 HA 同 cluster，MQTT discovery 已開
- Broker / Zigbee2MQTT 的 event log 可以在 k3s pod log 看

## Devices
- Dual-key Zigbee 按鈕（device_id `db23892bd2cedf0a6d91a23bb280b51a`）
  - `double_left` → 客廳循環
  - `double_right` → 臥室循環
- 六顆燈 × 兩房，以 ring group 分層（見 [[light-cycle]]）

## Automations
- `客廳燈rotation` — 見 [[light-cycle]]
- `臥室燈rotation` — 同模板，不同 entity

## Files
- [[light-cycle]] — 燈光狀態機設計 + YAML 模板（新房間照抄改 entity）

## Open Items
- 只處理了 double-click 循環；single-click on/off、long-press 尚未規劃
- 全關狀態下雙擊無反應（有 `light.<room> is on` guard），是否要加「全關 → 全開」尚未決定

## Promotion Rule
- 當流程脫離「我家這套硬體」（例如整理成通用 HA 多段燈光循環設計），改放 `04_playbooks/life/`
- 若抽出 Zigbee group 分層原則成通用筆記，放 `03_notes/`

## Related
- [[../../01_hubs/life]]
- [[../INDEX]]