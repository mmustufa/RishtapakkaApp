import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'biodata_ocr_parser.dart';

class MlKitScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Scan a photo/screenshot of a biodata sheet and extract fields
  Future<ScanResult> scanBiodataImage(File sourceImageFile) async {
    // 1. Permanently copy the image into local app internal storage
    final localSavedPath = await _saveImageToLocalStorage(
      sourceImageFile,
      folderName: 'biodata_scans',
    );

    // 2. Perform on-device ML Kit OCR
    final inputImage = InputImage.fromFilePath(localSavedPath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    // 3. Heuristic text parsing for biodata fields
    final parsed = BiodataOcrParser.parse(recognizedText.text);

    return ScanResult(
      parsedData: parsed,
      localImagePath: localSavedPath,
    );
  }

  /// Copies image file to sandboxed internal storage directory
  static Future<String> _saveImageToLocalStorage(
    File sourceFile, {
    required String folderName,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${appDir.path}/$folderName');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final ext = sourceFile.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$ext';
    final destinationFile = File('${targetDir.path}/$fileName');

    final copied = await sourceFile.copy(destinationFile.path);
    return copied.path;
  }

  /// Save candidate profile photo locally
  static Future<String> saveCandidatePhoto(File photoFile) async {
    return _saveImageToLocalStorage(photoFile, folderName: 'candidate_photos');
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class ScanResult {
  final ParsedBiodataResult parsedData;
  final String localImagePath;

  ScanResult({
    required this.parsedData,
    required this.localImagePath,
  });
}
