# sbx-kits-nemoclaw

A **mixin kit** for [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/)
(`sbx`) that adds the [NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw) CLI to
an existing sbx agent (`claude`, `codex`, `gemini`, …).

NemoClaw is a reference stack for running always-on AI agents inside
[NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) sandboxes, with guided
onboarding, routed inference, and network policy. This kit installs the
`nemoclaw` / `nemohermes` CLIs so whatever agent you already run can onboard and
drive NemoClaw. It ships **one image tag per supported agent**: OpenClaw (default)
and Hermes.

## Layout

```
spec.yaml                  # default kit (OpenClaw) — fill in / tweak
kits/openclaw/spec.yaml    # OpenClaw variant (== root)
kits/hermes/spec.yaml      # Hermes variant
agents/README.md           # agent + inference-provider matrix
agents/openclaw.md         # per-tag docs
agents/hermes.md
scripts/push-kits.sh       # validate + push each kit as an image tag
.github/workflows/push-kits.yaml
DOCKERHUB.md               # Docker Hub overview page
LICENSE                    # Apache-2.0
```

## Quick start

1. **Validate locally.**
   ```console
   sbx kit validate .
   sbx kit validate ./kits/hermes
   ```
2. **Try it without publishing** by layering the local directory onto an agent:
   ```console
   echo "$NVIDIA_INFERENCE_API_KEY" | sbx secret set -g nvidia
   sbx run --kit ./ claude              # OpenClaw
   sbx run --kit ./kits/hermes claude   # Hermes
   ```
3. **Publish** when it works:
   ```console
   DOCKERHUB_NAMESPACE=<you> ./scripts/push-kits.sh
   # then: sbx run --kit docker.io/<you>/sbx-nemoclaw-kits:latest claude
   ```

## The two axes: agent and inference provider

| Axis | Choices | How it's selected |
|---|---|---|
| **Agent** (image tag) | OpenClaw (default), Hermes | `NEMOCLAW_AGENT` — one kit per agent |
| **Inference provider** | NVIDIA Endpoints (default), OpenAI, Anthropic, Gemini, custom | `NEMOCLAW_PROVIDER` + matching `*_API_KEY` at onboarding |

Both kits default inference to **NVIDIA Endpoints** (`build.nvidia.com`,
`NVIDIA_INFERENCE_API_KEY`). See [`agents/README.md`](./agents/README.md) for the
full provider matrix and how to switch.

## Secrets: never hardcode

The kit contains no API key. Instead:

1. The var name is declared under `environment.proxyManaged`
   (`NVIDIA_INFERENCE_API_KEY`).
2. You store the value once: `sbx secret set -g nvidia`.
3. The sbx proxy injects it at runtime (`sbx run` has no `-e` flag), so the key
   never enters the spec, the image, or the sandbox filesystem.

To switch provider you swap the key var in both `environment.variables` and
`environment.proxyManaged`, add the provider's API host to
`network.allowedDomains`, and store the matching secret.

## The `agentContext` block matters

Installing the CLI is not enough — the agent has to *know* it's there. The
`agentContext` block is appended to the agent's memory file (`CLAUDE.md` /
`AGENTS.md`) so the agent reaches for NemoClaw and knows the onboarding one-liner.

> `agentContext` is the kit-spec v2 field name; older schemas called it `memory`.

## Caveats (read before relying on this)

NemoClaw is a **host-side orchestrator**, not a self-contained library like mem0:

- It requires **Node.js ≥ 22.16** in the sandbox base image. The first install
  step (`node --version`) fails fast if the base image is older.
- It creates OpenShell sandboxes using **Docker + k3s** and an ~2.4 GB image. A
  standard sbx sandbox does not nest Docker, so full `nemoclaw onboard` is
  expected to run where a Docker daemon is reachable. This mixin's job is to
  **install and expose the CLI** so an agent can configure and drive NemoClaw.
- The npm-from-git install runs NemoClaw's `prepare` build (TypeScript). It is the
  most likely thing to need adjustment on a given base image — validate it with a
  real `sbx run` before publishing.

These are honest limitations of putting an agent-orchestrator inside a sandbox;
the kit is structured so each assumption (Node, install command, provider, secret
name) is a single, clearly-labeled line in `spec.yaml` you can change.

## Proving the mixin is inside the sandbox

After launching an agent with the kit, verify on independent layers (use `!`
shell escapes inside the agent session):

```console
# 1. The CLI the kit installed is on PATH at the expected version
!~/.local/bin/nemoclaw --version

# 2. The env vars the kit set are present (these exist only in your spec)
!env | grep -E 'NEMOCLAW_AGENT|NEMOCLAW_PROVIDER'

# 3. The init file the kit wrote exists
!cat ~/.nemoclaw/onboard.env

# 4. End-to-end: drive the CLI
!source ~/.nemoclaw/onboard.env && nemoclaw --help
```

`#2` + `#3` are the distinguishing signature that the **mixin** (not a manual
install) wired things up, since both are declared only in `spec.yaml`.

