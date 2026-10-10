import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FileUploadWidget extends StatefulWidget {
  final Function(String) onUploadComplete;
  final Function(String) onError;
  final String storagePath;
  final bool allowImages;
  final bool allowPdfs;
  final double maxFileSizeMB;
  final String? initialImageUrl;
  final String? initialPdfName;

  const FileUploadWidget({
    Key? key,
    required this.onUploadComplete,
    required this.onError,
    required this.storagePath,
    this.allowImages = true,
    this.allowPdfs = true,
    this.maxFileSizeMB = 10,
    this.initialImageUrl,
    this.initialPdfName,
  }) : super(key: key);

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  File? _imageFile;
  String? _base64Image;
  PlatformFile? _pdfFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialImageUrl != null) {
      _base64Image = widget.initialImageUrl;
    }
    if (widget.initialPdfName != null) {
      _pdfFile = PlatformFile(
        name: widget.initialPdfName!,
        size: 0,
        bytes: null,
      );
    }
  }

  Future<void> _getImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (bytes.length > widget.maxFileSizeMB * 1024 * 1024) {
          widget.onError('حجم الصورة كبير جداً. الحد الأقصى هو ${widget.maxFileSizeMB} ميجابايت');
          return;
        }
        setState(() {
          _base64Image = base64Encode(bytes);
          _imageFile = File(image.path);
          _pdfFile = null;
        });
      }
    } catch (e) {
      widget.onError('حدث خطأ أثناء اختيار الصورة');
    }
  }

  Future<void> _pickPDFFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowCompression: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.size > widget.maxFileSizeMB * 1024 * 1024) {
          widget.onError('حجم الملف كبير جداً. الحد الأقصى هو ${widget.maxFileSizeMB} ميجابايت');
          return;
        }

        setState(() {
          _pdfFile = file;
          _base64Image = null;
          _imageFile = null;
        });
      }
    } catch (e) {
      widget.onError('حدث خطأ أثناء اختيار الملف');
    }
  }

  Future<void> _uploadFile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        widget.onError('يجب تسجيل الدخول أولاً');
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance.ref();

      if (_base64Image != null && _imageFile != null) {
        final String fileName = '${widget.storagePath}_${timestamp}_${user.uid}.jpg';
        final imageRef = storageRef.child('${widget.storagePath}/${user.uid}/images/$fileName');
        
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user.uid,
            'timestamp': timestamp.toString(),
            'type': 'image',
          }
        );

        Uint8List imageBytes = await _imageFile!.readAsBytes();
        final uploadTask = imageRef.putData(imageBytes, metadata);
        
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
          },
          onError: (error) {
            widget.onError('خطأ في عملية الرفع');
          }
        );

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        widget.onUploadComplete(downloadUrl);
      } 
      else if (_pdfFile != null && _pdfFile!.bytes != null) {
        final String fileName = '${widget.storagePath}_${timestamp}_${user.uid}.pdf';
        final pdfRef = storageRef.child('${widget.storagePath}/${user.uid}/pdfs/$fileName');
        
        final metadata = SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'uploadedBy': user.uid,
            'timestamp': timestamp.toString(),
            'fileName': _pdfFile!.name,
            'type': 'pdf',
          }
        );
        
        final Uint8List fileBytes = Uint8List.fromList(_pdfFile!.bytes!);
        final uploadTask = pdfRef.putData(fileBytes, metadata);
        
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
          },
          onError: (error) {
            widget.onError('خطأ في عملية الرفع');
          }
        );

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        widget.onUploadComplete(downloadUrl);
      }
    } catch (e) {
      if (e is FirebaseException) {
        _handleFirebaseError(e);
      } else {
        widget.onError('حدث خطأ أثناء رفع الملف');
      }
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'storage/unauthorized':
        widget.onError('غير مصرح لك برفع الملفات');
        break;
      case 'storage/canceled':
        widget.onError('تم إلغاء عملية الرفع');
        break;
      case 'storage/retry-limit-exceeded':
        widget.onError('فشل الاتصال. يرجى المحاولة مرة أخرى');
        break;
      case 'storage/invalid-checksum':
        widget.onError('خطأ في تحميل الملف. يرجى المحاولة مرة أخرى');
        break;
      case 'storage/invalid-format':
        widget.onError('صيغة الملف غير صحيحة');
        break;
      case 'storage/object-not-found':
        widget.onError('فشل الاتصال بالخادم. يرجى المحاولة مرة أخرى');
        break;
      case 'storage/quota-exceeded':
        widget.onError('تم تجاوز الحد المسموح به للتخزين');
        break;
      default:
        widget.onError('حدث خطأ أثناء رفع الملف: ${e.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.allowImages || widget.allowPdfs) ...[
            Row(
              children: [
                if (widget.allowImages)
                  Expanded(
                    child: _buildUploadOption(
                      icon: Icons.camera_alt,
                      label: 'اختيار صورة',
                      onPressed: _getImage,
                    ),
                  ),
                if (widget.allowImages && widget.allowPdfs)
                  const SizedBox(width: 12),
                if (widget.allowPdfs)
                  Expanded(
                    child: _buildUploadOption(
                      icon: Icons.upload_file,
                      label: 'اختيار ملف PDF',
                      onPressed: _pickPDFFile,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (_base64Image != null || _pdfFile != null) ...[
            Container(
              height: _base64Image != null ? 180 : null,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _base64Image != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(_base64Image!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 180,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _base64Image = null;
                                _imageFile = null;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  : _pdfFile != null
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pdfFile!.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _pdfFile = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : null,
            ),
            if (_isUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.blue.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'جاري الرفع... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_isUploading ? 'جاري الرفع...' : 'رفع الملف'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.1),
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
} 