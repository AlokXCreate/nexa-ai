import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleDriveService {
  final Dio _dio = Dio();
  
  // Custom GoogleSignIn instance equipped with drive.file scope
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  GoogleSignInAccount? _currentUser;
  String? _accessToken;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null && _accessToken != null;

  /// Authenticates with Google and requests drive.file scope access token.
  Future<bool> signIn() async {
    try {
      // First sign in the user
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return false;

      // Request authentication token
      final auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;
      
      return _accessToken != null;
    } catch (e) {
      _currentUser = null;
      _accessToken = null;
      rethrow;
    }
  }

  /// Signs out the active Google Drive session.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _accessToken = null;
  }

  /// Uploads binary backup bytes to Google Drive.
  Future<String> uploadBackup(String fileName, List<int> fileBytes) async {
    if (!isSignedIn) {
      final connected = await signIn();
      if (!connected) throw Exception('Google Drive not authenticated.');
    }

    try {
      // Build Google Drive API multipart upload payload
      final formData = FormData.fromMap({
        'metadata': MultipartFile.fromString(
          jsonEncode({
            'name': fileName,
            'description': 'LocalMind AI encrypted backup snapshot',
            'mimeType': 'application/octet-stream',
          }),
          contentType: DioMediaType.parse('application/json'), // Dio 5.x compatible media type
        ),
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: DioMediaType.parse('application/octet-stream'),
        ),
      });

      final response = await _dio.post(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data['id'] as String;
        return id;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Google Drive upload error: ${e.message}');
    }
  }

  /// Lists all backup files on Google Drive matching name format 'localmind_backup'.
  Future<List<Map<String, dynamic>>> listBackups() async {
    if (!isSignedIn) {
      final connected = await signIn();
      if (!connected) return [];
    }

    try {
      final response = await _dio.get(
        'https://www.googleapis.com/drive/v3/files',
        queryParameters: {
          'q': "name contains 'localmind_backup' and trashed = false",
          'fields': 'files(id, name, size, createdTime)',
          'orderBy': 'createdTime desc',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List files = response.data['files'] as List;
        return files.map((f) => Map<String, dynamic>.from(f as Map)).toList();
      } else {
        throw Exception('Listing failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Google Drive fetch list error: ${e.message}');
    }
  }

  /// Downloads backup file bytes using file ID.
  Future<List<int>> downloadBackup(String fileId) async {
    if (!isSignedIn) {
      final connected = await signIn();
      if (!connected) throw Exception('Google Drive not authenticated.');
    }

    try {
      final response = await _dio.get<List<int>>(
        'https://www.googleapis.com/drive/v3/files/$fileId',
        queryParameters: {
          'alt': 'media',
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Google Drive download error: ${e.message}');
    }
  }

  /// Deletes backup file from Google Drive using file ID.
  Future<void> deleteBackup(String fileId) async {
    if (!isSignedIn) {
      final connected = await signIn();
      if (!connected) throw Exception('Google Drive not authenticated.');
    }

    try {
      final response = await _dio.delete(
        'https://www.googleapis.com/drive/v3/files/$fileId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Delete failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Google Drive delete error: ${e.message}');
    }
  }
}
