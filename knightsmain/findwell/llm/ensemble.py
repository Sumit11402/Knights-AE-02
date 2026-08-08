"""Multi-LLM Ensemble and Consensus Synthesizer.

Queries Groq, Gemini, Anthropic, and OpenAI concurrently, compares their outputs,
and synthesizes a unified, high-confidence response.
"""

from __future__ import annotations

import concurrent.futures
import logging
import os
from dataclasses import dataclass, field
from typing import Any

from researchclaw.llm.client import LLMClient, LLMConfig, LLMResponse

logger = logging.getLogger(__name__)

# Default provider presets for the 4-LLM ensemble
DEFAULT_ENSEMBLE_PROVIDERS = {
    "groq": {
        "base_url": "https://api.groq.com/openai/v1",
        "api_key_env": "GROQ_API_KEY",
        "primary_model": "llama-3.1-8b-instant",
        "fallback_models": ["llama-3.3-70b-versatile", "mixtral-8x7b-32768"],
    },
    "gemini": {
        "base_url": "https://openrouter.ai/api/v1",
        "api_key_env": "OPENROUTER_API_KEY",
        "primary_model": "google/gemini-2.5-flash",
        "fallback_models": ["google/gemini-3.6-flash"],
    },
    "anthropic": {
        "base_url": "https://openrouter.ai/api/v1",
        "api_key_env": "OPENROUTER_API_KEY",
        "primary_model": "anthropic/claude-3-haiku",
        "fallback_models": ["anthropic/claude-sonnet-5", "anthropic/claude-opus-5"],
    },
    "openai": {
        "base_url": "https://openrouter.ai/api/v1",
        "api_key_env": "OPENROUTER_API_KEY",
        "primary_model": "openai/gpt-4o-mini",
        "fallback_models": ["openai/gpt-4o-2024-11-20"],
    },
}


@dataclass
class EnsembleResponse:
    """Consensus response containing synthesis and individual provider outputs."""

    synthesized_content: str
    individual_responses: dict[str, LLMResponse]
    consensus_summary: str = ""
    total_prompt_tokens: int = 0
    total_completion_tokens: int = 0


class ConsensusLLMClient:
    """Ensemble client running 4 AI models in parallel and combining outputs."""

    def __init__(self, clients: dict[str, LLMClient], synthesizer_key: str = "openai") -> None:
        self.clients = clients
        self.synthesizer_key = synthesizer_key if synthesizer_key in clients else next(iter(clients.keys()), "openai")

    @classmethod
    def from_env(cls, custom_config: dict[str, Any] | None = None) -> ConsensusLLMClient:
        """Factory creating clients for all configured providers from environment."""
        clients: dict[str, LLMClient] = {}
        provider_specs = custom_config or DEFAULT_ENSEMBLE_PROVIDERS

        for name, spec in provider_specs.items():
            env_var = spec.get("api_key_env", f"{name.upper()}_API_KEY")
            api_key = spec.get("api_key") or os.environ.get(env_var, "") or os.environ.get("OPENAI_API_KEY", "")

            if not api_key:
                logger.warning("No API key found for ensemble provider '%s' (%s). Skipping.", name, env_var)
                continue

            cfg = LLMConfig(
                base_url=spec.get("base_url", "https://api.openai.com/v1"),
                api_key=api_key,
                primary_model=spec.get("primary_model", "gpt-4o"),
                fallback_models=list(spec.get("fallback_models", [])),
            )
            client = LLMClient(cfg)

            # Use native Anthropic adapter if provider is anthropic and using native api.anthropic.com
            if (spec.get("provider") == "anthropic" or name == "anthropic") and "anthropic.com" in cfg.base_url:
                from researchclaw.llm.anthropic_adapter import AnthropicAdapter

                client._anthropic = AnthropicAdapter(cfg.base_url, cfg.api_key, cfg.timeout_sec)

            clients[name] = client

        if not clients:
            # Fallback to default LLMClient using OPENAI_API_KEY
            default_key = os.environ.get("OPENAI_API_KEY", "")
            cfg = LLMConfig(base_url="https://api.openai.com/v1", api_key=default_key, primary_model="gpt-4o")
            clients["openai"] = LLMClient(cfg)

        return cls(clients=clients)

    def chat_all(
        self,
        messages: list[dict[str, str]],
        *,
        max_tokens: int | None = None,
        temperature: float | None = None,
        json_mode: bool = False,
        system: str | None = None,
    ) -> dict[str, LLMResponse]:
        """Call all configured providers in parallel."""
        results: dict[str, LLMResponse] = {}

        def _call_provider(name: str, client: LLMClient) -> tuple[str, LLMResponse | None, Exception | None]:
            try:
                resp = client.chat(
                    messages=messages,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    json_mode=json_mode,
                    system=system,
                )
                return name, resp, None
            except Exception as exc:
                logger.warning("Ensemble provider '%s' failed: %s", name, exc)
                return name, None, exc

        with concurrent.futures.ThreadPoolExecutor(max_workers=len(self.clients)) as executor:
            futures = [
                executor.submit(_call_provider, name, client)
                for name, client in self.clients.items()
            ]
            for future in concurrent.futures.as_completed(futures):
                name, resp, _err = future.result()
                if resp is not None:
                    results[name] = resp

        return results

    def synthesize(
        self,
        original_messages: list[dict[str, str]],
        responses: dict[str, LLMResponse],
        json_mode: bool = False,
    ) -> str:
        """Compare and combine outputs from all 4 providers into a single consensus response."""
        if not responses:
            raise RuntimeError("No LLM responses available for synthesis.")

        if len(responses) == 1:
            return next(iter(responses.values())).content

        user_query = ""
        for m in reversed(original_messages):
            if m.get("role") == "user":
                user_query = m.get("content", "")
                break

        formatted_outputs = []
        for name, resp in responses.items():
            formatted_outputs.append(
                f"=== {name.upper()} (Model: {resp.model}) ===\n{resp.content}\n"
            )

        synth_prompt = (
            f"User Original Request:\n{user_query}\n\n"
            f"Here are independent responses from {len(responses)} top AI models:\n\n"
            + "\n".join(formatted_outputs)
            + "\nTask:\n"
            "Compare all model responses. Identify key consensus points where all models agree, "
            "resolve any conflicting details, and synthesize a single complete, highly accurate, "
            "and polished unified answer combining the best points from all outputs."
        )

        synth_client = self.clients.get(self.synthesizer_key) or next(iter(self.clients.values()))

        try:
            synth_resp = synth_client.chat(
                messages=[{"role": "user", "content": synth_prompt}],
                system="You are an expert AI Consensus Synthesizer.",
                json_mode=json_mode,
            )
            return synth_resp.content
        except Exception as exc:
            logger.warning("Synthesis call failed: %s. Falling back to longest response.", exc)
            return max(responses.values(), key=lambda r: len(r.content)).content

    def chat(
        self,
        messages: list[dict[str, str]],
        *,
        model: str | None = None,
        max_tokens: int | None = None,
        temperature: float | None = None,
        json_mode: bool = False,
        system: str | None = None,
        strip_thinking: bool = False,
    ) -> LLMResponse:
        """Main chat endpoint compatible with LLMClient interface.

        Queries all 4 providers concurrently and returns synthesized consensus.
        """
        all_responses = self.chat_all(
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature,
            json_mode=json_mode,
            system=system,
        )

        if not all_responses:
            raise RuntimeError("All ensemble providers failed.")

        final_content = self.synthesize(messages, all_responses, json_mode=json_mode)

        if strip_thinking:
            from researchclaw.utils.thinking_tags import strip_thinking_tags

            final_content = strip_thinking_tags(final_content)

        prompt_tok = sum(r.prompt_tokens for r in all_responses.values())
        comp_tok = sum(r.completion_tokens for r in all_responses.values())

        return LLMResponse(
            content=final_content,
            model=f"ensemble-consensus({','.join(all_responses.keys())})",
            prompt_tokens=prompt_tok,
            completion_tokens=comp_tok,
            total_tokens=prompt_tok + comp_tok,
            raw={"individual_responses": {k: v.raw for k, v in all_responses.items()}},
        )

    def preflight(self) -> tuple[bool, str]:
        """Preflight check across all ensemble clients."""
        statuses = []
        any_ok = False

        for name, client in self.clients.items():
            ok, msg = client.preflight()
            if ok:
                any_ok = True
                statuses.append(f"✓ {name}: {msg}")
            else:
                statuses.append(f"✗ {name}: {msg}")

        status_str = " | ".join(statuses)
        return any_ok, f"Ensemble preflight: {status_str}"
