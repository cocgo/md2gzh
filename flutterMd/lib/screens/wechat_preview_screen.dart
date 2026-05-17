import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/wechat_format.dart';

class WechatPreviewScreen extends StatefulWidget {
  final String markdown;

  const WechatPreviewScreen({super.key, required this.markdown});

  @override
  State<WechatPreviewScreen> createState() => _WechatPreviewScreenState();
}

class _WechatPreviewScreenState extends State<WechatPreviewScreen> {
  late final WebViewController _controller;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final htmlFragment = WechatFormat.convert(widget.markdown);
    final fullHtml = _buildHtml(htmlFragment);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _loaded = true);
          },
        ),
      )
      ..addJavaScriptChannel('Toast', onMessageReceived: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      })
      ..loadHtmlString(fullHtml);
  }

  String _buildHtml(String content) {
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: 'PingFang SC', BlinkMacSystemFont, Roboto, 'Helvetica Neue', sans-serif;
  padding: 20px;
  padding-bottom: 80px;
  -webkit-user-select: text;
  user-select: text;
  background: #fff;
}
#output { max-width: 677px; margin: 0 auto; }
#btn {
  position: fixed; bottom: 0; left: 0; right: 0;
  padding: 16px; padding-bottom: max(16px, env(safe-area-inset-bottom));
  background: #fff;
  border-top: 0.5px solid #e5e5e7;
  display: flex; gap: 10px; justify-content: center;
}
#btn-copy {
  flex: 1; max-width: 300px;
  padding: 12px 0; border: none; border-radius: 8px;
  background: #135ce0; color: #fff;
  font-size: 16px; font-weight: bold; cursor: pointer;
  box-shadow: 0 4px 12px rgba(19,92,224,0.3);
}
#btn-copy:active { background: #0d47d1; }
#btn-copy.done { background: #52c41a; }
.code-snippet__fix {
  word-wrap: break-word !important;
  font-size: 14px; margin: 10px 0; display: flex;
  color: #333; position: relative;
  background-color: rgba(0,0,0,0.03);
  border: 1px solid #f0f0f0; border-radius: 2px;
  line-height: 26px;
}
.code-snippet__fix .code-snippet__line-index {
  counter-reset: line; flex-shrink: 0; height: 100%;
  padding: 1em; list-style-type: none;
}
.code-snippet__fix .code-snippet__line-index li {
  list-style-type: none; text-align: right;
}
.code-snippet__fix .code-snippet__line-index li::before {
  min-width: 1.5em; text-align: right; left: -2.5em;
  counter-increment: line; content: counter(line);
  display: inline; color: rgba(0,0,0,0.15);
}
.code-snippet__fix pre {
  overflow-x: auto; padding: 1em; padding-left: 0;
  white-space: normal; flex: 1; -webkit-overflow-scrolling: touch;
}
.code-snippet__fix code {
  text-align: left; font-size: 14px; display: block;
  white-space: pre; display: flex; position: relative;
  font-family: Consolas,"Liberation Mono",Menlo,Courier,monospace;
}
</style>
</head>
<body>
<div id="output">$content</div>
<div id="btn">
  <button id="btn-copy" onclick="doCopy()">复制到公众号</button>
</div>
<script>
function doCopy() {
  var el = document.getElementById('output');
  el.focus();
  window.getSelection().removeAllRanges();
  var range = document.createRange();
  range.selectNodeContents(el);
  window.getSelection().addRange(range);
  try {
    if (document.execCommand('copy')) {
      Toast.postMessage('已复制，去公众号粘贴吧');
      var btn = document.getElementById('btn-copy');
      btn.textContent = '已复制';
      btn.classList.add('done');
      setTimeout(function(){ btn.textContent = '复制到公众号'; btn.classList.remove('done'); }, 3000);
    } else {
      Toast.postMessage('复制失败，请手动全选复制');
    }
  } catch(e) {
    Toast.postMessage('复制失败，请手动全选复制');
  }
  window.getSelection().removeAllRanges();
}
</script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: CupertinoNavigationBar(
        middle: const Text('公众号预览'),
        backgroundColor: const Color(0xFFF5F5F7),
        border: const Border(),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Color(0xFF0071E3)),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (!_loaded)
            const Center(
              child: CupertinoActivityIndicator(),
            ),
        ],
      ),
    );
  }
}
