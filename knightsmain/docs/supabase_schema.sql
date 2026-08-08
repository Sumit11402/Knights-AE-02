-- =============================================================================
-- FindWell — Supabase Database Schema
-- Run this script in your Supabase Dashboard SQL Editor (https://app.supabase.com)
-- =============================================================================

-- Enable vector extension for embeddings / vector search
CREATE EXTENSION IF NOT EXISTS vector;

-- -----------------------------------------------------------------------------
-- 1. Projects Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    topic TEXT NOT NULL,
    domain TEXT,
    current_stage INT NOT NULL DEFAULT 0,
    outline TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Row Level Security (RLS) for Projects
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own projects"
    ON public.projects
    FOR ALL
    USING (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 2. Papers Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.papers (
    id TEXT NOT NULL,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    authors TEXT[] DEFAULT '{}',
    abstract TEXT,
    summary TEXT,
    url TEXT,
    pdf_url TEXT,
    arxiv_id TEXT,
    doi TEXT,
    publication_year INT,
    categories TEXT[] DEFAULT '{}',
    is_saved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (project_id, id)
);

ALTER TABLE public.papers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their project papers"
    ON public.papers
    FOR ALL
    USING (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 3. Draft Sections Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.draft_sections (
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    section_name TEXT NOT NULL,
    content TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (project_id, section_name)
);

ALTER TABLE public.draft_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage draft sections"
    ON public.draft_sections
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.projects
            WHERE projects.id = draft_sections.project_id
            AND projects.user_id = auth.uid()
        )
    );

-- -----------------------------------------------------------------------------
-- 4. Chat Messages Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    model TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their project chat messages"
    ON public.chat_messages
    FOR ALL
    USING (
        auth.uid() = user_id OR EXISTS (
            SELECT 1 FROM public.projects
            WHERE projects.id = chat_messages.project_id
            AND projects.user_id = auth.uid()
        )
    );

-- -----------------------------------------------------------------------------
-- 5. Evidence & Vector Search Table (pgvector)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.evidence_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    claim TEXT NOT NULL,
    passage TEXT NOT NULL,
    source_url TEXT,
    confidence_score FLOAT DEFAULT 1.0,
    embedding VECTOR(1536), -- Compatible with OpenAI text-embedding-3-small
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.evidence_units ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access project evidence"
    ON public.evidence_units
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.projects
            WHERE projects.id = evidence_units.project_id
            AND projects.user_id = auth.uid()
        )
    );

-- Vector Similarity Search Function
CREATE OR REPLACE FUNCTION match_evidence (
    query_embedding VECTOR(1536),
    match_threshold FLOAT,
    match_count INT,
    filter_project_id UUID
)
RETURNS TABLE (
    id UUID,
    claim TEXT,
    passage TEXT,
    source_url TEXT,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        evidence_units.id,
        evidence_units.claim,
        evidence_units.passage,
        evidence_units.source_url,
        1 - (evidence_units.embedding <=> query_embedding) AS similarity
    FROM evidence_units
    WHERE evidence_units.project_id = filter_project_id
      AND 1 - (evidence_units.embedding <=> query_embedding) > match_threshold
    ORDER BY evidence_units.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. Standalone Conversations & Messages Tables (Capped at 10 Recent)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own conversations"
    ON public.conversations
    FOR ALL
    USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    attached_document_ref TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their conversation messages"
    ON public.messages
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- -----------------------------------------------------------------------------
-- 7. Retention Function & Trigger: Cap at 10 Most Recent Conversations Per User
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prune_old_conversations()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM public.conversations
    WHERE user_id = NEW.user_id
      AND id NOT IN (
          SELECT id FROM public.conversations
          WHERE user_id = NEW.user_id
          ORDER BY updated_at DESC, created_at DESC
          LIMIT 10
      );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_prune_old_conversations ON public.conversations;
CREATE TRIGGER trigger_prune_old_conversations
AFTER INSERT OR UPDATE ON public.conversations
FOR EACH ROW
EXECUTE FUNCTION public.prune_old_conversations();



