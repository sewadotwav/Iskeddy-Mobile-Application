import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../components/app_header.dart';
import '../../components/pill_button.dart';
import '../../components/app_toast.dart';
import '../../components/app_text_styles.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_enums.dart';
import '../../models/draft_course.dart';
import '../../models/meeting_time_model.dart';
import '../../config/secrets.dart';
import 'draft_review_screen.dart';

class OcrImportScreen extends StatefulWidget {
  const OcrImportScreen({super.key});

  @override
  State<OcrImportScreen> createState() => _OcrImportScreenState();
}

class _OcrImportScreenState extends State<OcrImportScreen> {
  List<File> _selectedImages = [];
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    
    if (source == ImageSource.gallery) {
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (pickedFiles.isEmpty) return;
      setState(() {
        _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
        _errorMessage = null;
      });
    } else {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return;
      setState(() {
        _selectedImages.add(File(picked.path));
        _errorMessage = null;
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImages.isEmpty) {
      AppToast.show(context, 'Please add at least one image.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final imageParts = <DataPart>[];
      for (final img in _selectedImages) {
        final imageBytes = await img.readAsBytes();
        final ext = img.path.split('.').last.toLowerCase();
        final mimeType = switch (ext) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png'           => 'image/png',
          'webp'          => 'image/webp',
          _               => 'image/jpeg',
        };
        imageParts.add(DataPart(mimeType, imageBytes));
      }

      // 3. Initialise the Gemini model
      if (geminiApiKey.isEmpty || geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        throw Exception('Paste your Gemini API key into lib/config/secrets.dart');
      }

      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: geminiApiKey,
      );

      // 4. Build the prompt — exact wording is critical for consistent output
      const prompt = '''
Extract all course/subject schedule information from the provided image(s).
Return ONLY a valid JSON array. No explanation, no markdown fences, no extra text.
Each element must have these exact keys:
  "title": string (required, the course or subject name),
  "days": array of strings — use only these exact values: Mon Tue Wed Thu Fri Sat Sun,
  "startTime": string in 24-hour HH:mm format (e.g. "08:30"),
  "endTime": string in 24-hour HH:mm format (e.g. "10:00"),
  "instructor": string or null,
  "roomNo": string or null,
  "courseType": one of "Lecture" "Lab" "Seminar" "Workshop" or null
If a course meets at multiple different time slots, include it as multiple
separate objects with the same title but different days/startTime/endTime.
If you cannot determine a value, use null. Never omit a key.
''';

      // 5. Send to Gemini as a multimodal request
      final response = await model.generateContent([
        Content.multi([
          ...imageParts,
          TextPart(prompt),
        ]),
      ]);

      final rawText = response.text;
      if (rawText == null || rawText.trim().isEmpty) {
        throw Exception('Empty response from Gemini.');
      }

      // 6. Strip markdown code fences if Gemini added them despite instructions
      final cleaned = rawText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      // 7. Parse JSON
      final List<dynamic> parsed = jsonDecode(cleaned) as List<dynamic>;

      if (parsed.isEmpty) {
        throw Exception('No courses found in the image.');
      }

      // 8. Convert to DraftCourse list with auto-assigned colors
      final draftCourses = _parseToDraftCourses(parsed);

      // 9. Navigate to draft review — push so student can go back
      if (!mounted) return;
      setState(() => _isProcessing = false);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DraftReviewScreen(draftCourses: draftCourses),
        ),
      );

      // 10. After returning from DraftReviewScreen, reset to upload state
      //     so the student can start a new import if needed
      if (mounted) {
        setState(() {
          _selectedImages.clear();
          _errorMessage = null;
        });
      }

    } on FormatException catch (e) {
      // JSON parse failure
      debugPrint('JSON Parse Error: $e');
      if (!mounted) return;
      AppToast.show(context, 'Parsing failed. Please try a clearer image.');
      setState(() {
        _isProcessing = false;
        _errorMessage =
          'Could not read the schedule format. Try a clearer image.';
      });
    } catch (e, stack) {
      debugPrint('OCR Processing Error: $e');
      debugPrint('Stacktrace: $stack');
      if (!mounted) return;
      
      final msg = e.toString().contains('GEMINI_API_KEY is not set') 
          ? 'API Key is missing.' 
          : 'Error processing image. Check connection.';
          
      AppToast.show(context, msg);
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().contains('GEMINI_API_KEY is not set')
            ? 'Developer Error: GEMINI_API_KEY is missing in environment variables.'
            : 'Could not process the image. Check your connection and try again.';
      });
    }
  }

  List<DraftCourse> _parseToDraftCourses(List<dynamic> parsed) {
    // Valid day strings — anything outside this set is discarded
    const validDays = {'Mon','Tue','Wed','Thu','Fri','Sat','Sun'};

    // Valid courseType values matching the app's enum labels
    const validCourseTypes = {'Lecture','Lab','Seminar','Workshop'};

    // Auto-assign colors in round-robin order from courseColorHexValues
    // so adjacent courses in the list get distinct colors
    int colorIndex = 0;

    return parsed.map((item) {
      final map = item as Map<String, dynamic>;

      // title — fallback to "Untitled Course" if missing or empty
      final title = (map['title'] as String? ?? '').trim();
      final safeTitle = title.isEmpty ? 'Untitled Course' : title;

      // days — filter to only valid strings, deduplicate
      final rawDays = (map['days'] as List<dynamic>? ?? [])
          .map((d) => d.toString().trim())
          .where((d) => validDays.contains(d))
          .toSet()
          .toList();

      // startTime / endTime — validate HH:mm format, fallback to defaults
      String safeStart = _validateTime(map['startTime'] as String?) ?? '08:00';
      String safeEnd   = _validateTime(map['endTime']   as String?) ?? '09:00';

      // Ensure endTime > startTime — if not, set endTime = startTime + 1 hour
      if (_timeToMinutes(safeEnd) <= _timeToMinutes(safeStart)) {
        final startMins = _timeToMinutes(safeStart);
        final correctedMins = startMins + 60;
        final h = (correctedMins ~/ 60) % 24;
        final m = correctedMins % 60;
        safeEnd =
          '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}';
      }

      // courseType — validate against allowed values
      final rawCourseType = (map['courseType'] as String?)?.trim();
      final courseType = (rawCourseType != null &&
        validCourseTypes.contains(rawCourseType))
          ? rawCourseType : null;

      final meetingTime = MeetingTime(
        days: rawDays,
        startTime: safeStart,
        endTime: safeEnd,
        classMode: ClassMode.onsite,
        courseType: courseType != null ? CourseTypeLabel.fromValue(courseType) : null,
      );

      // instructor / roomNo — null if blank
      final instructor = (map['instructor'] as String?)?.trim();
      final roomNo     = (map['roomNo'] as String?)?.trim();



      // Assign next color in rotation
      final colorHex = courseColorHexValues[colorIndex % courseColorHexValues.length];
      colorIndex++;

      return DraftCourse(
        title: safeTitle,
        colorHex: colorHex,
        meetingTimes: [meetingTime],
        instructor: (instructor?.isEmpty ?? true) ? null : instructor,
        roomNo: (roomNo?.isEmpty ?? true) ? null : roomNo,
        isIncluded: true,
      );
    }).toList();
  }

  // Returns the input string if it matches HH:mm, otherwise null
  String? _validateTime(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    final regex = RegExp(r'^\d{2}:\d{2}$');
    if (!regex.hasMatch(trimmed)) return null;
    final parts = trimmed.split(':');
    final h = int.tryParse(parts[0]) ?? -1;
    final m = int.tryParse(parts[1]) ?? -1;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return trimmed;
  }

  // Returns total minutes since midnight for a "HH:mm" string
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: accentColor, strokeWidth: 2),
              const SizedBox(height: 16),
              Text(
                'Reading your schedule...',
                style: appFont(fontSize: 14, color: const Color(0xFF8A8A8A)),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedImages.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppHeader(),
                const SizedBox(height: 20),
                Text(
                  'Review your ${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''} before processing',
                  style: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: const Icon(Icons.close, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                PillButton(
                  label: 'Process Image${_selectedImages.length > 1 ? 's' : ''}',
                  background: accentColor,
                  textColor: Colors.white,
                  onTap: _processImage,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 16, color: accentColor),
                      label: Text(
                        'Add Photo',
                        style: appFont(fontSize: 13, color: accentColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 16, color: accentColor),
                      label: Text(
                        'Add Gallery',
                        style: appFont(fontSize: 13, color: accentColor),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _selectedImages.clear();
                      _errorMessage = null;
                    }),
                    child: Text(
                      'Clear All',
                      style: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppHeader(),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.document_scanner_outlined,
                        size: 52, color: Color(0xFF8A8A8A)),
                    const SizedBox(height: 16),
                    Text(
                      'Upload Schedule Image',
                      style: appFont(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Take a photo or upload a screenshot of your class schedule',
                      style: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PillButton(
                label: 'Take Photo',
                background: accentColor,
                textColor: Colors.white,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: 'Choose from Gallery',
                background: const Color(0xFFF2F2F2),
                textColor: accentColor,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF4444), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: appFont(fontSize: 13, color: const Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
