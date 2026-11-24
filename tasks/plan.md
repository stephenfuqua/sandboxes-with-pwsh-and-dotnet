# Plan: pwsh-dotnet mixin

Source: `SPEC.md`. Single capability, so no capability map.

## Components and dependencies

1. **Dockerfile** (`pwsh-dotnet-mixin/pwsh-dotnet-mixin.dockerfile`): build stage downloads and
   checksum-verifies PowerShell and .NET SDK tarballs by `TARGETARCH`; `FROM scratch` final stage
   copies `/opt/...` plus symlinks.
2. **Descriptor** (`pwsh-dotnet-mixin.yaml`): args, provides, network-policy. Depends on the
   Dockerfile's build arg names.
3. **README rewrite**: depends on the verified behaviour of 1 and 2.
4. **Cleanup**: remove legacy dockerfiles. Only after host verification passes.

Order: spike → Dockerfile → descriptor → in-sandbox verification → host handoff → README → cleanup.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Workload (Ubuntu 26.04) lacks native libs (ICU, OpenSSL, libstdc++, zlib) | Task 1 spike with `ldd` in an `ubuntu:26.04` container. If missing, ask before bundling libs or changing approach. |
| Firewall blocks download hosts in the agent sandbox | Try early (Task 1). If blocked, request allow via the user, or hand build to host. |
| Descriptor syntax (`provides`, `args`) unverified | Fetch the upstream Claude mixin example before writing the YAML (Task 3). |
| Symlinks across `scratch` copy break `PATH` lookup | Create the symlinks in the build stage; check with `docker export \| tar -t`. |
| `dotnet` needs a writable `$HOME` / first-run state | Verify first-run behaviour; set `DOTNET_CLI_TELEMETRY_OPTOUT` / `DOTNET_NOLOGO` only if the descriptor supports env. Ask first. |
| NuGet hosts incomplete | Host-side negative/functional test reveals needed hosts; iterate. |

## Parallelism

Tasks 2 and 3 are largely sequential (the YAML needs arg names). README draft (Task 6) can start
after Task 3 in parallel with host verification. Cleanup is strictly last.

## Checkpoints

- After Task 1: go/no-go on tarball approach.
- After Task 4: in-sandbox build and `ldd` clean.
- After Task 5: user reports host results; fix and re-run.
