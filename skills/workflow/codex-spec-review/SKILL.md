---
name: codex-spec-review
description: Grill 之后用本机 Codex 只读审查实施计划、spec 或 tickets。
argument-hint: "[path] [--plan | --spec | --tickets]"
disable-model-invocation: true
---

# Codex Spec Review

Grill 由主持模型写出的计划 / spec / tickets，交给没参加过那轮决策的 Codex 做第二意见。用户点名要审的文档才调用。

这是只读 `codex exec`（PROMPT 从文件进 stdin），不是 `codex exec review`。**allowlist** 是送进 PROMPT 的仓库相对路径：Codex 仍可能读仓库里其它文件；展示和后续修改只针对 allowlist 上的文档。

默认停在回报。用户写了按意见改，才进入第 6 步。

## 1. 前置检查

```powershell
Get-Command codex -ErrorAction SilentlyContinue
codex --version
```

缺失或未登录：原样报告错误，提示 `codex login`，停止。

完成：已打印版本，或已停止并报告缺失。

## 2. 目标

用户给了路径就用路径。否则本轮刚写出的计划 / spec / `.scratch/<feature>/issues/` 优先（含 plan mode 的 `plan.md`）；再否则问路径。

审查类型：用户 `--plan` / `--spec` / `--tickets` 优先。否则：

- 文件名含 `spec` / `prd` → **spec**
- 目录、`.scratch/*/issues/`、或多个 `NN-*.md` → **tickets**
- 文件名含 `plan`、实施计划、或一份未标明类型的单文档 → **plan**
- 同一 feature 下 plan + spec、spec + tickets、或三者都在 → **一次审完**
- `.scratch/<feature>/` 同时有 `plan.md`、spec、`issues/` 且用户没收窄 → 全部列入

这些路径就是 **allowlist**。把 grill 里已拍板的决策写成最多 15 条「Settled decisions」。没有则写 `none; treat the documents as source of truth`。PROMPT 只给路径和这条摘要，让 Codex 自己读文件。

完成：allowlist、审查类型、Settled decisions 摘要。

## 3. 调用

把下面模板写成 **UTF-8 无 BOM** 的 PROMPT 文件（路径一行一个）：

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
$script = Join-Path $env:USERPROFILE ".agents\skills\codex-cli-windows.ps1"
$out = Join-Path $env:TEMP ("codex-spec-review-" + [guid]::NewGuid().ToString("N").Substring(0, 8) + ".md")
$err = "$out.err.log"
& $script -Mode exec -OutPath $out -ErrPath $err -WorkingDirectory (Get-Location).Path -PromptFile $promptFile
```

用户指定了模型或 effort 再加 `-Model` / `-Effort`。

同一轮还要用 findings → 等到进程退出且 `$out` 落盘。只要审查结果 → 后台跑，结束本回合，等完成通知再读 `$out`。

PROMPT 文件为空或启动器找不到 exe：修好后再跑一次。审查已启动（已有 `$out` 或 Codex session）则沿用该次输出。

完成：进程已结束或已后台交出，且知道 `$out` / `$err` 路径。

## 4. 过滤

**findings 只读 `$out`。** `$err` 是遥测；不对整份 `$err` 做 `Select-String ERROR`。

退出码非零且 `$out` 不存在：只取 `$err` 里**最后一条**以 `error:` 开头的行。

对 `$out` 里每一条 finding 分类：

- **范围内**：指向 allowlist 中的文档，或明确写那份文档的缺口 / 矛盾
- **范围外**：只指控 allowlist 外的文件，且不回指目标文档

降级（回报里声明）：存在范围外 finding。

完成：每条 finding 已标范围内或范围外。

## 5. 回报

1. allowlist、审查类型、启动器参数、是否降级
2. 范围内 BLOCKERS / GAPS / SUMMARY（保留 path）。范围内为空 → 「范围内无 findings」
3. 对每条范围内 finding：采纳 / 不适用（简短理由）。Findings 是输入，不是裁决

用户未要求改文档则停在这里。事后删除 `$out`、`$err`、PROMPT 文件。

完成：三条都已写出；范围内每条都有判断。

## 6. 修改

仅当用户要求按 findings 改文档时进入。只改 allowlist 上、且判断为**采纳**的文件。文档-only 跑 `git diff --check`。

完成：采纳项已改；若有文档 diff，空白检查通过。
