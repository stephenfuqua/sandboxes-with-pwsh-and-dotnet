# Tasks: pwsh-dotnet mixin

- [x] Task 1: Spike: tarball sources, checksums, and native library needs (done: go)
  - Acceptance: Know the exact download URLs and checksum method for PowerShell 7.6.5 and .NET SDK 10.0 (amd64 + arm64); firewall access confirmed or blocker reported; `ldd` list of missing libs on `ubuntu:26.04` (empty or enumerated).
  - Verify: `docker run --rm ubuntu:26.04 ...` output captured; go/no-go reported to the user.
  - Files: none (scratch only)

- [x] Task 2: Write the Dockerfile
  - Acceptance: Two-stage; `TARGETARCH`-aware; checksum-verified; `PWSH_VERSION` / `DOTNET_CHANNEL` build args; installs under `/opt`, symlinks `pwsh` and `dotnet` into `/usr/local/bin`; final stage `FROM scratch`.
  - Verify: `docker buildx build -f pwsh-dotnet-mixin/pwsh-dotnet-mixin.dockerfile pwsh-dotnet-mixin` succeeds; `docker export | tar -t` shows only intended paths and symlinks.
  - Files: `pwsh-dotnet-mixin/pwsh-dotnet-mixin.dockerfile`

- [x] Task 3: Write the descriptor
  - Acceptance: Syntax matches the upstream kit example (confirmed by fetching it); args map to Dockerfile build args with validation patterns; `provides` for pwsh and dotnet; network-policy allows NuGet host(s).
  - Verify: Compare against the upstream example; YAML parses (`python -c 'import yaml...'` or `yq`).
  - Files: `pwsh-dotnet-mixin/pwsh-dotnet-mixin.yaml`

- [x] Task 4: In-sandbox verification
  - Acceptance: Binaries run in an `ubuntu:26.04` container with the mixin files overlaid: `pwsh --version` = 7.6.5, `dotnet --version` = 10.0.x, `dotnet new console` + `dotnet build` works given network access.
  - Verify: Command output pasted into the report; any missing lib listed.
  - Files: none (a scratch test script in the scratchpad)

- [x] Task 5: Host verification handoff (blocks cleanup)
  - Acceptance: A concise checklist of `sbx` commands is given to the user for `shell`, `claude`, `copilot`, restore, and negative test; results received.
  - Verify: User reports pass/fail; fixes iterated until all pass.
  - Files: none (optionally a section in README)

- [x] Task 6: Rewrite the README
  - Acceptance: Documents the mixin, requirements (v3 workload, minimum `sbx` version), local and published usage, NuGet note, version args, licensing; no stale references to removed images; documents the accepted workload warning and the telemetry opt-out (see SPEC.md Known Limitations).
  - Verify: Markdown lint passes if configured; every command in the README was run or is copied from verified steps.
  - Files: `README.md`

- [ ] Task 7: Remove legacy dockerfiles (after Task 5 passes and the user confirms)
  - Acceptance: Both legacy dockerfiles deleted; the README no longer references them.
  - Verify: `git grep -n 'with-pwsh-and-dotnet.dockerfile'` returns nothing.
  - Files: `claude-with-pwsh-and-dotnet.dockerfile`, `copilot-with-pwsh-and-dotnet.dockerfile`

- [ ] Task 8: Publish (ask first)
  - Acceptance: User supplies Docker Hub namespace; user confirms the push; image consumable via `--kit <ref>`.
  - Verify: Host `sbx run claude --kit <ref>` and `pwsh`, `dotnet` work.
  - Files: none
