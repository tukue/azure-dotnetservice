FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/CloudNativeMicroservice/CloudNativeMicroservice.csproj", "CloudNativeMicroservice/"]
RUN dotnet restore "CloudNativeMicroservice/CloudNativeMicroservice.csproj"
COPY src/ .
RUN dotnet build "CloudNativeMicroservice/CloudNativeMicroservice.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "CloudNativeMicroservice/CloudNativeMicroservice.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "CloudNativeMicroservice.dll"]
