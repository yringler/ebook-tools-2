import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import '../lib/html_converter.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i', help: 'Input HTML file or directory')
    ..addOption('output', abbr: 'o', help: 'Output directory for converted files')
    ..addFlag('help', abbr: 'h', help: 'Show usage information', negatable: false);

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printUsage(parser);
      return;
    }

    final inputPath = results['input'] as String?;
    final outputPath = results['output'] as String?;

    if (inputPath == null || outputPath == null) {
      print('Error: Both --input and --output are required\n');
      _printUsage(parser);
      exit(1);
    }

    final converter = HtmlConverter();

    final inputFile = File(inputPath);
    final inputDir = Directory(inputPath);
    final outputDirectory = Directory(outputPath);

    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    if (await inputFile.exists()) {
      await _convertFile(inputFile, outputDirectory, converter);
    } else if (await inputDir.exists()) {
      await _convertDirectory(inputDir, outputDirectory, converter);
    } else {
      print('Error: Input path does not exist: $inputPath');
      exit(1);
    }

    print('\nConversion complete!');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

Future<void> _convertFile(File inputFile, Directory outputDir, HtmlConverter converter) async {
  print('Converting: ${inputFile.path}');

  final content = await inputFile.readAsString();
  final converted = converter.convert(content);

  final outputFile = File(path.join(outputDir.path, path.basename(inputFile.path)));
  await outputFile.writeAsString(converted);

  print('  -> ${outputFile.path}');
}

Future<void> _convertDirectory(Directory inputDir, Directory outputDir, HtmlConverter converter) async {
  print('Converting files in: ${inputDir.path}');

  await for (final entity in inputDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.html')) {
      final relativePath = path.relative(entity.path, from: inputDir.path);
      final outputFile = File(path.join(outputDir.path, relativePath));

      await outputFile.parent.create(recursive: true);

      final content = await entity.readAsString();
      final converted = converter.convert(content);
      await outputFile.writeAsString(converted);

      print('  ${entity.path} -> ${outputFile.path}');
    }
  }
}

void _printUsage(ArgParser parser) {
  print('Ebook HTML Converter - Convert HTML files for Calibre ebook conversion\n');
  print('Usage: dart run ebook_html_converter -i <input> -o <output>\n');
  print(parser.usage);
  print('\nExamples:');
  print('  dart run ebook_html_converter -i input.html -o output/');
  print('  dart run ebook_html_converter -i source_html/ -o output/');
}
