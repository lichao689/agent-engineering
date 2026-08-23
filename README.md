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

## 技能

- [`code-simplifier`](./skills/workflow/code-simplifier/SKILL.md)：对最近改动过的代码做行为不变的简化与清理，去掉多余防卫、明显废话注释和不必要抽象，并对齐仓库规范。
- [`rules-curator`](./skills/workflow/rules-curator/SKILL.md)：在写入根级 agent 规则文件前，整理和判断哪些规则值得长期保留。
- [`setup`](./skills/setup/SKILL.md)：安装、检查和修复这个技能包在 Codex 与 Claude Code 中的配置。
- [`autoreview`](./skills/external/autoreview/SKILL.md)：来自 [`openclaw/agent-skills`](https://github.com/openclaw/agent-skills/tree/main/skills/autoreview) 的提交前结构化代码审查技能。

## 脚本

```bash
./scripts/list-skills.sh
./scripts/link-skills.sh --target codex
```

`link-skills.sh` 默认会为 Codex 复制技能目录，为 Claude 创建链接。已有的非链接技能目录不会被删除，而是移动到带时间戳的备份目录。

## 外部技能同步

`autoreview` 每天由 GitHub Actions 检查一次上游更新。检测到变化后，工作流会同步完整技能目录、上游许可证和目录 tree 哈希，更新专用分支 `automation/sync-autoreview`，并自动创建或刷新合并到 `main` 的 PR。也可以在 Actions 页面手动运行 `Sync autoreview skill`。
