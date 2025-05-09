import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:messenger_clone/features/tin/pages/tin_uploadPage.dart';
import 'package:messenger_clone/features/tin/story_item.dart';

class GallerySelectionPage extends StatefulWidget {
  const GallerySelectionPage({super.key});

  @override
  State<GallerySelectionPage> createState() => _GallerySelectionPageState();
}

class _GallerySelectionPageState extends State<GallerySelectionPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isVideoMode = false;
  bool _cameraAvailable = true;
  bool _isRecording = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _cameraAvailable = false;
          _isLoading = false;
        });
        return;
      }
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _cameraAvailable = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera không khả dụng. Sử dụng thư viện thay thế.')),
      );
    }
  }

  Future<void> _captureMedia() async {
    if (!_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera chưa sẵn sàng!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      if (_isVideoMode) {
        if (!_isRecording) {
          await _cameraController!.startVideoRecording();
          setState(() {
            _isRecording = true;
          });
        } else {
          final videoFile = await _cameraController!.stopVideoRecording();
          setState(() {
            _isRecording = false;
          });
          if (videoFile != null) {
            _navigateToUploadPage(File(videoFile.path), isVideo: true);
          }
        }
      } else {
        final imageFile = await _cameraController!.takePicture();
        if (imageFile != null) {
          _navigateToUploadPage(File(imageFile.path), isVideo: false);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chụp ảnh/quay video: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getMediaFromGallery() async {
    setState(() {
      _isLoading = true;
    });
    try {
      XFile? pickedFile;
      if (_isVideoMode) {
        pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      } else {
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      }
      if (pickedFile != null && mounted) {
        _navigateToUploadPage(File(pickedFile.path), isVideo: _isVideoMode);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn từ thư viện: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToUploadPage(File file, {required bool isVideo}) async {
    final newStory = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryUploadPage(selectedImage: file),
      ),
    );
    if (newStory != null && newStory is StoryItem && mounted) {
      Navigator.pop(context, newStory);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * (1 / 3);
    final bottomSectionHeight = screenHeight * (2 / 3);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Top 1/3: Controls (reduced height to minimize empty space)
              Container(
                height: topSectionHeight * 0.6, // Reduced height to 60% of original top section
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Top row: Close button and recording indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        if (_isRecording && _cameraAvailable && _isCameraInitialized)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Đang quay',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Mode toggle and controls (moved up)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery picker icon
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                            onPressed: _getMediaFromGallery,
                          ),
                        ),
                        // Mode toggle (Photo/Video)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isVideoMode = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isVideoMode ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Ảnh',
                                  style: TextStyle(
                                    color: _isVideoMode ? Colors.white : Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isVideoMode = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isVideoMode ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Video',
                                  style: TextStyle(
                                    color: _isVideoMode ? Colors.black : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Camera flip icon
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                            onPressed: () async {
                              if (_cameras != null && _cameras!.length > 1) {
                                final newCamera = _cameras![_cameraController!.description == _cameras![0] ? 1 : 0];
                                await _cameraController!.dispose();
                                _cameraController = CameraController(
                                  newCamera,
                                  ResolutionPreset.high,
                                );
                                await _cameraController!.initialize();
                                if (mounted) {
                                  setState(() {});
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bottom 2/3: Camera view (expanded to take remaining space)
              Container(
                height: screenHeight - (topSectionHeight * 0.6), // Adjusted height to fill remaining space
                color: Colors.black,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : !_cameraAvailable || !_isCameraInitialized
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Camera không khả dụng',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _getMediaFromGallery,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.9),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 5,
                                    shadowColor: Colors.black.withOpacity(0.3),
                                  ),
                                  child: Text(
                                    _isVideoMode ? 'Chọn video từ thư viện' : 'Chọn ảnh từ thư viện',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : CameraPreview(_cameraController!),
              ),
            ],
          ),
          // Capture button overlay
          if (_cameraAvailable && _isCameraInitialized)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureMedia,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isVideoMode && _isRecording ? Colors.red : Colors.white,
                        width: 4,
                      ),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: _isVideoMode && _isRecording ? BoxShape.rectangle : BoxShape.circle,
                          color: _isVideoMode && _isRecording ? Colors.red : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}