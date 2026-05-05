import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

/// Holds the scraped metadata from an article URL.
class ScrapedArticle {
  final String text;
  final String title;
  final String? imageUrl;
  final String? category;

  ScrapedArticle({
    required this.text,
    required this.title,
    this.imageUrl,
    this.category,
  });
}

class ScraperService {
  /// Fetches the HTML content of a URL and extracts text + metadata.
  Future<ScrapedArticle> scrapeArticle(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load website. Status: ${response.statusCode}');
      }

      var document = parse(response.body);

      // --- TITLE ---
      String title = '';
      // 1. Try og:title (best quality)
      final ogTitle = document.querySelector('meta[property="og:title"]');
      if (ogTitle != null) {
        title = ogTitle.attributes['content'] ?? '';
      }
      // 2. Fallback to <title> tag
      if (title.isEmpty) {
        title = document.querySelector('title')?.text ?? 'Untitled Podcast';
      }

      // --- IMAGE ---
      String? imageUrl;
      // 1. Try og:image (the social share thumbnail — almost always the hero image)
      final ogImage = document.querySelector('meta[property="og:image"]');
      if (ogImage != null) {
        imageUrl = ogImage.attributes['content'];
      }
      // 2. Fallback to twitter:image
      if (imageUrl == null || imageUrl.isEmpty) {
        final twImage = document.querySelector('meta[name="twitter:image"]');
        if (twImage != null) {
          imageUrl = twImage.attributes['content'];
        }
      }

      // --- CATEGORY ---
      String? category;
      // 1. Try article:section
      final section = document.querySelector('meta[property="article:section"]');
      if (section != null) {
        category = section.attributes['content'];
      }
      // 2. Fallback to og:type if it's more specific than "article"
      if (category == null || category.isEmpty) {
        final ogType = document.querySelector('meta[property="og:type"]');
        if (ogType != null) {
          final typeVal = ogType.attributes['content'] ?? '';
          if (typeVal.isNotEmpty && typeVal != 'website' && typeVal != 'article') {
            category = typeVal;
          }
        }
      }
      // 3. Fallback to keywords meta
      if (category == null || category.isEmpty) {
        final keywords = document.querySelector('meta[name="keywords"]');
        if (keywords != null) {
          final kw = keywords.attributes['content'] ?? '';
          if (kw.isNotEmpty) {
            // Take the first keyword as category
            category = kw.split(',').first.trim();
          }
        }
      }

      // --- ARTICLE TEXT ---
      var paragraphs = document.getElementsByTagName('p');
      String articleText = '';
      
      for (var p in paragraphs) {
        if (p.text.trim().isNotEmpty) {
          articleText += '${p.text.trim()}\n\n';
        }
      }

      if (articleText.length < 100) {
        articleText = document.body?.text ?? 'No text found';
      }

      articleText = articleText.replaceAll(RegExp(r'\n{3,}'), '\n\n');

      if (articleText.length > 10000) {
        articleText = articleText.substring(0, 10000);
      }

      return ScrapedArticle(
        text: articleText,
        title: title.trim(),
        imageUrl: imageUrl,
        category: category,
      );
    } catch (e) {
      throw Exception('Failed to scrape URL: $e');
    }
  }
}
