# lichao689 Skills

个人 Codex / Claude Code 技能库。

## 安装

从 GitHub 安装：

```bash
npx skills@latest add lichao689/skills
```

也可以克隆仓库后同步本地技能：

```bash
git clone git@github.com:lichao689/skills.git ~/Developer/lichao689-skills
cd ~/Developer/lichao689-skills
./scripts/link-skills.sh --target codex
```

如果要用于 Claude Code 或同时用于两个宿主，把 `--target` 改成 `claude` 或 `all`。

如需同时安装精选版 gstack，使用：

```bash
./scripts/link-skills.sh --target codex --with-gstack
```

也可以只安装 gstack 精选技能：

```bash
./scripts/setup-gstack-subset.sh --target codex
./scripts/setup-gstack-subset.sh --target all --dry-run
```

gstack 安装需要 Git、Bun 和网络。安装器按仓库锁定的上游 commit 拉取并构建共享运行时，只向 Codex / Claude Code 暴露所选技能。首次遇到同名的非受管技能时，会先移动到技能目录内带时间戳的备份目录。

## 技能

- [`code-simplifier`](./skills/workflow/code-simplifier/SKILL.md)：对最近改动过的代码做行为不变的简化与清理，去掉多余防卫、明显废话注释和不必要抽象，并对齐仓库规范。
- [`rules-curator`](./skills/workflow/rules-curator/SKILL.md)：在写入根级 agent 规则文件前，整理和判断哪些规则值得长期保留。
- [`setup`](./skills/setup/SKILL.md)：安装、检查和修复这个技能包在 Codex 与 Claude Code 中的配置。
- [`autoreview`](./skills/external/autoreview/SKILL.md)：来自 [`openclaw/agent-skills`](https://github.com/openclaw/agent-skills/tree/main/skills/autoreview) 的提交前结构化代码审查技能。
- [`browser-harness`](./skills/external/browser-harness/SKILL.md)：来自 [`browser-use/browser-harness`](https://github.com/browser-use/browser-harness) 的浏览器自动化技能，通过 CDP 直接控制本地 Chrome。快照只包含技能文档；使用前需一次性安装 `browser-harness` CLI（见上游 [install.md](https://github.com/browser-use/browser-harness/blob/main/install.md)）。

### gstack 精选技能

本仓库保存 [`garrytan/gstack`](https://github.com/garrytan/gstack) 的 Claude/Codex 可审查快照，并提供共享运行时安装器。包含：`plan-eng-review`、`qa`、`browse`、`office-hours`、`plan-ceo-review`、`plan-design-review`、`design-review`、`autoplan`、`document-release`、`document-generate`、`plan-devex-review`、`devex-review`、`cso`。

这些快照位于 `external/gstack/`，不会被 `npx skills add` 当成普通独立技能安装。要让 `browse` 等共享命令可用，必须克隆本仓库并运行 `setup-gstack-subset.sh`。

## 脚本

```bash
./scripts/list-skills.sh
./scripts/link-skills.sh --target codex
./scripts/setup-gstack-subset.sh --target codex --dry-run
```

`link-skills.sh` 默认会为 Codex 复制技能目录，为 Claude 创建链接。已有的非链接技能目录不会被删除，而是移动到带时间戳的备份目录。

## 外部技能同步

`autoreview` 每天由 GitHub Actions 检查一次上游更新。检测到变化后，工作流会同步完整技能目录、上游许可证和目录 tree 哈希，更新专用分支 `automation/sync-autoreview`，并自动创建或刷新合并到 `main` 的 PR。也可以在 Actions 页面手动运行 `Sync autoreview skill`。

gstack 精选技能也每天检查一次。上游根目录 `VERSION` 变化时，`Sync curated gstack skills` 会重新生成两种宿主快照，更新 `automation/sync-gstack` 并创建或刷新 PR；工作流不会自动合并。上游同版本内发生变化时，可以手动运行工作流并勾选 `force`。同步 PR 由 GitHub Actions 和临时 `GITHUB_TOKEN` 创建，不消耗 Codex 或 Claude 模型额度。

`browser-harness` 同样每天检查一次。上游根目录 `SKILL.md` 或 `LICENSE` 变化时，`Sync browser-harness skill` 会同步字节一致的上游 blob 和 `.upstream-tree` 哈希，更新 `automation/sync-browser-harness` 并创建或刷新 PR；工作流不会自动合并，也可以在 Actions 页面手动运行。同步与本地安装的 CLI 版本无关，始终直接取自 GitHub 上游。
