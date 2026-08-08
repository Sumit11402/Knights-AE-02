import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:findwell_app/app/theme.dart';
import 'package:findwell_app/models/project.dart';
import 'package:findwell_app/models/paper.dart';
import 'package:findwell_app/providers/project_provider.dart';
import 'package:findwell_app/providers/settings_provider.dart';
import 'package:findwell_app/services/arxiv_service.dart';
import 'package:findwell_app/widgets/glass_card.dart';
import 'package:findwell_app/widgets/paper_card.dart';
import 'package:findwell_app/widgets/loading_shimmer.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref
          .read(projectPapersProvider(widget.projectId).notifier)
          .load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider(widget.projectId));
    final theme = Theme.of(context);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: const Center(child: Text('Project not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.topic,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: () =>
                context.push('/project/${widget.projectId}/chat'),
            icon: const Icon(Icons.chat_outlined),
            tooltip: 'Research Chat',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: AppColors.accentPurple,
            indicatorWeight: 3,
            labelColor: AppColors.accentPurple,
            unselectedLabelColor: theme.brightness == Brightness.dark
                ? AppColors.textMuted
                : AppColors.lightTextSecondary,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Outline', icon: Icon(Icons.lightbulb_outline, size: 18)),
              Tab(text: 'Papers', icon: Icon(Icons.article_outlined, size: 18)),
              Tab(text: 'Draft', icon: Icon(Icons.edit_note, size: 18)),
              Tab(text: 'Chat', icon: Icon(Icons.chat_bubble_outline, size: 18)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OutlineTab(projectId: widget.projectId),
          _PapersTab(projectId: widget.projectId),
          _DraftTab(projectId: widget.projectId),
          _QuickChatTab(projectId: widget.projectId),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 1: OUTLINE
// ═══════════════════════════════════════════════════════════

class _OutlineTab extends ConsumerStatefulWidget {
  final String projectId;
  const _OutlineTab({required this.projectId});

  @override
  ConsumerState<_OutlineTab> createState() => _OutlineTabState();
}

class _OutlineTabState extends ConsumerState<_OutlineTab> {
  bool _generating = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider(widget.projectId));
    if (project == null) return const SizedBox();
    final theme = Theme.of(context);

    if (project.outline != null && project.outline!.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 16, color: AppColors.accentPurple),
                const SizedBox(width: 6),
                Text('AI-Generated Outline',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: AppColors.accentPurple)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _generating ? null : _generateOutline,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Regenerate'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GlassCard(
              margin: EdgeInsets.zero,
              child: MarkdownBody(
                data: project.outline!,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodyLarge,
                  h1: theme.textTheme.headlineLarge,
                  h2: theme.textTheme.headlineMedium,
                  h3: theme.textTheme.titleLarge,
                  listBullet: theme.textTheme.bodyLarge,
                  code: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: AppColors.accentCyan,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No outline yet
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline,
                size: 56, color: AppColors.accentPurple.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Generate Research Outline',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'AI will decompose "${project.topic}" into a structured research outline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generating ? null : _generateOutline,
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                  _generating ? 'Generating...' : 'Generate Outline'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateOutline() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final project = ref.read(projectProvider(widget.projectId));
      if (project == null) return;

      ref
          .read(projectsProvider.notifier)
          .setStage(widget.projectId, ResearchStage.outlining);

      final llm = ref.read(llmServiceProvider);
      final outline = await llm.generateOutline(
        project.topic,
        domain: project.domain,
      );

      ref
          .read(projectsProvider.notifier)
          .setOutline(widget.projectId, outline);
    } catch (e) {
      setState(() => _error = e.toString());
      ref
          .read(projectsProvider.notifier)
          .setStage(widget.projectId, ResearchStage.created);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 2: PAPERS
// ═══════════════════════════════════════════════════════════

class _PapersTab extends ConsumerStatefulWidget {
  final String projectId;
  const _PapersTab({required this.projectId});

  @override
  ConsumerState<_PapersTab> createState() => _PapersTabState();
}

class _PapersTabState extends ConsumerState<_PapersTab> {
  final _searchCtrl = TextEditingController();
  final _arxiv = ArxivService();
  List<Paper> _searchResults = [];
  bool _searching = false;
  final Set<String> _summarizing = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    final project = ref.read(projectProvider(widget.projectId));
    if (project != null) {
      _searchCtrl.text = project.topic;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedPapers =
        ref.watch(projectPapersProvider(widget.projectId));
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search arXiv...',
                    prefixIcon:
                        const Icon(Icons.search, size: 18),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searching ? null : _search,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.error)),
          ),

        // Saved papers section
        if (savedPapers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.bookmark,
                    size: 14, color: AppColors.accentPurple),
                const SizedBox(width: 4),
                Text(
                  'Saved Papers (${savedPapers.length})',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: AppColors.accentPurple),
                ),
              ],
            ),
          ),
        ],

        // Results
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Saved papers
              ...savedPapers.map((paper) => PaperCard(
                    title: paper.title,
                    authors: paper.authorsShort,
                    abstract_: paper.abstract_,
                    summary: paper.summary,
                    year: paper.year,
                    categories: paper.categories,
                    isSaved: true,
                    onRemove: () => ref
                        .read(projectPapersProvider(widget.projectId)
                            .notifier)
                        .removePaper(paper.id),
                    onSummarize: () => _summarizePaper(paper),
                    isSummarizing: _summarizing.contains(paper.id),
                    onCopyCitation: () {
                      Clipboard.setData(
                          ClipboardData(text: paper.bibtex));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('BibTeX copied!')),
                      );
                    },
                    onOpenUrl: paper.url != null
                        ? () => launchUrl(Uri.parse(paper.url!))
                        : null,
                  )),

              // Divider if both sections exist
              if (savedPapers.isNotEmpty &&
                  _searchResults.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Search Results',
                            style: theme.textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),

              // Search results
              ..._searchResults.map((paper) {
                final isSaved = savedPapers
                    .any((p) => p.id == paper.id);
                return PaperCard(
                  title: paper.title,
                  authors: paper.authorsShort,
                  abstract_: paper.abstract_,
                  summary: paper.summary,
                  year: paper.year,
                  categories: paper.categories,
                  isSaved: isSaved,
                  onSave: isSaved
                      ? null
                      : () => ref
                            .read(projectPapersProvider(
                                    widget.projectId)
                                .notifier)
                            .savePaper(paper),
                  onSummarize: () => _summarizePaper(paper),
                  isSummarizing: _summarizing.contains(paper.id),
                  onCopyCitation: () {
                    Clipboard.setData(
                        ClipboardData(text: paper.bibtex));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('BibTeX copied!')),
                    );
                  },
                  onOpenUrl: paper.url != null
                      ? () => launchUrl(Uri.parse(paper.url!))
                      : null,
                );
              }),

              // Loading shimmer
              if (_searching)
                ...List.generate(
                    3, (_) => const LoadingShimmer.card()),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _search() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      ref
          .read(projectsProvider.notifier)
          .setStage(
              widget.projectId, ResearchStage.searchingLiterature);
      final results = await _arxiv.searchPapers(
        query: _searchCtrl.text.trim(),
        maxResults: 15,
      );
      setState(() => _searchResults = results);
      ref
          .read(projectsProvider.notifier)
          .setStage(
              widget.projectId, ResearchStage.literatureDone);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _summarizePaper(Paper paper) async {
    setState(() => _summarizing.add(paper.id));
    try {
      final llm = ref.read(llmServiceProvider);
      final summary =
          await llm.summarizePaper(paper.title, paper.abstract_);
      final updated = paper.copyWith(summary: summary);

      // Update in search results
      setState(() {
        _searchResults = [
          for (final p in _searchResults)
            if (p.id == paper.id) updated else p,
        ];
      });

      // Update in saved papers if exists
      final saved =
          ref.read(projectPapersProvider(widget.projectId));
      if (saved.any((p) => p.id == paper.id)) {
        ref
            .read(
                projectPapersProvider(widget.projectId).notifier)
            .updatePaper(updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Summary failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _summarizing.remove(paper.id));
    }
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 3: DRAFT
// ═══════════════════════════════════════════════════════════

class _DraftTab extends ConsumerStatefulWidget {
  final String projectId;
  const _DraftTab({required this.projectId});

  @override
  ConsumerState<_DraftTab> createState() => _DraftTabState();
}

class _DraftTabState extends ConsumerState<_DraftTab> {
  static const _sections = [
    'Abstract',
    'Introduction',
    'Related Work',
    'Method',
    'Experiments',
    'Results',
    'Conclusion',
  ];

  final Set<String> _generating = {};

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider(widget.projectId));
    if (project == null) return const SizedBox();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Header
        GlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.edit_note,
                  color: AppColors.accentPurple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paper Draft',
                        style: theme.textTheme.titleMedium),
                    Text(
                      '${project.draftSections.length}/${_sections.length} sections generated',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (project.draftSections.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _exportDraft(project),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export'),
                ),
            ],
          ),
        ),

        // Section cards
        ..._sections.map((section) {
          final content = project.draftSections[section];
          final hasContent = content != null && content.isNotEmpty;
          final isGenerating = _generating.contains(section);

          return GlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            borderColor: hasContent
                ? AppColors.success.withValues(alpha: 0.3)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: hasContent
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        hasContent
                            ? Icons.check
                            : Icons.edit_outlined,
                        size: 14,
                        color: hasContent
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(section,
                        style: theme.textTheme.titleMedium),
                    const Spacer(),
                    if (isGenerating)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                    else
                      TextButton(
                        onPressed: () =>
                            _generateSection(project, section),
                        child: Text(hasContent
                            ? 'Regenerate'
                            : 'Generate'),
                      ),
                  ],
                ),
                if (hasContent) ...[
                  const SizedBox(height: 10),
                  MarkdownBody(
                    data: content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium,
                      h1: theme.textTheme.titleLarge,
                      h2: theme.textTheme.titleMedium,
                      code: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _generateSection(
      ResearchProject project, String section) async {
    setState(() => _generating.add(section));
    try {
      ref.read(projectsProvider.notifier).setStage(
          widget.projectId, ResearchStage.drafting);

      final llm = ref.read(llmServiceProvider);
      final savedPapers =
          ref.read(projectPapersProvider(widget.projectId));

      final content = await llm.generateDraftSection(
        topic: project.topic,
        section: section,
        outline: project.outline,
        previousSections: project.draftSections.entries
            .map((e) => '## ${e.key}\n${e.value}')
            .join('\n\n'),
        paperSummaries:
            savedPapers.map((p) => '${p.title}: ${p.summary ?? p.abstract_}').toList(),
      );

      ref
          .read(projectsProvider.notifier)
          .updateDraftSection(widget.projectId, section, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating.remove(section));
    }
  }

  void _exportDraft(ResearchProject project) {
    final buffer = StringBuffer();
    buffer.writeln('# ${project.topic}\n');
    for (final section in _sections) {
      final content = project.draftSections[section];
      if (content != null) {
        buffer.writeln('## $section\n');
        buffer.writeln('$content\n');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Full draft copied to clipboard!')),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 4: QUICK CHAT (embedded, redirects to full chat)
// ═══════════════════════════════════════════════════════════

class _QuickChatTab extends ConsumerWidget {
  final String projectId;
  const _QuickChatTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Research Chat',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Ask questions about your research, get methodology suggestions, and discuss findings with AI.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.push('/project/$projectId/chat'),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open Full Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
