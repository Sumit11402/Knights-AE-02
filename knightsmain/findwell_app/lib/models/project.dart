/// Research project model — represents a user's research session.
class ResearchProject {
  final String id;
  final String topic;
  final String? domain;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ResearchStage currentStage;
  final String? outline;
  final List<String> paperIds;
  final Map<String, String> draftSections;
  final List<Map<String, String>> chatHistory;

  ResearchProject({
    required this.id,
    required this.topic,
    this.domain,
    required this.createdAt,
    required this.updatedAt,
    this.currentStage = ResearchStage.created,
    this.outline,
    this.paperIds = const [],
    this.draftSections = const {},
    this.chatHistory = const [],
  });

  ResearchProject copyWith({
    String? topic,
    String? domain,
    DateTime? updatedAt,
    ResearchStage? currentStage,
    String? outline,
    List<String>? paperIds,
    Map<String, String>? draftSections,
    List<Map<String, String>>? chatHistory,
  }) {
    return ResearchProject(
      id: id,
      topic: topic ?? this.topic,
      domain: domain ?? this.domain,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      currentStage: currentStage ?? this.currentStage,
      outline: outline ?? this.outline,
      paperIds: paperIds ?? this.paperIds,
      draftSections: draftSections ?? this.draftSections,
      chatHistory: chatHistory ?? this.chatHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'domain': domain,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'currentStage': currentStage.index,
        'outline': outline,
        'paperIds': paperIds,
        'draftSections': draftSections,
        'chatHistory': chatHistory,
      };

  factory ResearchProject.fromJson(Map<String, dynamic> json) {
    return ResearchProject(
      id: json['id'] as String,
      topic: json['topic'] as String,
      domain: json['domain'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      currentStage: ResearchStage.values[json['currentStage'] as int? ?? 0],
      outline: json['outline'] as String?,
      paperIds: List<String>.from(json['paperIds'] ?? []),
      draftSections: Map<String, String>.from(json['draftSections'] ?? {}),
      chatHistory: List<Map<String, String>>.from(
        (json['chatHistory'] as List?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            [],
      ),
    );
  }
}

enum ResearchStage {
  created,
  outlining,
  outlineDone,
  searchingLiterature,
  literatureDone,
  drafting,
  draftDone,
  reviewing,
  complete;

  String get label {
    switch (this) {
      case ResearchStage.created:
        return 'New';
      case ResearchStage.outlining:
        return 'Generating Outline...';
      case ResearchStage.outlineDone:
        return 'Outline Ready';
      case ResearchStage.searchingLiterature:
        return 'Searching Papers...';
      case ResearchStage.literatureDone:
        return 'Papers Found';
      case ResearchStage.drafting:
        return 'Writing Draft...';
      case ResearchStage.draftDone:
        return 'Draft Ready';
      case ResearchStage.reviewing:
        return 'Reviewing...';
      case ResearchStage.complete:
        return 'Complete';
    }
  }

  double get progress {
    return (index + 1) / ResearchStage.values.length;
  }
}
