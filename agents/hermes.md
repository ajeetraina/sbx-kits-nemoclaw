# Hermes

[Hermes](https://get-hermes.ai/) is NemoClaw's second supported agent. This is
what the `:hermes` tag selects.

| | |
|---|---|
| NemoClaw agent | `hermes` (`NEMOCLAW_AGENT=hermes`) |
| CLI entrypoint | `nemohermes` (alias of `nemoclaw` with the Hermes agent) |
| Default inference | NVIDIA Endpoints (`build.nvidia.com`) |
| Credential | `NVIDIA_INFERENCE_API_KEY` |
| Inference host | `integrate.api.nvidia.com` |

Hermes also exposes a dedicated **Hermes Provider** inference route during
onboarding (curated models such as `moonshotai/kimi-k2.6` and
`openai/gpt-5.4-mini`). The kit defaults to NVIDIA Endpoints; pick the Hermes
Provider route interactively with `nemohermes onboard` if you prefer it.

## Credential (store it as a secret, never on the command line)

```bash
echo "$NVIDIA_INFERENCE_API_KEY" | sbx secret set -g nvidia
```

> `nvidia` is the secret name the kit expects via `proxyManaged`. If your sbx
> build does not recognize it as a managed service, store it under whatever name
> your proxy maps to `NVIDIA_INFERENCE_API_KEY` and adjust `spec.yaml`.

## Run

```bash
echo "$NVIDIA_INFERENCE_API_KEY" | sbx secret set -g nvidia
sbx run --kit docker.io/ajeetraina777/sbx-nemoclaw-kits:hermes claude
# or straight from this repo:
sbx run --kit ./kits/hermes claude
```

## What the kit contains

`kits/hermes/spec.yaml` is identical to the OpenClaw kit except:

- `NEMOCLAW_AGENT=hermes` (selects Hermes instead of OpenClaw),
- `~/.nemoclaw/onboard.env` defaults to `nemohermes`.

The same `nemoclaw` / `nemohermes` CLIs are installed; only the selected agent
differs.

## Onboard (inside the sandbox)

```console
!source ~/.nemoclaw/onboard.env && nemohermes onboard --non-interactive
```

## Switch inference provider

Same procedure as OpenClaw — change `NEMOCLAW_PROVIDER`, the `*_API_KEY` var
(in `variables` and `proxyManaged`), and `allowedDomains`. See
[agents/README.md](./README.md) for the provider matrix.
