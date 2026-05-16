import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class ArticleService {
  static const String _key = 'articles';

  Future<List<Article>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((e) => Article.fromJson(jsonDecode(e))).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> save(Article article) async {
    final articles = await getAll();
    final index = articles.indexWhere((a) => a.id == article.id);
    if (index >= 0) {
      articles[index] = article;
    } else {
      articles.insert(0, article);
    }
    await _saveAll(articles);
  }

  Future<void> delete(String id) async {
    final articles = await getAll();
    articles.removeWhere((a) => a.id == id);
    await _saveAll(articles);
  }

  Future<void> _saveAll(List<Article> articles) async {
    final prefs = await SharedPreferences.getInstance();
    final data = articles.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, data);
  }
}
