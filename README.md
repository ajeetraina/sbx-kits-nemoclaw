# sbx-kits-nemoclaw

A **mixin kit** for [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/)
(`sbx`) that adds the [NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw) CLI to
whatever **sbx host agent** you run (`claude`, `codex`, `gemini`, … — the agent in
`sbx run --kit ./ claude`).

NemoClaw is a reference stack for running always-on AI agents inside
[NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) sandboxes, with guided
onboarding, routed inference, and network policy. This kit installs the
`nemoclaw` / `nemohermes` CLIs so the sbx host agent can onboard and drive
NemoClaw.


## Run the published kit

The kit is published on Docker Hub, so you can run it directly — no clone needed.
Store the NVIDIA inference key once (see [Inference key](#inference-key)), then:

```bash
# OpenClaw (default)
sbx run --kit docker.io/ajeetraina777/sbx-nemoclaw-kits:latest claude

# Hermes
sbx run --kit docker.io/ajeetraina777/sbx-nemoclaw-kits:hermes claude
```

`:latest` and `:openclaw` are the same image; `:hermes` selects the Hermes agent.
The `claude` at the end is the sbx host agent — swap it for `codex`, `gemini`, etc.

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
2. **Store the inference key** (see [Inference key](#inference-key) below):
   ```console
   sbx secret set-custom -g --host integrate.api.nvidia.com \
     --env NVIDIA_INFERENCE_API_KEY --placeholder 'nvapi-{rand}' \
     --value "$NVIDIA_INFERENCE_API_KEY"
   ```
3. **Try it without publishing** by layering the local directory onto an agent:
   ```console
   sbx run --kit ./ claude              # OpenClaw
   sbx run --kit ./kits/hermes claude   # Hermes
   ```
4. **Publish**:
   ```console
   DOCKERHUB_NAMESPACE=<you> ./scripts/push-kits.sh
   # then: sbx run --kit docker.io/<you>/sbx-nemoclaw-kits:latest claude
   ```

## The two axes: agent and inference provider

| Axis | Choices | How it's selected |
|---|---|---|
| **NemoClaw agent** (image tag) | OpenClaw (default), Hermes | `NEMOCLAW_AGENT` — one kit per NemoClaw agent |
| **Inference provider** | NVIDIA Endpoints (default), OpenAI, Anthropic, Gemini, custom | `NEMOCLAW_PROVIDER` + matching `*_API_KEY` at onboarding |

(The **sbx host agent** — `claude` / `codex` / `gemini` — is a separate, third
choice you make on the `sbx run` command line; it is independent of both axes.)

Both kits default inference to **NVIDIA Endpoints** (`build.nvidia.com`,
`NVIDIA_INFERENCE_API_KEY`). See [`agents/README.md`](./agents/README.md) for the
full provider matrix and how to switch.

## Inference key

The kit contains no API key. NemoClaw defaults to **NVIDIA Endpoints**, and sbx
has **no built-in `nvidia` secret service** — so the key is injected as a
**custom secret** bound to the NVIDIA host:

```console
sbx secret set-custom -g \
  --host integrate.api.nvidia.com \
  --env NVIDIA_INFERENCE_API_KEY \
  --placeholder 'nvapi-{rand}' \
  --value "$NVIDIA_INFERENCE_API_KEY"
```

What this does (`sbx secret set-custom --help`):

- sets `NVIDIA_INFERENCE_API_KEY` in the sandbox to a `nvapi-…` **placeholder**
  (the `nvapi-` prefix satisfies NemoClaw's local key-format check), and
- the sbx proxy swaps the placeholder for the real key **only** on outbound
  requests to `integrate.api.nvidia.com`.

So the real key never enters the spec, the image, or the sandbox filesystem
(`sbx run` has no `-e` flag). That is why the spec does **not** declare
`NVIDIA_INFERENCE_API_KEY` and does **not** use `proxyManaged`.

### Switching to a built-in provider instead

OpenAI, Anthropic, and Google **are** built-in sbx services, so for those you can
use the simpler `proxyManaged` path: set `NEMOCLAW_PROVIDER` (`openai` /
`anthropic` / `gemini`), swap `integrate.api.nvidia.com` in `allowedDomains` for
that provider's host, add the key var to `environment.proxyManaged`, and store it
with `sbx secret set -g <service>` (e.g. `-g openai`). See
[`agents/README.md`](./agents/README.md) for the full matrix.

## The `agentContext` block matters

Installing the CLI is not enough. the agent has to *know* it's there. The
`agentContext` block is appended to the agent's memory file (`CLAUDE.md` /
`AGENTS.md`) so the agent reaches for NemoClaw and knows the onboarding one-liner.

> `agentContext` is the kit-spec v2 field name; older schemas called it `memory`.

## What this kit does and the hard limit

NemoClaw is a **host-side orchestrator**, not a self-contained library like mem0.
Be precise about what the mixin can and cannot do inside an sbx sandbox.

**✅ Works (verified):**
- Installs a working `nemoclaw` / `nemohermes` CLI. Note: a plain
  `npm install -g git+…NemoClaw.git` does **not** work — NemoClaw's bin needs a
  compiled `dist/` that only its `prepare` (TypeScript) build produces (the
  published `nemoclaw@0.1.0` on npm is broken the same way). The kit therefore
  clones, runs `npm install` (builds `dist/` via the local `tsc` devDep), drops
  `.git` (so `prepare`'s `npm-link-or-shim.sh` doesn't symlink a shim into the
  deleted source tree), then installs globally. Verified on the `shell` and
  `claude` base images (Node v22.22, npm 9) → `nemoclaw --version` = `v0.1.0`.
- CLI inspection/config and **cloud / routed inference** setup
  (`NEMOCLAW_PROVIDER=build` → NVIDIA Endpoints) — the parts that don't need a
  local OpenShell gateway.

**❌ Does NOT work — `nemoclaw onboard` creating a *local* OpenShell sandbox.**
This is a structural wall, not a kit bug. NemoClaw's gateway runs **k3s**, and
k3s's kubelet needs `/dev/kmsg`:

```
failed to run Kubelet: ... open /dev/kmsg: no such file or directory
```

Docker Sandboxes **deliberately** does not expose `/dev/kmsg` to the workload (it
leaks host kernel state); k3s **requires** it for node health. Two security models
collide — both correct for their threat model — so no env var, install step, or
privilege flag in this kit can bridge it. The local-OpenShell layer must run where
a real host kernel is reachable (bare host, a VM, or NemoClaw's cloud-only mode).

Full writeup of the nesting and the exact wall:
[*I tried to run NVIDIA NemoClaw inside Docker Sandboxes — it got seven layers deep before hitting a wall*](https://www.ajeetraina.com/i-tried-to-run-nvidia-nemoclaw-inside-docker-sandboxes-it-got-seven-layers-deep-before-hitting-a-wall/).

**Other note:** NemoClaw requires **Node.js ≥ 22.16** in the base image; the first
install step (`node --version`) fails fast if it's older.

So treat this as a **CLI + cloud-mode** mixin, not a "run OpenShell inside sbx"
one. The kit is structured so each assumption (Node, install command, provider,
secret name) is a single, clearly-labeled line in `spec.yaml` you can change.

## Proving the mixin is inside the sandbox

After launching an agent with the kit, verify on independent layers (use `!`
shell escapes inside the agent session):

```console
# 1. The CLI the kit installed is on PATH at the expected version
!nemoclaw --version

# 2. The env vars the kit set are present (these exist only in your spec)
!env | grep -E 'NEMOCLAW_AGENT|NEMOCLAW_PROVIDER'

# 3. The init file the kit wrote exists
!cat ~/.nemoclaw/onboard.env

# 4. End-to-end: drive the CLI
!source ~/.nemoclaw/onboard.env && nemoclaw --help
```

`#2` + `#3` are the distinguishing signature that the **mixin** (not a manual
install) wired things up, since both are declared only in `spec.yaml`.

