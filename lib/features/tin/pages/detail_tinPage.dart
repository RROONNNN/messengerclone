import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:messenger_clone/features/tin/story_item.dart';

class StoryDetailPage extends StatefulWidget {
  final List<StoryItem> stories;
  final int initialIndex;

  const StoryDetailPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> with TickerProviderStateMixin {
  late List<AnimationController> _progressControllers;
  late int _currentIndex;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  VideoPlayerController? _prevVideoController;
  ChewieController? _prevChewieController;
  VideoPlayerController? _nextVideoController;
  ChewieController? _nextChewieController;
  bool _isPlaying = true;
  bool _isVideoInitializing = false;
  bool _isContentLoaded = false; // Biến mới để kiểm tra trạng thái load nội dung
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isMessageFocused = false;
  bool _isLoading = false;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  int _nextIndex = 0;
  int _prevIndex = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _messageFocusNode.addListener(_onFocusChange);
  }

  void _initializeControllers() {
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _updateAdjacentIndices();
    _progressControllers = List.generate(
      widget.stories.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(seconds: 15), // Tăng duration lên 15 giây
      ),
    );
    _resetVideo(); // Khởi tạo nội dung (ảnh hoặc video) và chạy progress sau khi load xong
    _preloadAdjacentVideos();
  }

  void _updateAdjacentIndices() {
    _nextIndex = _currentIndex < widget.stories.length - 1 ? _currentIndex + 1 : _currentIndex;
    _prevIndex = _currentIndex > 0 ? _currentIndex - 1 : _currentIndex;
  }

  void _onFocusChange() {
    if (_isDisposed) return;
    setState(() {
      _isMessageFocused = _messageFocusNode.hasFocus;
    });
    if (_isMessageFocused) {
      _pauseProgress();
    } else {
      _resumeProgress();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageController.dispose();
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    for (var controller in _progressControllers) {
      controller.dispose();
    }
    _disposeVideoControllers();
    super.dispose();
  }

  void _disposeVideoControllers() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _prevVideoController?.dispose();
    _prevChewieController?.dispose();
    _nextVideoController?.dispose();
    _nextChewieController?.dispose();
  }

  void _startProgressForCurrentSequence() {
    if (_isDisposed || _currentIndex >= widget.stories.length || !_isContentLoaded) return;
    final currentStory = widget.stories[_currentIndex];
    final sequenceStartIndex = _currentIndex - (_currentIndex % currentStory.totalStories);
    final sequenceEndIndex = sequenceStartIndex + currentStory.totalStories - 1;

    for (var controller in _progressControllers) {
      controller.stop();
    }

    for (int i = sequenceStartIndex; i < _currentIndex; i++) {
      if (i < widget.stories.length) {
        _progressControllers[i].value = 1.0;
      }
    }

    if (_currentIndex < widget.stories.length) {
      final isVideo = currentStory.isVideo ?? false;
      if (isVideo && _videoPlayerController?.value.isInitialized == true) {
        _progressControllers[_currentIndex].duration = _videoPlayerController!.value.duration;
      } else {
        _progressControllers[_currentIndex].duration = const Duration(seconds: 15); // Đảm bảo duration là 15 giây
      }

      if (_progressControllers[_currentIndex].isCompleted) {
        _progressControllers[_currentIndex].reset();
      }

      if (!_isMessageFocused) {
        _progressControllers[_currentIndex].forward().then((_) {
          if (_isDisposed) return;
          if (_currentIndex < sequenceEndIndex && _currentIndex < widget.stories.length - 1) {
            _nextStory();
          } else {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  void _nextStory() {
    if (_isDisposed) return;
    if (_currentIndex < widget.stories.length - 1) {
      _progressControllers[_currentIndex].stop();
      setState(() {
        _currentIndex++;
        _updateAdjacentIndices();
        _isContentLoaded = false; // Reset trạng thái load khi chuyển story
        _resetVideo();
        _preloadAdjacentVideos();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_isDisposed) return;
    if (_currentIndex > 0) {
      _progressControllers[_currentIndex].stop();
      setState(() {
        _currentIndex--;
        _updateAdjacentIndices();
        _isContentLoaded = false; // Reset trạng thái load khi chuyển story
        _resetVideo();
        _preloadAdjacentVideos();
      });
      debugPrint('Previous story: _currentIndex = $_currentIndex'); // Debug
    } else {
      debugPrint('At first story, cannot go back'); // Debug
    }
  }

  Future<void> _resetVideo() async {
    if (_isVideoInitializing || _isDisposed) return;
    _isVideoInitializing = true;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isContentLoaded = false; // Reset trạng thái load
      });
    }

    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;

    final story = widget.stories[_currentIndex];
    final isVideo = story.isVideo ?? false;

    if (isVideo) {
      try {
        _videoPlayerController = VideoPlayerController.network(story.imageUrl);
        await _videoPlayerController!.initialize();
        if (_isDisposed) {
          _videoPlayerController?.dispose();
          return;
        }
        if (mounted) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoPlayerController!,
              autoPlay: true,
              looping: true,
              showControls: false,
              aspectRatio: _videoPlayerController!.value.aspectRatio.clamp(0.5, 2.0),
              allowFullScreen: false,
            );
            _isLoading = false;
            _isContentLoaded = true; // Đánh dấu nội dung đã load xong
            _startProgressForCurrentSequence(); // Bắt đầu progress bar
          });
        }
      } catch (e) {
        debugPrint('Error initializing video: $e');
        if (mounted && !_isDisposed) {
          setState(() {
            _chewieController = null;
            _isLoading = false;
            _isContentLoaded = true; // Đánh dấu nội dung đã load (dù lỗi)
            _startProgressForCurrentSequence(); // Chạy progress bar ngay cả khi lỗi
          });
        }
      }
    } else {
      // Ảnh không cần chờ load (CachedNetworkImage sẽ xử lý)
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
          _isContentLoaded = true; // Đánh dấu nội dung đã load
          _startProgressForCurrentSequence(); // Bắt đầu progress bar
        });
      }
    }
    _isVideoInitializing = false;
  }

  Future<void> _preloadAdjacentVideos() async {
    if (_isDisposed) return;
    _prevVideoController?.dispose();
    _prevChewieController?.dispose();
    _nextVideoController?.dispose();
    _nextChewieController?.dispose();
    _prevVideoController = null;
    _prevChewieController = null;
    _nextVideoController = null;
    _nextChewieController = null;

    if (_prevIndex >= 0 && _prevIndex != _currentIndex) {
      final prevStory = widget.stories[_prevIndex];
      if (prevStory.isVideo ?? false) {
        try {
          _prevVideoController = VideoPlayerController.network(prevStory.imageUrl);
          await _prevVideoController!.initialize();
          if (_isDisposed) {
            _prevVideoController?.dispose();
            return;
          }
          if (mounted) {
            _prevChewieController = ChewieController(
              videoPlayerController: _prevVideoController!,
              autoPlay: false,
              looping: false,
              showControls: false,
              aspectRatio: _prevVideoController!.value.aspectRatio.clamp(0.5, 2.0),
              allowFullScreen: false,
            );
          }
        } catch (e) {
          debugPrint('Error preloading previous video: $e');
          _prevVideoController?.dispose();
          _prevVideoController = null;
        }
      }
    }

    if (_nextIndex < widget.stories.length && _nextIndex != _currentIndex) {
      final nextStory = widget.stories[_nextIndex];
      if (nextStory.isVideo ?? false) {
        try {
          _nextVideoController = VideoPlayerController.network(nextStory.imageUrl);
          await _nextVideoController!.initialize();
          if (_isDisposed) {
            _nextVideoController?.dispose();
            return;
          }
          if (mounted) {
            _nextChewieController = ChewieController(
              videoPlayerController: _nextVideoController!,
              autoPlay: false,
              looping: false,
              showControls: false,
              aspectRatio: _nextVideoController!.value.aspectRatio.clamp(0.5, 2.0),
              allowFullScreen: false,
            );
          }
        } catch (e) {
          debugPrint('Error preloading next video: $e');
          _nextVideoController?.dispose();
          _nextVideoController = null;
        }
      }
    }
  }

  void _togglePlayPause() {
    if (_isDisposed) return;
    final story = widget.stories[_currentIndex];
    final isVideo = story.isVideo ?? false;
    if (isVideo && _videoPlayerController?.value.isInitialized == true) {
      setState(() {
        if (_isPlaying) {
          _videoPlayerController!.pause();
          _progressControllers[_currentIndex].stop();
        } else {
          _videoPlayerController!.play();
          _startProgressForCurrentSequence();
        }
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _pauseProgress() {
    _progressControllers[_currentIndex].stop();
    if (_videoPlayerController?.value.isInitialized == true) {
      _videoPlayerController!.pause();
      if (!_isDisposed && mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  void _resumeProgress() {
    if (_isDisposed) return;
    if (!_isMessageFocused) {
      _startProgressForCurrentSequence();
      if (_videoPlayerController?.value.isInitialized == true) {
        _videoPlayerController!.play();
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (_isDisposed) return;
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
    _pauseProgress();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDisposed) return;
    if (_isDragging) {
      final width = MediaQuery.of(context).size.width;
      setState(() {
        _dragOffset += details.delta.dx / width;
        _dragOffset = _dragOffset.clamp(-1.0, 1.0);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDisposed) return;
    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });
      if (_dragOffset.abs() > 0.3) {
        if (_dragOffset < 0 && _currentIndex < widget.stories.length - 1) {
          _nextStory();
        } else if (_dragOffset > 0 && _currentIndex > 0) {
          _previousStory();
          debugPrint('Drag to previous, _currentIndex = $_currentIndex');
        }
      } else if (details.primaryVelocity != null) {
        if (details.primaryVelocity! > 500 && _currentIndex > 0) {
          _previousStory();
          debugPrint('Velocity to previous, _currentIndex = $_currentIndex');
        } else if (details.primaryVelocity! < -500 && _currentIndex < widget.stories.length - 1) {
          _nextStory();
        }
      } else {
        _resumeProgress();
      }
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  void _handleVerticalDrag(DragEndDetails details) {
    if (_isDisposed) return;
    if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
      Navigator.of(context).pop();
    }
  }

  void _handleTap(TapDetails details) {
    if (_isDisposed) return;
    final width = MediaQuery.of(context).size.width;
    if (details.localPosition.dx < width * 0.3 && _currentIndex > 0) {
      _previousStory();
      debugPrint('Tap to previous, _currentIndex = $_currentIndex');
    } else if (details.localPosition.dx > width * 0.7) {
      if (_currentIndex < widget.stories.length - 1) {
        _nextStory();
      } else {
        Navigator.of(context).pop();
      }
    } else {
      final story = widget.stories[_currentIndex];
      final isVideo = story.isVideo ?? false;
      if (isVideo) {
        _togglePlayPause();
      }
    }
    debugPrint('Tap position: ${details.localPosition.dx}, Screen width: $width');
    debugPrint('Current index: $_currentIndex, Total stories: ${widget.stories.length}');
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      debugPrint('Sending message: ${_messageController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi tin nhắn!')),
      );
      _messageController.clear();
    }
    FocusScope.of(context).unfocus();
  }

  String _formatPostedTime(DateTime postedAt) {
    final now = DateTime.now();
    final difference = now.difference(postedAt);
    if (difference.inHours > 0) {
      return 'Đăng ${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return 'Đăng ${difference.inMinutes} phút trước';
    } else {
      return 'Đăng ${difference.inSeconds} giây trước';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.stories.length) return const Scaffold(backgroundColor: Colors.black);
    final story = widget.stories[_currentIndex];
    final isVideo = story.isVideo ?? false;
    final nextStory = _nextIndex < widget.stories.length ? widget.stories[_nextIndex] : null;
    final prevStory = _prevIndex >= 0 ? widget.stories[_prevIndex] : null;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final dragFactor = _dragOffset.clamp(-1.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        onVerticalDragEnd: _handleVerticalDrag,
        onTapUp: (details) => _handleTap(TapDetails(localPosition: details.localPosition)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isDragging && prevStory != null)
              _buildAdjacentStory(prevStory, dragFactor, width, height, true),
            Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..translate(width * dragFactor * 0.5)
                  ..rotateY(dragFactor * 0.3)
                  ..setEntry(1, 0, -dragFactor * 0.3)
                  ..scale(1.0 - dragFactor.abs() * 0.2),
                child: _buildCurrentStory(story, isVideo),
              ),
            ),
            if (_isDragging && nextStory != null)
              _buildAdjacentStory(nextStory, -dragFactor, width, height, false),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            _buildProgressBars(story),
            _buildHeader(story),
            ...story.textOverlays.map((overlay) => _buildTextOverlay(overlay)).toList(),
            if (isVideo && !_isPlaying)
              _buildPlayPauseIcon(),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjacentStory(StoryItem story, double dragFactor, double width, double height, bool isPrevious) {
    return Positioned(
      left: isPrevious ? -width * (1.0 - dragFactor.abs()) : null,
      right: isPrevious ? null : -width * (1.0 - dragFactor.abs()),
      top: 0,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translate((isPrevious ? width : -width) * dragFactor.clamp(-1.0, 0.0))
          ..rotateY(-dragFactor * 0.3)
          ..setEntry(1, 0, dragFactor * 0.3)
          ..scale(0.9 + dragFactor.abs() * 0.1),
        child: Opacity(
          opacity: dragFactor.abs().clamp(0.0, 1.0),
          child: Container(
            width: width,
            height: height,
            color: Colors.black,
            child: (story.isVideo ?? false)
                ? _buildVideoWidget(isPrevious ? _prevChewieController : _nextChewieController)
                : CachedNetworkImage(
                    imageUrl: story.imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red, size: 50),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStory(StoryItem story, bool isVideo) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isVideo && _videoPlayerController != null && _chewieController != null
          ? _buildVideoWidget(_chewieController, key: ValueKey(_currentIndex))
          : CachedNetworkImage(
              key: ValueKey(_currentIndex),
              imageUrl: story.imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red, size: 50),
            ),
    );
  }

  Widget _buildVideoWidget(ChewieController? controller, {Key? key}) {
    if (controller == null) return const SizedBox.shrink();
    return AspectRatio(
      key: key,
      aspectRatio: controller.videoPlayerController.value.aspectRatio.clamp(0.5, 2.0),
      child: Chewie(controller: controller),
    );
  }
Widget _buildProgressBars(StoryItem story) {
  return Positioned(
    top: 28,
    left: 8,
    right: 8,
    child: Row(
      children: List.generate(story.totalStories, (index) { // Sửa "index carpets" thành "index"
        final storyIndex = (_currentIndex - (_currentIndex % story.totalStories) + index).toInt(); // Chuyển sang int
        if (storyIndex >= widget.stories.length) return const SizedBox.shrink();
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.withOpacity(0.3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AnimatedBuilder(
                animation: _progressControllers[storyIndex],
                builder: (context, child) {
                  double progressValue = storyIndex < _currentIndex
                      ? 1.0
                      : storyIndex == _currentIndex
                          ? _progressControllers[storyIndex].value
                          : 0.0;
                  return LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressValue > 0 ? Colors.white : Colors.white.withOpacity(0.5),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }),
    ),
  );
}

  Widget _buildHeader(StoryItem story) {
    return Positioned(
      top: 40,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: CachedNetworkImageProvider(story.avatarUrl),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _formatPostedTime(story.postedAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.group, color: Colors.white, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Semantics(
            label: 'Đóng story',
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
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
    );
  }

  Widget _buildPlayPauseIcon() {
    return Center(
      child: Icon(
        Icons.play_arrow,
        color: Colors.white.withOpacity(0.7),
        size: 60,
      ),
    );
  }

  Widget _buildInputSection() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              height: 40,
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
                controller: _messageController,
                focusNode: _messageFocusNode,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Gửi tin nhắn...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            width: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildReactionButton(Icons.favorite, Colors.pink),
                _buildReactionButton(Icons.thumb_up, Colors.blue),
                _buildReactionButton(Icons.sentiment_very_satisfied, Colors.yellow),
                _buildReactionButton(Icons.star, Colors.amber),
                _buildReactionButton(Icons.cake, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phản hồi: ${icon.codePoint}')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(1, 1),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class TapDetails {
  final Offset localPosition;

  const TapDetails({required this.localPosition});
}