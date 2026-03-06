FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

RUN dotnet tool install -g apache.avro.tools --version 1.12.1
ENV PATH="${PATH}:/root/.dotnet/tools"

COPY Directory.Build.props /opt/build-tools/Directory.Build.props.template
COPY generate-json-context.cs /opt/build-tools/generate-json-context.cs
COPY entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh

ENTRYPOINT [ "/bin/entrypoint.sh"]
