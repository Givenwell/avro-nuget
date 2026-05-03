FROM mcr.microsoft.com/dotnet/sdk:10.0@sha256:e362a8dbcd691522456da26a5198b8f3ca1d7641c95624fadc5e3e82678bd08a AS build

RUN dotnet tool install -g apache.avro.tools --version 1.12.1
ENV PATH="${PATH}:/root/.dotnet/tools"

COPY Directory.Build.props /opt/build-tools/Directory.Build.props.template
COPY generate-json-context.cs /opt/build-tools/generate-json-context.cs
COPY strip-avro.cs /opt/build-tools/strip-avro.cs
COPY entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh

ENTRYPOINT [ "/bin/entrypoint.sh"]
