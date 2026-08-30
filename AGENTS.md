# Agent Engineering 仓库规则

## 开工与权威

- 权威顺序：当前用户指令、本文件、目标内容所属说明、现有实现与验证结果。
- README、knowledge、playbooks 和仓库说明使用中文；代码、命令和 Skill 保持其现有语言与上游格式。
- 只修改任务拥有的文件，保留用户或并行改动；外部写入、仓库设置、push 和发布需要当前任务明确授权。

## 内容归口

| 内容 | 唯一落点 |
|---|---|
| 可自动发现和调用的 Agent 工作流 | `skills/` |
| 带原始链接、作者、日期和核对时间的来源笔记 | `knowledge/` |
| 综合多个来源形成的跨项目做法 | `playbooks/` |
| 可复制的成熟起始产物 | 首份真实模板出现后建立 `templates/` |
| 安装、同步和确定性检查 | `scripts/` |

- `skills/external/` 是上游镜像，只通过对应同步工作流更新，并保留 upstream 身份与许可证。
- 项目特定业务规则留在目标项目；本仓只接收跨项目可复用资产。
- 来源笔记摘要和分析外部材料，不复制文章全文；事实贴近原始链接，推论与来源主张分开。
- 同一结论只保留一个事实源：knowledge 保存证据，playbook 保存综合方法，Skill 保存可执行流程。

## 验证与完成

- 修改根文档、knowledge、playbooks、插件清单或安装入口后运行 `python scripts/validate-repository.py`。
- 修改安装脚本后运行 `bash -n scripts/link-skills.sh scripts/list-skills.sh`，并在临时目录验证目标安装。
- 修改 Skill 时运行适用的 Skill 结构校验和最窄行为测试；普通文档变更不触发全量外部镜像测试。
- 完成条件：目标内容归口正确，内部链接与分发入口通过验证，最后一次相关修改已提交，未包含其他改动。
