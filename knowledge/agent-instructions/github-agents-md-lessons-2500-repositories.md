---
title: "How to write a great agents.md: Lessons from over 2,500 repositories"
source_url: "https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/"
author: "Matt Nigh"
published: "2025-11-19"
updated: "2025-11-25"
checked: "2026-08-31"
status: source-note
---

# GitHub 博客：如何写好 Agent 指令

## 记录定位

本文是对 GitHub 博客文章 [*How to write a great agents.md: Lessons from over 2,500 repositories*](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/) 的中文来源笔记，并用 GitHub 当前官方文档核对相关产品概念。它保存“来源说了什么、哪些结论仍成立、哪些术语需要谨慎解释”，不是文章全文翻译，也不是所有仓库必须照搬的规范。

## 来源元数据

- 原始文章：[How to write a great agents.md: Lessons from over 2,500 repositories](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- 作者：[Matt Nigh](https://github.blog/author/matt-nigh/)
- 发布日期：2025-11-19；更新日期：2025-11-25。日期以[文章页眉](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)为准。
- 本笔记核对日期：2026-08-31。

## 文章的主要观察

1. **为 Agent 指定具体工作，而不是泛化人设。** 文章认为有效配置通常说明角色、技术能力、任务、输出和禁止事项；“通用助手”式描述提供的可执行信息太少。[原文：实践观察与示例](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
2. **把高频、可直接执行的命令放在前面。** 命令应包含真实入口、参数或常用选项，并说明它验证什么；只写工具名不能帮助 Agent 稳定完成构建和测试。[原文：Put commands early](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
3. **用真实示例表达风格。** 一段来自当前代码库的代表性正例，通常比抽象描述更容易执行；示例应保持短小并有明确适用范围。[原文：Code examples over explanations](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
4. **明确边界。** 文章把规则分为 Always、Ask first、Never，并建议点名密钥、供应商目录、生产配置等高风险对象。[原文：示例中的三级边界](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#example-of-a-great-agentmd-file)
5. **给出具体项目上下文。** 技术栈、主要版本、目录职责和读写位置都应具体到 Agent 能据此选择入口；但精确版本仍应由依赖清单等事实源维护，避免指令副本漂移。[原文：Be specific about your stack](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
6. **覆盖六个核心领域。** 文章归纳为命令、测试、项目结构、代码风格、Git 工作流和边界。[原文：Cover six core areas](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
7. **从窄任务开始并持续迭代。** 先为一个明确任务建立最小配置，再根据实际失误补充；不主张一次性设计一个包办所有工作的 Agent。[原文：How to build your first agent](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#how-to-build-your-first-agent)

## 用当前 GitHub 文档校准术语和边界

### `AGENTS.md` 是共享 Agent 指令

GitHub 当前把 `AGENTS.md` 列为仓库 Agent 指令：仓库中可以有多个，处理文件时由目录树中最近的 `AGENTS.md` 优先。它与仓库级 `.github/copilot-instructions.md`、路径级 `.github/instructions/**/*.instructions.md` 属于不同的指令入口。[GitHub Docs：添加仓库自定义指令](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions)

因此，本文中关于“命令、测试、结构、风格、Git 和边界”的经验可以用于设计根 `AGENTS.md`；但在子目录增加同名文件会改变适用范围和优先关系，不能只把根文件机械拆分。[GitHub Docs：最近的 `AGENTS.md` 优先](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions)

### 自定义 Agent Profile 是另一种资产

GitHub 当前的自定义 Agent 是带 YAML frontmatter 的 Markdown Profile。仓库级 Profile 通常位于 `.github/agents/`，当前创建流程使用描述性文件名和 `.agent.md` 扩展名；`description` 为必填项，还可声明 `tools`、`model`、调用方式和 MCP 配置。[GitHub Docs：创建自定义 Agent](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/create-custom-agents) [GitHub Docs：Profile 配置参考](https://docs.github.com/en/copilot/reference/custom-agents-configuration)

这意味着原文把自定义 Agent 描述成“定义在 `agents.md` 文件中的 persona”，应按其发表时的产品语境阅读。今天设计仓库时，应先判断目标是所有任务共享的 `AGENTS.md`，还是只承担特定角色的 `.github/agents/*.agent.md`，不要只依据相似文件名把二者混为一谈。[GitHub Docs：About custom agents](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-custom-agents)

### Agent Skills 是按需加载的可复用工作流

Agent Skill 是包含 `SKILL.md`，并可附带脚本、示例和资源的目录；Copilot 根据用户请求和 Skill 描述决定何时加载。GitHub 支持仓库级 Skill 和个人级 Skill。[GitHub Docs：About agent skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)

GitHub 的归口建议是：几乎每项任务都需要的简短规则放入自定义指令，更详细、只在相关任务出现时才需要的流程放入 Skill。这为“根指令保持短而稳定、重工作流按需展开”提供了官方依据。[GitHub Docs：Skills versus custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills#skills-versus-custom-instructions)

### 指令优先级依产品表面而异

GitHub.com 的响应定制文档给出的顺序是：个人指令优先，其次是仓库指令；仓库内部依次为路径级、`.github/copilot-instructions.md`、Agent 指令，最后是组织指令。官方同时建议避免互相冲突。[GitHub Docs：Precedence of custom instructions](https://docs.github.com/en/copilot/concepts/prompting/response-customization#precedence-of-custom-instructions)

但 Copilot CLI 文档明确说，多份适用指令会被组合，且不定义这些文件之间的通用优先级。因此不能把 GitHub.com 的顺序推广成所有客户端的统一规则；跨客户端仓库更应维护一个事实正文，并让适配入口引用它而不是复制内容。[GitHub Docs：Copilot CLI 中多份指令的交互](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions#how-multiple-instruction-files-interact)

不同 Copilot 功能和 IDE 对 `AGENTS.md`、路径指令及仓库级指令的支持也不完全相同，设计前应核对目标客户端，而不是假定所有入口都会加载。[GitHub Docs：自定义指令支持矩阵](https://docs.github.com/en/copilot/reference/custom-instructions-support)

## 与仓库改名相关的维护事实

- GitHub 仓库改名后，网页访问以及指向旧地址的 `git clone`、`git fetch`、`git push` 通常会重定向，但官方仍建议立即更新本地 `origin`，以减少混淆。[GitHub Docs：Renaming a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository)
- 旧仓库名不要被重新占用，否则旧地址重定向会失效。[GitHub Docs：旧名称警告](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository#renaming-a-repository)
- GitHub 不会重定向引用改名仓库中 GitHub Action 的 `uses:` 调用；若仓库发布 Action，不能把普通仓库改名重定向当成兼容方案。[GitHub Docs：Action 例外](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository#renaming-a-repository)
- GitHub Pages 的项目站点 URL 是改名迁移的例外，官方建议使用自定义域名降低影响。[GitHub Docs：Pages 注意事项](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository#renaming-a-repository)

## 文章的适用边界与局限性

- 这是 GitHub 员工基于公开仓库的实践性博客，不是带有可复现数据集、评分标准、对照实验和统计结果的研究论文。文章没有公开“成功”“最佳表现”的量化定义，因此其结论适合作为启发式检查项，而非因果定律。[原始文章](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- 原文重点是专职自定义 Agent，不能直接推导出“每个仓库都应创建六个 Agent”。是否创建 Profile 应由反复出现的独立职责、上下文隔离收益和工具边界决定。[原文：Six agents worth building](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#six-agents-worth-building) [GitHub Docs：自定义 Agent 的当前定位](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-custom-agents)
- “给出具体版本”与“避免事实漂移”需要平衡：指令可写稳定的技术身份，但精确版本最好链接到锁文件、manifest 或生成源，而不是复制一份会过期的清单。这是工程化补充，不是原文给出的结论。
- 自定义指令是给非确定性模型的上下文，不是安全沙箱或策略引擎；即使写了 Never，也仍需权限控制、分支保护、CI 和确定性检查。[GitHub Docs：自定义指令可能不会每次完全一致地执行](https://docs.github.com/en/copilot/concepts/prompting/response-customization)
- GitHub 产品和文件约定会继续演进；复用本笔记时，应以顶部 `checked` 日期判断是否需要重新核对官方文档。

## WAVER 本次实践形成的衍生经验

以下是把文章原则应用到复杂、多客户端工程仓库后得到的工程化补充，不冒充原文结论：

1. **共享正文保持单一事实源。** 根 `AGENTS.md` 保存跨任务常驻规则；客户端适配文件只导入或指向正文，不复制一份近似摘要。这样可降低多个入口组合且优先级不一致时的漂移风险。[GitHub Docs：Copilot CLI 会组合多份指令](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions#how-multiple-instruction-files-interact)
2. **把“30 秒开工卡”置顶。** 高频命令同时写明使用场景与完成含义，尤其区分 focused 测试、影响验证、格式检查和全量测试；这把原文“命令前置”转化为可验证入口。[原文：Put commands early](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
3. **边界按授权等级编排。** Always、Ask first、Never 不只是视觉分组，还分别对应默认动作、需要新授权的外部状态变化和不可接受行为。[原文：三级边界示例](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#example-of-a-great-agentmd-file)
4. **目录地图只保留稳定路由。** 根指令说明主要目录的职责和第一入口，细节转到项目标准、领域上下文和源代码；精确依赖版本链接权威 manifest。
5. **按需细节进入 Skills。** 测试证据、API 文档、架构图等具有明确触发条件的流程放入 Skill，并在其中保存短小正反例，避免根指令承担所有教程。[GitHub Docs：Skills versus custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills#skills-versus-custom-instructions)
6. **对指令本身做确定性检查。** 检查命令是否真实存在、链接是否可解析、Skill frontmatter 是否有效、禁止的重复入口是否重新出现。自然语言约束仍由 CI 或脚本验证可机器判断的部分。[GitHub Docs：模型遵循指令具有非确定性](https://docs.github.com/en/copilot/concepts/prompting/response-customization)
7. **建立规则准入标准。** 跨任务、反复出现且高风险的约束进入根指令；有明确触发条件的工作流进入 Skill；持久领域合同进入项目标准；可执行行为进入任务脚本；一次性事故先记录证据，不立即扩张常驻上下文。

## 可复用的 `AGENTS.md` 设计检查清单

- [ ] **目标和作用域：** 这是所有任务共享的 `AGENTS.md`、路径专属指令、专职 Agent Profile，还是按需 Skill？先选对资产类型。[GitHub Docs：仓库指令类型](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions) [GitHub Docs：Skills 与指令](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills#skills-versus-custom-instructions)
- [ ] **权威顺序：** 是否说明用户请求、最近的嵌套指令、项目事实源、代码与测试之间的关系，并避免不同文件出现冲突？[GitHub Docs：最近的 `AGENTS.md`](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions) [GitHub Docs：避免冲突](https://docs.github.com/en/copilot/concepts/prompting/response-customization#precedence-of-custom-instructions)
- [ ] **开工命令：** 构建、focused 测试、影响验证、lint、格式和生成命令是否真实可执行，并说明参数与通过含义？[原文：Put commands early](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
- [ ] **测试策略：** 是否告诉 Agent 何时跑最窄证据、何时升级影响范围、何时才跑全量，以及测试文件应放在哪里？[原文：六个核心领域](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
- [ ] **目录路由：** 是否给出主要模块的职责、权威入口和允许读写的位置，而不是复制完整目录树？[原文：Project knowledge](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#example-of-a-great-agentmd-file)
- [ ] **技术事实：** 稳定技术栈是否明确；容易变化的版本、命令和配置是否链接到 manifest、Taskfile 或其他单一事实源？[原文：Be specific about your stack](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
- [ ] **代码风格：** 是否引用当前 canonical 实现，或在按需 Skill 中提供一个最小正例与一个有解释的反例？[原文：Code examples over explanations](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#what-works-in-practice-lessons-from-2500-repos)
- [ ] **Git 与并行修改：** 是否说明分支策略、dirty tree、允许提交的文件、并行写入和禁止的破坏性命令？[原文：六个核心领域含 Git workflow](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#key-takeaways)
- [ ] **授权边界：** Always、Ask first、Never 是否可区分；密钥、生产环境、部署、依赖、数据库、生成目录等风险是否点名？[原文：三级边界](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#example-of-a-great-agentmd-file)
- [ ] **客户端差异：** 目标客户端是否支持所选指令类型；是否避免依赖一个被误认为“全平台通用”的优先级？[GitHub Docs：支持矩阵](https://docs.github.com/en/copilot/reference/custom-instructions-support) [GitHub Docs：CLI 不定义通用优先级](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions#how-multiple-instruction-files-interact)
- [ ] **确定性护栏：** 能由脚本、权限、CI 或分支保护验证的规则，是否从纯自然语言升级成机器检查？[GitHub Docs：指令遵循具有非确定性](https://docs.github.com/en/copilot/concepts/prompting/response-customization)
- [ ] **迭代与维护：** 是否从当前反复发生的问题出发；是否有所有者、复核日期和删除过时规则的机制？[原文：Start simple, test, iterate](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/#key-takeaways)

## 主要来源

- [Matt Nigh, *How to write a great agents.md: Lessons from over 2,500 repositories*](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [GitHub Docs, Adding repository custom instructions for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions)
- [GitHub Docs, Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [GitHub Docs, About agent skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [GitHub Docs, Adding agent skills for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
- [GitHub Docs, About customizing GitHub Copilot responses](https://docs.github.com/en/copilot/concepts/prompting/response-customization)
- [GitHub Docs, Adding custom instructions for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)
- [GitHub Docs, Renaming a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository)
