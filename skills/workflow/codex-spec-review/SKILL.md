---
name: codex-spec-review
description: >
  用本机 Codex CLI 只读审查 grill 之后写出的实施计划、spec 或 tickets（不是代码 diff）。
  Use when the user asks Codex to review a plan, implementation plan, spec, tickets, PRD,
  实施计划, grill 之后的计划/规格/工单, /codex-spec-review, or a second opinion on those docs.
  Do not use /codex-review (native git reviewer) or Grok /review for this.
argument-hint: "[path] [--plan | --spec | --tickets]"
disable-model-invocation: true
---

# Codex Plan / Spec / Tickets Review

Grill 由 Grok 主持，写出的计划/spec/tickets 也是 Grok。Codex 没参加过那轮决策，适合当第二意见。
**不要自动跑。** 用户点名审这份文档才调用。文档经常只是一份实施计划，不必先有 spec 或 tickets。

这不是 `codex exec review`。那条命令审 git diff。这里审文档，用只读 `codex exec`，PROMPT 从文件进 stdin。

Windows 调用**必须**走启动器 `$env:USERPROFILE\.agents\skills\codex-cli-windows.ps1`（仓库源文件 `scripts/codex-cli-windows.ps1`）。不要手写 `codex exec $PROMPT`、不要 PowerShell `< NUL`（本模式需要 stdin 读 PROMPT 文件）。

## 1. 解析目标

用户给了路径就用路径。否则：

1. 本轮刚写出的计划 / spec / `.scratch/<feature>/issues/` 优先（Grok plan mode 的 `plan.md` 也算）
2. 否则问用户要路径，不要猜整个仓库

用户 `--plan` / `--spec` / `--tickets` 优先。否则：

- 文件名含 `spec`/`prd` → **spec**
- 目录、`.scratch/*/issues/`、或多个 `NN-*.md` → **tickets**
- 文件名含 `plan`、实施计划、或一份未标明类型的单文档 → **plan**
- 同一 feature 下 plan + spec、spec + tickets、或三者都在 → **一次审完**，PROMPT 里列出全部仓库相对路径
- `.scratch/<feature>/` 同时有 `plan.md`、spec、`issues/` 且用户没收窄 → 全部列入，不要只送其中一份

把 grill 里已经拍板的决策写成最多 15 条「Settled decisions」放进 PROMPT。没有就写「none; treat the documents as source of truth」。不要把整段 grill 对话贴给 Codex。不要把文档正文嵌进 PROMPT；只给路径，让 Codex 自己读。

完成：已有路径列表、审查类型、Settled decisions 摘要。

## 2. 调用

把下面模板写成 **UTF-8 无 BOM** 的 PROMPT 文件（路径用仓库相对路径，一行一个）：

```
You are an independent reviewer. You did not write these documents and did not run the grilling session.

Read these repo-relative paths yourself (do not assume content from this prompt):
<PATHS>

Settled decisions from grilling (do not re-open these unless the document contradicts them):
<SETTLED or "none; treat the documents as source of truth">

Review as:
- plan: steps missing or in the wrong order, unbounded scope, cannot land as written, contradicts the codebase, hidden design the grill never settled, no way to prove a step is done
- spec: holes, contradictions, untestable stories, scope creep, missing out-of-scope, decisions that the codebase cannot support
- tickets: not a vertical slice, missing/wrong blockers, too big for one context window, acceptance criteria that cannot be proven, tickets that smuggle design the spec never made

Only report findings that would change whether we should implement this as written.
Do not suggest rewriting tone or adding speculative features.

Return:

BLOCKERS
Must-fix before implementation. Each: path, what's wrong, what would make it implementable.
If none: None.

GAPS
Real omissions. Each: path, gap, why it matters.
If none: None.

SUMMARY
2-3 sentences. Ship / revise first.
```

```powershell
Get-Command codex -ErrorAction SilentlyContinue
if (-not $?) { throw "codex CLI missing; run codex login after install" }

$script = Join-Path $env:USERPROFILE ".agents\skills\codex-cli-windows.ps1"
$out = Join-Path $env:TEMP ("codex-spec-review-" + [guid]::NewGuid().ToString("N").Substring(0, 8) + ".md")
$err = "$out.err.log"
& $script -Mode exec -OutPath $out -ErrPath $err -WorkingDirectory (Get-Location).Path -PromptFile $promptFile
```

- 用户指定模型/effort 才加 `-Model` / `-Effort`
- 不要 `--json`、不要 yolo、不要 `codex exec review`
- 缺失 CLI 或未登录：原样报错并停。不要改用 Grok 自己审

等待：同一轮还要用 findings（按意见改文档）→ 等到进程结束，`block_until_ms` ≥ 10 分钟。只要审查结果 → 后台跑并结束当前回合。

**调用错误**（脚本找不到 exe、PROMPT 文件为空）：修调用后再跑一次。  
**审查已启动**：禁止重试。

完成：进程已结束或已后台交出，且知道 `$out` / `$err` 路径。

## 3. 回报

读 `$out` 作为 findings。退出码非零且 `$out` 不存在：只取 `$err` 里最后一条 `error:` 行，不要全文搜 `ERROR`。

给用户：Codex 原文 findings + 你的采纳/驳回（短理由）。不要默默改文档。用户说按意见改再改。

删掉 `$out`、`$err`、PROMPT 文件。
