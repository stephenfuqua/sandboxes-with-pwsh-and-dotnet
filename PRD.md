# PRD: PowerShell and .NET SDK Mixin for Docker Sandbox

- **Status:** Released (v1 published to Docker Hub)
- **Owner:** Stephen A. Fuqua
- **Repository:** `sandboxes-with-pwsh-and-dotnet`
- **Sources:** `SPEC.md`, `README.md`, `NOTICES.md`, `tasks/plan.md`, `tasks/todo.md`,
  `tasks/host-verification.md`; Docker Sandbox documentation on
  [kits](https://docs.docker.com/ai/sandboxes/customize/) and
  [tool mixins](https://docs.docker.com/ai/sandboxes/customize/author/tool-mixins/)
- **Not available:** usage analytics, user research, issue tracker items

This PRD describes the capabilities of the released product. Build and packaging details live in
`SPEC.md`.

## 1. Product overview

The product is a Docker Sandbox mixin: an add-on that gives any compatible sandbox PowerShell and the
.NET SDK. A developer adds it when creating a sandbox, and the agent or person working in that
sandbox can then run PowerShell scripts and build, restore and run .NET projects.

It replaces two earlier images that each bundled the tools onto one specific agent's sandbox
template. Those images duplicated their install steps, were pinned to particular base images, and
needed a workaround for a missing package feed.

### 1.1 Strategic alignment

- **Agent-agnostic tooling:** one add-on works with any compatible workload (plain shell, Claude Code,
  Copilot and others) instead of one image per agent.
- **Lower maintenance:** no per-agent images to rebuild when an agent's template changes.
- **Declared access:** the add-on states the network access its tools need, so users do not have to
  hand-craft sandbox policy for routine package restore.
- **Trustworthy supply chain:** tools come from their official publishers and are integrity-checked.

### 1.2 Target users and personas

- **Sandbox user (developer):** runs coding agents in Docker Sandbox on .NET or PowerShell codebases.
  Comfortable with the command line. Pain point: agent templates lack these tools, and building a
  custom image per agent is tedious. Success: one flag on `sbx run` yields a working toolchain.
- **Coding agent:** the AI agent operating inside the sandbox. Needs `pwsh` and `dotnet` on the path
  and able to restore packages without interactive approval.
- **Maintainer / publisher:** builds and publishes the mixin, chooses default versions, and updates
  it when upstream releases change.

### 1.3 Jobs to be done

- When I start a sandbox for a .NET project, I want PowerShell and the .NET SDK already available, so
  that my agent can build and test the code without installing anything.
- When I switch agents (for example from Claude Code to Copilot), I want the same add-on to work, so
  that I don't maintain one image per agent.
- When my project needs packages from nuget.org, I want restore to work out of the box, so that I
  don't have to edit sandbox network policy first.
- When I need a different .NET or PowerShell version, I want to choose it when creating the sandbox,
  so that I don't fork the add-on.
- When I share the add-on with others, I want them to use a published reference, so that they don't
  need to build it themselves.

## 2. System context

- **Docker Sandbox runtime (`sbx`):** creates sandboxes from a workload plus zero or more mixins, builds
  or pulls the mixin, and enforces network policy.
- **Workload:** the base sandbox environment (`shell`, `claude`, `copilot`, ...). It supplies the
  operating system and most native libraries, the default user, and the launch command.
- **Upstream publishers:** Microsoft (PowerShell, .NET SDK) and Debian (ICU, a Unicode library the
  workloads lack).
- **Package registry:** nuget.org, reached from inside the sandbox at runtime.
- **Image registry:** Docker Hub, which hosts the published mixin.
- **Builder:** Docker with Buildx (or another OCI-compatible builder) on the user's host, used when
  building from source.

## 3. Functional requirements

### 3.1 Tool provisioning

- **FR-TOOL-1:** The mixin SHALL make PowerShell available on the default command path of the sandbox.
- **FR-TOOL-2:** The mixin SHALL make the .NET SDK available on the default command path of the
  sandbox.
- **FR-TOOL-3:** Both tools SHALL run as the workload's default (non-root) user.
- **FR-TOOL-4:** The mixin SHALL supply any native library the tools need that supported workloads do
  not provide.
- **FR-TOOL-5:** The mixin SHALL NOT replace the workload's launch command, default user or working
  directory.
- **FR-TOOL-6:** The mixin SHALL declare the tools and versions it provides, so the sandbox runtime can
  detect conflicts with other kits that provide the same tools.

### 3.2 Workload compatibility

- **FR-COMPAT-1:** The mixin SHALL work with the `shell`, `claude` and `copilot` workloads.
- **FR-COMPAT-2:** The mixin SHOULD work with any other v3 workload built on the Docker sandbox
  templates.
- **FR-COMPAT-3:** A user SHALL be able to add the mixin with a single option when creating a
  sandbox, from either a local source directory or a published reference.

### 3.3 Version selection

- **FR-VER-1:** The mixin SHALL expose a PowerShell version argument, defaulting to 7.6.5.
- **FR-VER-2:** The mixin SHALL expose a .NET release-channel argument, defaulting to 10.0, and SHALL
  install the newest SDK in the chosen channel.
- **FR-VER-3:** The mixin SHALL reject malformed version arguments before installing anything.
- **FR-VER-4:** Users SHALL be able to set version arguments when creating a sandbox, without editing
  the mixin.

### 3.4 Network access

- **FR-NET-1:** The mixin SHALL grant the sandbox outbound HTTPS access to nuget.org's API host, so
  that package restore and package add work with no other policy.
- **FR-NET-2:** The mixin SHALL NOT grant access to any other host.
- **FR-NET-3:** Without the mixin's network rule, and with no user policy allowing it, restore SHALL
  fail. This confirms the rule is what grants access.

### 3.5 Configuration defaults

- **FR-CONF-1:** The mixin SHALL opt out of .NET CLI and PowerShell telemetry by default.
- **FR-CONF-2:** The mixin SHALL suppress the .NET first-run banner.

### 3.6 Distribution

- **FR-DIST-1:** Users SHALL be able to build and use the mixin from source, locally.
- **FR-DIST-2:** The maintainer SHALL be able to publish the mixin to Docker Hub with the metadata the
  sandbox runtime needs to use it as a kit.
- **FR-DIST-3:** Users SHALL be able to use the published mixin by reference, without building it.

### 3.7 Licensing and notices

- **FR-LIC-1:** The mixin SHALL include the license and third-party notices of every bundled
  component.
- **FR-LIC-2:** The repository SHALL document the licenses of bundled components and where their
  notices are found.

### 3.8 Documentation

- **FR-DOC-1:** The README SHALL document requirements, local and published usage, version arguments,
  NuGet access and known limitations.
- **FR-DOC-2:** Every command in the README SHALL have been run successfully.

## 4. Non-functional requirements

### 4.1 Compatibility

- **NFR-COMPAT-1:** The mixin SHALL require `sbx` v0.45 or later, the first release with v3 kits.
- **NFR-COMPAT-2:** The mixin SHALL be a v3 kit and SHALL only be combined with v3 workloads and
  mixins.
- **NFR-COMPAT-3:** The mixin SHALL support amd64 and SHOULD support arm64. arm64 is not yet verified.

### 4.2 Security and supply chain

- **NFR-SEC-1:** All bundled software SHALL come from its official publisher and SHALL be verified
  against the publisher's checksum or signature before inclusion. A failed check SHALL fail the build.
- **NFR-SEC-2:** The mixin SHALL add only the tools, their required libraries and their notices to
  the sandbox. It SHALL NOT add package managers, shells or other tooling from the build process.
- **NFR-SEC-3:** Network access SHALL be limited to the named hosts in FR-NET-1, with no wildcards.
- **NFR-SEC-4:** The mixin SHALL NOT request credentials and SHALL NOT contain credentials or registry
  tokens.
- **NFR-SEC-5:** Bundled tool directories SHALL NOT be writable by the sandbox's default user.

### 4.3 Privacy

- **NFR-PRIV-1:** Bundled tools SHALL NOT send usage telemetry by default (see FR-CONF-1).

### 4.4 Reliability and reproducibility

- **NFR-REL-1:** The PowerShell version SHALL be exact for a given argument value.
- **NFR-REL-2:** The .NET SDK version MAY differ between builds made at different times, because the
  channel resolves to the newest SDK (see section 6).

### 4.5 Operations and SDLC

- **NFR-OPS-1:** Each change to the mixin SHALL be verified in a newly created sandbox, because a
  sandbox keeps the kits it was created with.
- **NFR-OPS-2:** Verification SHALL cover smoke tests on each supported workload, a NuGet restore with
  only the mixin's network rule, and the negative test in FR-NET-3.
- **NFR-OPS-3:** Publishing to Docker Hub SHALL require explicit maintainer action and confirmation.

### 4.6 Compliance

- **NFR-COMP-1:** Bundled components SHALL be under licenses that permit redistribution, and their
  notices SHALL ship with them (see FR-LIC-1).

### 4.7 Not applicable

- Accessibility, user-interface performance and observability have no product surface beyond the
  command line and are intentionally omitted.

## 5. System architecture

| Component | Responsibility | Owner | Runtime |
| --- | --- | --- | --- |
| Tool overlay | PowerShell, .NET SDK, the missing native library, notices and telemetry defaults | This repository | Layered onto the workload inside the sandbox |
| Kit descriptor | Name, version arguments, provided tools, network access declaration | This repository | Read by `sbx` when creating a sandbox |
| Sandbox runtime (`sbx`) | Combines workload and mixins, builds or pulls kits, enforces network policy | Docker | User's host |
| Workload | Operating system, base native libraries, default user, launch command | Docker | Inside the sandbox |
| Docker Hub | Hosts the published mixin | Docker; namespace owned by the maintainer | Public registry |
| Upstream publishers | Source of PowerShell, .NET SDK and ICU releases and their checksums | Microsoft, Debian | Reached at build time only |
| nuget.org | Package source for restore | Microsoft | Reached at runtime from the sandbox |

Data ownership: the mixin holds no user data. Package caches and project files belong to the
workload's user home and project directory.

## 6. Out of scope and known limitations

### Out of scope

- Per-agent images or base-image pinning.
- Package feeds other than nuget.org (private feeds, GitHub Packages, Azure Artifacts). Users add
  their own policy for these.
- .NET workloads (`dotnet workload install`) and other optional SDK components.
- Additional tools beyond PowerShell and the .NET SDK.
- Workloads older than v3 kits, and workloads that are not built on the Docker sandbox templates.
- Credential handling for registries or package feeds.

### Known limitations

- **Workload warning:** the first `dotnet` command in a fresh home directory prints "An issue was
  encountered verifying workloads." Restore, build and run are unaffected. Accepted rather than making
  a shared directory world-writable.
- **No `dotnet workload install`**, for the same reason.
- **SDK version drift:** builds at different times may produce different .NET SDK patch versions.
- **arm64 unverified.**
- **Native library dependency:** the mixin relies on the workload for most native libraries, so a
  workload that drops one of them would break the tools.

## 7. Open questions and decision log

### Open questions

- Should arm64 be verified on hardware before it is described as supported?
- Should the .NET SDK version be pinnable to an exact patch release for reproducible builds?
- Should the workload warning be fixed, given that the fix means a writable shared directory?
- What versioning and tagging policy should the published image follow when defaults change?

### Decisions

- **Replace the per-agent images** with one agent-agnostic mixin, once verified. Done.
- **One combined mixin** for PowerShell and .NET, not two.
- **Official release archives** from the publishers, not distribution package feeds, to avoid
  per-distribution feed gaps.
- **Bundle ICU** because the sandbox templates lack it, rather than requiring a different workload.
- **Allow only nuget.org's API host**, which host verification showed is enough for restore.
- **Accept the workload warning** rather than loosen file permissions.
- **Opt out of telemetry** by default.

## 8. Glossary

- **Docker Sandbox / `sbx`:** Docker's tool for running coding agents in isolated environments, and its
  command-line interface.
- **Kit:** a package of software and configuration for a sandbox, described by a descriptor file.
- **Workload:** the base kit a sandbox starts from, such as `shell`, `claude` or `copilot`.
- **Mixin:** a kit that adds tools or access to a workload rather than defining one.
- **v3:** the current kit format. All kits in a sandbox must use the same format version.
- **Kit argument:** a named setting a kit exposes, set with `--kit-arg` when creating a sandbox.
- **Provides:** the tools and versions a kit declares, used to detect conflicts between kits.
- **Network policy:** the sandbox's allow list of outbound hosts.
- **.NET channel:** a major.minor release line, such as 10.0, that contains successive SDK releases.
- **ICU:** International Components for Unicode, a library .NET and PowerShell need for culture and
  text handling.
- **NuGet / nuget.org:** the .NET package manager and its public package registry.
