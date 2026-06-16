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

## Credential (store it as a custom secret)

NVIDIA is **not** a built-in sbx secret service, so store the key as a *custom*
secret bound to the NVIDIA host. The sandbox sees only a `nvapi-…` placeholder;
the proxy swaps in the real key on requests to that host:

> ⚠️ `sbx secret set-custom` is marked **EXPERIMENTAL** (may change in future sbx
> releases), and it has **no stdin option** — the value is passed via `--value`,
> which sbx flags as "visible in shell history". Pass it from an env var (as below)
> rather than pasting the literal key, and clear your history if needed.

```bash
sbx secret set-custom -g \
  --host integrate.api.nvidia.com \
  --env NVIDIA_INFERENCE_API_KEY \
  --placeholder 'nvapi-{rand}' \
  --value "$NVIDIA_INFERENCE_API_KEY"
```

> The `nvapi-{rand}` placeholder satisfies NemoClaw's local `nvapi-` prefix check
> while the real key stays on the proxy. This is why the spec does **not** declare
> `NVIDIA_INFERENCE_API_KEY` or use `proxyManaged`.

## Run

```bash
sbx secret set-custom -g --host integrate.api.nvidia.com \
  --env NVIDIA_INFERENCE_API_KEY --placeholder 'nvapi-{rand}' \
  --value "$NVIDIA_INFERENCE_API_KEY"
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
