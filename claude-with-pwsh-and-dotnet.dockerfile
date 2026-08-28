FROM docker/sandbox-templates:claude-code@sha256:7fa049b8d7a0cf10f6a4200148ee475e94fc4fb5ef50dfacc4257699cb9a34bc AS pwsh

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-transport-https software-properties-common && \
    # Ubuntu version is hard-coded to 24 because Microsoft hasn't published Powershell yet for 26,
    # which is what sandbox@7fa049b uses.
    curl -fsSL -O https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends powershell && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER agent

FROM pwsh
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends dotnet-sdk-10.0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER agent
