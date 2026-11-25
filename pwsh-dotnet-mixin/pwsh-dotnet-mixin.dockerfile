# syntax=docker/dockerfile:1

# Build stage: download and verify PowerShell and the .NET SDK. Nothing from this stage
# reaches the sandbox except the files copied into /out.
FROM ubuntu:26.04 AS build

ARG TARGETARCH
ARG PWSH_VERSION=7.6.5
# Release channel, e.g. "10.0": resolves to the latest SDK in that channel at build time.
ARG DOTNET_CHANNEL=10.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl jq libc-bin && \
    rm -rf /var/lib/apt/lists/*

# Microsoft's naming for the CPU architectures that Docker calls amd64 and arm64.
RUN case "${TARGETARCH}" in \
      amd64) echo x64 > /arch ;; \
      arm64) echo arm64 > /arch ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac

# PowerShell. The release publishes its checksums as a UTF-16 file, hence iconv.
RUN set -eu; \
    arch="$(cat /arch)"; \
    base="https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}"; \
    file="powershell-${PWSH_VERSION}-linux-${arch}.tar.gz"; \
    curl -fsSL -o "/tmp/${file}" "${base}/${file}"; \
    curl -fsSL "${base}/hashes.sha256" | iconv -f UTF-16 -t UTF-8 | tr -d '\r' | \
      grep -F "${file}" | sed 's/ \*/  /' > /tmp/pwsh.sha256; \
    test -s /tmp/pwsh.sha256; \
    (cd /tmp && sha256sum -c pwsh.sha256); \
    mkdir -p /out/opt/pwsh /out/usr/local/bin; \
    tar -xzf "/tmp/${file}" -C /out/opt/pwsh; \
    chmod 755 /out/opt/pwsh/pwsh; \
    ln -s /opt/pwsh/pwsh /out/usr/local/bin/pwsh

# .NET SDK. URL and SHA-512 come from Microsoft's release metadata for the channel.
RUN set -eu; \
    arch="$(cat /arch)"; \
    curl -fsSL -o /tmp/releases.json \
      "https://builds.dotnet.microsoft.com/dotnet/release-metadata/${DOTNET_CHANNEL}/releases.json"; \
    jq -r --arg rid "linux-${arch}" \
      '.releases[0].sdk.files[] | select(.rid == $rid and (.name | endswith(".tar.gz"))) | "\(.hash) \(.url)"' \
      /tmp/releases.json > /tmp/sdk.txt; \
    test "$(wc -l < /tmp/sdk.txt)" -eq 1; \
    read -r hash url < /tmp/sdk.txt; \
    curl -fsSL -o /tmp/dotnet-sdk.tar.gz "${url}"; \
    echo "${hash}  /tmp/dotnet-sdk.tar.gz" | sha512sum -c -; \
    mkdir -p /out/opt/dotnet; \
    tar -xzf /tmp/dotnet-sdk.tar.gz -C /out/opt/dotnet; \
    ln -s /opt/dotnet/dotnet /out/usr/local/bin/dotnet

# ICU stage. The sandbox templates (Debian 13 / Docker Hardened Images) ship OpenSSL, libstdc++,
# zlib and Kerberos but not ICU, without which pwsh and dotnet fail at startup. Take ICU from
# the matching Debian release so it links against the workload's glibc and libstdc++. apt
# verifies the package signature. Only the three libraries .NET loads are kept.
FROM debian:trixie-slim AS icu
RUN set -eu; \
    apt-get update; \
    cd /tmp; \
    apt-get download libicu76; \
    dpkg-deb -x libicu76_*.deb /tmp/icu; \
    libdir="$(ls -d /tmp/icu/usr/lib/*-linux-gnu)"; \
    dest="/out/usr/lib/$(basename "${libdir}")"; \
    mkdir -p "${dest}"; \
    for lib in libicuuc libicui18n libicudata; do cp -a "${libdir}/${lib}.so."* "${dest}/"; done

# Final stage: files only. The workload must supply the remaining native libraries
# (OpenSSL, libstdc++, zlib, Kerberos), which the sandbox templates do.
FROM scratch
COPY --from=build /out/ /
COPY --from=icu /out/ /

# A mixin's image ENV merges into the workload. Opt out of .NET CLI telemetry and the
# first-run banner; PowerShell telemetry is likewise disabled.
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    POWERSHELL_TELEMETRY_OPTOUT=1
