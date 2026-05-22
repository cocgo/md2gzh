import 'package:markdown/markdown.dart' as md;

class WechatFormat {
  static String convert(String markdown) {
    // add space after closing ** when followed by CJK, helps parser recognize bold
    var src = markdown.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*(?=[\u4e00-\u9fff\u3000-\u303f])'),
      (m) => '**${m.group(1)}** ',
    );

    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    final nodes = document.parse(src);
    final buffer = StringBuffer();
    final footnotes = <List<String>>[];

    for (final node in nodes) {
      buffer.write(_renderNode(node, null, footnotes));
    }

    // post-process
    var result = buffer.toString();

    if (footnotes.isNotEmpty) {
      result += '<h3 style="font-weight:bold;font-size:120%;margin:40px 10px 20px 10px;">References</h3>';
      result += '<p style="margin:10px 10px;font-size:14px;">';
      for (final f in footnotes) {
        result += '<code style="font-size:90%;opacity:0.6;">[${f[0]}]</code> ${f[1]}: <i>${f[2]}</i><br/>';
      }
      result += '</p>';
    }

    return result;
  }

  static int _addFootnote(List<List<String>> footnotes, String title, String link) {
    final newIndex = footnotes.length + 1;
    footnotes.add([newIndex.toString(), title, link]);
    return newIndex;
  }

  static String _renderNode(md.Node node, String? parentTag, List<List<String>> footnotes) {
    if (node is md.Element) {
      return _renderElement(node, parentTag, footnotes);
    }
    return node.textContent;
  }

  static String _renderElement(md.Element element, String? parentTag, List<List<String>> footnotes) {
    final tag = element.tag;
    final children = (element.children ?? [])
        .map((n) => _renderNode(n, tag, footnotes))
        .join('');

    switch (tag) {
      case 'h1':
      case 'h2':
        return '<h2 style="font-size:140%;text-align:center;font-weight:normal;margin:80px 10px 40px 10px;color:#3f3f3f;line-height:1.5;">$children</h2>';
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return '<h3 style="font-weight:bold;font-size:120%;margin:40px 10px 20px 10px;color:#3f3f3f;line-height:1.5;">$children</h3>';
      case 'p':
        if (parentTag == 'blockquote') {
          return '<p style="margin:0;font-size:15px;color:rgb(91,91,91);line-height:1.6;">$children</p>';
        }
        return '<p style="margin:10px 10px;font-size:16px;color:#3f3f3f;line-height:1.6;">$children</p>';
      case 'blockquote':
        return '<blockquote style="color:rgb(91,91,91);padding:1px 0 1px 10px;background:rgba(158,158,158,0.1);border-left:3px solid rgb(158,158,158);">$children</blockquote>';
      case 'pre':
        return _renderCodeBlock(element);
      case 'code':
        if (parentTag == 'pre') {
          return children;
        }
        return '<code style="font-size:90%;font-family:Consolas,Monaco,Menlo,monospace;color:#ff3502;background:#f8f5ec;padding:3px 5px;border-radius:2px;">$children</code>';
      case 'strong':
        return '<strong style="font-weight:bold;">$children</strong>';
      case 'em':
        return '<em style="font-style:italic;">$children</em>';
      case 'a':
        final href = element.attributes['href'] ?? '';
        final text = children;
        if (href.startsWith('https://mp.weixin.qq.com')) {
          return '<a href="$href" style="color:#576b95;text-decoration:none;">$text</a>';
        }
        if (href == text) return text;
        final ref = _addFootnote(footnotes, text, href);
        return '<span style="color:#ff3502;">$text<sup>[$ref]</sup></span>';
      case 'img':
        final src = element.attributes['src'] ?? '';
        final alt = element.attributes['alt'] ?? '';
        return '<img style="border-radius:4px;display:block;margin:20px auto;width:100%;" src="$src" alt="$alt"/>';
      case 'ul':
        return '<p style="margin-left:0;padding-left:20px;list-style:circle;margin:10px 10px;font-size:16px;color:#3f3f3f;line-height:1.6;">$children</p>';
      case 'ol':
        return '<p style="margin-left:0;padding-left:20px;margin:10px 10px;font-size:16px;color:#3f3f3f;line-height:1.6;">$children</p>';
      case 'li':
        if (parentTag == 'ul') {
          return '<span style="text-indent:-20px;display:block;margin:10px 10px;font-size:16px;color:#3f3f3f;line-height:1.6;"><span style="margin-right:10px;">&#8226;</span>$children</span>';
        }
        return '<span style="text-indent:-20px;display:block;margin:10px 10px;font-size:16px;color:#3f3f3f;line-height:1.6;">$children</span>';
      case 'hr':
        return '<hr style="border-style:solid;border-width:1px 0 0;border-color:rgba(0,0,0,0.1);-webkit-transform-origin:0 0;-webkit-transform:scale(1,0.5);transform-origin:0 0;transform:scale(1,0.5);">';
      case 'table':
        return '<table style="border-collapse:collapse;margin:20px 0;font-size:16px;color:#3f3f3f;">$children</table>';
      case 'thead':
        return '<thead style="background:rgba(0,0,0,0.05);">$children</thead>';
      case 'tbody':
        return '<tbody>$children</tbody>';
      case 'tr':
        return '<tr>$children</tr>';
      case 'th':
        return '<th style="font-size:80%;border:1px solid #dfdfdf;padding:4px 8px;font-weight:bold;">$children</th>';
      case 'td':
        return '<td style="font-size:80%;border:1px solid #dfdfdf;padding:4px 8px;">$children</td>';
      case 'br':
        return '<br/>';
      default:
        return '<$tag>$children</$tag>';
    }
  }

  static String _renderCodeBlock(md.Element element) {
    String code = '';
    final children = element.children;
    if (children != null && children.isNotEmpty) {
      code = children.first.textContent;
    }

    final escaped = code.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    final lines = escaped.split('\n');
    final codeLines = <String>[];
    final numbers = <String>[];

    for (final line in lines) {
      codeLines.add('<code><span class="code-snippet_outer">${line.isEmpty ? '<br>' : line}</span></code>');
      numbers.add('<li></li>');
    }

    return '<section class="code-snippet__fix code-snippet__js">'
        '<ul class="code-snippet__line-index code-snippet__js">${numbers.join('')}</ul>'
        '<pre class="code-snippet__js">${codeLines.join('')}</pre></section>';
  }
}
