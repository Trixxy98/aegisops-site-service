FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/Service/Service.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build --chown=$APP_UID:$APP_UID /app .
USER $APP_UID
ARG VERSION=v0.0.0-dev
ARG COMMIT_SHA=local
ARG BUILD_TIME=unknown
ARG AEGISOPS_FIXTURE_FAIL_HEALTH=false
ENV ASPNETCORE_URLS=http://+:8080 \
    Service__Version=$VERSION \
    Service__CommitSha=$COMMIT_SHA \
    Service__BuildTime=$BUILD_TIME \
    AegisOpsFixture__FailHealth=$AEGISOPS_FIXTURE_FAIL_HEALTH
EXPOSE 8080
ENTRYPOINT ["dotnet", "Service.dll"]
