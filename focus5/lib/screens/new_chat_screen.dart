class NewChatScreen extends StatefulWidget {
  @override
  _NewChatScreenState createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatProvider _chatProvider = ChatProvider();
  
  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 2 tabs if admin, 1 if not
    _tabController = TabController(
      length: _chatProvider.isAdmin ? 2 : 1, 
      vsync: this
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Chat'),
        bottom: _chatProvider.isAdmin ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Coaches'),
            Tab(text: 'All Users'),
          ],
        ) : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (query) => _chatProvider.searchUsers(query),
            ),
          ),
          Expanded(
            child: _chatProvider.isAdmin
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    // Coaches Tab
                    _buildUserList(showOnlyCoaches: true),
                    // All Users Tab
                    _buildUserList(showOnlyCoaches: false),
                  ],
                )
              : _buildUserList(showOnlyCoaches: true),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList({required bool showOnlyCoaches}) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isSearching) {
          return Center(child: CircularProgressIndicator());
        }

        if (chatProvider.error != null) {
          return Center(child: Text(chatProvider.error!));
        }

        final users = showOnlyCoaches
            ? chatProvider.searchResults.where((user) => user.role == 'coach').toList()
            : chatProvider.searchResults;

        if (users.isEmpty) {
          return Center(
            child: Text(showOnlyCoaches 
              ? 'No coaches found' 
              : 'No users found'
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: user.avatarUrl.isEmpty
                    ? Text(user.name[0].toUpperCase())
                    : null,
                backgroundImage: user.avatarUrl.isNotEmpty
                    ? NetworkImage(user.avatarUrl)
                    : null,
              ),
              title: Text(user.name),
              subtitle: Text(user.role.capitalize()),
              trailing: Text(user.id),
              onTap: () => chatProvider.startChatWith(user),
            );
          },
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
} 