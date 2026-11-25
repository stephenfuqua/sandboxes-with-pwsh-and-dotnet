# Spec: Docker Sandbox mixin for PowerShell and .NET SDK

## Objective

Replace the two per-agent Docker images in this repository with a single
[Docker Sandbox mixin](https://docs.docker.com/ai/sandboxes/customize/author/tool-mixins/)
(a "kit") that adds PowerShell and the .NET SDK to any v3 sandbox workload
(`claude`, `copilot`, `shell`, ...).

Why: today the same install steps are duplicated across two dockerfiles, each
pinned to a base-image digest and carrying an Ubuntu 24.04 apt-feed workaround.
A mixin is agent-agnostic, needs no base-image pinning, and can declare the
NuGet network access the tools need.

Users: developers running agents in Docker Sandbox who need `pwsh` and
`dotnet` available in the sandbox.

Decisions already made (from review):

- Replace the existing dockerfiles once the mixin is verified.
- One combined mixin (`pwsh-dotnet`), not two.
- Install from official relocatable tarballs in a build stage.
- Test with a local `--kit ./dir`; publish to Docker Hub with `buildx`.

## Tech Stack

- Docker Sandbox CLI (`sbx`), kit schema `# syntax=docker/sandbox-kit:3`,
  `schemaVersion: "3"`, `kind: mixin`
- BuildKit (`docker buildx`), `FROM scratch` final stage
- PowerShell 7.6.5 (arg default), .NET SDK 10.0 (arg default)

## Commands

```bash
# Test locally (sandbox name must be new after each kit edit)
sbx run shell --name pwsh-dotnet-test --kit ./pwsh-dotnet-mixin

# Verify inside the sandbox
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
dotnet --version
dotnet new console -o /tmp/hello && dotnet run --project /tmp/hello   # needs NuGet access

# Build and publish
docker buildx build -f pwsh-dotnet-mixin/pwsh-dotnet-mixin.dockerfile \
  -t <dockerhub-user>/pwsh-dotnet-mixin:<version> --push pwsh-dotnet-mixin

# Consume published
sbx run claude --kit <dockerhub-user>/pwsh-dotnet-mixin:<version>
```

## Project Structure

```text
pwsh-dotnet-mixin/
  pwsh-dotnet-mixin.dockerfile  → build stage (download tarballs) + scratch final stage
  pwsh-dotnet-mixin.yaml        → descriptor: args, provides, capabilities
README.md                       → usage, publishing, requirements, licensing
NOTICES.md                      → third-party license notices
SPEC.md                         → this file
```

The two legacy per-agent dockerfiles (Claude and Copilot) were removed after verification.

## Code Style

Descriptor (see `pwsh-dotnet-mixin/pwsh-dotnet-mixin.yaml`; syntax confirmed against
the upstream `docker/sandbox-kit-spec` v3 spec and JSON schema):

```yaml
# syntax=docker/sandbox-kit:3
schemaVersion: "3"
kind: mixin
displayName: PowerShell and .NET SDK
description: PowerShell and the .NET SDK from Microsoft's official release tarballs, as a self-contained overlay
licenses: [MIT]
dockerfile: pwsh-dotnet-mixin.dockerfile

args:
  pwshVersion:
    default: "7.6.5"
    pattern: '^[0-9]+\.[0-9]+\.[0-9]+$'
    buildArg: PWSH_VERSION
  # Release channel; the build resolves it to the latest SDK in that channel.
  dotnetChannel:
    default: "10.0"
    pattern: '^[0-9]+\.[0-9]+$'
    buildArg: DOTNET_CHANNEL

provides:
  - "pwsh@${{ kit.args.pwshVersion }}"
  - "dotnet@${{ kit.args.dotnetChannel }}"

capabilities:
  - type: com.docker.sandbox/network-policy@1
    config:
      runtime:
        allow:
          # NuGet package restore. Downloads at build time use the builder's network and need no rule.
          - api.nuget.org:443
```

Notes from the v3 spec: `provides` entries must be versioned and may reference
args; there is no environment-variable capability (a mixin's image `ENV` merges
into the workload, while `entrypoint`, `cmd`, `user` and `workdir` are ignored);
the descriptor names its Dockerfile with `dockerfile:`.

Dockerfile conventions: multi-stage, `TARGETARCH` for amd64/arm64 selection,
checksum-verified downloads, final stage `FROM scratch` with `COPY --from`
only; no apt in the final stage; tools under `/opt`, symlinked into a
directory on the workload's `PATH` (`/usr/local/bin`). Pin versions via args,
not literals. Comments explain why, not what.

## Testing Strategy

No unit-test framework applies; verification is behavioural. `sbx` is **not
installed** in the agent sandbox, so verification is split in two.

**A. Verified in the agent sandbox (Docker daemon available):**

- Build: `docker buildx build` succeeds from a clean cache; the final image
  contains only the intended files (inspect with `docker create` + `docker export | tar -t`).
- Checksums: tarball downloads verify (requires firewall access to the
  download hosts; otherwise handed to the host).
- Library check (stand-in for compatibility): run `ldd` on `pwsh`/`dotnet`
  binaries and `pwsh -c` / `dotnet --version` inside an `ubuntu:26.04`
  container with the mixin files copied in, and list any missing libraries.

**B. Handed to the user to run on their host (needs `sbx`):**

- Smoke: `pwsh` and `dotnet` run on the `shell` workload (amd64; arm64 if
  hardware is available).
- Compatibility: same smoke on the `claude` and `copilot` workloads, which
  are Ubuntu 26.04 based. This confirms the workload provides the native
  libraries (ICU, OpenSSL, zlib, etc.) the tarballs need.
- Functional: `dotnet new console` + `dotnet run` succeeds with NuGet access
  allowed by the descriptor and no extra user policy.
- Negative: with the kit's network rule absent, restore fails (confirms the
  rule is what grants access).

## Boundaries

- Always: verify checksums of downloaded tarballs; keep the final stage
  `scratch`; test on a fresh sandbox name after each kit edit; keep versions
  as args.
- Ask first: adding network allow entries beyond NuGet; adding the
  `credential` capability; adding further tools to the mixin; changing the
  published image name or Docker Hub namespace; deleting the old dockerfiles
  (only after verification passes).
- Never: commit credentials or registry tokens; push to Docker Hub without
  confirmation; widen network policy to wildcards for convenience.

## Known Limitations

- **Workload warning (accepted, documented):** the first `dotnet` command per
  fresh home directory prints `An issue was encountered verifying workloads.`
  `/opt/dotnet` is root-owned and read-only for the `agent` user, so the SDK
  cannot create `/opt/dotnet/metadata`. It does not affect restore, build or
  run. `dotnet workload install` will fail for the same reason. Decision: leave
  as is rather than make a directory world-writable. A possible future fix is
  `mkdir -m 0777 /out/opt/dotnet/metadata` in the build stage.
- Telemetry is opted out via image `ENV` (`DOTNET_CLI_TELEMETRY_OPTOUT`,
  `DOTNET_NOLOGO`, `POWERSHELL_TELEMETRY_OPTOUT`).
- Requires a workload that provides ICU, OpenSSL, libstdc++, zlib and Kerberos
  libraries (the `claude-code` and `copilot` templates do).
- Each build pulls the latest SDK of the channel, so builds are not
  reproducible across SDK releases.

## Success Criteria

1. `sbx run shell --kit ./pwsh-dotnet-mixin` yields a shell where
   `pwsh --version` prints 7.6.5 and `dotnet --version` prints a 10.0.x SDK.
2. The same holds with the `claude` and `copilot` workloads.
3. `dotnet restore` of a console project succeeds with only the kit's
   network rules in effect.
4. The mixin publishes to Docker Hub and can be consumed by reference.
5. The two legacy dockerfiles and their digest pins are removed; the README
   documents the mixin, requirements (v3 workload), the NuGet note, and
   licensing (MIT Microsoft software; tarball sources).
6. ~~The README warning about giving agents build tools remains.~~ Dropped: the warning was removed deliberately.

## Open Questions

1. **Is `sbx` available in this sandbox?** If not, verification must happen on
   your host and I would hand over exact commands. (Likely, since we are
   inside a sandbox.)
2. **Runtime libraries on 26.04 workloads**: unverified. The spike in task 1
   answers this. If libraries are missing, options are bundling them into the
   mixin or declaring a different workload requirement.
3. **Exact network hosts** for `dotnet restore` (`api.nuget.org` alone vs.
   also `*.nuget.org` / `globalcdn.nuget.org`): determine empirically.
4. ~~Exact `provides` and `args` syntax~~: resolved from the upstream v3 spec.
5. **Docker Hub namespace and image name** for publishing.
6. **Tarball sources**: PowerShell from GitHub releases vs. `aka.ms`; .NET via
   `dotnet-install.sh` vs. direct download. Both need checksums.
7. **Does `sbx` need to be on a minimum version** for kit support? Document it.
