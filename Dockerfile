# syntax=docker/dockerfile:1.7

FROM eclipse-temurin:25-jdk-jammy@sha256:89565961a318534f01c971c7b1d030e60713c66995b887c94010cef938dbc53e AS build

WORKDIR /workspace
COPY --chmod=0755 gradlew ./gradlew
COPY gradle ./gradle
COPY build.gradle settings.gradle gradle.properties gradle.lockfile ./
RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew resolveRuntimeDependencies --no-configuration-cache --no-daemon

COPY src ./src
RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew clean installDist --offline --no-daemon

FROM gcr.io/distroless/java17-debian13:nonroot@sha256:2dcb2b21efab7e9250945985e0b0aab99ec7835db96a7bbc68edd1a0ad2e51ff

ARG VERSION=dev
ARG REVISION=unknown
LABEL org.opencontainers.image.title="Blazra" \
      org.opencontainers.image.description="A least-privilege Kubernetes image update sidecar" \
      org.opencontainers.image.source="https://github.com/ocularminds/blazra" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}"

WORKDIR /opt/blazra
COPY --from=build --chown=65532:65532 /workspace/build/install/blazra/lib ./lib

USER 65532:65532
ENTRYPOINT ["java", "-cp", "/opt/blazra/lib/*", "io.github.ocularminds.blazra.BlazraApplication"]
