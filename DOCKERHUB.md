# NemoClaw kit for Docker Sandboxes

A standalone [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) kit
(`kind: mixin`) that adds the [NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw)
CLI to any sandbox agent. NemoClaw runs always-on AI agents inside
[NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) sandboxes, with guided
onboarding, routed inference, and network-policy controls. This image ships one
tag per supported **NemoClaw agent**.

> Two distinct "agent" layers: the **sbx host agent** (`claude` / `codex` /
> `gemini`) is what `sbx run` launches and this mixin layers onto; the **NemoClaw
> agent** (`OpenClaw` / `Hermes`) is what NemoClaw runs inside OpenShell. The image
> tags below select the NemoClaw agent.

Source and full docs: https://github.com/ajeetraina/sbx-kits-nemoclaw

## Image tags

| Tag | Agent | CLI | Default inference | Credential |
|-----|-------|-----|-------------------|------------|
| `latest`, `openclaw` | OpenClaw (default) | `nemoclaw` | NVIDIA Endpoints | `NVIDIA_INFERENCE_API_KEY` |
| `hermes` | Hermes | `nemohermes` | NVIDIA Endpoints | `NVIDIA_INFERENCE_API_KEY` |

Both tags install the same `nemoclaw` + `nemohermes` CLIs and differ only in which
agent `NEMOCLAW_AGENT` selects. Inference defaults to NVIDIA Endpoints
(`build.nvidia.com`); you can switch to OpenAI, Anthropic, Gemini, or any
OpenAI-compatible endpoint at onboarding time.

## Quick start

NVIDIA is not a built-in sbx secret service, so store the key as a custom secret
bound to the NVIDIA host, then run (`set-custom` is experimental; it takes the
value via `--value`, so pass it from an env var rather than the literal key):

    sbx secret set-custom -g --host integrate.api.nvidia.com \
      --env NVIDIA_INFERENCE_API_KEY --placeholder 'nvapi-{rand}' \
      --value "$NVIDIA_INFERENCE_API_KEY"

    sbx run --kit docker.io/ajeetraina777/sbx-nemoclaw-kits:latest claude   # OpenClaw
    sbx run --kit docker.io/ajeetraina777/sbx-nemoclaw-kits:hermes claude   # Hermes

The kit holds no key. The sandbox sees only a `nvapi-…` placeholder; the sbx proxy
swaps it for the real key on outbound requests to `integrate.api.nvidia.com`, so
the key never enters the sandbox. `sbx run` has no `-e` flag by design.

## How it works

Each kit installs the NemoClaw CLI from the NVIDIA repo via npm into
`~/.local/bin`, sets `NEMOCLAW_AGENT` to the tag's agent, defaults
`NEMOCLAW_PROVIDER=build` (NVIDIA Endpoints), allows the install + inference
domains, and writes `~/.nemoclaw/onboard.env` with non-interactive onboarding
defaults. Inside the sandbox:

    source ~/.nemoclaw/onboard.env && nemoclaw onboard --non-interactive

## Caveats

NemoClaw is a host-side orchestrator: it needs **Node.js 22.16+** and **Docker**
to create OpenShell sandboxes (Docker + k3s + an ~2.4 GB image). A standard sbx
sandbox does not nest Docker, so this mixin is primarily for **installing and
driving the CLI** from an agent; full `nemoclaw onboard` runs where a Docker
daemon is reachable. See the GitHub README for details.

Per-agent setup notes and the raw `spec.yaml` for each kit live on GitHub:
https://github.com/ajeetraina/sbx-kits-nemoclaw/tree/main/agents
