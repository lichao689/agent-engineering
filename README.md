# lichao689 Skills

个人 Codex / Claude Code / Grok Build 技能库。

## 安装

从 GitHub 安装：

```bash
npx skills@latest add lichao689/skills
```

也可以克隆仓库后同步本地技能。默认装到用户级 `~/.agents/skills`（Grok Build 与 Codex 都会扫描）：

```bash
git clone git@github.com:lichao689/skills.git ~/Developer/lichao689-skills
cd ~/Developer/lichao689-skills
./scripts/link-skills.sh --target agents
```

如果要用于 Claude Code 或 Codex 专用目录，把 `--target` 改成 `claude`、`codex` 或 `all`。

首次遇到同名的非链接技能时，会先移动到技能目录内带时间戳的备份目录。

## 技能

- [`codex-review`](./skills/workflow/codex-review/SKILL.md)：用本机 Codex CLI 原生审核器审查 git 改动（uncommitted / base / commit / 点名路径）。
- [`codex-spec-review`](./skills/workflow/codex-spec-review/SKILL.md)：用本机 Codex CLI 只读审查 grill 之后的实施计划、spec 或 tickets；参数可省略，按路径和用语判定。
- [`code-simplifier`](./skills/workflow/code-simplifier/SKILL.md)：对最近改动过的代码做行为不变的简化与清理，去掉多余防卫、明显废话注释和不必要抽象，并对齐仓库规范。
- [`rules-curator`](./skills/workflow/rules-curator/SKILL.md)：在写入根级 agent 规则文件前，整理和判断哪些规则值得长期保留。
- [`setup`](./skills/setup/SKILL.md)：安装、检查和修复这个技能包在 `~/.agents/skills`、Codex 与 Claude Code 中的配置。
- [`autoreview`](./skills/external/autoreview/SKILL.md)：来自 [`openclaw/agent-skills`](https://github.com/openclaw/agent-skills/tree/main/skills/autoreview) 的提交前结构化代码审查技能。
- [`browser-harness`](./skills/external/browser-harness/SKILL.md)：来自 [`browser-use/browser-harness`](https://github.com/browser-use/browser-harness) 的浏览器自动化技能，通过 CDP 直接控制本地 Chrome。快照只包含技能文档；使用前需一次性安装 `browser-harness` CLI（见上游 [install.md](https://github.com/browser-use/browser-harness/blob/main/install.md)）。

## 脚本

```bash
./scripts/list-skills.sh
./scripts/link-skills.sh --target agents
```

`link-skills.sh` 默认会为 `agents` / Codex 复制技能目录，为 Claude 创建链接。已有的非链接技能目录不会被删除，而是移动到带时间戳的备份目录。安装时也会把 `scripts/codex-cli-windows.ps1` 复制到技能目录根，作为 Windows 上 Codex 调用入口。

## 外部技能同步

`autoreview` 每天由 GitHub Actions 检查一次上游更新。检测到变化后，工作流会同步完整技能目录、上游许可证和目录 tree 哈希，更新专用分支 `automation/sync-autoreview`，并自动创建或刷新合并到 `main` 的 PR。也可以在 Actions 页面手动运行 `Sync autoreview skill`。

`browser-harness` 同样每天检查一次。上游根目录 `SKILL.md` 或 `LICENSE` 变化时，`Sync browser-harness skill` 会同步字节一致的上游 blob 和 `.upstream-tree` 哈希，更新 `automation/sync-browser-harness` 并创建或刷新 PR；工作流不会自动合并，也可以在 Actions 页面手动运行。同步与本地安装的 CLI 版本无关，始终直接取自 GitHub 上游。
