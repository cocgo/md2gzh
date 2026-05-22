# MD公众号

一个简洁优雅的 Markdown 编辑器，专为微信公众号发布设计。

## ✨ 功能特性

- 📝 **实时编辑预览** - 左侧编辑 Markdown，右侧实时预览渲染效果
- 📋 **一键复制到公众号** - 转换为简洁 HTML 格式，直接粘贴到微信公众号
- 📚 **历史记录管理** - 左侧列表显示所有文章，快速切换和删除
- 💾 **自动保存** - 本地存储，关闭应用也不丢失
- 📥 **快速粘贴** - 一键粘贴剪贴板内容

## 🎨 界面布局

```
┌─────────────────────────────────────────────┐
│  工具栏：新建 | 粘贴 | 保存 | 复制MD | 复制到公众号 │
├──────────┬─────────────────┬─────────────────┤
│          │                 │                 │
│  历史记录  │   Markdown编辑   │     实时预览     │
│          │                 │                 │
│          │                 │                 │
└──────────┴─────────────────┴─────────────────┘
```

## 🚀 快速开始

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# macOS
flutter run -d macos

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

## 📖 使用说明

1. **编辑内容** - 在右上区域输入 Markdown 文本
2. **实时预览** - 右下区域自动显示渲染效果
3. **保存文章** - 点击"保存"按钮保存到历史记录
4. **复制到公众号** - 点击"复制到公众号"，粘贴到微信编辑器即可

## 🎯 Markdown 语法支持

| 语法 | 效果 |
|------|------|
| `# 标题` | 一级标题 |
| `## 标题` | 二级标题 |
| `### 标题` | 三级标题 |
| `**粗体**` | **粗体** |
| `*斜体*` | *斜体* |
| `- 列表项` | 无序列表 |
| `> 引用` | 引用块 |
| `` `代码` `` | 行内代码 |
| `[链接](url)` | 超链接 |

## 🛠 技术栈

- **Flutter** - 跨平台应用框架
- **flutter_markdown** - Markdown 渲染
- **shared_preferences** - 本地存储
- **Apple Minimalist** - 设计风格

## 📝 输出示例

输入：
```markdown
# 文章标题
这是一段**粗体**文字
```

输出（复制到公众号）：
```html
<h1>文章标题</h1>
<p>这是一段<strong>粗体</strong>文字</p>
```

# 打包发布
## 安卓打包
cd /Users/lzlc/Documents/appGit/md2gzh/flutterMd && flutter build apk --release 2>&1 | tail -5
cp /Users/lzlc/Documents/appGit/md2gzh/flutterMd/build/app/outputs/flutter-apk/app-release.apk /Users/lzlc/Documents/appGit/md2gzh/flutterMd/release/markdown-editor-android.apk

## macos打包发布
cd /Users/lzlc/Documents/appGit/md2gzh/flutterMd && flutter build macos --release 2>&1 | tail -3
cd /Users/lzlc/Documents/appGit/md2gzh/flutterMd/build/macos/Build/Products/Release && rm -f /Users/lzlc/Documents/appGit/md2gzh/flutterMd/release/markdown-editor-macos.zip && zip -r /Users/lzlc/Documents/appGit/md2gzh/flutterMd/release/markdown-editor-macos.zip "MD公众号.app" -q

## 📄 许可证

MIT License

## 👨‍💻 作者

- **微信号**: weiyimbw
- **版本**: v1.0.4
- **官网**: actnow.top

