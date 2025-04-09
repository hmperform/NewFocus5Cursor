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
  
  // Subscriptions to clean up
  List<StreamSubscription> _subscriptions = [];
  
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
  
  bool get isCoach => _currentChatUser?.isCoach ?? false;
  bool get isAdmin => _currentChatUser?.isAdmin ?? false;
  bool get canCreateChatWithAnyone => isCoach || isAdmin;
  
  ChatProvider() {
    // Initialize by loading chats when user is authenticated
    if (_auth.currentUser != null) {
      _loadCurrentUserDetails();
      loadChats();
    }
    
    // Listen for auth state changes
    _subscriptions.add(
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          _loadCurrentUserDetails();
          loadChats();
        } else {
          // Clear data when user logs out
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
    if (_auth.currentUser == null) return;
    
    _isCurrentUserLoading = true;
    notifyListeners();
    
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        _currentChatUser = ChatUser.fromFirestore(doc);
        _users[currentUserId] = _currentChatUser!;
      }
    } catch (e) {
      _error = "Error loading current user details: ${e.toString()}";
    } finally {
      _isCurrentUserLoading = false;
      notifyListeners();
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
      for (var subscription in _subscriptions.where(
        (s) => s.hashCode.toString().contains('messages'))) {
        subscription.cancel();
        _subscriptions.remove(s);
      }
      
      // Listen for messages in this chat
      final messageStream = _firestore
          .collection('messages')
          .where('chatRef', isEqualTo: _firestore.collection('chats').doc(chatId))
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to latest 50 messages
          .snapshots();
          
      _subscriptions.add(
        messageStream.listen(
          (snapshot) {
            _messages[chatId] = snapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc))
                .toList();
            _isLoadingMessages = false;
            notifyListeners();
            
            // Mark messages as read
            markChatAsRead(chatId);
          },
          onError: (e) {
            _error = "Error loading messages: ${e.toString()}";
            _isLoadingMessages = false;
            notifyListeners();
          }
        )
      );
    } catch (e) {
      _error = "Error loading messages: ${e.toString()}";
      _isLoadingMessages = false;
      notifyListeners();
    }
  }
  
  // Send a message
  Future<void> sendMessage(String chatId, String content, {MessageType type = MessageType.text, String? mediaUrl}) async {
    if (_auth.currentUser == null) return;
    
    try {
      final timestamp = FieldValue.serverTimestamp();
      final senderRef = _firestore.collection('users').doc(currentUserId);
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // Add message to Firestore
      await _firestore.collection('messages').add({
        'chatRef': chatRef,
        'senderRef': senderRef,
        'content': content,
        'timestamp': timestamp,
        'isRead': false,
        'reactions': [],
        'type': type.toString().split('.').last,
        'mediaUrl': mediaUrl,
        // Keep the legacy fields for backward compatibility
        'chatId': chatId,
        'senderId': currentUserId
      });
      
      // Update chat's last message info
      await chatRef.update({
        'lastMessageText': content,
        'lastMessageTime': timestamp,
        'lastMessageSenderRef': senderRef,
        'readBy': [currentUserId],
        // Keep the legacy fields for backward compatibility
        'lastMessageSenderId': currentUserId
      });
    } catch (e) {
      _error = "Error sending message: ${e.toString()}";
      notifyListeners();
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
  
  // Search for users
  Future<List<ChatUser>> searchUsers(String query) async {
    if (query.length < 2) return [];
    
    try {
      // Search by name
      final nameResults = await _firestore
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();
      
      // Convert to ChatUser objects
      final users = nameResults.docs
          .map((doc) => ChatUser.fromFirestore(doc))
          .where((user) => user.userId != currentUserId) // Exclude current user
          .toList();
      
      // Apply permission filtering if needed
      if (!canCreateChatWithAnyone) {
        // Regular users can only chat with coaches
        return users.where((user) => user.isCoach).toList();
      }
      
      return users;
    } catch (e) {
      _error = "Error searching users: ${e.toString()}";
      notifyListeners();
      return [];
    }
  }
  
  // Check if user can start chat with another user
  bool canStartChatWith(ChatUser user) {
    // Admin or coach can chat with anyone
    if (isAdmin || isCoach) return true;
    
    // Regular users can only chat with coaches
    return user.isCoach;
  }
  
  // Create or get existing chat with users
  Future<String?> createChat(List<String> otherUserIds) async {
    if (_auth.currentUser == null) return null;
    
    try {
      // Create all participant IDs
      final participantIds = [...otherUserIds, currentUserId];
      final participantRefs = participantIds.map((id) => _firestore.collection('users').doc(id)).toList();
      
      // For 1:1 chats, check if a chat already exists
      if (otherUserIds.length == 1) {
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
        'isGroupChat': otherUserIds.length > 1,
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
} 