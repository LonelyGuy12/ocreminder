import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lonelyreminder/models/event_model.dart';
import 'package:lonelyreminder/services/event_parser.dart';

class OcrService {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  /// Extracts text from an image file using Google ML Kit
  Future<String> extractTextFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Extracts text from an image picked from camera or gallery
  Future<String> extractTextFromImageSource(ImageSource source) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80, // Reduce quality to improve performance
    );

    if (pickedFile == null) {
      throw Exception('No image selected');
    }

    final File imageFile = File(pickedFile.path);
    return await extractTextFromFile(imageFile);
  }

  /// Processes an image from camera and extracts event information
  Future<Event> processImageFromCamera() async {
    try {
      final text = await extractTextFromImageSource(ImageSource.camera);
      return await EventParser.parseEvent(text);
    } catch (e) {
      rethrow;
    }
  }

  /// Processes an image from gallery and extracts event information
  Future<Event> processImageFromGallery() async {
    try {
      final text = await extractTextFromImageSource(ImageSource.gallery);
      return await EventParser.parseEvent(text);
    } catch (e) {
      rethrow;
    }
  }

  /// Cleans up and releases resources used by the OCR service
  Future<void> close() async {
    await _textRecognizer.close();
  }
}