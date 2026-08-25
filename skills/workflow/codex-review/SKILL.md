---
name: codex-review
description: >
  用本机 OpenAI Codex CLI 的原生审核器审查当前改动（uncommitted、相对 base 分支、指定 commit、或点名路径）。
  Use when the user asks for Codex review, /codex-review, /codex:review, 让 Codex 审代码,
  跨模型第二意见, adversarial review, or a second opinion on the working tree / branch / commit.
  Do not use Grok's built-in /review for these requests.
argument-hint: "[--uncommitted | --base <ref> | --commit <sha>] [--adversarial] [paths|focus]"
---

# Codex Review

把改动交给本机 Codex 的**原生审核器**（`codex exec review`），不是 Grok `/review`，也不是 `codex exec "请 review 这段代码"`。

只读。默认不改文件、不进入 review→fix 循环。用户明确要求按 findings 修时才修。

Windows 调用**必须**走启动器 `$env:USERPROFILE\.agents\skills\codex-cli-windows.ps1`（仓库源文件 `scripts/codex-cli-windows.ps1`）。不要手写 `codex exec`、不要 PowerShell `< NUL`、不要 `Start-Process -ArgumentList` 传带空格的 PROMPT。

## 1. 前置检查

```powershell
Get-Command codex -ErrorAction SilentlyContinue
codex --version
```

缺失或未登录：原样报告错误，提示 `codex login`，**停止**。不要改用 Grok `/review` 顶替。

完成：已打印版本，或已停止并报告缺失。

## 2. 解析范围

从用户输入取出（`--uncommitted` / `--base` / `--commit` 三者互斥）：

| 输入 | 范围 |
|---|---|
| `--uncommitted` | staged + unstaged + untracked（整棵脏树） |
| `--base <ref>` | 相对该 base 的分支 diff |
| `--commit <sha>` | 该 commit 引入的改动 |
| 点名路径、「本对话改的代码」、本任务拥有文件 | git 范围仍按下面自动目标；另建 **FOCUS_PATHS** allowlist |
| `--adversarial` 或剩余焦点文本 | 写入 PROMPT 文件，不是 argv |
| `--model` / `--effort` | 透传到脚本；用户没说则用 Codex 默认 |

自动目标（用户没给三者之一时）：

```powershell
git status --porcelain
```

1. 用户给了 FOCUS_PATHS → git 范围用 `--uncommitted`（工作区脏）或 `--base <default>`（干净但在功能分支）；审查后**只向用户展示命中 FOCUS_PATHS 的 findings**。
2. 工作区脏、没有 FOCUS_PATHS、且 porcelain 行数 **> 8** → **先问**审整棵脏树还是列出文件。停到用户回答。不要调用 Codex。
3. 工作区脏、porcelain ≤ 8 → `--uncommitted`。
4. 干净且不在默认分支（`origin/main`，否则 `origin/master`，否则本地 `main`/`master`）→ `--base <default>`。
5. 已在默认分支且干净 → 打印「没有可审的改动」，不要调用 Codex，不要用 `HEAD~N` 凑目标。

完成：已确定唯一 git 范围，以及可选的 FOCUS_PATHS。

## 3. 调用

把对抗焦点和 FOCUS_PATHS 写成 **UTF-8 无 BOM** 的 PROMPT 文件。不要把 diff 嵌进 PROMPT。原生审核器自己看 git。

对抗式开头（可再追加用户焦点）：

```
Challenge the implementation and design. Only report issues that would change a merge decision. Prioritize expensive attack surfaces: correctness, data loss, rollback, races, auth.
```

有 FOCUS_PATHS 时追加：只审这些路径；其他脏文件忽略。

```powershell
$script = Join-Path $env:USERPROFILE ".agents\skills\codex-cli-windows.ps1"
$out = Join-Path $env:TEMP ("codex-review-" + [guid]::NewGuid().ToString("N").Substring(0, 8) + ".md")
$err = "$out.err.log"
# 按范围选 -Uncommitted 或 -Base 或 -Commit；有 PROMPT 文件才传 -PromptFile
& $script -Mode review -OutPath $out -ErrPath $err -WorkingDirectory (Get-Location).Path -Uncommitted -PromptFile $promptFile
```

约束：

- 只通过该脚本调用。脚本在 0.149.x 等把 scope 与 PROMPT 判成互斥时，会**自动丢掉 PROMPT 再跑一次**；此时必须按 FOCUS_PATHS 过滤 findings，并在回报里写明发生了降级。
- 只读：脚本已固定 `sandbox_mode="read-only"` 与 `--ephemeral`。不要 `--full-auto`、不要 yolo、不要 `--json`、不要 `--last`。
- 审查正文只读 `$out`。
- 用户指定模型才加 `-Model`；effort 才加 `-Effort`。
- 顶层 `codex review` 不能带 `-m`，不要默认走它。脚本已失败且 stderr 表明二进制不认识 `exec review` 时，才允许再试一次同范围的顶层 `codex review`。仍失败则停。不要退回 `codex exec "Review this diff"`。

等待：

- 同一轮还要用 findings（提交、按意见修、继续实现）→ **等到进程结束**。`block_until_ms` ≥ `min(20, 10 + 0.5 * porcelain行数)` 分钟。
- 本轮只要审查结果 → 后台跑，结束当前回合，等完成通知后再读 `$out`。

**调用错误**（stdin/参数/互斥 flag、脚本抛「CLI missing」）：按脚本的一次降级处理；不要换配方连打。  
**审查已启动**（已有 `$out` 或 Codex session 已开始）：禁止重试。

完成：进程已结束（或已后台交出去），且知道 `$out` / `$err` 路径。

## 4. 回报

读 `$out` 作为 findings。

退出码非零且 `$out` 不存在：只取 `$err` 里**最后一条**以 `error:` 开头的行（忽略 websocket、skill 全文、git dump）。不要对整份 `$err` 做 `Select-String ERROR`。

向用户输出：

1. 目标（uncommitted / base / commit）、FOCUS_PATHS、是否发生 scope+PROMPT 降级、实际调用（脚本参数即可）
2. Codex 原文 findings（可轻度整理，不丢文件:行）。有 FOCUS_PATHS 时只列命中 allowlist 的条目；若降级后原文全是范围外文件，写明「范围内无 findings」
3. 你的判断：采纳 / 不适用（简短理由）。Findings 是输入，不是裁决
4. 不要默默按 review 改代码。用户说「按 Codex 的意见修」再修

事后删除 `$out`、`$err`、PROMPT 文件。
