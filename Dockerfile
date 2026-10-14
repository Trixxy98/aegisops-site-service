FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/Service/Service.csproj -c Release -o /app

# demo/vulnerable pins an old runtime so Trivy reports known CVEs. Do not merge this to main.
FROM mcr.microsoft.com/dotnet/aspnet:8.0.0
WORKDIR /app
COPY --from=build /app .
ARG VERSION=v0.0.0-dev
ARG COMMIT_SHA=local
ARG BUILD_TIME=unknown
ENV ASPNETCORE_URLS=http://+:8080 \
    Service__Version=$VERSION \
    Service__CommitSha=$COMMIT_SHA \
    Service__BuildTime=$BUILD_TIME
EXPOSE 8080
ENTRYPOINT ["dotnet", "Service.dll"]
