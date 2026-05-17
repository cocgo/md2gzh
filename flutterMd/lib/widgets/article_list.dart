import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/article.dart';

class ArticleList extends StatelessWidget {
  final List<Article> articles;
  final Article? selected;
  final void Function(Article) onSelect;
  final void Function(Article) onDelete;

  const ArticleList({
    super.key,
    required this.articles,
    this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F7),
        border: Border(
          right: BorderSide(color: Color(0xFFE5E5E7), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E5E7), width: 0.5),
              ),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '历史记录',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: articles.isEmpty
                ? const Center(
                    child: Text(
                      '暂无文章',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF86868B),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: articles.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 0.5,
                      color: Color(0xFFE5E5E7),
                    ),
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      final isSelected = selected?.id == article.id;
                      return _ArticleItem(
                        article: article,
                        isSelected: isSelected,
                        onTap: () => onSelect(article),
                        onDelete: () => onDelete(article),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ArticleItem extends StatelessWidget {
  final Article article;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ArticleItem({
    required this.article,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFFFF) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title.isEmpty ? '未命名文章' : article.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D1D1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(article.updatedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  CupertinoIcons.trash,
                  size: 18,
                  color: Color(0xFF86868B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
