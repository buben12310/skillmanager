<div align="center">

# SkillManager

**一站式管理你所有 AI Agent 的 Skills 与 MCPs**

[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-blue)]()
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)](https://flutter.dev)
[![Go](https://img.shields.io/badge/Go-1.22+-00ADD8)](https://go.dev)

[功能特性](#-功能特性) · [支持的 Agent](#-支持的-agent) · [下载安装](#-下载安装) · [使用指南](#-使用指南) · [构建指南](#-构建指南) · [贡献](#-贡献)

</div>

---

## 为什么需要 SkillManager？

如果你同时使用多个 AI 编程 Agent（Claude Code、Codex、Trae、Hermes…），你会遇到这些痛点：

- 每个 Agent 的 Skill 存放在不同位置，手动管理繁琐
- 想把同一个 Skill 安装到多个 Agent，要重复操作
- 没有统一界面查看「我装了哪些 Skill」「哪些启用了」
- MCP 配置散落在各 Agent 的配置文件里，难以维护
- 想从 GitHub 找新 Skill，但要手动 clone、放对目录、命名正确

**SkillManager** 把这些都收进一个桌面应用：浏览 → 安装 → 启停 → 备份，全图形化操作。

---

## ✨ 功能特性

### Agent 管理
- 🤖 **预设 7 个 Agent**：Claude Code / Codex / OpenCode / Hermes / Trae / ZCode / WorkBuddy，开箱即用
- 🔍 **自动扫描**：一键检测已安装的 Agent 及其 Skill 目录（支持多候选路径 + 递归深度扫描）
- 📁 **自定义 Agent**：通过文件资源管理器选择路径，添加任何兼容 SKILL.md 标准的 Agent

### Skill 管理
- 📦 **统一视图**：每个 Agent 下的 Skill 一目了然，支持启用/禁用切换
- 🌐 **GitHub 市场**：浏览热门 Skill 仓库，关键词搜索（直连 GitHub API），一键安装
- 🧠 **智能安装**：自动识别三种仓库结构（单 skill / skillpack / multi-skill），无需手动调整目录
- 📥 **本地导入**：从本地文件夹导入 Skill，支持导出到其他 Agent
- 📖 **SKILL.md 渲染**：内置 Markdown 渲染器，直接预览 Skill 说明文档

### MCP 管理
- 🔌 **MCP 配置**：每个 Agent 下的 MCP 服务集中管理
- 🤝 **握手测试**：基于子进程握手协议的 MCP 连接测试，验证可用性

### 体验优化
- 🎨 **主题定制**：亮/暗模式 + 5 种强调色，即时切换
- 💾 **备份恢复**：一键导出所有 Agent/Skill/MCP 配置为 ZIP，迁移无忧
- ⚡ **跨平台**：Windows / macOS / Linux 全平台支持
- 🔒 **本地优先**：所有数据存储在本地 SQLite，不上传任何信息

---

## 🤖 支持的 Agent

| Agent | Skill 路径 | 备注 |
|---|---|---|
| **Claude Code** | `~/.claude/skills/` | Anthropic 官方 CLI |
| **Codex** | `~/.codex/skills/` | OpenAI Codex CLI |
| **OpenCode** | `~/.config/opencode/skills/` | 开源 Agent |
| **Hermes** | `~/.hermes/skills/` | 多平台候选（含 Windows `%LOCALAPPDATA%`） |
| **Trae** | `~/.trae-cn/skills/` | 兼容 TRAE IDE 与 TRAE CLI |
| **ZCode** | `~/.zcode/skills/` | 含插件缓存目录扫描 |
| **WorkBuddy** | `~/.workbuddy/skills/` | — |

未安装的 Agent 也会显示（标注「未安装」），方便你了解支持范围。

---

## 📥 下载安装

### 方式一：下载预编译版本（推荐普通用户）

前往 [Releases](../../releases) 页面下载最新版：

- **Windows**: `SkillManager-windows-x64.zip`
  - 解压后运行 `skillmanager.exe` 即可，无需安装

> macOS / Linux 版本将在后续发布

### 方式二：从源码构建

适合开发者或想体验最新功能的用户，详见下方 [构建指南](#-构建指南)。

---

## 📖 使用指南

### 首次启动

1. 启动应用，主界面会列出 7 个预设 Agent
2. 点击右上角「扫描」按钮，自动检测已安装的 Agent 及其 Skill
3. 扫描完成后，已安装的 Agent 显示为「已安装」，未安装的显示「未安装」

### 安装 Skill

**从市场安装**：
1. 点击左侧「市场」标签
2. 浏览热门仓库，或在搜索框输入关键词（如 `obsidian`、`git`）
3. 点击仓库卡片，查看 README 预览
4. 选择目标 Agent，点击「安装」
5. 安装完成后，对应 Agent 的 Skill 列表中会出现新 Skill

**从本地导入**：
1. 进入 Agent 详情页，切换到 Skills 标签
2. 点击「导入 Skill」按钮
3. 选择本地含 `SKILL.md` 的文件夹

### 配置 MCP

1. 进入 Agent 详情页，切换到 MCPs 标签
2. 点击「添加 MCP」，填写名称、命令、参数
3. 点击「测试连接」验证 MCP 可用性

### 主题与设置

- 进入「设置」页面可切换亮/暗模式、选择强调色
- 可选填 GitHub Token 提升市场 API 配额（从 60 req/h 提升到 5000 req/h）
- 「备份」功能可导出全部配置为 ZIP 文件

---

## 🏗️ 架构概览

SkillManager 采用 **Flutter UI + Go 内核** 的双进程架构：

```
┌─────────────────┐       HTTP REST        ┌─────────────────┐
│   Flutter UI    │ <───────────────────> │    Go Core      │
│  Riverpod + MD3 │   stdout JSON 握手     │  chi + SQLite   │
└─────────────────┘                        └─────────────────┘
                                                      │
                                                      ▼
                                           ┌──────────────────┐
                                           │ GitHub API       │
                                           │ (市场浏览/搜索)   │
                                           └──────────────────┘
```

- **UI 层**：Flutter Desktop + Riverpod + Material 3
- **内核层**：Go + chi 路由 + modernc.org/sqlite（纯 Go，无 CGO）
- **IPC**：子进程 + stdout JSON 握手 + HTTP REST（127.0.0.1）
- **数据**：SQLite 本地存储，所有路径用 `~/...` 形式跨平台

> 详细的架构说明、数据库 Schema、扫描算法等见 [DEVELOPER.md](DEVELOPER.md)

---

## 🔧 构建指南

### 环境要求

- [Flutter](https://flutter.dev) 3.x（启用 desktop 支持）
- [Go](https://go.dev) 1.22+
- [Git](https://git-scm.com)（用于 Skill 安装时的 `git clone`）

### 一键构建（Windows）

仓库根目录提供了 `release.ps1` 脚本，一键完成清理、编译、打包：

```powershell
.\release.ps1
```

脚本流程：
1. 终止运行中的进程，清除本地缓存（从零开始测试）
2. 编译 Go 内核：`go build -o skillmanager-core.exe ./cmd/server`
3. Flutter 依赖：`flutter pub get`
4. 构建 Flutter Release：`flutter build windows --release`
5. 拷贝 Go 二进制到 Release 输出目录

### 手动开发模式

```bash
# 终端 1：启动 Go 内核（可选，Flutter 会自动拉起）
cd skillmanager-core
go run ./cmd/server

# 终端 2：启动 Flutter UI
cd app
flutter pub get
flutter run -d windows
```

### 可选配置

| 配置项 | 设置方式 | 默认值 | 说明 |
|---|---|---|---|
| GitHub Token | Settings → GitHub Token | 空 | 匿名调用 60 req/h，设置后 5000 req/h |
| 主题模式 | Settings → 主题 | Light | Light / Dark |
| 强调色 | Settings → 强调色 | 紫色 | 5 种可选 |

---

## 🛠️ 技术栈

| 层 | 技术 |
|---|---|
| UI 框架 | Flutter Desktop + Material 3 |
| 状态管理 | Riverpod |
| 后端框架 | Go + chi |
| 数据库 | modernc.org/sqlite（纯 Go，无 CGO） |
| GitHub SDK | go-github |
| 字体 | Inter + Noto Sans SC（SIL OFL 1.1） |
| 备份 | archive（ZIP 格式） |

---

## 📁 项目结构

```
skillmanager/
├── app/                     # Flutter UI 层
│   └── lib/
│       ├── core/            # 主题、路径、进程启动
│       ├── data/            # 数据模型 + Repository 抽象 + HTTP 实现
│       ├── features/        # 功能页面 (home/marketplace/settings/...)
│       └── shared/          # 通用组件
├── skillmanager-core/       # Go 内核
│   ├── cmd/server/          # 入口
│   └── internal/
│       ├── agent/           # Agent/Skill/MCP 仓储 + 服务 + 扫描逻辑
│       ├── api/             # HTTP 路由与 handlers
│       ├── marketplace/     # GitHub 客户端 + 智能安装
│       └── storage/         # SQLite + 迁移 + 预设数据
├── release.ps1              # 一键构建脚本
├── DESIGN_SPEC.md           # 设计规范
├── DEVELOPMENT_PLAN.md      # 开发规划
├── DEVELOPER.md             # 开发者文档（架构细节）
└── README.md                # 本文档
```

---

## 🗺️ 路线图

- [x] M1-M3：Flutter UI + Mock 数据
- [x] M4-M5：Go 内核 + HTTP 仓储 + Skill/MCP CRUD
- [x] M6：GitHub 市场集成 + 智能安装
- [x] M7：备份/恢复、主题、polish
- [x] 7 个 Agent 自动扫描 + 递归深度 Skill 发现
- [ ] Skill 上游自动更新检测
- [ ] macOS / Linux 打包发布
- [ ] 自定义 Agent 格式插件系统
- [ ] Skill 依赖冲突检测

---

## 🤝 贡献

欢迎通过 Issue 和 PR 贡献代码！

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/your-feature`
3. 提交更改：`git commit -m 'feat: add your feature'`
4. 推送分支：`git push origin feature/your-feature`
5. 提交 Pull Request

开发相关细节请参考 [DEVELOPER.md](DEVELOPER.md)。

### 贡献方向

- 🐛 报告 Bug：通过 Issue 描述复现步骤
- 💡 功能建议：欢迎在 Issue 中讨论
- 🌍 适配新 Agent：参考 `agentCandidate` 结构体添加新 Agent 支持
- 📝 完善文档：README / DEVELOPER.md / 代码注释
- 🎨 UI/UX 改进：欢迎提供设计建议

---

## 📜 许可证

[MIT License](LICENSE) — 可自由使用、修改、分发。

---

## 🙏 鸣谢

- [go-github](https://github.com/google/go-github) — GitHub API 客户端
- [modernc.org/sqlite](https://gitlab.com/cznic/sqlite) — 纯 Go SQLite 实现
- [chi](https://github.com/go-chi/chi) — 轻量 HTTP 路由
- [archive](https://pub.dev/packages/archive) — ZIP 备份
- [Inter](https://rsms.me/inter/) & [Noto Sans SC](https://fonts.google.com/noto) — 开源字体
- [agentskills.io](https://agentskills.io) — SKILL.md 开放标准

---

## 📢 商标声明

"Claude Code"、"Codex"、"OpenCode"、"Hermes"、"Trae"、"ZCode"、"WorkBuddy" 等产品名称均为各自公司或作者的商标，本项目与这些产品无任何关联。本项目为社区开发的第三方管理工具，非上述任何产品的官方产品。

---

<div align="center">

如果这个项目对你有帮助，欢迎 ⭐ Star 支持一下！

</div>
