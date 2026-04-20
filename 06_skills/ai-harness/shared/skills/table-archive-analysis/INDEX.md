---
title: Table Archive Analysis Skill
kind: skill-index
tags:
  - sporty
  - dba
  - archive
  - table-dependency
---

# Table Archive Analysis Skill

將既有 `~/.claude/skills/table-archive-analysis` 收斂到 repo 內的單一來源。
這是一個工作專用 skill，用來分析 `afbet_patron` 表的依賴路徑與 archive
rule 風險，並產出 Jira / DBA SOP 可直接使用的報告。

## Files

- [[SKILL]] — agent 入口與使用範圍
- [[discovery-workflow]] — 查表、追呼叫鏈、整理 path object 的流程
- [[archive-evaluation]] — Q1 到 Q4 archive 判準與最終建議格式
- [[report-template]] — 最終報告骨架

## Notes

- 名稱維持 `table-archive-analysis`，避免打破既有 `~/.claude/skills/`
  的使用習慣。
- 內容實際上是 Sporty / DBA review 專用，不應視為通用 skill。

## Related

- [[../../../INDEX]]
- [[../../../../INDEX]]
