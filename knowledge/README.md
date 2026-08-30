# Knowledge

本目录保存来源可追溯的 Agent 工程知识笔记。它回答“来源说了什么、证据在哪里、适用边界是什么”，不直接承担仓库规则或自动调用流程。

## 来源笔记合同

每份来源笔记使用 YAML frontmatter，至少包含：

```yaml
---
title: 来源标题
source_url: https://example.com/original
author: 作者或机构
published: YYYY-MM-DD
updated: YYYY-MM-DD
checked: YYYY-MM-DD
status: source-note
---
```

正文应包含来源摘要、主要主张、适用边界、局限性、可复用结论和近邻链接。直接事实贴近原始来源；本仓推论明确标为推论。只保存必要短引文，不复制外部文章全文。

## 当前主题

- [`agent-instructions/`](./agent-instructions/)：`AGENTS.md`、自定义 Agent、Skills 与仓库指令设计。
