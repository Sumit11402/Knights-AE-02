/// Academic paper model — represents a paper from arXiv or other sources.
class Paper {
  final String id;
  final String title;
  final List<String> authors;
  final String abstract_;
  final String? summary;
  final String? url;
  final String? pdfUrl;
  final String? arxivId;
  final String? doi;
  final int? year;
  final int? citationCount;
  final DateTime? publishedDate;
  final List<String> categories;
  final bool isSaved;

  Paper({
    required this.id,
    required this.title,
    required this.authors,
    required this.abstract_,
    this.summary,
    this.url,
    this.pdfUrl,
    this.arxivId,
    this.doi,
    this.year,
    this.citationCount,
    this.publishedDate,
    this.categories = const [],
    this.isSaved = false,
  });

  Paper copyWith({
    String? summary,
    bool? isSaved,
  }) {
    return Paper(
      id: id,
      title: title,
      authors: authors,
      abstract_: abstract_,
      summary: summary ?? this.summary,
      url: url,
      pdfUrl: pdfUrl,
      arxivId: arxivId,
      doi: doi,
      year: year,
      citationCount: citationCount,
      publishedDate: publishedDate,
      categories: categories,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  String get authorsShort {
    if (authors.isEmpty) return 'Unknown';
    if (authors.length == 1) return authors.first;
    if (authors.length == 2) return '${authors[0]} & ${authors[1]}';
    return '${authors[0]} et al.';
  }

  String get bibtex {
    final key = arxivId ?? id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final authorStr = authors.join(' and ');
    return '''@article{$key,
  title={$title},
  author={$authorStr},
  year={$year ?? ${DateTime.now().year}},
  ${arxivId != null ? 'eprint={$arxivId},' : ''}
  ${doi != null ? 'doi={$doi},' : ''}
}''';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'authors': authors,
        'abstract_': abstract_,
        'summary': summary,
        'url': url,
        'pdfUrl': pdfUrl,
        'arxivId': arxivId,
        'doi': doi,
        'year': year,
        'citationCount': citationCount,
        'publishedDate': publishedDate?.toIso8601String(),
        'categories': categories,
        'isSaved': isSaved,
      };

  factory Paper.fromJson(Map<String, dynamic> json) {
    return Paper(
      id: json['id'] as String,
      title: json['title'] as String,
      authors: List<String>.from(json['authors'] ?? []),
      abstract_: json['abstract_'] as String? ?? '',
      summary: json['summary'] as String?,
      url: json['url'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      arxivId: json['arxivId'] as String?,
      doi: json['doi'] as String?,
      year: json['year'] as int?,
      citationCount: json['citationCount'] as int?,
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'] as String)
          : null,
      categories: List<String>.from(json['categories'] ?? []),
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }
}
