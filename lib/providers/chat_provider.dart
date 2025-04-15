import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  
  List<Chat> _chats = [];
  Map<String, List<ChatMessage>> _messages = {};
  Map<String, ChatUser> _users = {};
  String? _selectedChatId;
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  String? _error;
  ChatUser? _currentChatUser;
  bool _isCurrentUserLoading = true;
  bool _isAdmin = false;
  bool _isCoach = false;
  
  // Subscriptions to clean up
  List<StreamSubscription> _subscriptions = [];
  
  List<ChatUser> _searchResults = [];
  List<ChatUser> get searchResults => _searchResults;
  
  bool _isSearching = false;
  bool get isSearching => _isSearching;
  
  // Getters
  List<Chat> get chats => _chats;
  Map<String, List<ChatMessage>> get messages => _messages;
  String? get selectedChatId => _selectedChatId;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;
  bool get hasError => _error != null;
  String get currentUserId => _auth.currentUser?.uid ?? '';
  ChatUser? get currentChatUser => _currentChatUser;
  bool get isCurrentUserLoading => _isCurrentUserLoading;
  
  bool get isCoach => _isCoach;
  bool get isAdmin => _isAdmin;
  bool get canCreateChatWithAnyone => isCoach || isAdmin;
  
  String? _lastLoadedUserId;
  Timer? _authDebounceTimer;
  
  ChatProvider() {
    // Initialize by loading chats when user is authenticated
    if (_auth.currentUser != null) {
      _loadCurrentUserDetails();
      loadChats();
    }
    
    // Listen for auth state changes - but debounce to avoid excessive updates
    _subscriptions.add(
      _auth.authStateChanges().listen((user) {
        // Avoid triggering this too frequently during app startup or navigation
        if (_authDebounceTimer?.isActive ?? false) {
          debugPrint('ChatProvider: Debouncing rapid auth state change');
          return;
        }
        
        _authDebounceTimer = Timer(const Duration(milliseconds: 500), () {}); 
        
        if (user != null) {
          final currentUserId = user.uid;
          // Only reload if we have a different user or first time loading
          if (currentUserId != _lastLoadedUserId) {
            debugPrint('ChatProvider: Auth state change - loading data for user: ${user.uid}');
            _lastLoadedUserId = currentUserId;
            _loadCurrentUserDetails();
            loadChats();
          } else {
            debugPrint('ChatProvider: Auth state change - same user, skipping reload');
          }
        } else {
          // Clear data when user logs out
          debugPrint('ChatProvider: Auth state change - user logged out, clearing data');
          _lastLoadedUserId = null;
          _chats = [];
          _messages = {};
          _users = {};
          _selectedChatId = null;
          _currentChatUser = null;
          notifyListeners();
        }
      })
    );
  }
  
  @override
  void dispose() {
    // Clean up subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
  
  // Load current user details
  Future<void> _loadCurrentUserDetails() async {
    if (_auth.currentUser == null) {
      _currentChatUser = null;
      _isAdmin = false; // Reset if no user
      _isCoach = false; // Reset if no user
      _isCurrentUserLoading = false;
      debugPrint("ChatProvider: _loadCurrentUserDetails - No authenticated user found.");
      notifyListeners();
      return;
    }

    _isCurrentUserLoading = true;
    // Don't notify yet, wait until data is fetched or error occurs

    final userId = _auth.currentUser!.uid;
    debugPrint("ChatProvider: _loadCurrentUserDetails - Loading details for UID: $userId");

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        debugPrint("ChatProvider: _loadCurrentUserDetails - Fetched user data: ${data.toString()}"); // Log raw data

        // Explicitly log the value being checked for isAdmin
        final isAdminValue = data?['isAdmin'];
        final isCoachValue = data?['isCoach'];
        debugPrint("ChatProvider: _loadCurrentUserDetails - Raw isAdmin value from Firestore: $isAdminValue (Type: ${isAdminValue?.runtimeType})");
        debugPrint("ChatProvider: _loadCurrentUserDetails - Raw isCoach value from Firestore: $isCoachValue (Type: ${isCoachValue?.runtimeType})");

        _currentChatUser = ChatUser.fromFirestore(userDoc);
        _users[currentUserId] = _currentChatUser!; // Update cache
        _isAdmin = _currentChatUser!.isAdmin; // Rely on the parsed value
        _isCoach = _currentChatUser!.isCoach; // Rely on the parsed value

        debugPrint("ChatProvider: _loadCurrentUserDetails - Parsed user: Name=${_currentChatUser!.name}, isAdmin=$_isAdmin, isCoach=$_isCoach");

      } else {
        debugPrint("ChatProvider: _loadCurrentUserDetails - Error - Current user document not found in Firestore for UID: $userId");
        _error = "Current user data not found."; // Set error state
        _currentChatUser = null;
        _isAdmin = false;
        _isCoach = false;
      }
    } catch (e) {
      _error = "Error loading current user: ${e.toString()}";
      debugPrint("ChatProvider: _loadCurrentUserDetails - Error loading details: $e");
      _currentChatUser = null;
       _isAdmin = false; // Reset on error
       _isCoach = false; // Reset on error
    } finally {
      _isCurrentUserLoading = false;
      debugPrint("ChatProvider: _loadCurrentUserDetails - Finished. isAdmin is now $_isAdmin");
      notifyListeners(); // Notify UI that loading finished/state updated
    }
  }
  
  // Set the selected chat
  void selectChat(String chatId) {
    _selectedChatId = chatId;
    getMessagesForChat(chatId);
    notifyListeners();
  }
  
  // Load all chats for current user
  Future<void> loadChats() async {
    if (_auth.currentUser == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Clear existing subscriptions
      for (var subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions = [];
      
      // Listen for chats where current user is a participant
      final chatStream = _firestore
          .collection('chats')
          .where('participantRefs', arrayContains: _firestore.collection('users').doc(currentUserId))
          .orderBy('lastMessageTime', descending: true)
          .snapshots();
          
      _subscriptions.add(
        chatStream.listen(
          (snapshot) {
            _chats = snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
            _isLoading = false;
            notifyListeners();
            
            // Load the first chat's messages if there's no selected chat
            if (_chats.isNotEmpty && _selectedChatId == null) {
              selectChat(_chats.first.id);
            }
          },
          onError: (e) {
            _error = "Error loading chats: ${e.toString()}";
            _isLoading = false;
            notifyListeners();
          }
        )
      );
    } catch (e) {
      _error = "Error loading chats: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get messages for a specific chat
  void getMessagesForChat(String chatId) {
    _isLoadingMessages = true;
    notifyListeners();
    
    try {
      // Clear existing message subscriptions
      _subscriptions.removeWhere((subscription) {
        if (subscription.hashCode.toString().contains('messages')) {
          subscription.cancel();
          return true;
        }
        return false;
      });
      
      // Listen for messages in this chat
      final messageStream = _firestore
          .collection('messages')
          .where('chatRef', isEqualTo: _firestore.collection('chats').doc(chatId))
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to latest 50 messages
          .snapshots();
          
      final subscription = messageStream.listen(
        (snapshot) {
          final newMessages = snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
          
          // Check if messages are actually different before updating
          final existingMessages = _messages[chatId] ?? [];
          if (!_areMessageListsEqual(existingMessages, newMessages)) {
            _messages[chatId] = newMessages;
            _isLoadingMessages = false;
            notifyListeners();
            
            // Mark messages as read
            markChatAsRead(chatId);
          }
        },
        onError: (e) {
          _error = "Error loading messages: ${e.toString()}";
          _isLoadingMessages = false;
          notifyListeners();
        }
      );
      
      _subscriptions.add(subscription);
    } catch (e) {
      _error = "Error loading messages: ${e.toString()}";
      _isLoadingMessages = false;
      notifyListeners();
    }
  }
  
  // Helper method to compare message lists
  bool _areMessageListsEqual(List<ChatMessage> list1, List<ChatMessage> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }
  
  // Send a message
  Future<void> sendMessage(String chatId, String content, {MessageType type = MessageType.text, String? mediaUrl}) async {
    final String functionCallId = DateTime.now().millisecondsSinceEpoch.toString(); // Unique ID for this call
    debugPrint("[$functionCallId] sendMessage START: ChatID=$chatId, Content='$content'");

    if (_auth.currentUser == null) {
       debugPrint("[$functionCallId] sendMessage: Error - No authenticated user.");
      _error = "User not logged in";
      notifyListeners();
      return;
    }
    
    final messageId = _firestore.collection('messages').doc().id;
    debugPrint("[$functionCallId] sendMessage: Generated MessageID=$messageId");

    try {
      final timestamp = FieldValue.serverTimestamp(); // Get timestamp before transaction
      final senderRef = _firestore.collection('users').doc(currentUserId);
      final chatRef = _firestore.collection('chats').doc(chatId);
      final messageRef = _firestore.collection('messages').doc(messageId);

      final messageData = {
        'chatRef': chatRef,
        'senderRef': senderRef,
        'content': content,
        'timestamp': timestamp, // Use the pre-fetched timestamp
        'isRead': false,
        'reactions': [],
        'type': type.toString().split('.').last,
        'mediaUrl': mediaUrl,
        // Legacy fields
        'chatId': chatId,
        'senderId': currentUserId
      };
      
      debugPrint("[$functionCallId] sendMessage: Prepared message data. Starting transaction...");
      // Use a transaction to ensure atomic updates
      await _firestore.runTransaction((transaction) async {
        debugPrint("[$functionCallId] sendMessage: Transaction START for MessageID=$messageId");
        // 1. Set the message document
        transaction.set(messageRef, messageData);
        debugPrint("[$functionCallId] sendMessage: Transaction - Step 1 SET Message $messageId.");

        // 2. Update the chat document's last message details
        transaction.update(chatRef, {
          'lastMessageText': content,
          'lastMessageTime': timestamp, // Use the same pre-fetched timestamp
          'lastMessageSenderRef': senderRef,
          'readBy': [currentUserId],
          // Legacy fields
          'lastMessageSenderId': currentUserId
        });
         debugPrint("[$functionCallId] sendMessage: Transaction - Step 2 UPDATED Chat $chatId last message.");
         debugPrint("[$functionCallId] sendMessage: Transaction END for MessageID=$messageId");
      });
       debugPrint("[$functionCallId] sendMessage: Transaction successful for MessageID=$messageId.");

      // --- Optimistic update was already removed --- 

    } catch (e) {
      _error = "Error sending message: ${e.toString()}";
      debugPrint("[$functionCallId] sendMessage: Error during transaction for MessageID=$messageId: $e");
      notifyListeners();
    } finally {
       debugPrint("[$functionCallId] sendMessage END: ChatID=$chatId");
    }
  }
  
  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final userRef = _firestore.collection('users').doc(currentUserId);
      
      // Update chat document
      await chatRef.update({
        'readBy': FieldValue.arrayUnion([currentUserId]),
      });
      
      // Update all unread messages sent by others
      final batch = _firestore.batch();
      final unreadMessages = await _firestore
          .collection('messages')
          .where('chatRef', isEqualTo: chatRef)
          .where('senderRef', isNotEqualTo: userRef)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      _error = "Error marking chat as read: ${e.toString()}";
      notifyListeners();
    }
  }
  
  // Get user details
  Future<ChatUser?> getUserDetails(String userId) async {
    // Return from cache if available
    if (_users.containsKey(userId)) {
      return _users[userId];
    }
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = ChatUser.fromFirestore(doc);
        _users[userId] = user;
        return user;
      }
    } catch (e) {
      _error = "Error getting user details: ${e.toString()}";
      notifyListeners();
    }
    
    return null;
  }
  
  // Get coach details
  Future<Map<String, dynamic>?> getCoachDetails(String userId) async {
    try {
      final user = await getUserDetails(userId);
      if (user == null || !user.isCoach || user.coachRef == null) return null;
      
      final coachId = user.coachRef!['id'];
      final doc = await _firestore.collection('coaches').doc(coachId).get();
      
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      _error = "Error getting coach details: ${e.toString()}";
      notifyListeners();
    }
    
    return null;
  }
  
  // Search for users or list all users for admin
  Future<void> searchUsers(String query) async {
    final lowerCaseQuery = query.trim().toLowerCase();
    debugPrint('Searching/Listing users with query: "$lowerCaseQuery", isAdmin: $isAdmin');

    _isSearching = true;
    _searchResults = []; // Clear previous results
    notifyListeners();

    try {
      List<ChatUser> users;

      if (isAdmin) {
        // Admin: Fetch ALL users first
        debugPrint('Admin: Fetching all users...');
        final userDocsSnapshot = await _firestore
            .collection('users')
            .get();

        users = userDocsSnapshot.docs
            .map((doc) => ChatUser.fromFirestore(doc))
            .where((user) => user.userId != currentUserId) // Exclude current user
            .toList();
        debugPrint('Admin: Fetched ${users.length} other users.');

        // If query is not empty, filter client-side
        if (lowerCaseQuery.isNotEmpty) {
          debugPrint('Admin: Filtering client-side for "$lowerCaseQuery"...');
          users = users.where((user) {
            final nameMatch = user.name.toLowerCase().contains(lowerCaseQuery);
            final fullNameMatch = user.fullName.toLowerCase().contains(lowerCaseQuery);
            return nameMatch || fullNameMatch;
          }).toList();
          debugPrint('Admin: Found ${users.length} matching users after filtering.');
        } else {
           debugPrint('Admin: Displaying all ${users.length} fetched users (no query).');
        }

      } else {
        // Non-admin: Server-side query for coaches ONLY if query is not empty
        if (lowerCaseQuery.isNotEmpty) {
          debugPrint('Non-admin: Querying coaches matching "$lowerCaseQuery"...');
          final userDocsSnapshot = await _firestore
              .collection('users')
              .where('isCoach', isEqualTo: true)
              .where('fullName', isGreaterThanOrEqualTo: query) // Use original query for Firestore
              .where('fullName', isLessThanOrEqualTo: query + '\\uf8ff')
              .limit(20)
              .get();
              
          users = userDocsSnapshot.docs
              .map((doc) => ChatUser.fromFirestore(doc))
              .where((user) => user.userId != currentUserId)
              .toList();
          debugPrint('Non-admin: Found ${users.length} matching coaches.');
        } else {
          // Non-admin and empty query: Show coaches they can potentially chat with (or empty list)
          // Depending on requirements, you might fetch all coaches here or leave it empty
          debugPrint('Non-admin: Empty query, showing no results initially (or fetch all coaches).');
          users = []; // Or fetch all coaches via getAvailableUsers logic if needed
        }
      }
      
      _searchResults = users;

    } catch (e) {
      _error = "Error searching users: ${e.toString()}";
      debugPrint('Error searching users: $e');
      _searchResults = []; // Ensure results are empty on error
    } finally {
       _isSearching = false;
       notifyListeners();
    }
  }
  
  // Check if user can start chat with another user
  bool canStartChatWith(ChatUser user) {
    // Admin or coach can chat with anyone
    if (isAdmin || isCoach) return true;
    
    // Regular users can only chat with coaches
    return user.isCoach;
  }
  
  // Get available users for group chat
  Future<List<ChatUser>> getAvailableUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatUser(
          id: doc.id,
          name: data['name'] ?? '',
          fullName: data['fullName'] ?? '',
          avatarUrl: data['avatarUrl'],
          status: UserStatus.values.firstWhere(
            (e) => e.toString() == 'UserStatus.${data['status'] ?? 'offline'}',
            orElse: () => UserStatus.offline,
          ),
          role: data['role'] ?? 'user',
          specialization: data['specialization'] ?? '',
          isAdmin: data['isAdmin'] ?? false,
          isCoach: data['isCoach'] ?? false,
        );
      }).toList();

      // Filter out current user
      users.removeWhere((user) => user.id == currentUserId);

      // If user is admin, show all users
      if (isAdmin) {
        return users;
      }

      // For non-admins, only show coaches
      return users.where((user) => user.isCoach).toList();
    } catch (e) {
      debugPrint('Error getting available users: $e');
      return [];
    }
  }

  // Create a new chat with multiple users (group chat)
  Future<String?> createChat(
    List<String> otherUserIds, {
    bool isGroup = false,
    String? groupName,
  }) async {
    if (_auth.currentUser == null) return null;
    
    try {
      // Create all participant IDs
      final participantIds = [...otherUserIds, currentUserId];
      final participantRefs = participantIds.map((id) => _firestore.collection('users').doc(id)).toList();
      
      // For 1:1 chats, check if a chat already exists
      if (!isGroup && otherUserIds.length == 1) {
        final existingChats = await _firestore
            .collection('chats')
            .where('participantIds', arrayContains: currentUserId)
            .get();
        
        for (var doc in existingChats.docs) {
          final chat = Chat.fromFirestore(doc);
          if (chat.participantIds.length == 2 && 
              chat.participantIds.contains(otherUserIds[0])) {
            return chat.id;
          }
        }
      }
      
      // Get current user document reference
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      
      // Create a new chat
      final chatRef = await _firestore.collection('chats').add({
        'participantIds': participantIds,
        'participantRefs': participantRefs,
        'createdAt': FieldValue.serverTimestamp(),
        'createdByRef': currentUserRef,
        'lastMessageText': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderRef': currentUserRef,
        'isGroupChat': isGroup,
        'groupName': groupName,
        'readBy': [currentUserId],
        // Keep legacy fields for compatibility
        'createdBy': currentUserId,
        'lastMessageSenderId': currentUserId
      });
      
      return chatRef.id;
    } catch (e) {
      _error = "Error creating chat: ${e.toString()}";
      notifyListeners();
      return null;
    }
  }

  // Add members to a group chat
  Future<void> addGroupMembers(String chatId, List<String> newMemberIds) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      
      if (!chatDoc.exists) {
        throw Exception('Chat does not exist');
      }
      
      final data = chatDoc.data()!;
      final currentParticipants = List<String>.from(data['participantIds'] ?? []);
      final currentRefs = List<DocumentReference>.from(data['participantRefs'] ?? []);
      
      // Add new members
      for (final memberId in newMemberIds) {
        if (!currentParticipants.contains(memberId)) {
          currentParticipants.add(memberId);
          currentRefs.add(_firestore.collection('users').doc(memberId));
        }
      }
      
      await chatRef.update({
        'participantIds': currentParticipants,
        'participantRefs': currentRefs,
      });
    } catch (e) {
      _error = "Error adding group members: ${e.toString()}";
      notifyListeners();
      rethrow;
    }
  }

  // Remove a member from a group chat
  Future<void> removeGroupMember(String chatId, String memberId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      
      if (!chatDoc.exists) {
        throw Exception('Chat does not exist');
      }
      
      final data = chatDoc.data()!;
      final currentParticipants = List<String>.from(data['participantIds'] ?? []);
      final currentRefs = List<DocumentReference>.from(data['participantRefs'] ?? []);
      
      // Remove member
      currentParticipants.remove(memberId);
      currentRefs.removeWhere((ref) => ref.id == memberId);
      
      await chatRef.update({
        'participantIds': currentParticipants,
        'participantRefs': currentRefs,
      });
    } catch (e) {
      _error = "Error removing group member: ${e.toString()}";
      notifyListeners();
      rethrow;
    }
  }

  // Get chat stream
  Stream<Chat> getChatStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => Chat.fromFirestore(doc));
  }

  // Get chat by ID
  Future<Chat> getChat(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return Chat.fromFirestore(doc);
  }
} 