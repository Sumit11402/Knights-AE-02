"""Unit tests for ConsensusLLMClient (4-LLM Multi-Provider Ensemble)."""

from unittest.mock import MagicMock, patch

import pytest
from researchclaw.llm.client import LLMResponse
from researchclaw.llm.ensemble import ConsensusLLMClient, DEFAULT_ENSEMBLE_PROVIDERS


def test_ensemble_initialization_from_env(monkeypatch):
    """Test initializing ConsensusLLMClient with environment variables."""
    monkeypatch.setenv("GROQ_API_KEY", "gsk_test_groq")
    monkeypatch.setenv("GEMINI_API_KEY", "AIzaSy_test_gemini")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "sk-ant_test_anthropic")
    monkeypatch.setenv("OPENAI_API_KEY", "sk-proj_test_openai")

    client = ConsensusLLMClient.from_env()

    assert "groq" in client.clients
    assert "gemini" in client.clients
    assert "anthropic" in client.clients
    assert "openai" in client.clients
    assert len(client.clients) == 4


def test_chat_all_parallel_calls(monkeypatch):
    """Test parallel chat_all execution across mock providers."""
    mock_groq = MagicMock()
    mock_groq.chat.return_value = LLMResponse(content="Groq output: 42", model="llama-3.3-70b")

    mock_gemini = MagicMock()
    mock_gemini.chat.return_value = LLMResponse(content="Gemini output: 42", model="gemini-2.0-flash")

    mock_anthropic = MagicMock()
    mock_anthropic.chat.return_value = LLMResponse(content="Anthropic output: 42", model="claude-3-5-sonnet")

    mock_openai = MagicMock()
    mock_openai.chat.return_value = LLMResponse(content="OpenAI output: 42", model="gpt-4o")

    clients = {
        "groq": mock_groq,
        "gemini": mock_gemini,
        "anthropic": mock_anthropic,
        "openai": mock_openai,
    }

    ensemble = ConsensusLLMClient(clients=clients)
    messages = [{"role": "user", "content": "What is 6 * 7?"}]
    responses = ensemble.chat_all(messages)

    assert len(responses) == 4
    assert responses["groq"].content == "Groq output: 42"
    assert responses["gemini"].content == "Gemini output: 42"
    assert responses["anthropic"].content == "Anthropic output: 42"
    assert responses["openai"].content == "OpenAI output: 42"


def test_synthesize_combines_outputs():
    """Test synthesizing outputs from multiple models into a consensus answer."""
    mock_synth_client = MagicMock()
    mock_synth_client.chat.return_value = LLMResponse(
        content="Consensus: All 4 models agree that 6 * 7 = 42.",
        model="gpt-4o",
    )

    clients = {"openai": mock_synth_client}
    ensemble = ConsensusLLMClient(clients=clients, synthesizer_key="openai")

    responses = {
        "groq": LLMResponse(content="Groq says 42", model="llama3"),
        "gemini": LLMResponse(content="Gemini says 42", model="gemini"),
        "anthropic": LLMResponse(content="Claude says 42", model="claude"),
        "openai": LLMResponse(content="GPT says 42", model="gpt-4o"),
    }

    original_messages = [{"role": "user", "content": "What is 6 * 7?"}]
    synthesized = ensemble.synthesize(original_messages, responses)

    assert "Consensus" in synthesized
    assert mock_synth_client.chat.called


def test_chat_full_flow():
    """Test full chat() call on ConsensusLLMClient returning LLMResponse."""
    mock_groq = MagicMock()
    mock_groq.chat.return_value = LLMResponse(content="Groq response", model="llama-3.3-70b", prompt_tokens=10, completion_tokens=15)

    mock_openai = MagicMock()
    mock_openai.chat.return_value = LLMResponse(content="Synthesized final consensus", model="gpt-4o", prompt_tokens=20, completion_tokens=30)

    clients = {
        "groq": mock_groq,
        "openai": mock_openai,
    }

    ensemble = ConsensusLLMClient(clients=clients, synthesizer_key="openai")
    messages = [{"role": "user", "content": "Explain quantum computing."}]

    resp = ensemble.chat(messages)

    assert "Synthesized final consensus" in resp.content
    assert "ensemble-consensus" in resp.model
    assert resp.prompt_tokens > 0
    assert resp.completion_tokens > 0
