FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/Service/Service.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:10.0
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home app
WORKDIR /home/app
COPY --from=build /app .
USER app
ARG VERSION=v0.0.0-dev
ARG COMMIT_SHA=local
ARG BUILD_TIME=unknown
ENV ASPNETCORE_URLS=http://+:8080 \
    Service__Version=$VERSION \
    Service__CommitSha=$COMMIT_SHA \
    Service__BuildTime=$BUILD_TIME
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s CMD curl -fsS http://127.0.0.1:8080/health || exit 1
ENTRYPOINT ["dotnet", "Service.dll"]
