import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:findwell_app/models/project.dart';
import 'package:findwell_app/models/paper.dart';
import 'package:findwell_app/providers/settings_provider.dart';
import 'package:findwell_app/services/supabase_service.dart';

const _uuid = Uuid();

/// All projects list provider.
final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<ResearchProject>>((ref) {
  return ProjectsNotifier(ref);
});

/// Single project provider by ID.
final projectProvider =
    Provider.family<ResearchProject?, String>((ref, id) {
  final projects = ref.watch(projectsProvider);
  try {
    return projects.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

/// Saved papers for a specific project.
final projectPapersProvider =
    StateNotifierProvider.family<ProjectPapersNotifier, List<Paper>, String>(
        (ref, projectId) {
  return ProjectPapersNotifier(ref, projectId);
});

// ── Projects Notifier ──────────────────────────────────────

class ProjectsNotifier extends StateNotifier<List<ResearchProject>> {
  final Ref _ref;

  ProjectsNotifier(this._ref) : super([]);

  Future<void> load() async {
    final storage = _ref.read(storageServiceProvider);

    // Paint instantly from local cache first — no spinner/blank screen
    // while waiting on the network.
    state = await storage.getProjects();

    // Then reconcile with the cloud. This is what makes projects/chat
    // history created on another device (or the Chrome extension) show
    // up here — previously this class never talked to Supabase at all.
    try {
      final remote = await SupabaseService().fetchProjects();
      final merged = <String, ResearchProject>{
        for (final p in state) p.id: p,
      };
      for (final r in remote) {
        final existing = merged[r.id];
        // Last-write-wins by updatedAt so we don't clobber a newer local
        // edit with a stale cloud copy, or vice versa.
        if (existing == null || r.updatedAt.isAfter(existing.updatedAt)) {
          merged[r.id] = r;
        }
      }
      final list = merged.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = list;

      // Persist the merged result back to local storage so next launch
      // (even fully offline) already has everything.
      for (final p in list) {
        await storage.saveProject(p);
      }
    } catch (_) {
      // Offline or not signed in — local-only state from above is fine.
    }
  }

  Future<ResearchProject> createProject(String topic, {String? domain}) async {
    final project = ResearchProject(
      id: _uuid.v4(),
      topic: topic,
      domain: domain,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = [project, ...state];
    await _ref.read(storageServiceProvider).saveProject(project);
    unawaited(SupabaseService().saveProject(project));
    return project;
  }

  Future<void> updateProject(ResearchProject project) async {
    final updated = project.copyWith(updatedAt: DateTime.now());
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p,
    ];
    await _ref.read(storageServiceProvider).saveProject(updated);
    // Every chat message goes through addChatMessage() -> updateProject(),
    // so this one line is what makes chat history sync to the cloud at all.
    unawaited(SupabaseService().saveProject(updated));
  }

  Future<void> deleteProject(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _ref.read(storageServiceProvider).deleteProject(id);
    unawaited(SupabaseService().deleteProject(id));
  }

  Future<void> setOutline(String projectId, String outline) async {
    final project = state.firstWhere((p) => p.id == projectId);
    await updateProject(project.copyWith(
      outline: outline,
      currentStage: ResearchStage.outlineDone,
    ));
  }

  Future<void> setStage(String projectId, ResearchStage stage) async {
    final project = state.firstWhere((p) => p.id == projectId);
    await updateProject(project.copyWith(currentStage: stage));
  }

  Future<void> updateDraftSection(
      String projectId, String section, String content) async {
    final project = state.firstWhere((p) => p.id == projectId);
    final sections = Map<String, String>.from(project.draftSections);
    sections[section] = content;
    await updateProject(project.copyWith(
      draftSections: sections,
      currentStage: ResearchStage.draftDone,
    ));
  }

  Future<void> addChatMessage(
      String projectId, Map<String, String> message) async {
    final project = state.firstWhere((p) => p.id == projectId);
    final history = List<Map<String, String>>.from(project.chatHistory);
    history.add(message);
    await updateProject(project.copyWith(chatHistory: history));
  }
}

// ── Project Papers Notifier ────────────────────────────────

class ProjectPapersNotifier extends StateNotifier<List<Paper>> {
  final Ref _ref;
  final String projectId;

  ProjectPapersNotifier(this._ref, this.projectId) : super([]);

  Future<void> load() async {
    final storage = _ref.read(storageServiceProvider);
    state = await storage.getPapersForProject(projectId);
  }

  Future<void> savePaper(Paper paper) async {
    final saved = paper.copyWith(isSaved: true);
    state = [...state, saved];
    await _ref.read(storageServiceProvider).savePaper(projectId, saved);

    // Update project paperIds
    final projects = _ref.read(projectsProvider.notifier);
    final project =
        _ref.read(projectsProvider).firstWhere((p) => p.id == projectId);
    final paperIds = List<String>.from(project.paperIds);
    if (!paperIds.contains(paper.id)) {
      paperIds.add(paper.id);
      await projects.updateProject(project.copyWith(
        paperIds: paperIds,
        currentStage: ResearchStage.literatureDone,
      ));
    }
  }

  Future<void> removePaper(String paperId) async {
    state = state.where((p) => p.id != paperId).toList();
    await _ref.read(storageServiceProvider).removePaper(projectId, paperId);
  }

  Future<void> updatePaper(Paper paper) async {
    state = [
      for (final p in state)
        if (p.id == paper.id) paper else p,
    ];
    await _ref.read(storageServiceProvider).savePaper(projectId, paper);
  }
}