# Agents and inference providers for the NemoClaw kit

[NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw) is a reference stack for
running always-on AI agents inside [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell)
sandboxes. It supports two agents, and the kit ships one image tag per agent:

| Agent | Tag | CLI entrypoint | Select with |
|---|---|---|---|
| [OpenClaw](./openclaw.md) (default) | `:openclaw` / `:latest` | `nemoclaw` | `NEMOCLAW_AGENT=openclaw` |
| [Hermes](./hermes.md) | `:hermes` | `nemohermes` | `NEMOCLAW_AGENT=hermes` |

Both tags install the **same** `nemoclaw` + `nemohermes` CLIs; they differ only
in which agent `NEMOCLAW_AGENT` selects and which onboarding defaults the
`~/.nemoclaw/onboard.env` file carries.

## The two axes: agent vs. inference provider

NemoClaw separates *which agent runs* from *which model serves it*:

- **Agent** — `OpenClaw` or `Hermes`. This is the image-tag axis above.
- **Inference provider** — where the agent's model traffic is routed. The agent
  inside the sandbox always talks to `inference.local`; NemoClaw routes it to the
  provider you pick during `nemoclaw onboard`.

Both kits default the inference provider to **NVIDIA Endpoints**
(`build.nvidia.com`, key `NVIDIA_INFERENCE_API_KEY`). You can switch to any of the
providers below by changing two things before onboarding: `NEMOCLAW_PROVIDER` and
the matching `*_API_KEY`.

| Provider | `NEMOCLAW_PROVIDER` | Key env var | API host | sbx secret path |
|---|---|---|---|---|
| NVIDIA Endpoints (default) | `build` | `NVIDIA_INFERENCE_API_KEY` | `integrate.api.nvidia.com` | **custom** (`set-custom`) |
| OpenAI | `openai` | `OPENAI_API_KEY` | `api.openai.com` | built-in (`set -g openai`) |
| Anthropic | `anthropic` | `ANTHROPIC_API_KEY` | `api.anthropic.com` | built-in (`set -g anthropic`) |
| Google Gemini | `gemini` | `GEMINI_API_KEY` | `generativelanguage.googleapis.com` | built-in (`set -g google`) |
| Other OpenAI-compatible | `custom` | `COMPATIBLE_API_KEY` | your `NEMOCLAW_ENDPOINT_URL` | custom (`set-custom`) |

**NVIDIA is not a built-in sbx secret service.** Its key is injected as a *custom*
secret bound to the NVIDIA host (the sandbox sees only a placeholder):

```bash
sbx secret set-custom -g --host integrate.api.nvidia.com \
  --env NVIDIA_INFERENCE_API_KEY --placeholder 'nvapi-{rand}' \
  --value "$NVIDIA_INFERENCE_API_KEY"
```

The built-in providers (OpenAI / Anthropic / Google) use the simpler
`sbx secret set -g <service>` path. To switch provider you also change
`NEMOCLAW_PROVIDER` and swap the API host in the kit's `network.allowedDomains`
(the default kits only allow `integrate.api.nvidia.com`), then re-run onboarding.
See the per-agent pages for the exact commands.

## Two things that apply to every agent

1. **NemoClaw needs Docker on the host.** It creates OpenShell sandboxes (Docker +
   k3s + an ~2.4 GB image). A standard sbx sandbox does not nest Docker, so full
   `nemoclaw onboard` is expected to run where a Docker daemon is reachable. This
   mixin installs the **CLI** so an agent can inspect, configure, and drive
   NemoClaw; see the kit README "Caveats" section.
2. **Credentials stay out of the sandbox.** The real key is held by the sbx proxy
   (a stored secret); the sandbox sees only a placeholder and the proxy swaps it in
   on outbound requests to the provider host (`sbx run` has no `-e` flag). The key
   never enters the spec, the image, or the sandbox filesystem.

## How to switch agent

Each agent is published as an image tag, and the same specs live under
[`kits/`](../kits). Pick one and run it:

```bash
sbx secret set-custom -g --host integrate.api.nvidia.com \
  --env NVIDIA_INFERENCE_API_KEY --placeholder 'nvapi-{rand}' \
  --value "$NVIDIA_INFERENCE_API_KEY"
sbx run --kit docker.io/ajeetraina777/sbx-nemoclaw-kits:hermes claude
# or from this repo:
sbx run --kit ./kits/hermes claude
```
