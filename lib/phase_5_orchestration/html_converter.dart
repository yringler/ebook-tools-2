import 'package:html/parser.dart' as parser;

class HtmlConverter {
  String convert(String htmlContent) {
    final document = parser.parse(htmlContent);

    // We'll add parsing logic here as needed

    return document.outerHtml;
  }
}
