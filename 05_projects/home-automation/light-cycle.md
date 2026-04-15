---
title: Light Cycle State Machine
kind: project-note
topic: life
tags:
  - home-automation
  - home-assistant
  - zigbee
---

# Light Cycle State Machine

雙擊一顆按鈕在「全開 → 中圈+中央 → 只剩中央 → 全開」之間循環。
每個房間一份 state、一份 automation、一套 ring group。

## Group Layering（per room）

| Entity | 角色 |
|---|---|
| `light.<room>` | 全房間 group（reset 時一次開滿） |
| `light.<room>_inner_ring` | 最外圈，第一步關掉 |
| `light.<room>_inner_ring2` | 中圈，第二步關掉 |
| （中央單燈） | 剩下的那顆，不進任何 ring |

> 命名歷史包袱：`inner_ring` 實際放的是**外**圈燈、`inner_ring2` 才是中圈。沿用不改名。

## State Machine

每個房間有自己的 `input_select.<room>_light_mode`，options：`all` / `four` / `center`。

```
all  --double-click-->  four    # turn_off inner_ring
four --double-click-->  center  # turn_off inner_ring2
center --double-click-> all     # turn_on light.<room>
```

Guard：`light.<room> is on` — 房間全關時雙擊不觸發（保留給未來 single-click on/off 使用）。

## YAML Template

新房間照抄，只換：
- `alias`
- `subtype`（按鈕位置）
- 四個 `<room>` 字串
- `input_select` 名稱

```yaml
alias: <room>燈rotation
description: ""
triggers:
  - domain: mqtt
    device_id: db23892bd2cedf0a6d91a23bb280b51a
    type: action
    subtype: double_<left|right>
    trigger: device
conditions:
  - condition: state
    entity_id: light.<room>
    state:
      - "on"
actions:
  - choose:
      - conditions:
          - condition: state
            entity_id: input_select.<room>_light_mode
            state: all
        sequence:
          - action: light.turn_off
            target:
              entity_id: light.<room>_inner_ring
          - action: input_select.select_option
            target:
              entity_id: input_select.<room>_light_mode
            data:
              option: four

      - conditions:
          - condition: state
            entity_id: input_select.<room>_light_mode
            state: four
        sequence:
          - action: light.turn_off
            target:
              entity_id: light.<room>_inner_ring2
          - action: input_select.select_option
            target:
              entity_id: input_select.<room>_light_mode
            data:
              option: center

      - conditions:
          - condition: state
            entity_id: input_select.<room>_light_mode
            state: center
        sequence:
          - action: light.turn_on
            target:
              entity_id: light.<room>
          - action: input_select.select_option
            target:
              entity_id: input_select.<room>_light_mode
            data:
              option: all
    default:
      - action: light.turn_on
        target:
          entity_id: light.<room>
      - action: input_select.select_option
        target:
          entity_id: input_select.<room>_light_mode
        data:
          option: all
mode: single
```

## 設計理由

- **漸進式 `turn_off` 而不是「全關再開子集」**：只送一條 Zigbee multicast，比「全關+指定開」少一次延遲，肉眼不會看到閃爍。
- **reset 用 `turn_on light.<room>`**：回到 all 時所有燈一次亮起，即使中間有人手動開關過個別燈，也會被拉回一致狀態。
- **per-room input_select**：早期版本兩個 automation 共用 `input_select.light_mode`，切了客廳再切臥室會讀錯狀態，已拆開。
- **`default:` 分支**：input_select 若是初始未設或被手動改到奇怪值，強制回 all，避免卡死。

## 已知限制

- 雙擊是唯一入口。全關狀態下沒有反應，要配 single-click on/off 才完整。
- 若手動（app / 語音）個別開關燈，狀態機不會同步，要等一次 reset（循環到 all）才會對齊。

## Related
- [[INDEX]]