import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:findwell_app/models/paper.dart';

/// arXiv search API client.
///
/// Uses the arXiv Atom feed API to search for real academic papers.
/// See: https://info.arxiv.org/help/api/index.html
class ArxivService {
  final Dio _dio;

  ArxivService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://export.arxiv.org/api/',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  /// Search arXiv for papers matching the query.
  ///
  /// Returns up to [maxResults] papers sorted by relevance.
  Future<List<Paper>> searchPapers({
    required String query,
    int maxResults = 15,
    int start = 0,
    ArxivSortBy sortBy = ArxivSortBy.relevance,
  }) async {
    // Build the arXiv query — search in title + abstract
    final searchQuery = 'all:${_sanitizeQuery(query)}';

    try {
      final response = await _dio.get(
        'query',
        queryParameters: {
          'search_query': searchQuery,
          'start': start,
          'max_results': maxResults,
          'sortBy': sortBy.value,
          'sortOrder': 'descending',
        },
      );

      final xml = XmlDocument.parse(response.data as String);
      final entries = xml.findAllElements('entry');

      return entries.map((entry) => _parseEntry(entry)).toList();
    } on DioException catch (e) {
      throw ArxivException('arXiv search failed: ${e.message}');
    } on XmlException catch (e) {
      throw ArxivException('Failed to parse arXiv response: $e');
    }
  }

  Paper _parseEntry(XmlElement entry) {
    final id = _text(entry, 'id');
    final title = _text(entry, 'title').replaceAll(RegExp(r'\s+'), ' ').trim();
    final abstract_ =
        _text(entry, 'summary').replaceAll(RegExp(r'\s+'), ' ').trim();
    final published = _text(entry, 'published');

    // Extract authors
    final authors = entry
        .findAllElements('author')
        .map((a) => _text(a, 'name'))
        .where((name) => name.isNotEmpty)
        .toList();

    // Extract arXiv ID from URL
    final arxivId = id.split('/abs/').last.split('v').first;

    // Extract categories
    final categories = entry
        .findAllElements('category')
        .map((c) => c.getAttribute('term') ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    // PDF link
    final links = entry.findAllElements('link');
    String? pdfUrl;
    for (final link in links) {
      if (link.getAttribute('title') == 'pdf') {
        pdfUrl = link.getAttribute('href');
        break;
      }
    }
    pdfUrl ??= 'https://arxiv.org/pdf/$arxivId';

    DateTime? publishedDate;
    try {
      publishedDate = DateTime.parse(published);
    } catch (_) {}

    return Paper(
      id: arxivId,
      title: title,
      authors: authors,
      abstract_: abstract_,
      url: 'https://arxiv.org/abs/$arxivId',
      pdfUrl: pdfUrl,
      arxivId: arxivId,
      year: publishedDate?.year,
      publishedDate: publishedDate,
      categories: categories,
    );
  }

  String _text(XmlElement parent, String tag) {
    final el = parent.findElements(tag).firstOrNull;
    return el?.innerText ?? '';
  }

  String _sanitizeQuery(String query) {
    // Remove special characters that break arXiv queries
    return query
        .replaceAll(RegExp(r'[^\w\s\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

enum ArxivSortBy {
  relevance('relevance'),
  lastUpdatedDate('lastUpdatedDate'),
  submittedDate('submittedDate');

  final String value;
  const ArxivSortBy(this.value);
}

class ArxivException implements Exception {
  final String message;
  ArxivException(this.message);

  @override
  String toString() => message;
}
