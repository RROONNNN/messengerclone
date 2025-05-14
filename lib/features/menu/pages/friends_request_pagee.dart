import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:messenger_clone/common/services/friend_service.dart';
import 'package:messenger_clone/common/services/user_service.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  List<Map<String, dynamic>> _friendRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _fetchFriendRequests();
  }

  Future<void> _fetchFriendRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      _currentUserId = user.$id;
      final requests = await FriendService.getPendingFriendRequests(user.$id);
      final detailedRequests = await Future.wait(requests.map((request) async {
        final userData = await UserService.fetchUserDataById(request['userId']);
        return {
          'requestId': request['requestId'],
          'userId': request['userId'],
          'name': userData['userName'] ?? 'Unknown',
          'photoUrl': userData['photoUrl'],
        };
      }).toList());

      setState(() {
        _friendRequests = detailedRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load friend requests: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await FriendService.acceptFriendRequest(requestId, _currentUserId);
      await _fetchFriendRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await FriendService.declineFriendRequest(requestId);
      await _fetchFriendRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline request: $e')),
        );
      }
    }
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
        title: const TitleText('Friend Requests', fontSize: 25, fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
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

    if (_friendRequests.isEmpty) {
      return const Center(
        child: TitleText(
          'No friend requests.',
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          return _buildRequestCard(context, request);
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    return Card(
      color: context.theme.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: request['photoUrl'] != null && request['photoUrl'].startsWith('http')
              ? NetworkImage(request['photoUrl'])
              : const AssetImage('assets/images/avatar.png'),
        ),
        title: TitleText(
          request['name'],
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.theme.textColor,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () => _acceptRequest(request['requestId']),
              child: const Text('Accept', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: BorderSide(color: context.theme.textColor)),
              onPressed: () => _declineRequest(request['requestId']),
              child: const Text('Decline', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}