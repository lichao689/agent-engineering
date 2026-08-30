# 设计和维护 `AGENTS.md`

本手册用于新建、审查或收敛一个仓库的 Agent 常驻规则。它综合 [GitHub 2500+ 仓库文章来源笔记](../knowledge/agent-instructions/github-agents-md-lessons-2500-repositories.md)、GitHub 官方文档和真实项目实践；目标仓库的代码、测试与现行决策始终优先。

## 1. 先确定指令载体

| 内容 | 推荐载体 |
|---|---|
| 所有 Coding Agent 都要遵守的仓库常驻规则 | 根或路径内最近的 `AGENTS.md` |
| 只适用于某一客户端的常驻差异 | 该客户端的仓库指令文件，只写差异 |
| 有明确角色、工具和写入范围的专职 Agent | `.github/agents/*.md` 等 Agent profile |
| 有任务触发条件的可执行流程 | `SKILL.md` |
| 来源证据与跨来源综合方法 | knowledge / playbook |

完成：每条拟写规则只有一个权威载体，没有为了兼容而复制正文。

## 2. 建立 30 秒开工面

Agent 首次进入仓库时应能快速确定：

1. 权威顺序和读取起点；
2. 最常用的精确命令及其完成含义；
3. 主要目录与职责；
4. 当前任务可以直接做、需要确认和禁止做的事项；
5. 最小验证与完成条件。

命令优先引用稳定的 Task/package script 接口，不复制易漂移的底层展开。版本和目录能从环境低成本读取时，让 manifest 与文件树保持事实源。

完成：一个新 Agent 不需要搜索历史计划，就能选择第一批文件和最窄验证命令。

## 3. 覆盖六个核心领域

| 领域 | 应回答的问题 |
|---|---|
| Commands | 开发、检查、测试和生成分别运行什么精确命令？ |
| Testing | focused、impact、full 如何选择，什么才算证据？ |
| Structure | 入口、业务逻辑、I/O、测试与文档分别在哪里？ |
| Style | 哪些非显然约定会改变实现，哪里有真实正反例？ |
| Git | 默认分支/worktree 策略是什么，如何保护已有改动？ |
| Boundaries | Always、Ask first、Never 各包含哪些高风险行为？ |

边界优先写正向目标；只有不可替代的安全闸门才使用禁止语句。把硬边界集中放置，避免散落在多个章节。

## 4. 用示例保护高方差决策

示例应展示 Agent 容易误判、且错误代价真实存在的 seam，例如：

- API 合同从 router/schema/test 取证，而不是凭业务直觉补错误码；
- 测试断言公开响应和持久化结果，而不是私有调用顺序；
- 架构图使用产品词汇和可复现证据，而不是自动聚类编号。

通用格式、语言基础和可由 lint 自动判定的内容通常不值得占用常驻规则。跨任务示例放入对应 Skill 或 playbook，根 `AGENTS.md` 只保留触发指针。

完成：每个示例都能改变一个真实决策，并且与其规则共置。

## 5. 分层披露而不是堆积

- 所有任务都需要：内联到 `AGENTS.md`。
- 只有某类任务需要：通过清晰指针进入标准、Context 或 Skill。
- 单一外部来源：保存为 source note。
- 多来源综合后的操作方法：保存为 playbook。

不要把依赖版本清单、完整目录树、历史计划和一次性事故复盘复制进常驻上下文。指针必须同时说明目标是什么、什么任务触发读取。

完成：删去一个分支专属段落后，其他任务仍能正常开工；需要该分支的任务能通过指针可靠找到它。

## 6. 让规则可以验证和演进

至少检查：

- 文档指针目标存在；
- `task`、npm 或其他命令在真实 manifest 中存在；
- 客户端适配没有复制并覆盖共享规则；
- Skill frontmatter 与目录身份一致；
- 生成目录、外部镜像和凭据边界明确；
- 最后一次相关修改后的匹配证据通过。

新规则的准入条件是“跨任务、反复出现、会显著改变结果或风险”。一次性失误先局部修正；只有观察到重复偏差，才提升为常驻规则。定期删除已由环境、工具或代码直接表达的缓存式说明。

## 交付检查清单

- [ ] 常驻规则具有明确权威顺序和开工入口。
- [ ] 高频命令精确、可执行并说明完成含义。
- [ ] 项目结构只描述稳定职责，不缓存完整文件树。
- [ ] 测试策略区分 focused、impact 与 full。
- [ ] Git 规则保护 dirty tree 和并行改动。
- [ ] 边界按 Always / Ask first / Never 可扫描呈现。
- [ ] 示例保护高方差 seam，不重复基础教程。
- [ ] 专项内容已披露到 Skill、标准、knowledge 或 playbook。
- [ ] 客户端副本和旧命令不存在漂移。
- [ ] 有确定性检查或最小人工核对方法。

全部满足后，`AGENTS.md` 才算完成；行数短不是目标，可快速检索且每条规则仍能改变行为才是目标。

## 相关官方文档

- [GitHub：Adding repository custom instructions for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions)
- [GitHub：Copilot customization cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
- [GitHub：About custom agents](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-custom-agents)
