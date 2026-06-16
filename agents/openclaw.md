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

## Credential (store it as a secret, never on the command line)

`sbx run` has no `-e` flag. Store the key once with sbx's secret manager; the
proxy injects it at runtime so it never enters the sandbox or your shell history:

```bash
echo "$NVIDIA_INFERENCE_API_KEY" | sbx secret set -g nvidia
# or run `sbx secret set -g nvidia` for an interactive prompt
```

> `nvidia` is the secret name the kit expects via `proxyManaged`. If your sbx
> build does not recognize `nvidia` as a managed service, store it under whatever
> name your proxy maps to `NVIDIA_INFERENCE_API_KEY` and adjust `spec.yaml`.

## Run

```bash
echo "$NVIDIA_INFERENCE_API_KEY" | sbx secret set -g nvidia
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
