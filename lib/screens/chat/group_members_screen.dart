import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_models.dart';

class GroupMembersScreen extends StatefulWidget {
  final String chatId;
  final bool isAdmin;

  const GroupMembersScreen({
    Key? key,
    required this.chatId,
    required this.isAdmin,
  }) : super(key: key);

  @override
  _GroupMembersScreenState createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;

  Future<void> _addMembers() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.addGroupMembers(widget.chatId, _selectedUserIds.toList());
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding members: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.removeGroupMember(widget.chatId, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing member: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Members'),
        actions: widget.isAdmin ? [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _isLoading ? null : () => _showAddMembersDialog(),
          ),
        ] : null,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return StreamBuilder<Chat>(
            stream: chatProvider.getChatStream(widget.chatId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final chat = snapshot.data!;
              return ListView.builder(
                itemCount: chat.participantIds.length,
                itemBuilder: (context, index) {
                  final userId = chat.participantIds[index];
                  return FutureBuilder<ChatUser?>(
                    future: chatProvider.getUserDetails(userId),
                    builder: (context, userSnapshot) {
                      final user = userSnapshot.data;
                      if (user == null) {
                        return const ListTile(
                          title: Text('Loading...'),
                        );
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(user.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.role),
                        trailing: widget.isAdmin && userId != chatProvider.currentUserId
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _removeMember(userId),
                              )
                            : null,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddMembersDialog() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chat = await chatProvider.getChat(widget.chatId);
    final currentMembers = chat.participantIds.toSet();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Members'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<ChatUser>>(
            future: chatProvider.getAvailableUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final users = snapshot.data ?? [];
              return StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...users.where((user) => !currentMembers.contains(user.id)).map(
                        (user) => CheckboxListTile(
                          title: Text(user.name),
                          subtitle: Text(user.role),
                          value: _selectedUserIds.contains(user.id),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserIds.add(user.id);
                              } else {
                                _selectedUserIds.remove(user.id);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(user.name[0].toUpperCase())
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addMembers();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 