# 项目记忆系统

这套记忆不是聊天记录，而是**可检索的决策与上下文索引**。核心思路和 skill 一样：
常驻一个小索引，主题文件按需加载，避免每次把全部历史塞进上下文。

## 结构

```
docs/memory/
├─ MEMORY.md              # 工作室常驻索引（≤8 KB）
├─ decisions/             # ADR：已定型的架构/设计决策
├─ sessions/              # 每个大任务的阶段总结
├─ glossary.md            # 术语表
├─ open-questions.md      # 未定问题
└─ games/<slug>/          # 也可放在 games/<slug>/docs/memory/
   ├─ MEMORY.md           # 游戏常驻索引
   ├─ systems/            # 战斗、道具、关卡、叙事等系统记忆
   ├─ decisions/          # 游戏级 ADR
   └─ sessions/           # 游戏级阶段总结
```

## 文件格式

```yaml
---
name: short-kebab-case
description: one-line summary used for recall
type: studio | system | content | decision | session | reference
status: active | superseded | archived
updated: YYYY-MM-DD
load_when: when this file is relevant
---
```

一个文件只放一件事或一个决策。互相关联的文件用相对链接连起来。

## 读取规则

1. 先读 `docs/memory/MEMORY.md`。
2. 做某款游戏时，再读 `games/<slug>/docs/memory/MEMORY.md`。
3. 只加载 `load_when` 与当前任务匹配的文件，不要整棵记忆树全读。
4. 记忆与 GDD/ADR 冲突时，以 GDD/ADR 为准。

## 写入规则

- 新增记忆后，在索引里加一行：摘要 + 何时加载。
- 索引控制在 8 KB 以内；过时内容归档，不要无限增长。
- 稳定的设计/架构决策写成 ADR，放入 `decisions/`，并从索引链接。
- **每完成一次大任务或里程碑，必须写一份 session 总结并更新索引。**
- 设计决策改变玩法时，先更新 GDD，再更新记忆；记忆只做指针，不复制 GDD。
- 不存密钥、账号、大段日志。

## 大任务检查清单

- [ ] 写了 `sessions/YYYY-MM-DD-<topic>.md`
- [ ] 更新了索引
- [ ] 稳定决策已升 ADR
- [ ] 链接有效，过时条目已归档
- [ ] 没有密钥/大日志

## 与 GDD 的关系

GDD 是玩法和范围的唯一事实来源；记忆负责“我们为什么这么定、去哪里找细节”。
每款游戏的 GDD 在 `games/<slug>/docs/GDD.md`，游戏记忆索引必须链接它。
