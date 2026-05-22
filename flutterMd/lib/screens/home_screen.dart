import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../models/article.dart';
import '../services/article_service.dart';
import '../services/wechat_format.dart';
import '../screens/wechat_preview_screen.dart';
import '../widgets/article_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ArticleService();
  List<Article> _articles = [];
  Article? _current;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSidebar = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    _articles = await _service.getAll();
    if (_articles.isNotEmpty) {
      _current = _articles.first;
      _controller.text = _current!.content;
    } else {
      _newArticle();
    }
    setState(() {});
  }

  void _newArticle() {
    final article = Article(title: '', content: '');
    _controller.text = '';
    _current = article;
    setState(() {});
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
      setState(() {});
    }
  }

  void _selectArticle(Article article) {
    _current = article;
    _controller.text = article.content;
    setState(() {});
  }

  Future<void> _deleteArticle(Article article) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除文章'),
        content: const Text('确定要删除这篇文章吗?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.delete(article.id);
      if (_current?.id == article.id) {
        _current = null;
        _controller.clear();
      }
      await _loadArticles();
    }
  }

  Future<void> _saveArticle() async {
    if (_current == null) return;
    var content = _controller.text;
    content = _fixBoldSyntax(content);
    if (content != _controller.text) {
      _controller.text = content;
    }
    final title = _extractTitle(content);
    final article = _current!.copyWith(
      title: title,
      content: content,
    );
    await _service.save(article);
    _current = article;
    await _loadArticles();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已保存'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _fixBoldSyntax(String text) {
    return text
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*(?=[\u4e00-\u9fff])'), (m) => '**${m.group(1)}** ')
        .replaceAllMapped(RegExp(r'\*(.+?)\*(?=[\u4e00-\u9fff])'), (m) => '*${m.group(1)}* ');
  }

  String _extractTitle(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
      if (trimmed.isNotEmpty) {
        return trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed;
      }
    }
    return '未命名文章';
  }

  void _copyMarkdown() {
    final text = _controller.text;
    if (text.isEmpty) return;
    
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Markdown已复制'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyForWechat() {
    final text = _controller.text;
    if (text.isEmpty) return;
    
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => WechatPreviewScreen(markdown: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: const Color(0xFFFFFFFF),
              child: Column(
                children: [
                  _buildToolbar(isMobile),
                  Expanded(
                    child: Row(
                      children: [
                        if (!isMobile) ...[
                          SizedBox(
                            width: 160,
                            child: ArticleList(
                              articles: _articles,
                              selected: _current,
                              onSelect: _selectArticle,
                              onDelete: _deleteArticle,
                            ),
                          ),
                        ],
                        Expanded(child: _buildEditor()),
                        Container(
                          width: 0.5,
                          color: const Color(0xFFE5E5E7),
                        ),
                        Expanded(child: _buildPreview()),
                      ],
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
            if (isMobile && _showSidebar)
              GestureDetector(
                onTap: () => setState(() => _showSidebar = false),
                child: Container(
                  color: Colors.black54,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            if (isMobile && _showSidebar)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 240,
                child: ArticleList(
                  articles: _articles,
                  selected: _current,
                  onSelect: (article) {
                    _selectArticle(article);
                    setState(() => _showSidebar = false);
                  },
                  onDelete: _deleteArticle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(bool isMobile) {
    final buttonWidgets = [
      CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onPressed: _newArticle,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.add, size: 18, color: Color(0xFF0071E3)),
            SizedBox(width: 4),
            Text(
              '新建',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0071E3),
              ),
            ),
          ],
        ),
      ),
      CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onPressed: _pasteFromClipboard,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.doc_on_clipboard, size: 18, color: Color(0xFF0071E3)),
            SizedBox(width: 4),
            Text(
              '粘贴',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0071E3),
              ),
            ),
          ],
        ),
      ),
      CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onPressed: _current != null ? _saveArticle : null,
        child: Opacity(
          opacity: _current != null ? 1.0 : 0.5,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.floppy_disk, size: 18, color: Color(0xFF0071E3)),
              SizedBox(width: 4),
              Text(
                '保存',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0071E3),
                ),
              ),
            ],
          ),
        ),
      ),
      CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onPressed: _controller.text.isNotEmpty ? _copyMarkdown : null,
        child: Opacity(
          opacity: _controller.text.isNotEmpty ? 1.0 : 0.5,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.doc_on_doc, size: 18, color: Color(0xFF86868B)),
              SizedBox(width: 4),
              Text(
                '复制MD',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF86868B),
                ),
              ),
            ],
          ),
        ),
      ),
      CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        onPressed: _controller.text.isNotEmpty ? _copyForWechat : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: _controller.text.isNotEmpty
                ? const Color(0xFF0071E3)
                : const Color(0xFFE5E5E7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.square_on_square, size: 16, color: Color(0xFFFFFFFF)),
              SizedBox(width: 6),
              Text(
                '复制到公众号',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E7), width: 0.5),
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: () => setState(() => _showSidebar = true),
                      child: const Icon(CupertinoIcons.bars, size: 20, color: Color(0xFF0071E3)),
                    ),
                    ...buttonWidgets.take(3),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: buttonWidgets.skip(3).toList(),
                ),
              ],
            )
          : Row(
              children: buttonWidgets,
            ),
    );
  }

  Widget _buildEditor() {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F7),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E5E7), width: 0.5),
              ),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Markdown 编辑',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF86868B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              scrollController: _scrollController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1D1D1F),
                height: 1.6,
                fontFamily: 'Menlo',
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                hintText: '开始输入 Markdown 内容...',
                hintStyle: TextStyle(
                  color: Color(0xFF86868B),
                  fontSize: 15,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F7),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E5E7), width: 0.5),
              ),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '预览',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF86868B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: SelectionArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: MarkdownBody(
                  data: _controller.text,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      // 可以在这里处理链接点击
                    }
                  },
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                    height: 1.3,
                  ),
                  h2: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                    height: 1.3,
                  ),
                  h3: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                    height: 1.3,
                  ),
                  p: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1D1D1F),
                    height: 1.6,
                  ),
                  blockquote: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF86868B),
                    height: 1.6,
                  ),
                  code: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Menlo',
                    backgroundColor: Color(0xFFF5F5F7),
                  ),
                  listBullet: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1D1D1F),
                  ),
                  tableHead: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                  tableBody: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F7),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E7), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () async {
              final url = Uri.parse('https://actnow.top');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text(
              'v1.0.3',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF0071E3),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse('weixin://profiles/gh_b6b9760dbffe');
                  try {
                    await launchUrl(url);
                  } catch (e) {
                    await Clipboard.setData(const ClipboardData(text: 'weiyimbw'));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已复制微信号，请在微信中搜索'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  '作者微信: weiyimbw',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0071E3),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
