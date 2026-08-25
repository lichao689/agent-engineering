---
name: codex-review
description: >
  Native Codex CLI reviewer (`codex exec review`) for uncommitted changes, a
  base-branch diff, a named commit, or an allowlist of paths. Triggers:
  /codex-review, /codex:review, Codex review, 让 Codex 审代码, adversarial
  review, second opinion on the working tree or a commit.
argument-hint: "[--uncommitted | --base <ref> | --commit <sha>] [--adversarial] [paths]"
---

# Codex Review

把改动交给本机 Codex 的**原生审核器**（启动器里的 `codex exec review`）。

**allowlist** 是报告契约，不是 Codex 的输入范围：`--uncommitted` 始终把整棵脏树交给审核器；有 allowlist 时只展示、只修改命中路径的 findings。脏树大于 allowlist 时，范围外误报是预期输出。

默认停在回报。用户写了修 / 按意见改 / 提交，才进入第 6 步。

## 1. 前置检查

```powershell
Get-Command codex -ErrorAction SilentlyContinue
codex --version
```

缺失或未登录：原样报告错误，提示 `codex login`，停止。

完成：已打印版本，或已停止并报告缺失。

## 2. 范围

从用户输入取出唯一 git 范围（三者互斥）：

| 输入 | git 范围 |
|---|---|
| `--uncommitted` | staged + unstaged + untracked（整棵脏树） |
| `--base <ref>` | 相对该 base 的分支 diff |
| `--commit <sha>` | 该 commit 引入的改动 |

点名路径、「本对话改的代码」、本任务拥有文件 → 另建 **allowlist**。`--adversarial` 与剩余焦点写入 PROMPT 文件。`--model` / `--effort` 仅在用户指定时传给启动器。

用户没给三者之一时：

```powershell
git status --porcelain
```

1. 有 allowlist → 脏则 `--uncommitted`，干净且在功能分支则 `--base <default>`。
2. 脏、无 allowlist、porcelain **> 8** → 先问审整棵脏树还是列出文件；停到用户回答。
3. 脏、porcelain ≤ 8 → `--uncommitted`。
4. 干净且不在默认分支（`origin/main`，否则 `origin/master`，否则本地 `main`/`master`）→ `--base <default>`。
5. 已在默认分支且干净 → 打印「没有可审的改动」，停止。

完成：唯一 git 范围，以及可选的 allowlist 路径列表。

## 3. 调用

对抗焦点和 allowlist 写成 **UTF-8 无 BOM** 的 PROMPT 文件。原生审核器自己看 git，PROMPT 里不嵌 diff。

对抗式开头：

```
Challenge the implementation and design. Only report issues that would change a merge decision. Prioritize expensive attack surfaces: correctness, data loss, rollback, races, auth.
```

有 allowlist 时追加路径列表，并写明：这是报告 allowlist；审核器仍会看到当前 git 范围里的全部改动。

```powershell
$script = Join-Path $env:USERPROFILE ".agents\skills\codex-cli-windows.ps1"
$out = Join-Path $env:TEMP ("codex-review-" + [guid]::NewGuid().ToString("N").Substring(0, 8) + ".md")
$err = "$out.err.log"
& $script -Mode review -OutPath $out -ErrPath $err -WorkingDirectory (Get-Location).Path -Uncommitted -PromptFile $promptFile
```

（按第 2 步改 `-Uncommitted` / `-Base` / `-Commit`。有 PROMPT 才传 `-PromptFile`。用户指定了模型或 effort 再加 `-Model` / `-Effort`。）

同一轮还要用 findings → 等到进程退出且 `$out` 落盘。只要审查结果 → 后台跑，结束本回合，等完成通知再读 `$out`。

启动器已处理一次 scope+PROMPT 互斥降级。调用已启动（已有 `$out` 或 Codex session）则沿用该次输出。脚本失败且 stderr 表明二进制不认识 `exec review` 时，才允许同范围再试一次顶层 `codex review`。

完成：进程已结束或已后台交出，且知道 `$out` / `$err` 路径。

## 4. 过滤

**findings 只读 `$out`。** `$err` 是遥测（websocket、skill 全文、git dump）；不把它当审查正文，不对整份 `$err` 做 `Select-String ERROR`。

退出码非零且 `$out` 不存在：只取 `$err` 里**最后一条**以 `error:` 开头的行。

对 `$out` 里每一条 finding 分类：

- **范围内**：路径落在 allowlist 内（无 allowlist 则全部范围内）
- **范围外**：有 allowlist 且路径未命中

降级（回报里声明）：`$err` 含 `dropped PROMPT`，或存在范围外 finding。

完成：每条 finding 已标范围内或范围外。

## 5. 回报

1. git 范围、allowlist、是否降级、启动器参数
2. 范围内 findings（轻度整理，保留文件:行）。范围内为空 → 「范围内无 findings」
3. 对每条范围内 finding：采纳 / 不适用（简短理由）。Findings 是输入，不是裁决

用户未要求修改则停在这里。事后删除 `$out`、`$err`、PROMPT 文件。

完成：三条都已写出；范围内每条都有判断。

## 6. 修改与提交

仅当用户要求按 findings 修改（或修改后提交）时进入。

1. 只改范围内且判断为**采纳**的项。
2. 用 `task test:related -- <allowlist 与为修复新增的文件>` 验证。
3. 若还要求提交：`git add` 只含 allowlist 及为这些修复新建的文件；commit 按仓库 Git 规则。

完成：采纳项已改；相关测试通过；若提交，已提交文件不超出 allowlist 与对应新文件。
