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

Each kit clones the NemoClaw repo, builds it (the `npm install` `prepare` step
compiles its TypeScript `dist/`), installs the `nemoclaw` / `nemohermes` CLIs
globally on `PATH`, sets `NEMOCLAW_AGENT` to the tag's agent, defaults
`NEMOCLAW_PROVIDER=build` (NVIDIA Endpoints), allows the install + inference
domains, and writes `~/.nemoclaw/onboard.env` with non-interactive onboarding
defaults. Inside the sandbox:

    source ~/.nemoclaw/onboard.env && nemoclaw onboard --non-interactive

## Caveats — this is a CLI + cloud-mode mixin

The kit installs and drives the `nemoclaw` / `nemohermes` CLI and supports cloud /
routed inference (NVIDIA Endpoints). It does **not** let you run NemoClaw's full
**local** OpenShell stack inside an sbx sandbox.

`nemoclaw onboard`'s gateway runs **k3s**, whose kubelet needs `/dev/kmsg`
(`open /dev/kmsg: no such file or directory`). Docker Sandboxes deliberately
withholds `/dev/kmsg` from the workload, and k3s requires it — a structural
collision no kit setting can bridge. Run the local-OpenShell layer on a real host
/ VM, or use NemoClaw's cloud-only mode. NemoClaw also needs **Node.js 22.16+**.

Full writeup: https://www.ajeetraina.com/i-tried-to-run-nvidia-nemoclaw-inside-docker-sandboxes-it-got-seven-layers-deep-before-hitting-a-wall/

Per-agent setup notes and the raw `spec.yaml` for each kit live on GitHub:
https://github.com/ajeetraina/sbx-kits-nemoclaw/tree/main/agents
