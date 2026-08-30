# Agent Engineering

面向 Codex、Claude Code、Grok Build 及兼容 Coding Agent 的个人 Agent 工程资产库。这里同时维护可执行 Skills、来源可追溯的知识笔记、可复用工作手册，以及安装、同步和验证工具。

## 内容模型

| 位置 | 内容 | 是否直接执行 |
|---|---|---|
| [`skills/`](./skills/) | 可被 Agent 发现和调用的 Skills；`external/` 保存带来源与许可证的上游镜像 | 是 |
| [`knowledge/`](./knowledge/README.md) | 对文章、规范和官方文档的来源笔记，保存证据而非仓库规则 | 否 |
| [`playbooks/`](./playbooks/designing-agents-md.md) | 综合多个来源形成的跨项目实践 | 按需读取 |
| [`scripts/`](./scripts/) | 安装、同步和确定性验证工具 | 是 |

外部来源先进入 `knowledge/`，可复用结论再进入 `playbooks/`，成熟且需要自动触发的流程才进入 `skills/`。具体项目的业务规则继续留在各自仓库。

仓库名与分发包标识相互独立：仓库改名为 `agent-engineering`，现有 Claude 分发包标识暂保留为 `lichao689-skills`，避免无必要地破坏已有调用。

## 安装 Skills

从 GitHub 安装：

```bash
npx skills@latest add lichao689/agent-engineering
```

也可以克隆仓库后同步本地技能。默认装到用户级 `~/.agents/skills`（Grok Build 与 Codex 都会扫描）：

```bash
git clone git@github.com:lichao689/agent-engineering.git ~/Developer/agent-engineering
cd ~/Developer/agent-engineering
./scripts/link-skills.sh --target agents
```

如果要用于 Claude Code 或 Codex 专用目录，把 `--target` 改成 `claude`、`codex` 或 `all`。首次遇到同名的非链接技能时，会先移动到技能目录内带时间戳的备份目录。

## Agent 指令设计资料

- [GitHub 2500+ 仓库 `agents.md` 文章来源笔记](./knowledge/agent-instructions/github-agents-md-lessons-2500-repositories.md)
- [设计和维护 `AGENTS.md` 工作手册](./playbooks/designing-agents-md.md)

来源笔记记录“来源说了什么、证据在哪里、适用边界是什么”；工作手册记录跨项目可复用的设计方法。两者都不替代目标仓库自己的代码、测试与现行规则。

## Skills

- [`codex-review`](./skills/workflow/codex-review/SKILL.md)：用本机 Codex CLI 原生审核器审查 git 改动（uncommitted / base / commit / 点名路径）。
- [`codex-spec-review`](./skills/workflow/codex-spec-review/SKILL.md)：用本机 Codex CLI 只读审查 grill 之后的实施计划、spec 或 tickets；参数可省略，按路径和用语判定。
- [`code-simplifier`](./skills/workflow/code-simplifier/SKILL.md)：对最近改动过的代码做行为不变的简化与清理，去掉多余防卫、明显废话注释和不必要抽象，并对齐仓库规范。
- [`rules-curator`](./skills/workflow/rules-curator/SKILL.md)：在写入根级 Agent 规则文件前，整理和判断哪些规则值得长期保留。
- [`setup`](./skills/setup/SKILL.md)：安装、检查和修复 Skills 分发包在 `~/.agents/skills`、Codex 与 Claude Code 中的配置。
- [`autoreview`](./skills/external/autoreview/SKILL.md)：来自 [`openclaw/agent-skills`](https://github.com/openclaw/agent-skills/tree/main/skills/autoreview) 的提交前结构化代码审查 Skill。
- [`browser-harness`](./skills/external/browser-harness/SKILL.md)：来自 [`browser-use/browser-harness`](https://github.com/browser-use/browser-harness) 的浏览器自动化 Skill。使用前需一次性安装 `browser-harness` CLI，详见上游 [install.md](https://github.com/browser-use/browser-harness/blob/main/install.md)。
- [`mattpocock`](./skills/external/mattpocock/README.md)：来自 [`mattpocock/skills`](https://github.com/mattpocock/skills) 的完整镜像，当前按上游提交 `6654f6b`（2026-08-24）同步。

## 工具与验证

```bash
python scripts/validate-repository.py
./scripts/list-skills.sh
./scripts/link-skills.sh --target agents
```

`link-skills.sh` 默认会为 `agents` / Codex 复制技能目录，为 Claude 创建链接；安装时也会把 `scripts/codex-cli-windows.ps1` 复制到技能目录根，作为 Windows 上 Codex 调用入口。

## 外部 Skills 同步

`autoreview` 与 `browser-harness` 每天由 GitHub Actions 检查一次上游更新。工作流保存上游许可证和 tree/blob 身份，更新各自的 `automation/sync-*` 分支并创建或刷新 PR，不自动覆盖 `main`。

`skills/external/` 是上游镜像面，日常修改应进入同步工作流，而不是手工改写镜像内容。
