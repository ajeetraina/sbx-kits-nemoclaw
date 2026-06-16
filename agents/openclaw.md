# OpenClaw (default)

[OpenClaw](https://openclaw.ai) is NemoClaw's default agent. This is what the
`:latest` / `:openclaw` tag selects.

| | |
|---|---|
| NemoClaw agent | `openclaw` (`NEMOCLAW_AGENT=openclaw`) |
| CLI entrypoint | `nemoclaw` |
| Default inference | NVIDIA Endpoints (`build.nvidia.com`) |
| Credential | `NVIDIA_INFERENCE_API_KEY` |
| Inference host | `integrate.api.nvidia.com` |

## Credential (store it as a custom secret)

`sbx run` has no `-e` flag, and NVIDIA is **not** a built-in sbx secret service.
Store the key once as a *custom* secret bound to the NVIDIA host; the sandbox sees
only a `nvapi-…` placeholder and the proxy swaps in the real key on requests to
that host:

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

> The `nvapi-{rand}` placeholder keeps NemoClaw's local `nvapi-` prefix check
> happy while the real key stays on the proxy. This is why the spec does **not**
> declare `NVIDIA_INFERENCE_API_KEY` or use `proxyManaged`.

## Run

```bash
sbx secret set-custom -g --host integrate.api.nvidia.com \
  --env NVIDIA_INFERENCE_API_KEY --placeholder 'nvapi-{rand}' \
  --value "$NVIDIA_INFERENCE_API_KEY"
sbx run --kit docker.io/ajeetraina777/sbx-nemoclaw-kits:latest claude
# or straight from this repo, no Hub pull:
sbx run --kit ./kits/openclaw claude
```

## What the kit contains

`kits/openclaw/spec.yaml` wires everything:

- installs the `nemoclaw` / `nemohermes` CLIs from the NVIDIA repo via npm,
- sets `NEMOCLAW_AGENT=openclaw` and `NEMOCLAW_PROVIDER=build` (NVIDIA Endpoints),
- allows `github.com`, `registry.npmjs.org`, and `integrate.api.nvidia.com`,
- writes `~/.nemoclaw/onboard.env` with non-interactive onboarding defaults.

## Onboard (inside the sandbox)

```console
!source ~/.nemoclaw/onboard.env && nemoclaw onboard --non-interactive
```

## Switch inference provider

To run OpenClaw against, say, Anthropic instead of NVIDIA Endpoints, edit the kit
before launching: set `NEMOCLAW_PROVIDER: "anthropic"`, swap the key var to
`ANTHROPIC_API_KEY` (under both `variables` and `proxyManaged`), add
`api.anthropic.com` to `allowedDomains`, then store the key
(`sbx secret set -g anthropic`) and run. See [agents/README.md](./README.md) for
the full provider matrix.
