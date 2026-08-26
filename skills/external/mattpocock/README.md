# mattpocock/skills 外部技能包

来自 [`mattpocock/skills`](https://github.com/mattpocock/skills)（"Skills for Real Engineers"，MIT 许可证）的完整镜像。

- 同步时间：2026-08-26
- 对应上游提交：`6654f6b60cd9d5be8b54c6fafe44346dabeb3b76`（2026-08-24）
- `.upstream-tree` 记录上游 `skills/` 目录的 git tree 哈希，用于校验后续同步是否漂移。

## 目录结构

保留上游原始分类，安装脚本 `scripts/link-skills.sh` 会递归发现所有 `SKILL.md` 并按目录名安装：

| 分类 | 内容 |
|---|---|
| `skills/engineering/` | 工程类核心技能（tdd、code-review、diagnosing-bugs、wayfinder 等 18 个） |
| `skills/productivity/` | 效率类（grilling、handoff、teach 等 7 个） |
| `skills/in-progress/` | 上游实验性技能（implement-spec、retro、writing-* 等 8 个） |
| `skills/misc/` | 杂项（setup-pre-commit 等 4 个） |
| `skills/deprecated/` | 已废弃占位，安装时会被排除 |

## 再次同步

```bash
git clone --depth 1 https://github.com/mattpocock/skills /tmp/mp-upstream
rm -rf skills/external/mattpocock/skills
cp -R /tmp/mp-upstream/skills skills/external/mattpocock/skills
cp /tmp/mp-upstream/LICENSE skills/external/mattpocock/LICENSE
git -C /tmp/mp-upstream rev-parse HEAD:skills > skills/external/mattpocock/.upstream-tree
```

注意：上游已删除的历史技能（`to-issues`、`to-prd`、`decision-mapping`、`writing-great-skills`）不在本镜像中，但可能仍存在于本机 `~/.agents/skills`。
