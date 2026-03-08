#!/bin/sh -l

set -e

SRC=./src

for i in "$@"; do
  case $i in
    -n=*|--package-name=*)
      PACKAGE_NAME="${i#*=}"
      shift
      ;;
    -v=*|--package-version=*)
      PACKAGE_VERSION="${i#*=}"
      shift
      ;;
    -p=*|--avro-dir-path=*)
      AVRO_FOLDER="${i#*=}"
      shift
      ;;
    -o=*|--output-path=*)
      OUTPUT_PATH="${i#*=}"
      shift
      ;;
    -c=*|--company=*)
      COMPANY="${i#*=}"
      shift
      ;;
    -a=*|--authors=*)
      AUTHORS="${i#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

echo "[Inputs]:"
echo "  - Package name    = $PACKAGE_NAME"
echo "  - Package version = $PACKAGE_VERSION"
echo "  - Avro folder     = $AVRO_FOLDER"
echo "  - Output path     = $OUTPUT_PATH"
echo "  - Company         = $COMPANY"
echo "  - Authors         = $AUTHORS"

export PATH="$PATH:/root/.dotnet/tools"
PACKAGE_SRC_FOLDER=$SRC/$PACKAGE_NAME
PROJ=$PACKAGE_SRC_FOLDER/$PACKAGE_NAME.csproj

echo "Clean up..."
rm -rf ./src

echo "Creating file 'Directory.Build.props'..."
cp /opt/build-tools/Directory.Build.props.template ./Directory.Build.props
sed -i -e "s/{{ Company }}/$COMPANY/g" -e "s/{{ Authors }}/$AUTHORS/g" Directory.Build.props

echo "Creating $PACKAGE_NAME project..."
dotnet new classlib --name $PACKAGE_NAME --output $SRC/$PACKAGE_NAME --framework net10.0
dotnet add $SRC/$PACKAGE_NAME/$PACKAGE_NAME.csproj package Apache.Avro --version 1.12.1
rm -f ./$SRC/$PACKAGE_NAME/Class1.cs
# Apache.Avro is only needed for avrogen codegen - it will be removed from the package after generation

echo "Adding Avro files..."

count=$(find $AVRO_FOLDER -name "*.avsc" | wc -l)
if [ "$count" -eq "0" ]; then
  echo "Error: No Avro schema file found at '$AVRO_FOLDER'"
  exit -1
fi

for file in $(find $AVRO_FOLDER -name "*.avsc" -exec readlink -f {} \;)
do
  echo "Avro schema file found at '$file'. Trying to generate the corresponding C# class at '$PACKAGE_SRC_FOLDER'..."
  avrogen -s $file $PACKAGE_SRC_FOLDER
done

echo "Removing Avro dependency and replacing with IGivenwellEvent..."
# Remove Avro usings, ISpecificRecord -> IGivenwellEvent
find $PACKAGE_SRC_FOLDER -name "*.cs" | while read file; do
  sed -i \
    -e '/using global::Avro/d' \
    -e 's/global::Avro\.Specific\.ISpecificRecord/IGivenwellEvent/g' \
    -e 's/: ISpecificRecord/: IGivenwellEvent/g' \
    "$file"
done
# Strip Avro-generated Schema property, _SCHEMA field, Get and Put methods
EVENT_FILES=$(find $(realpath $PACKAGE_SRC_FOLDER) -name "*.cs" -exec grep -l "IGivenwellEvent" {} \;)
dotnet run /opt/build-tools/strip-avro.cs -- $EVENT_FILES
# Remove the Apache.Avro package reference - it was only needed for avrogen codegen
dotnet remove $PROJ package Apache.Avro

echo "Generating JsonSerializerContext..."
dotnet run /opt/build-tools/generate-json-context.cs -- $(realpath $SRC) $PACKAGE_NAME $(realpath $AVRO_FOLDER)

echo "Restoring packages..."
dotnet restore $PROJ

echo "Building the project..."
dotnet build -c Release --no-restore $PROJ

echo "Packing $PACKAGE_NAME version $PACKAGE_VERSION at $OUTPUT_PATH..."
dotnet pack $PROJ -c Release --no-build --no-restore -p:PackageVersion=$PACKAGE_VERSION -o $OUTPUT_PATH
