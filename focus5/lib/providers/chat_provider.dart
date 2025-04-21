import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';  // Add this import for StreamSubscription
import '../models/chat_models.dart';
// FieldValue is in cloud_firestore

// Helper class to store cache entry with timestamp
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);

  bool isStale(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }
}

class ChatProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isSearching = false;
  String _error = '';
  List<ChatUser> _searchResults = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Chat> _chats = [];
  final Map<String, List<ChatMessage>> _messages = {};
  // Update userCache to store CacheEntry<ChatUser?>
  final Map<String, _CacheEntry<ChatUser?>> _userCache = {}; 
  final Map<String, String> _coachUserMapping = {};
  final Map<String, DateTime> _recentlySentMessages = {};
  final Map<String, StreamSubscription<QuerySnapshot>> _messageListeners = {};
  static Set<String>? _activeListenerChats;

  // Define cache duration
  static const Duration _cacheMaxAge = Duration(minutes: 5);

  // Update the isAdmin getter to check both email and Firestore data
  bool _isAdminCached = false;
  bool _isCoachCached = false;

  bool get isAdmin {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final email = currentUser.email;
      if (email != null && email.endsWith('@hmperform.com')) {
        return true;
      }
    }
    return _isAdminCached;
  }
  
  bool get isCoach => _isCoachCached;

  // Add method to check admin status in Firestore
  Future<void> _checkAdminStatus() async {
    if (_auth.currentUser == null) return;
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
          
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final emailIsAdmin = _auth.currentUser?.email?.endsWith('@hmperform.com') ?? false;
        _isAdminCached = data['isAdmin'] == true || emailIsAdmin;
        _isCoachCached = data['isCoach'] == true;
        debugPrint('ChatProvider: Updated admin status for current user: $_isAdminCached');
        debugPrint('ChatProvider: Updated coach status for current user: $_isCoachCached');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ChatProvider Error: Failed to check admin status: $e');
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get error => _error;
  List<ChatUser> get searchResults => _searchResults;
  String get currentUserId => _auth.currentUser?.uid ?? 'unknown';
  List<Chat> get chats => _chats;
  
  ChatProvider() {
    _initChats();
    _initCoachUserMapping();
    _checkAdminStatus();
  }

  // Initialize chats
  Future<void> _initChats() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_auth.currentUser != null) {
        await _initCoachUserMapping(); // Ensure mapping is done first
        _listenToChats();
      }
    } catch (e) {
      debugPrint('Error initializing chats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Listen to chats collection for this user
  void _listenToChats() {
    _firestore
        .collection('chats')
        .where('participantIds', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      _chats = snapshot.docs.map((doc) {
        final data = doc.data();
        return Chat(
          id: doc.id,
          participantIds: List<String>.from(data['participantIds'] ?? []),
          lastMessageText: data['lastMessageText'] ?? '',
          lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastMessageSenderId: data['lastMessageSenderId'] ?? '',
          hasUnreadMessages: data['readBy'] == null || 
              !(data['readBy'] as List<dynamic>).contains(currentUserId),
          isGroupChat: data['isGroupChat'] ?? false,
          groupName: data['groupName'],
          groupAvatarUrl: data['groupAvatarUrl'],
        );
      }).toList();
      
      // Pre-fetch user details for participants when chat list updates
      for (final chat in _chats) {
        for (final participantId in chat.participantIds) {
          if (participantId != currentUserId) {
            getUserDetails(participantId); // Fetch details, populating cache
          }
        }
      }

      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to chats: $e');
    });
  }

  // Get messages for a specific chat
  List<ChatMessage> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }
  
  // Load initial messages without setting up listeners
  Future<void> _loadInitialMessages(String chatId) async {
    debugPrint('ChatProvider: Loading initial messages for chat: $chatId');
    
    if (chatId.isEmpty) {
      debugPrint('ChatProvider Error: Cannot load initial messages - chat ID is empty');
      return;
    }
    
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      final messagesQuery = await _firestore
          .collection('messages')
          .where(Filter.or(
              Filter('chatId', isEqualTo: chatId),
              Filter('chatRef', isEqualTo: chatRef)
          ))
          .orderBy('timestamp', descending: false)
          .get();
      
      if (messagesQuery.docs.isNotEmpty) {
        debugPrint('ChatProvider: Found ${messagesQuery.docs.length} initial messages for chat $chatId');
        _handleMessageUpdate(chatId, messagesQuery.docs);
      }
    } catch (e, stackTrace) {
      debugPrint('ChatProvider Error: Failed to load initial messages for chat $chatId: $e');
      debugPrint('ChatProvider Error: Stack trace: $stackTrace');
    }
  }

  // Load messages for a chat and listen for updates
  Future<void> loadMessages(String chatId) async {
    debugPrint('ChatProvider: Loading messages for chat: $chatId');
    
    if (chatId.isEmpty) {
      debugPrint('ChatProvider Error: Cannot load messages - chat ID is empty');
      return;
    }
    
    // Skip if we're already loaded and listening to this chat's messages
    if (_messages.containsKey(chatId) && _messages[chatId]!.isNotEmpty && 
        _messageListeners.containsKey(chatId) && _messageListeners[chatId] != null) {
      debugPrint('ChatProvider: Already have ${_messages[chatId]!.length} messages for chat $chatId with active listener');
      return;
    }
    
    // Initialize with empty array only if we don't already have messages
    if (!_messages.containsKey(chatId)) {
      _messages[chatId] = []; // Initialize with empty array
      notifyListeners(); // Notify UI that we're loading messages
    }
    
    // Ensure we have a listener for new messages
    _ensureMessageListener(chatId);
    
    // Also fetch the existing messages right away for faster display
    await resetAndReloadMessages(chatId);
  }

  // Initialize coach-user mapping
  Future<void> _initCoachUserMapping() async {
    try {
      debugPrint('ChatProvider: Initializing coach-user mapping');
      final coachesSnapshot = await _firestore.collection('coaches').get();
      
      for (final doc in coachesSnapshot.docs) {
        final data = doc.data();
        if (data['associatedUser'] != null) {
          String userId = '';
          
          // Handle different formats of associatedUser field
          if (data['associatedUser'] is Map && data['associatedUser']['id'] != null) {
            userId = data['associatedUser']['id'];
          } else if (data['associatedUser'] is DocumentReference) {
            userId = data['associatedUser'].id;
          } else {
            // Try to extract ID from string representation
            final associatedUserStr = data['associatedUser'].toString();
            if (associatedUserStr.contains('/')) {
              userId = associatedUserStr.split('/').last.replaceAll(')', '');
            }
          }
          
          if (userId.isNotEmpty) {
            final coachId = 'coach-${doc.id}'; // Simplified coach ID format
            final coachName = data['name'] ?? 'Coach';
            debugPrint('ChatProvider: Mapping user $userId to coach $coachId ($coachName)');
            _coachUserMapping[userId] = coachId;
            
            // Pre-cache the coach in userCache to ensure quick lookups
            final coachUser = ChatUser(
              id: coachId,
              name: coachName,
              fullName: coachName,
              avatarUrl: data['imageUrl'] ?? '',
              status: UserStatus.online,
              role: 'coach',
              specialization: data['specialization'] ?? '',
            );
            _updateCache(coachId, coachUser); 
            debugPrint('ChatProvider: Pre-cached coach user: ${coachUser.name} with ID $coachId');
          }
        }
      }
      
      debugPrint('ChatProvider: Initialized ${_coachUserMapping.length} coach-user mappings');
    } catch (e) {
      debugPrint('ChatProvider Error: Failed to initialize coach-user mapping: $e');
    }
  }
  
  // Check if a user ID might be a coach's associated user
  String _checkForCoachUserId(String userId) {
    // If this ID is mapped to a coach, return the coach ID instead
    if (_coachUserMapping.containsKey(userId)) {
      final coachId = _coachUserMapping[userId]!;
      debugPrint('ChatProvider: User $userId is mapped to coach $coachId');
      return coachId;
    }
    return userId;
  }

  // Helper to update cache with timestamp
  void _updateCache(String userId, ChatUser? user) {
     _userCache[userId] = _CacheEntry(user, DateTime.now());
  }

  // Get user details with improved caching and resilience
  Future<ChatUser?> getUserDetails(String userId) async {
    if (userId.isEmpty) {
      debugPrint('ChatProvider: Cannot get user details - user ID is empty');
      return _createDefaultUser(userId, 'Unknown User'); // Return default instead of null
    }
    
    // 1. Check cache (and staleness)
    final cachedEntry = _userCache[userId];
    if (cachedEntry != null && !cachedEntry.isStale(_cacheMaxAge)) {
      debugPrint('ChatProvider: User $userId found in cache (fresh): ${cachedEntry.data?.name}');
      // Return cached data, even if it was null (meaning previously not found)
      return cachedEntry.data; 
    } else if (cachedEntry != null) {
       debugPrint('ChatProvider: User $userId found in cache (stale), fetching fresh data.');
    }

    // 2. Fetch from Firestore if not in cache or stale
    ChatUser? user;
    try {
      final effectiveUserId = _checkForCoachUserId(userId); // Get actual ID (could be coach ID)
      
      // Is it a coach ID?
      if (effectiveUserId.startsWith('coach-')) {
        debugPrint('ChatProvider: Fetching coach details for $effectiveUserId');
        final coachDocId = effectiveUserId.replaceFirst('coach-', '');
        final coachDoc = await _firestore.collection('coaches').doc(coachDocId).get();
        
        if (coachDoc.exists) {
          final coachData = coachDoc.data()!;
          user = ChatUser(
            id: effectiveUserId, // Use the 'coach-' prefixed ID
            name: coachData['name'] ?? 'Unknown Coach',
            fullName: 'Coach ${coachData['name'] ?? 'Unknown'}', // Use "Coach Name" format
            avatarUrl: coachData['imageUrl'] ?? '',
            status: UserStatus.online, 
            role: 'coach',
            specialization: coachData['specialization'] ?? '',
          );
          debugPrint('ChatProvider: Fetched coach user from Firestore: ${user.name}');
        } else {
           debugPrint('ChatProvider: Coach document $coachDocId not found in Firestore for $effectiveUserId');
           // Cache null result for coach
           user = null; 
        }
      } 
      // Is it a regular user ID?
      else {
         debugPrint('ChatProvider: Fetching regular user details for $effectiveUserId');
         final userDoc = await _firestore.collection('users').doc(effectiveUserId).get();
         if (userDoc.exists) {
           final userData = userDoc.data()!;
           user = ChatUser(
             id: effectiveUserId,
             name: userData['username'] ?? 'Unknown User',
             fullName: userData['fullName'] ?? userData['username'] ?? 'Unknown User',
             avatarUrl: userData['profileImageUrl'] ?? '',
             status: UserStatus.online, // Assuming online for now
             role: userData['isCoach'] == true ? 'coach' : 'user',
             specialization: userData['specialization'] ?? '',
           );
           debugPrint('ChatProvider: Fetched regular user from Firestore: ${user.name}');
         } else {
            debugPrint('ChatProvider: User document $effectiveUserId not found in Firestore');
            // Cache null result for user
            user = null; 
         }
      }
    } catch (e) {
      debugPrint('ChatProvider Error: Failed to get user details for $userId: $e');
      user = null; // Ensure user is null on error
    }

    // 3. Update cache (even if null, to prevent repeated lookups for non-existent users)
    _updateCache(userId, user);

    // 4. Return fetched user or a default if null
    return user ?? _createDefaultUser(userId, userId.startsWith('coach-') ? 'Unknown Coach' : 'Unknown User');
  }

  // Helper to create a default user object
  ChatUser _createDefaultUser(String id, String defaultName) {
    return ChatUser(
      id: id,
      name: defaultName,
      fullName: defaultName,
      avatarUrl: '', // Default avatar?
      status: UserStatus.offline,
      role: 'user', // Default role?
      specialization: '',
    );
  }
  
  UserStatus _getUserStatus(String? status) {
    switch (status) {
      case 'online': return UserStatus.online;
      case 'away': return UserStatus.away;
      default: return UserStatus.offline;
    }
  }
  
  // Get coach details
  Future<Map<String, dynamic>?> getCoachDetails(String coachId) async {
    try {
      final doc = await _firestore.collection('coaches').doc(coachId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown Coach',
        'avatarUrl': data['imageUrl'] ?? '',
        'specialization': data['specialization'] ?? '',
        'rating': data['rating'] ?? 0.0,
        'reviewCount': data['reviewCount'] ?? 0,
        'experience': data['experience'] ?? '',
        'bio': data['bio'] ?? '',
      };
    } catch (e) {
      debugPrint('Error getting coach details: $e');
      return null;
    }
  }

  // Send a message
  Future<void> sendMessage(String chatId, String content) async {
    if (content.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }
    
    if (currentUserId == 'unknown' || _auth.currentUser == null) {
      throw Exception('You must be logged in to send messages');
    }
    
    try {
      final timestamp = DateTime.now();
      final messageRef = _firestore.collection('messages').doc();
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // Create message data
      final message = {
        'chatId': chatId,
        'chatRef': chatRef,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
        'senderId': currentUserId,
        'senderRef': _firestore.collection('users').doc(currentUserId),
        'readBy': [currentUserId],
      };
      
      // Update chat document
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        throw Exception('Chat does not exist');
      }
      
      // Update chat with latest message info
      await chatRef.update({
        'lastMessageText': content,
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'lastMessageSenderId': currentUserId,
        'readBy': [currentUserId],
      });
      
      // Add message to Firestore
      debugPrint('ChatProvider: Adding message to Firestore with ID: ${messageRef.id}');
      await messageRef.set(message);
      debugPrint('ChatProvider: Message sent successfully with ID: ${messageRef.id}');
      
      // Add to recently sent messages to prevent duplicate
      _recentlySentMessages[messageRef.id] = DateTime.now();
      
      // Let the Firestore listener handle the state update
      // This prevents duplicate messages from appearing
      
    } catch (e, stackTrace) {
      debugPrint('ChatProvider Error: Error sending message: $e');
      debugPrint('ChatProvider Error: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Send a message with shared content
  Future<void> sendMessageWithSharedContent(
    String chatId, 
    String content, 
    SharedContent sharedContent,
  ) async {
    if (currentUserId == 'unknown' || _auth.currentUser == null) {
      throw Exception('You must be logged in to send messages');
    }
    
    try {
      final timestamp = DateTime.now();
      final messageRef = _firestore.collection('messages').doc();
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // Create message data
      final message = {
        'chatId': chatId,
        'chatRef': chatRef,
        'content': content.isEmpty ? 'Shared a ${sharedContent.contentType}' : content,
        'timestamp': Timestamp.fromDate(timestamp),
        'senderId': currentUserId,
        'senderRef': _firestore.collection('users').doc(currentUserId),
        'readBy': [currentUserId],
        'sharedContent': {
          'contentId': sharedContent.contentId,
          'contentType': sharedContent.contentType,
          'title': sharedContent.title,
          'description': sharedContent.description,
          'thumbnailUrl': sharedContent.thumbnailUrl,
          'metadata': sharedContent.metadata,
        },
      };
      
      // Update chat document
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        throw Exception('Chat does not exist');
      }
      
      // Update chat with latest message info
      await chatRef.update({
        'lastMessageText': content.isEmpty 
          ? 'Shared a ${sharedContent.contentType}: ${sharedContent.title}' 
          : content,
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'lastMessageSenderId': currentUserId,
        'readBy': [currentUserId],
      });
      
      // Add message to Firestore
      debugPrint('ChatProvider: Adding message with shared content to Firestore with ID: ${messageRef.id}');
      await messageRef.set(message);
      debugPrint('ChatProvider: Message with shared content sent successfully with ID: ${messageRef.id}');
      
      // Add to recently sent messages to prevent duplicate
      _recentlySentMessages[messageRef.id] = DateTime.now();
      
    } catch (e, stackTrace) {
      debugPrint('ChatProvider Error: Error sending message with shared content: $e');
      debugPrint('ChatProvider Error: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      
      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        final readBy = List<String>.from(data['readBy'] ?? []);
        
        if (!readBy.contains(currentUserId)) {
          readBy.add(currentUserId);
          await chatRef.update({'readBy': readBy});
        }
      }
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
    }
  }
  
  // Add reaction to message
  Future<void> addReactionToMessage(String chatId, String messageId, String reaction) async {
    try {
      final messageRef = _firestore.collection('messages').doc(messageId);
      final messageDoc = await messageRef.get();
      
      if (messageDoc.exists) {
        final data = messageDoc.data()!;
        final reactions = Map<String, List<String>>.from(
          data['reactions'] ?? <String, List<String>>{});
        
        if (reactions.containsKey(reaction)) {
          if (reactions[reaction]!.contains(currentUserId)) {
            reactions[reaction]!.remove(currentUserId);
            if (reactions[reaction]!.isEmpty) {
              reactions.remove(reaction);
            }
          } else {
            reactions[reaction]!.add(currentUserId);
          }
        } else {
          reactions[reaction] = [currentUserId];
        }
        
        await messageRef.update({'reactions': reactions});
      }
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }
  
  // Create a new chat with a user
  Future<String?> createNewChat(String otherUserId, {bool isGroup = false, String? groupName}) async {
    try {
      debugPrint('Creating new chat with user $otherUserId');
      
      if (otherUserId.isEmpty) {
        debugPrint('Error: Cannot create chat - other user ID is empty');
        throw Exception('Cannot create chat - other user ID is empty');
      }
      
      if (currentUserId == 'unknown' || _auth.currentUser == null) {
        debugPrint('Error: Cannot create chat - user not logged in');
        throw Exception('You must be logged in to create chats');
      }
      
      // Check if the other user exists in users collection
      final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
      if (!otherUserDoc.exists) {
        debugPrint('Error: User $otherUserId does not exist in users collection');
        throw Exception('Cannot create chat - the selected user does not have a valid account');
      }
      
      // Check if a chat already exists with this user
      if (!isGroup) {
        for (final chat in _chats) {
          if (!chat.isGroupChat && 
              chat.participantIds.contains(currentUserId) && 
              chat.participantIds.contains(otherUserId)) {
            debugPrint('Found existing chat with this user: ${chat.id}');
            return chat.id;
          }
        }
      }
      
      // Create a new chat
      final chatRef = _firestore.collection('chats').doc();
      final timestamp = DateTime.now();
      final participantIds = isGroup 
          ? [currentUserId, otherUserId] // For group chats, add more participants as needed
          : [currentUserId, otherUserId];
      
      debugPrint('Creating new chat with ID: ${chatRef.id}');
      await chatRef.set({
        'participantIds': participantIds,
        'createdAt': Timestamp.fromDate(timestamp),
        'createdBy': currentUserId,
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'isGroupChat': isGroup,
        'readBy': [currentUserId],
        'groupName': groupName,
      });
      
      debugPrint('Chat created successfully: ${chatRef.id}');
      return chatRef.id;
    } catch (e, stackTrace) {
      debugPrint('Error creating new chat: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // Re-throw to be handled by UI
    }
  }

  // Unified message handling
  void _handleMessageUpdate(String chatId, List<QueryDocumentSnapshot> docs) {
    debugPrint('ChatProvider: Processing ${docs.length} messages for chat $chatId');
    
    final messages = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Skip if this message was just sent locally (extend time window to 10 seconds)
      if (_recentlySentMessages.containsKey(doc.id)) {
        final sentTime = _recentlySentMessages[doc.id]!;
        if (DateTime.now().difference(sentTime) < const Duration(seconds: 10)) {
          debugPrint('ChatProvider: Skipping duplicate message: ${doc.id} (sent ${DateTime.now().difference(sentTime).inSeconds}s ago)');
          return null;
        }
        // Remove old entries
        _recentlySentMessages.remove(doc.id);
      }

      // Extract content, defaulting to empty string if missing
      final String content = data['content'] ?? '';
      
      // Extract senderId, either from direct field or reference
      String senderId = data['senderId'] ?? '';
      if (senderId.isEmpty && data['senderRef'] != null) {
        try {
          final senderRef = data['senderRef'];
          if (senderRef is DocumentReference) {
            senderId = senderRef.id;
          } else {
            final senderRefStr = senderRef.toString();
            final pathParts = senderRefStr.split('/');
            if (pathParts.length >= 2) {
              senderId = pathParts.last.replaceAll(')', '');
            }
          }
        } catch (e) {
          debugPrint('ChatProvider Error: Error extracting senderId from reference: $e');
        }
      }
      
      // Check if this is actually a coach's associated user
      senderId = _checkForCoachUserId(senderId);
      
      // Pre-cache the user details (asynchronously)
      getUserDetails(senderId).then((user) {
        if (user != null) {
          debugPrint('ChatProvider: Pre-fetched/updated user details for $senderId: ${user.name}');
        }
      });
      
      // Parse shared content if present
      SharedContent? sharedContent;
      if (data['sharedContent'] != null) {
        final sharedContentData = data['sharedContent'] as Map<String, dynamic>;
        sharedContent = SharedContent(
          contentId: sharedContentData['contentId'] ?? '',
          contentType: sharedContentData['contentType'] ?? 'unknown',
          title: sharedContentData['title'] ?? '',
          description: sharedContentData['description'] ?? '',
          thumbnailUrl: sharedContentData['thumbnailUrl'],
          metadata: sharedContentData['metadata'] ?? {},
        );
        debugPrint('ChatProvider: Parsed shared content: ${sharedContent.contentType} - ${sharedContent.title}');
      }
      
      return ChatMessage(
        id: doc.id,
        senderId: senderId,
        content: content,
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRead: (data['readBy'] as List<dynamic>?)?.contains(currentUserId) ?? false,
        reactions: data['reactions'] != null 
            ? Map<String, List<String>>.from((data['reactions'] as Map).map(
                (key, value) => MapEntry(key, List<String>.from(value))
              ))
            : null,
        sharedContent: sharedContent,
      );
    }).where((message) => message != null).cast<ChatMessage>().toList();

    // Sort messages by timestamp to ensure correct order
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    if (messages.isNotEmpty) {
      debugPrint('ChatProvider: Updating UI with ${messages.length} messages for chat $chatId');
      // Only update if messages actually changed
      final existingMessages = _messages[chatId] ?? [];
      if (!_areMessageListsEqual(existingMessages, messages)) {
        _messages[chatId] = messages;
        notifyListeners();
      } else {
        debugPrint('ChatProvider: Messages unchanged, skipping UI update');
      }
    }
  }

  // Set up message listener with unified handling
  void _listenForMessages(String chatId) {
    debugPrint('ChatProvider: Setting up message listener for chat: $chatId');
    
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // Cancel any existing listener for this chat
      _messageListeners[chatId]?.cancel();
      
      // Set up new listener
      _messageListeners[chatId] = _firestore.collection('messages')
          .where(Filter.or(
              Filter('chatId', isEqualTo: chatId),
              Filter('chatRef', isEqualTo: chatRef)
          ))
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) {
        debugPrint('ChatProvider: Message listener update: ${snapshot.docs.length} messages for chat $chatId');
        _handleMessageUpdate(chatId, snapshot.docs);
      }, onError: (e, stackTrace) {
        debugPrint('ChatProvider Error: Message listener error for chat $chatId: $e');
        debugPrint('ChatProvider Error: Stack trace: $stackTrace');
      });
    } catch (e, stackTrace) {
      debugPrint('ChatProvider Error: Failed to set up message listener for chat $chatId: $e');
      debugPrint('ChatProvider Error: Stack trace: $stackTrace');
    }
  }

  // Reset and reload messages with unified handling
  Future<void> resetAndReloadMessages(String chatId) async {
    debugPrint('ChatProvider: Reloading messages for chat: $chatId');
    
    if (chatId.isEmpty) {
      debugPrint('ChatProvider Error: Cannot reset messages - chat ID is empty');
      return;
    }
    
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      final messagesQuery = await _firestore
          .collection('messages')
          .where(Filter.or(
              Filter('chatId', isEqualTo: chatId),
              Filter('chatRef', isEqualTo: chatRef)
          ))
          .orderBy('timestamp', descending: false)
          .get();
      
      debugPrint('ChatProvider: Found ${messagesQuery.docs.length} messages for chat $chatId');
      _handleMessageUpdate(chatId, messagesQuery.docs);
      
      // Mark chat as read
      await markChatAsRead(chatId);
      
    } catch (e, stackTrace) {
      debugPrint('ChatProvider Error: Failed to reload messages for chat $chatId: $e');
      debugPrint('ChatProvider Error: Stack trace: $stackTrace');
      
      if (!_messages.containsKey(chatId)) {
        _messages[chatId] = [];
        notifyListeners();
      }
    }
  }
  
  // Ensure a message listener is active for this chat
  void _ensureMessageListener(String chatId) {
    if (_messageListeners.containsKey(chatId) && _messageListeners[chatId] != null) {
      debugPrint('ChatProvider: Chat $chatId already has an active listener, skipping setup');
      return;
    }
    
    debugPrint('ChatProvider: Setting up message listener for chat: $chatId');
    _listenForMessages(chatId);
  }

  // Clean up listeners when leaving a chat
  void cleanupChat(String chatId) {
    debugPrint('ChatProvider: Cleaning up chat $chatId');
    
    // Cancel the message listener
    _messageListeners[chatId]?.cancel();
    _messageListeners.remove(chatId);
    
    // Keep the messages in memory but mark them as not being actively listened to
    _activeListenerChats?.remove(chatId);
  }

  // Clear user cache for a specific user ID
  void clearUserCache(String userId) {
    debugPrint('ChatProvider: Clearing user cache for $userId');
    if (_userCache.containsKey(userId)) {
      _userCache.remove(userId);
    }
  }
  
  // Clear all user cache
  void clearAllUserCache() {
    debugPrint('ChatProvider: Clearing all user cache');
    _userCache.clear();
  }

  @override
  void dispose() {
    // _sessionTimeoutTimer?.cancel(); // Removed session timer logic
    for (final listener in _messageListeners.values) {
      listener.cancel();
    }
    _messageListeners.clear();
    _activeListenerChats?.clear();
    super.dispose();
  }

  // Debug coach information
  Future<void> debugCoachInfo(String coachId) async {
    debugPrint('=== DEBUG COACH INFO for $coachId ===');
    try {
      if (!coachId.startsWith('coach-')) {
        debugPrint('Not a coach ID format: $coachId');
        return;
      }
      
      final numericId = coachId.replaceFirst('coach-', '');
      debugPrint('Looking up coach with numeric ID: $numericId');
      
      // Get coach document
      final coachDoc = await _firestore.collection('coaches').doc(numericId).get();
      
      if (!coachDoc.exists) {
        debugPrint('Coach document does not exist for $coachId');
        return;
      }
      
      final data = coachDoc.data()!;
      debugPrint('Coach data: ${data.toString()}');
      
      // Check associated user
      if (data['associatedUser'] != null) {
        debugPrint('Coach has associatedUser: ${data['associatedUser']}');
        
        // Try to extract the user ID
        String? userId;
        if (data['associatedUser'] is Map && data['associatedUser']['id'] != null) {
          userId = data['associatedUser']['id'];
        } else if (data['associatedUser'] is DocumentReference) {
          userId = data['associatedUser'].id;
        }
        
        if (userId != null) {
          debugPrint('Associated user ID: $userId');
          
          // Check if user exists
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            debugPrint('User document exists: ${userDoc.data()}');
            
            // Check if user is in the cache
            if (_userCache.containsKey(userId)) {
              debugPrint('User is in cache: ${_userCache[userId]?.data?.name}, ID: ${_userCache[userId]?.data?.id}');
            } else {
              debugPrint('User is NOT in cache');
            }
            
            // Check if coach is in the cache
            if (_userCache.containsKey(coachId)) {
              debugPrint('Coach is in cache: ${_userCache[coachId]?.data?.name}, ID: ${_userCache[coachId]?.data?.id}');
            } else {
              debugPrint('Coach is NOT in cache');
            }
            
            // Check if mapping exists
            if (_coachUserMapping.containsKey(userId)) {
              debugPrint('Mapping exists: ${_coachUserMapping[userId]}');
            } else {
              debugPrint('No mapping exists for this user ID');
            }
          } else {
            debugPrint('User document does NOT exist for ID: $userId');
          }
        } else {
          debugPrint('Could not extract user ID from associatedUser');
        }
      } else {
        debugPrint('Coach has no associatedUser field');
      }
      
      // Try getting user details directly
      final cachedUser = await getUserDetails(coachId);
      debugPrint('Results from getUserDetails: ${cachedUser?.name}, ID: ${cachedUser?.id}');
      
    } catch (e, stackTrace) {
      debugPrint('Error in debugCoachInfo: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    debugPrint('=== END DEBUG COACH INFO ===');
  }

  // Update searchUsers method
  Future<void> searchUsers(String query) async {
    final lowerCaseQuery = query.trim().toLowerCase();
    debugPrint('ChatProvider: Starting user search with query: "$lowerCaseQuery"');

    _isSearching = true;
    _searchResults = [];
    notifyListeners();

    try {
      // Get all users first
      debugPrint('ChatProvider: Fetching users from Firestore...');
      final userQuery = await _firestore.collection('users').get();
      debugPrint('ChatProvider: Found ${userQuery.docs.length} users in users collection');
      
      final allUsers = userQuery.docs.map((doc) {
        final data = doc.data();
        final isAdmin = data['isAdmin'] == true;
        final isCoach = data['isCoach'] == true;
        final username = data['username'] ?? 'Unknown User';
        debugPrint('ChatProvider: Processing user ${doc.id}: $username (isAdmin: $isAdmin, isCoach: $isCoach)');
        
        return ChatUser(
          id: doc.id,
          name: username,
          fullName: data['fullName'] ?? username,
          avatarUrl: data['profileImageUrl'] ?? '',
          status: UserStatus.online,
          role: isCoach ? 'coach' : (isAdmin ? 'admin' : 'user'),
          specialization: data['specialization'] ?? '',
        );
      }).toList();

      // Get all coaches
      debugPrint('ChatProvider: Fetching coaches from Firestore...');
      final coachQuery = await _firestore.collection('coaches').get();
      debugPrint('ChatProvider: Found ${coachQuery.docs.length} coaches in coaches collection');
      
      final coaches = coachQuery.docs.map((doc) {
        final data = doc.data();
        final coachName = data['name'] ?? 'Unknown Coach';
        debugPrint('ChatProvider: Processing coach ${doc.id}: $coachName');
        
        return ChatUser(
          id: 'coach-${doc.id}',
          name: coachName,
          fullName: coachName,
          avatarUrl: data['imageUrl'] ?? '',
          status: UserStatus.online,
          role: 'coach',
          specialization: data['specialization'] ?? '',
        );
      }).toList();

      // Combine all users and coaches
      List<ChatUser> allResults = [...allUsers, ...coaches];
      debugPrint('ChatProvider: Combined ${allResults.length} total users before filtering');

      // Remove current user
      allResults = allResults.where((user) => user.id != currentUserId).toList();
      debugPrint('ChatProvider: ${allResults.length} users after removing current user');

      // Apply search filter if query exists
      if (lowerCaseQuery.isNotEmpty) {
        allResults = allResults.where((user) {
          final nameMatch = user.name.toLowerCase().contains(lowerCaseQuery);
          final fullNameMatch = user.fullName.toLowerCase().contains(lowerCaseQuery);
          return nameMatch || fullNameMatch;
        }).toList();
        debugPrint('ChatProvider: ${allResults.length} users after applying search filter');
      }

      debugPrint('ChatProvider: Setting search results with ${allResults.length} users');
      _searchResults = allResults;

    } catch (e) {
      debugPrint('ChatProvider Error: Error searching users: $e');
      _error = "Error searching users: ${e.toString()}";
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Helper method to compare message lists
  bool _areMessageListsEqual(List<ChatMessage> list1, List<ChatMessage> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id || 
          list1[i].content != list2[i].content ||
          list1[i].timestamp != list2[i].timestamp) {
        return false;
      }
    }
    return true;
  }

  // Get all users for group chat creation
  Future<List<ChatUserData>> getAllUsers() async {
    try {
      final List<ChatUserData> allUsers = [];
      
      // Get all users
      final userDocs = await _firestore.collection('users').get();
      
      // Exclude current user
      for (final doc in userDocs.docs) {
        if (doc.id == currentUserId) continue;
        
        final data = doc.data();
        final String email = (data['email'] ?? '').toString();
        final bool isAdmin = data['isAdmin'] == true || (email.isNotEmpty && email.endsWith('@hmperform.com'));
        final bool isCoach = data['isCoach'] == true;
        final String role = isAdmin ? 'admin' : (isCoach ? 'coach' : (data['role'] ?? 'user'));
        
        // Prioritize fullName over username
        final String fullName = data['fullName'] ?? '';
        final String username = data['username'] ?? '';
        final String displayName = fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : (data['name'] ?? 'Unknown User'));
        
        allUsers.add(ChatUserData(
          id: doc.id,
          name: displayName,
          userName: username,
          fullName: fullName,
          imageUrl: data['profileImage'] ?? data['profileImageUrl'] ?? '',
          role: role,
          specialization: '',
          status: data['status'] ?? 'offline',
        ));
      }
      
      // Get coaches to ensure we have them all
      final coachDocs = await _firestore.collection('coaches').get();
      
      for (final doc in coachDocs.docs) {
        final data = doc.data();
        String? userId = data['userId'] as String?;
        
        // Skip if no valid userId
        if (userId == null || userId.isEmpty) continue;
        
        // Check if we already have this user
        if (allUsers.any((user) => user.id == userId)) continue;
        
        // Add coach
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() ?? {};
          final String displayName = userData['fullName'] ?? data['name'] ?? 'Unknown Coach';
          
          allUsers.add(ChatUserData(
            id: userId,
            name: displayName,
            userName: userData['username'] ?? '',
            fullName: userData['fullName'] ?? displayName,
            imageUrl: data['imageUrl'] ?? '',
            role: 'coach',
            specialization: data['specialization'] ?? '',
            status: userData['status'] ?? 'offline',
            coachId: doc.id,
          ));
        }
      }
      
      return allUsers;
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  // Create a group chat
  Future<String?> createGroupChat({
    required List<String> participantIds,
    required String groupName,
  }) async {
    if (participantIds.isEmpty) {
      throw Exception('At least one participant must be selected');
    }
    
    if (groupName.isEmpty) {
      throw Exception('Group name is required');
    }
    
    try {
      // Add current user to participants if not already included
      final allParticipantIds = [...participantIds];
      if (!allParticipantIds.contains(currentUserId)) {
        allParticipantIds.add(currentUserId);
      }
      
      final timestamp = DateTime.now();
      
      // Create the chat document
      final chatDoc = await _firestore.collection('chats').add({
        'participantIds': allParticipantIds,
        'createdBy': currentUserId,
        'createdAt': Timestamp.fromDate(timestamp),
        'lastMessageText': 'Group chat created',
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'lastMessageSenderId': currentUserId,
        'readBy': [currentUserId],
        'isGroupChat': true,
        'groupName': groupName,
      });
      
      // Create welcome message
      await _firestore.collection('messages').add({
        'chatId': chatDoc.id,
        'senderId': currentUserId,
        'content': 'Welcome to the group chat!',
        'timestamp': Timestamp.fromDate(timestamp),
        'readBy': [currentUserId],
      });
      
      // Fetch the new chat
      await _initChats();
      
      return chatDoc.id;
    } catch (e) {
      debugPrint('Error creating group chat: $e');
      return null;
    }
  }
} 