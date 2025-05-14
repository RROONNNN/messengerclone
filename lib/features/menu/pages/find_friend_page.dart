import 'dart:async';

import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:messenger_clone/common/services/friend_service.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';

class FindFriendsPage extends StatefulWidget {
  const FindFriendsPage({super.key});

  @override
  State<FindFriendsPage> createState() => _FindFriendsPageState();
}

class _FindFriendsPageState extends State<FindFriendsPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _currentUserId = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await FriendService.searchUsersByName(query);
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) throw Exception('User not logged in');

      _currentUserId = currentUser.$id;
      final updatedResults = await Future.wait(results.map((user) async {
        final status = await FriendService.getFriendshipStatus(_currentUserId, user['userId']);
        return {
          ...user,
          'friendshipStatus': status['status'],
          'requestId': status['requestId'],
          'direction': status['direction'],
        };
      }).toList());

      setState(() {
        _searchResults = updatedResults;
        _isLoading = false;
      });
      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _debounceSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query.trim());
    });
  }

  void _updateFriendshipStatus(String userId, String newStatus, String newRequestId, String newDirection) {
    setState(() {
      _searchResults = _searchResults.map((user) {
        if (user['userId'] == userId) {
          return {
            ...user,
            'friendshipStatus': newStatus,
            'requestId': newRequestId,
            'direction': newDirection,
          };
        }
        return user;
      }).toList();
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: context.theme.textColor,
        ),
        title: const TitleText('Find Friends', fontSize: 25, fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBar(context),
              const SizedBox(height: 16),
              Expanded(child: _buildSearchResults(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name...',
        hintStyle: TextStyle(color: context.theme.textColor.withOpacity(0.5)),
        prefixIcon: Icon(Icons.search, color: context.theme.textColor.withOpacity(0.7)),
        filled: true,
        fillColor: context.theme.grey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(color: context.theme.textColor),
      onChanged: _debounceSearch,
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: TitleText(
          _errorMessage!,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: context.theme.red,
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: TitleText(
          'No users found.',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: context.theme.textColor.withOpacity(0.7),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildUserCard(context, user, _currentUserId),
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user, String currentUserId) {
    final isCurrentUser = currentUserId == user['userId'];
    final friendshipStatus = user['friendshipStatus'] as String;
    final requestId = user['requestId'] as String;
    final direction = user['direction'] as String;

    if (isCurrentUser) {
      return Card(
        color: context.theme.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: user['photoUrl'] != null && user['photoUrl'].startsWith('http')
                ? NetworkImage(user['photoUrl'])
                : const AssetImage('assets/images/avatar.png'),
          ),
          title: TitleText(
            user['name'] ?? 'Unknown',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.theme.textColor,
          ),
          subtitle: TitleText(
            user['aboutMe']?.isNotEmpty == true ? user['aboutMe'] : 'No description',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: context.theme.textColor.withOpacity(0.7),
          ),
        ),
      );
    }

    if (friendshipStatus == 'pending' && direction == 'received') {
      return Card(
        color: context.theme.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: user['photoUrl'] != null && user['photoUrl'].startsWith('http')
                ? NetworkImage(user['photoUrl'])
                : const AssetImage('assets/images/avatar.png'),
          ),
          title: TitleText(
            user['name'] ?? 'Unknown',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.theme.textColor,
          ),
          subtitle: TitleText(
            user['aboutMe']?.isNotEmpty == true ? user['aboutMe'] : 'No description',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: context.theme.textColor.withOpacity(0.7),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () async {
                  try {
                    await FriendService.acceptFriendRequest(requestId, currentUserId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request accepted')),
                      );
                      _updateFriendshipStatus(user['userId'], 'accepted', requestId, direction);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to accept request: $e')),
                      );
                    }
                  }
                },
                child: const Text('Accept', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.theme.textColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () async {
                  try {
                    await FriendService.declineFriendRequest(requestId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request declined')),
                      );
                      _updateFriendshipStatus(user['userId'], 'none', '', '');
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to decline request: $e')),
                      );
                    }
                  }
                },
                child: const Text('Decline', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: context.theme.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: user['photoUrl'] != null && user['photoUrl'].startsWith('http')
              ? NetworkImage(user['photoUrl'])
              : const AssetImage('assets/images/avatar.png'),
        ),
        title: TitleText(
          user['name'] ?? 'Unknown',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.theme.textColor,
        ),
        subtitle: TitleText(
          user['aboutMe']?.isNotEmpty == true ? user['aboutMe'] : 'No description',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: context.theme.textColor.withOpacity(0.7),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: friendshipStatus == 'none' ? context.theme.blue : context.theme.grey,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: friendshipStatus == 'none'
              ? () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Add Friend'),
                content: const Text('Do you want to send a friend request to this user?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Send'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              try {
                await FriendService.sendFriendRequest(currentUserId, user['userId']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Friend request sent!')),
                  );
                  _updateFriendshipStatus(user['userId'], 'pending', '', 'sent');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().contains('already exists')
                            ? 'A friend request or friendship already exists with this user.'
                            : e.toString().contains('Failed to send friend request')
                            ? e.toString().replaceFirst('Exception: Failed to send friend request: ', '')
                            : 'Failed to send request: $e',
                      ),
                    ),
                  );
                }
              }
            }
          }
              : friendshipStatus == 'pending' && direction == 'sent'
              ? () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Friend Request'),
                content: const Text('Do you want to cancel the friend request?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              try {
                await FriendService.cancelFriendRequest(requestId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Friend request canceled')),
                  );
                  _updateFriendshipStatus(user['userId'], 'none', '', '');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel request: $e')),
                  );
                }
              }
            }
          }
              : null,
          child: Text(
            friendshipStatus == 'pending' && direction == 'sent'
                ? 'Request Sent'
                : friendshipStatus == 'accepted'
                ? 'Friends'
                : 'Add Friend',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}