import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:messenger_clone/common/services/story_service.dart';
import 'package:messenger_clone/common/services/user_service.dart';
import 'package:messenger_clone/features/main_page/main_page.dart';
import 'dart:ui' as ui;
import '../../../common/services/auth_service.dart';
import '../../../common/widgets/dialog/custom_alert_dialog.dart';
import '../../../common/widgets/dialog/loading_dialog.dart';
import '../widgets/story_item.dart';

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
  File? _capturedMedia;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  bool _isDrawingMode = false;
  final List<Offset> _drawPoints = [];
  Color _drawColor = Colors.red;
  double _brushSize = 5.0;

  final List<Sticker> _stickers = [
    Sticker(asset: 'assets/sticker/sticker1.png', position: const Offset(50, 50)),
    Sticker(asset: 'assets/sticker/sticker2.png', position: const Offset(150, 50)),
  ];
  final List<Sticker> _addedStickers = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.stopVideoRecording().catchError((_) {});
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraAvailable = false;
            _isLoading = false;
          });
          CustomAlertDialog.show(
            context: context,
            title: 'Lỗi',
            message: 'Camera không khả dụng. Vui lòng sử dụng thư viện thay thế.',
          );
        }
        return;
      }
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high);
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraAvailable = false;
          _isLoading = false;
        });
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Camera không khả dụng. Vui lòng sử dụng thư viện thay thế.',
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1 || !_cameraAvailable || !_isCameraInitialized) return;
    final newCamera = _cameraController!.description == _cameras![0] ? _cameras![1] : _cameras![0];
    setState(() => _isLoading = true);
    await _cameraController?.stopVideoRecording().catchError((_) {});
    await _cameraController?.dispose();
    _cameraController = CameraController(newCamera, ResolutionPreset.high);
    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isLoading = false;
        });
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Không thể chuyển đổi camera.',
        );
      }
    }
  }

  Future<void> _captureMedia() async {
    if (!_cameraController!.value.isInitialized) {
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Camera chưa sẵn sàng!',
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: 'Đang xử lý...'),
    );
    try {
      if (_isVideoMode) {
        if (!_isRecording) {
          await _cameraController!.startVideoRecording();
          if (mounted) {
            setState(() => _isRecording = true);
          }
          Navigator.of(context).pop();
        } else {
          final videoFile = await _cameraController!.stopVideoRecording();
          if (mounted) {
            setState(() {
              _isRecording = false;
              _capturedMedia = File(videoFile.path);
            });
            Navigator.of(context).pop();
            CustomAlertDialog.show(
              context: context,
              title: 'Thành công',
              message: 'Đã quay video thành công! Đang tải lên...',
            );
            await _uploadMedia(_capturedMedia!, isVideo: true);
          }
        }
      } else {
        final imageFile = await _cameraController!.takePicture();
        if (mounted) {
          setState(() {
            _capturedMedia = File(imageFile.path);
            _isCameraInitialized = false;
          });
          Navigator.of(context).pop();
          CustomAlertDialog.show(
            context: context,
            title: 'Thành công',
            message: 'Đã chụp ảnh thành công!',
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Lỗi khi chụp/quay: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getMediaFromGallery() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: 'Đang chọn media...'),
    );
    try {
      XFile? pickedFile = _isVideoMode
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() {
          _capturedMedia = File(pickedFile.path);
          _isCameraInitialized = false;
        });
        Navigator.of(context).pop();
        if (_isVideoMode) {
          CustomAlertDialog.show(
            context: context,
            title: 'Thành công',
            message: 'Đã chọn video! Đang tải lên...',
          );
          await _uploadMedia(_capturedMedia!, isVideo: true);
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Lỗi khi chọn từ thư viện: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _mergeImageWithDrawingsAndStickers() async {
    if (_capturedMedia == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: 'Đang hợp nhất ảnh...'),
    );
    try {
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final uint8List = byteData!.buffer.asUint8List();

      final tempFile = File('${Directory.systemTemp.path}/merged_story.png');
      await tempFile.writeAsBytes(uint8List);

      setState(() {
        _capturedMedia = tempFile;
      });
      Navigator.of(context).pop();
    } catch (e) {
      Navigator.of(context).pop();
      CustomAlertDialog.show(
        context: context,
        title: 'Lỗi',
        message: 'Lỗi khi hợp nhất ảnh!',
      );
    }
  }

  Future<StoryItem?> _uploadMedia(File file, {required bool isVideo}) async {
    if (!isVideo && (_drawPoints.isNotEmpty || _addedStickers.isNotEmpty)) {
      await _mergeImageWithDrawingsAndStickers();
      file = _capturedMedia!;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: 'Đang tải lên...'),
    );
    final userId = await AuthService.isLoggedIn();
    if (userId == null) {
      Navigator.of(context).pop();
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Vui lòng đăng nhập để đăng tin!',
        );
      }
      return null;
    }
    try {
      final mediaUrl = await StoryService.postStory(
        userId: userId,
        mediaFile: file,
        mediaType: isVideo ? 'video' : 'image',
      );
      final userData = await UserService.fetchUserDataById(userId);
      final newStory = StoryItem(
        userId: userId,
        title: userData['userName'] as String? ?? 'Bạn',
        imageUrl: mediaUrl,
        avatarUrl: userData['photoUrl'] as String? ?? '',
        isVideo: isVideo,
        postedAt: DateTime.now(),
        totalStories: 1,
      );
      Navigator.of(context).pop();
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Thành công',
          message: 'Đã đăng tin thành công!',
          onPressed: () {
            Navigator.of(context).pop(newStory);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
                  (route) => false,
            );
          },
        );
      }
      return newStory;
    } catch (e) {
      Navigator.of(context).pop();
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Lỗi khi tải lên: $e',
        );
      }
      return null;
    }
  }

  void _startDrawing(Offset position) {
    setState(() {
      _isDrawingMode = true;
      _drawPoints.add(position);
    });
  }

  void _updateDrawing(Offset position) {
    if (_isDrawingMode) {
      setState(() {
        _drawPoints.add(position);
      });
    }
  }

  void _endDrawing() {
    setState(() {
      _isDrawingMode = false;
    });
  }

  void _addSticker(Sticker sticker) {
    setState(() {
      _addedStickers.add(sticker.copyWith(position: const Offset(50, 50)));
    });
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _stickers.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _addSticker(_stickers[index]),
                child: Image.asset(
                  _stickers[index].asset,
                  width: 60,
                  height: 60,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSticker(Sticker sticker) {
    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final index = _addedStickers.indexOf(sticker);
          if (index != -1) {
            setState(() {
              _addedStickers[index] = sticker.copyWith(
                position: Offset(
                  sticker.position.dx + details.delta.dx,
                  sticker.position.dy + details.delta.dy,
                ),
              );
            });
          }
        },
        child: Image.asset(
          sticker.asset,
          width: 100,
          height: 100,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * (1 / 3);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_capturedMedia == null || _isVideoMode)
            Column(
              children: [
                Container(
                  height: topSectionHeight * 0.6,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          if (_isRecording && _cameraAvailable && _isCameraInitialized)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                                  SizedBox(width: 6),
                                  Text('Đang quay', style: TextStyle(color: Colors.white, fontSize: 14)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                            onPressed: _getMediaFromGallery,
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _isVideoMode = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isVideoMode ? Colors.black.withOpacity(0.8) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('Ảnh', style: TextStyle(color: _isVideoMode ? Colors.white : Colors.black)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => setState(() => _isVideoMode = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isVideoMode ? Colors.white : Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('Video', style: TextStyle(color: _isVideoMode ? Colors.black : Colors.white)),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                            onPressed: _switchCamera,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: screenHeight - (topSectionHeight * 0.6),
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
                          ),
                          child: const Text('Camera không khả dụng', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _getMediaFromGallery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Text(_isVideoMode ? 'Chọn video' : 'Chọn ảnh'),
                        ),
                      ],
                    ),
                  )
                      : CameraPreview(_cameraController!),
                ),
              ],
            )
          else
            RepaintBoundary(
              key: _repaintBoundaryKey,
              child: GestureDetector(
                onPanStart: (details) => _isDrawingMode ? _startDrawing(details.localPosition) : null,
                onPanUpdate: (details) => _isDrawingMode ? _updateDrawing(details.localPosition) : null,
                onPanEnd: (details) => _isDrawingMode ? _endDrawing() : null,
                child: Stack(
                  children: [
                    Center(
                      child: Image.file(
                        _capturedMedia!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    CustomPaint(
                      painter: DrawingPainter(_drawPoints, _drawColor, _brushSize),
                      child: const SizedBox.expand(),
                    ),
                    ..._addedStickers.map((sticker) => _buildSticker(sticker)).toList(),
                  ],
                ),
              ),
            ),
          if (_capturedMedia == null && _cameraAvailable && _isCameraInitialized)
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
                      border: Border.all(color: _isVideoMode && _isRecording ? Colors.red : Colors.white, width: 4),
                      color: Colors.white,
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
          if (_capturedMedia != null && !_isVideoMode)
            Positioned(
              top: 40,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _capturedMedia = null;
                          _drawPoints.clear();
                          _addedStickers.clear();
                          _isDrawingMode = false;
                          _isCameraInitialized = true;
                        });
                        _initializeCamera();
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.brush, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isDrawingMode = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.label, color: Colors.white),
                          onPressed: () {
                            _showStickerPicker();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_capturedMedia != null && !_isVideoMode && _isDrawingMode)
            Positioned(
              bottom: 140,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        DropdownButton<Color>(
                          value: _drawColor,
                          items: [
                            Colors.red,
                            Colors.blue,
                            Colors.green,
                            Colors.yellow,
                            Colors.black,
                          ].map((color) => DropdownMenuItem<Color>(
                            value: color,
                            child: CircleAvatar(backgroundColor: color, radius: 10),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              _drawColor = value!;
                            });
                          },
                        ),
                        Slider(
                          value: _brushSize,
                          min: 1.0,
                          max: 20.0,
                          onChanged: (value) {
                            setState(() {
                              _brushSize = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _drawPoints.clear();
                        _isDrawingMode = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (_capturedMedia != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                elevation: 6,
                onPressed: () async {
                  await _uploadMedia(_capturedMedia!, isVideo: _isVideoMode);
                },
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double brushSize;

  DrawingPainter(this.points, this.color, this.brushSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Sticker {
  final String asset;
  final Offset position;

  Sticker({required this.asset, required this.position});

  Sticker copyWith({String? asset, Offset? position}) {
    return Sticker(
      asset: asset ?? this.asset,
      position: position ?? this.position,
    );
  }
}