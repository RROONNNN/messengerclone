import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:messenger_clone/features/tin/story_item.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

class StoryUploadPage extends StatefulWidget {
  final File? selectedImage;

  const StoryUploadPage({super.key, this.selectedImage});

  @override
  State<StoryUploadPage> createState() => _StoryUploadPageState();
}

class _StoryUploadPageState extends State<StoryUploadPage> {
  File? _selectedImage;
  final List<TextOverlay> _textOverlays = [];
  final List<Offset> _drawPoints = [];
  final TextEditingController _textController = TextEditingController();
  Offset _textPosition = const Offset(16, 150);
  bool _isTextInputVisible = false;
  bool _isDrawingMode = false;
  Color _drawColor = Colors.red;
  double _brushSize = 5.0;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final List<Sticker> _stickers = [
    Sticker(asset: 'assets/sticker1.png', position: const Offset(50, 50)),
    Sticker(asset: 'assets/sticker2.png', position: const Offset(150, 50)),
    // Add more sticker assets as needed
  ];
  final List<Sticker> _addedStickers = [];

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.selectedImage;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addTextOverlay() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _textOverlays.add(
          TextOverlay(
            content: _textController.text,
            position: _textPosition,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        _textController.clear();
        _isTextInputVisible = false;
      });
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

  Future<void> _mergeImageWithTextAndDrawings() async {
    if (_selectedImage == null) return;

    try {
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final uint8List = byteData!.buffer.asUint8List();

      final tempFile = File('${Directory.systemTemp.path}/merged_story.png');
      await tempFile.writeAsBytes(uint8List);

      setState(() {
        _selectedImage = tempFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ảnh đã được hợp nhất!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi hợp nhất ảnh!')),
      );
    }
  }

  void _uploadStory() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh trước khi đăng!')),
      );
      return;
    }

    if (_textOverlays.isNotEmpty || _drawPoints.isNotEmpty || _addedStickers.isNotEmpty) {
      _mergeImageWithTextAndDrawings().then((_) {
        debugPrint('Đăng tin với ảnh: ${_selectedImage!.path}');
        debugPrint('Text overlays: ${_textOverlays.map((overlay) => overlay.content).toList()}');
        debugPrint('Draw points: $_drawPoints');
        debugPrint('Stickers: ${_addedStickers.map((s) => s.asset).toList()}');

        final newStory = StoryItem(
          userId: 'current_user',
          title: 'Bạn',
          imageUrl: _selectedImage!.path,
          avatarUrl: 'https://picsum.photos/50?random=1',
          notificationCount: 0,
          isVideo: false,
          totalStories: 1,
          postedAt: DateTime.now(),
          textOverlays: _textOverlays,
          hasBorder: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng tin thành công!')),
        );

        Navigator.of(context).pop(newStory);
      });
      return;
    }

    debugPrint('Đăng tin với ảnh: ${_selectedImage!.path}');
    debugPrint('Text overlays: ${_textOverlays.map((overlay) => overlay.content).toList()}');
    debugPrint('Draw points: $_drawPoints');
    debugPrint('Stickers: ${_addedStickers.map((s) => s.asset).toList()}');

    final newStory = StoryItem(
      userId: 'current_user',
      title: 'Bạn',
      imageUrl: _selectedImage!.path,
      avatarUrl: 'https://picsum.photos/50?random=1',
      notificationCount: 0,
      isVideo: false,
      totalStories: 1,
      postedAt: DateTime.now(),
      textOverlays: _textOverlays,
      hasBorder: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đăng tin thành công!')),
    );

    Navigator.of(context).pop(newStory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RepaintBoundary(
            key: _repaintBoundaryKey,
            child: GestureDetector(
              onPanStart: (details) => _isDrawingMode ? _startDrawing(details.localPosition) : null,
              onPanUpdate: (details) => _isDrawingMode ? _updateDrawing(details.localPosition) : null,
              onPanEnd: (details) => _isDrawingMode ? _endDrawing() : null,
              child: Stack(
                children: [
                  if (_selectedImage != null)
                    Center(
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        'Chọn ảnh để bắt đầu',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  CustomPaint(
                    painter: DrawingPainter(_drawPoints, _drawColor, _brushSize),
                    child: const SizedBox.expand(),
                  ),
                  ..._textOverlays.map((overlay) => _buildTextOverlay(overlay)).toList(),
                  ..._addedStickers.map((sticker) => _buildSticker(sticker)).toList(),
                ],
              ),
            ),
          ),
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
                    onPressed: () => Navigator.of(context).pop(),
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
                        icon: const Icon(Icons.text_fields, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isTextInputVisible = true;
                            _textPosition = const Offset(16, 150);
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
          if (_isTextInputVisible)
            Positioned(
              bottom: 140,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Nhập văn bản...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (_) => _addTextOverlay(),
                      ),
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
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: _addTextOverlay,
                    ),
                  ),
                ],
              ),
            ),
          if (_isDrawingMode)
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
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              elevation: 6,
              onPressed: _uploadStory,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextOverlay(TextOverlay overlay) {
    return Positioned(
      left: overlay.position.dx,
      top: overlay.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final index = _textOverlays.indexOf(overlay);
          if (index != -1) {
            setState(() {
              _textOverlays[index] = TextOverlay(
                content: overlay.content,
                position: Offset(
                  overlay.position.dx + details.delta.dx,
                  overlay.position.dy + details.delta.dy,
                ),
                style: overlay.style,
              );
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Text(
            overlay.content,
            style: overlay.style.copyWith(
              color: Colors.white,
              shadows: const [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black54,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
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
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
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