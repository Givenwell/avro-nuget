// Strips Avro-specific code from generated event classes.
// Removes the Schema property, _SCHEMA static field, Get and Put methods.
// Usage: dotnet run strip-avro.cs -- <file1.cs> [file2.cs ...]

using System.Text.RegularExpressions;

foreach (var file in args)
{
    var content = File.ReadAllText(file);

    // Remove static _SCHEMA field
    content = Regex.Replace(content,
        @"\n\t\tpublic static global::Avro\.Schema _SCHEMA = .*?;\n",
        "\n", RegexOptions.Singleline);

    // Remove Schema property
    content = Regex.Replace(content,
        @"\t\tpublic virtual global::Avro\.Schema Schema\n\t\t\{[^}]*\{[^}]*\}[^}]*\}\n",
        "", RegexOptions.Singleline);

    // Remove Get method
    content = Regex.Replace(content,
        @"\t\tpublic virtual object Get\(int fieldPos\)\n\t\t\{.*?\n\t\t\}\n",
        "", RegexOptions.Singleline);

    // Remove Put method
    content = Regex.Replace(content,
        @"\t\tpublic virtual void Put\(int fieldPos, object fieldValue\)\n\t\t\{.*?\n\t\t\}\n",
        "", RegexOptions.Singleline);

    File.WriteAllText(file, content);
}
