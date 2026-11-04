# 2026-11-04 · T17 吞噬/归档权柄、信任分层、结局画廊

> 第 25 程。三项 T17 内容扩展落地；第一章内容与核心框架未改，章节 2–4 仍不可达。

## 吞噬 / 归档权柄

- 数据：`AuthorityData` 新增 `unlock_condition`（`corruption` / `records` / `profile_records`）与
  `unlock_threshold`；`archive.tres` 记录 ≥ 2、`devour.tres` 污染 ≥ 40 才进入 Boss 权柄池。
- 池：`AuthorityController.build_pool` 保留作者顺序，再追加满足条件的权柄并去重；四选项页改为
  2 列网格（`AuthorityChoiceUI`），避免 4 张卡横向挤爆。
- 吞噬：`AuthorityController.damage_multiplier` = `1 + 污染 × 0.006`（上限 1.6），每帧同时写入
  近战/远程武器倍率与短语 `damage_scale`；HUD 标为「可用」而非已消耗。
- 归档：最终死亡先提交死亡（`_death_committed`、删除局内检查点），再弹出一次物品选择；选择会
  暂停树、吞掉 Start/B，HUD 立即隐藏。武器替换起始武器，遗物进下一局背包并加污染；两个初始
  武器不出现在候选里。`Profile.archived_item` 只存 `kind/id`，旧档缺键为空。
- 兼容：`RunSave` 的 `archive_used` 可选，旧检查点仍可读；`Profile` 的 `archived_item` 经过
  类型与白名单校验，坏值丢弃。

## 信任分层

- `TrustData`（新）从 `Profile.npc_trust` 的原始 float 派生 4 档：
  陌生 0 / 熟悉 2 / 信任 6 / 托付 12。**不新增存档键**，旧档天然落在陌生。
- 收益：
  - 对话：每 NPC 每档一句 `trust_lines`，`talk_to_npc` 插在问候后；离线 `NPCProfiles.resolve`
    在熟悉以上附加同档态度句并把 mood 调暖；AI system prompt 由 Hub 注入当前档位与态度。
  - 折扣：咕噜商店、阿砚锻造取 `max(既有祝福, 档位折扣)`，档位折扣 0/5/10/15%，不叠加。
  - 锻造祝福：阿砚托付时每次回 Hub 第一次锻造免费（`_trust_forge_used` 每次 Hub 重建重置）；
    与既有 `forge_free` 祝福互斥消耗，不会一次升级吃掉两份。
  - 起始资源：新局按每 NPC 档位加残页（0/1/3/6），与言灵起始页共用 20 页上限。
- AI 仍默认关闭；配置后失败静默回退离线结果，且每次回 Hub 每个 NPC 只结算一次，不双叠。

## 结局画廊

- `CampaignData.ENDINGS` 成为五个结局（复原/焚毁档案/深渊回响/未完的注脚/记录中断）的唯一
  来源，顺序按 GDD §12.2；`ending_for` 只做 id 选择。
- `EndingGalleryUI`（新）只读 `Profile.endings` 的字符串 id：已解锁显示标题与正文，未解锁显示
  「？？？」与「尚未记录」占位；旧档里的未知 id 保留在存档但不展示。
- 标题页新增「结局画廊」按钮；A 打开、B 关闭并把焦点还给按钮，画廊 `PROCESS_MODE_ALWAYS`，
  标题暂停时仍可操作。

## 验证

- 单元 **5645 / 0**（新增 `test_archive_authority`、`test_trust_tiers`、`test_ending_gallery`）。
- 八套集成全部 0 失败；具体数字以 `SUPERVISOR_STATUS.md` 第 25 程日志为准。
- `--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏与像素资产检查见状态文件。
