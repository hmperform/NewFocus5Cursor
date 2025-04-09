import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_models.dart';

class ChatProvider with ChangeNotifier {
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Chat> _chats = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, ChatUser> _userCache = {};

  // Cache to map user IDs to coach IDs
  final Map<String, String> _coachUserMapping = {};

  // Getters
  bool get isLoading => _isLoading;
  String get currentUserId => _auth.currentUser?.uid ?? 'unknown';
  List<Chat> get chats => _chats;
  
  ChatProvider() {
    _initChats();
    _initCoachUserMapping();
  }

  // Initialize chats
  Future<void> _initChats() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_auth.currentUser != null) {
        // Wait for coach mapping to be initialized
        await _initCoachUserMapping();
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
      
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to chats: $e');
    });
  }

  // Get messages for a specific chat
  List<ChatMessage> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }
  
  // Load messages for a chat and listen for updates
  Future<void> loadMessages(String chatId) async {
    debugPrint('ChatProvider: Loading messages for chat: $chatId');
    
    if (chatId.isEmpty) {
      debugPrint('ChatProvider Error: Cannot load messages - chat ID is empty');
      return;
    }
    
    // Skip if we're already loaded and listening to this chat's messages
    if (_messages.containsKey(chatId) && _messages[chatId]!.isNotEmpty) {
      debugPrint('ChatProvider: Already have ${_messages[chatId]!.length} messages for chat $chatId, ensuring listener');
      // Just make sure we have a listener set up
      _ensureMessageListener(chatId);
      return;
    }
    
    // Check if chat exists in Firestore but not in local state
    if (!_chats.any((chat) => chat.id == chatId)) {
      debugPrint('ChatProvider: Chat not found in local state, checking Firestore');
      try {
        final chatDoc = await _firestore.collection('chats').doc(chatId).get();
        if (chatDoc.exists) {
          debugPrint('ChatProvider: Found chat in Firestore, adding to local state');
          final data = chatDoc.data()!;
          final chat = Chat(
            id: chatDoc.id,
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
          
          _chats = [..._chats, chat];
          notifyListeners();
        } else {
          debugPrint('ChatProvider Error: Chat $chatId not found in Firestore');
          throw Exception('Chat not found');
        }
      } catch (e) {
        debugPrint('ChatProvider Error: Error checking chat in Firestore: $e');
        rethrow;
      }
    }
    
    // Initialize with empty array only if we don't already have messages
    if (!_messages.containsKey(chatId) || _messages[chatId]!.isEmpty) {
      _messages[chatId] = []; // Initialize with empty array
      notifyListeners(); // Notify UI that we're loading messages
    }
    
    // Ensure we have a listener for new messages
    _ensureMessageListener(chatId);
    
    // Also fetch the existing messages right away for faster display
    await resetAndReloadMessages(chatId);
    
    // Mark chat as read
    markChatAsRead(chatId);
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
          }
          
          if (userId.isNotEmpty) {
            final coachId = 'coach-${doc.id}';
            final coachName = data['name'] ?? 'Coach';
            debugPrint('ChatProvider: Mapping user $userId to coach $coachId ($coachName)');
            _coachUserMapping[userId] = coachId;
            
            // Pre-cache the coach in userCache to ensure quick lookups
            _userCache[coachId] = ChatUser(
              id: coachId,
              name: coachName,
              avatarUrl: data['imageUrl'] ?? '',
              status: UserStatus.online,
              role: 'coach',
              specialization: data['specialization'] ?? '',
            );
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

  // Get user details
  Future<ChatUser?> getUserDetails(String userId) async {
    debugPrint('ChatProvider: Getting user details for $userId');
    
    // Check if this userId is actually a coach's associated user
    final effectiveUserId = _checkForCoachUserId(userId);
    if (effectiveUserId != userId) {
      debugPrint('ChatProvider: Using coach ID $effectiveUserId instead of user ID $userId');
      userId = effectiveUserId;
    }
    
    // Return from cache if available
    if (_userCache.containsKey(userId)) {
      debugPrint('ChatProvider: Found user $userId in cache: ${_userCache[userId]?.name}');
      return _userCache[userId];
    }
    
    try {
      // First, check if this is a coach ID
      if (userId.startsWith('coach-')) {
        debugPrint('ChatProvider: Checking coaches collection for $userId');
        // Extract the coach numeric ID
        final coachNumericId = userId.replaceFirst('coach-', '');
        
        // Get the coach document
        final coachDoc = await _firestore.collection('coaches').doc(coachNumericId).get();
        
        if (coachDoc.exists) {
          debugPrint('ChatProvider: Found coach document for $userId');
          final data = coachDoc.data()!;
          debugPrint('ChatProvider: Coach data: ${data.toString()}');
          
          // If the coach has an associated user, use that instead
          if (data['associatedUser'] != null) {
            final associatedUser = data['associatedUser'];
            String associatedUserId;
            
            if (associatedUser is Map && associatedUser.containsKey('id')) {
              // Map format {"id": "userId", "path": "users"}
              associatedUserId = associatedUser['id'];
              debugPrint('ChatProvider: Coach has associated user ID: $associatedUserId');
              
              // Recursively get the associated user details
              // But first store a temporary entry to prevent infinite recursion
              _userCache[userId] = ChatUser(
                id: userId,
                name: data['name'] ?? 'Coach',
                avatarUrl: data['imageUrl'] ?? '',
                status: UserStatus.online,
                role: 'coach',
                specialization: data['specialization'] ?? '',
              );
              
              // Get the actual user
              final actualUser = await getUserDetails(associatedUserId);
              if (actualUser != null) {
                debugPrint('ChatProvider: Found associated user for coach');
                // Create a merged user with coach info but linked to real user
                final mergedUser = ChatUser(
                  id: userId, // Keep the coach ID for references
                  name: data['name'] ?? actualUser.name, // Prefer coach name
                  avatarUrl: data['imageUrl'] ?? actualUser.avatarUrl,
                  status: actualUser.status, // Use real user status
                  role: 'coach',
                  specialization: data['specialization'] ?? '',
                );
                _userCache[userId] = mergedUser;
                return mergedUser;
              }
            } else if (associatedUser is DocumentReference) {
              // Handle DocumentReference format
              associatedUserId = associatedUser.id;
              debugPrint('ChatProvider: Coach has associated user reference: $associatedUserId');
              
              // Similar logic as above
              _userCache[userId] = ChatUser(
                id: userId,
                name: data['name'] ?? 'Coach',
                avatarUrl: data['imageUrl'] ?? '',
                status: UserStatus.online,
                role: 'coach',
                specialization: data['specialization'] ?? '',
              );
              
              final actualUser = await getUserDetails(associatedUserId);
              if (actualUser != null) {
                final mergedUser = ChatUser(
                  id: userId,
                  name: data['name'] ?? actualUser.name,
                  avatarUrl: data['imageUrl'] ?? actualUser.avatarUrl,
                  status: actualUser.status,
                  role: 'coach',
                  specialization: data['specialization'] ?? '',
                );
                _userCache[userId] = mergedUser;
                return mergedUser;
              }
            }
          }
          
          // If no associated user or couldn't find it, return the coach directly
          final coachUser = ChatUser(
            id: userId,
            name: data['name'] ?? 'Unnamed Coach',
            avatarUrl: data['imageUrl'] ?? '',
            status: UserStatus.online, // Assume coaches are online
            role: 'coach',
            specialization: data['specialization'] ?? '',
          );
          
          debugPrint('ChatProvider: Caching coach information for $userId with name: ${coachUser.name}');
          _userCache[userId] = coachUser;
          return coachUser;
        } else {
          debugPrint('ChatProvider: Coach document not found for $userId');
        }
      }
      
      // Regular user lookup
      debugPrint('ChatProvider: Checking users collection for $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      
      // If not found in either collection
      if (!doc.exists) {
        debugPrint('ChatProvider: No document found for $userId in users collection');
        _userCache[userId] = ChatUser(
          id: userId,
          name: 'Unknown User',
          avatarUrl: '',
          status: UserStatus.offline,
          role: 'unknown',
          specialization: '',
        );
        return _userCache[userId];
      }
      
      // Process the found document
      final data = doc.data()!;
      debugPrint('ChatProvider: User document data: ${data.toString()}');
      
      final name = data['name'] ?? data['displayName'] ?? 'Unknown User';
      debugPrint('ChatProvider: Extracted name: $name for user $userId');
      
      final user = ChatUser(
        id: doc.id,
        name: name,
        avatarUrl: data['profileImage'] ?? data['photoURL'] ?? '',
        status: _getUserStatus(data['status']),
        role: data['role'] ?? 'user',
        specialization: data['specialization'] ?? '',
      );
      
      debugPrint('ChatProvider: Caching user information for $userId with name: ${user.name}');
      _userCache[userId] = user;
      return user;
    } catch (e, stackTrace) {
      debugPrint('ChatProvider Error: Error getting user details for $userId: $e');
      debugPrint('ChatProvider Error: Stack trace: $stackTrace');
      
      // Return a fallback user object
      final fallbackUser = ChatUser(
        id: userId,
        name: 'User ($userId)',
        avatarUrl: '',
        status: UserStatus.offline,
        role: 'unknown',
        specialization: '',
      );
      
      _userCache[userId] = fallbackUser;
      return fallbackUser;
    }
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
    try {
      debugPrint('ChatProvider: Sending message to chat $chatId: $content');
      
      if (chatId.isEmpty) {
        debugPrint('ChatProvider Error: Cannot send message - chat ID is empty');
        throw Exception('Cannot send message - chat ID is empty');
      }
      
      if (currentUserId == 'unknown' || _auth.currentUser == null) {
        debugPrint('ChatProvider Error: Cannot send message - user not logged in');
        throw Exception('You must be logged in to send messages');
      }
      
      // Check if the chat exists in local state
      final localChat = _chats.firstWhere(
        (chat) => chat.id == chatId,
        orElse: () => Chat(
          id: '',
          participantIds: [],
          lastMessageText: '',
          lastMessageTime: DateTime.now(),
          lastMessageSenderId: '',
          hasUnreadMessages: false,
          isGroupChat: false,
        ),
      );
      
      if (localChat.id.isEmpty) {
        debugPrint('ChatProvider Warning: Chat $chatId not found in local state, will check Firestore');
      } else {
        debugPrint('ChatProvider: Found chat in local state with participants: ${localChat.participantIds}');
      }
      
      final messageRef = _firestore.collection('messages').doc();
      final timestamp = DateTime.now();
      
      // Create message object with correct field names to match Firestore expectations
      final message = {
        'id': messageRef.id,
        'chatId': chatId,
        'senderId': currentUserId,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
        'readBy': [currentUserId],
        'type': 'text',
        // Add reference fields that match what Firestore is expecting
        'chatRef': _firestore.collection('chats').doc(chatId),
        'senderRef': _firestore.collection('users').doc(currentUserId),
      };
      
      debugPrint('ChatProvider: Checking if chat exists in Firestore: $chatId');
      // Create or update the chat
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      
      if (chatDoc.exists) {
        final data = chatDoc.data();
        debugPrint('ChatProvider: Updating existing chat with participants: ${data?['participantIds']}');
        // Update existing chat
        await chatRef.update({
          'lastMessageText': content,
          'lastMessageTime': Timestamp.fromDate(timestamp),
          'lastMessageSenderId': currentUserId,
          'readBy': [currentUserId],
        });
      } else {
        debugPrint('ChatProvider Error: Chat document $chatId does not exist in Firestore!');
        debugPrint('ChatProvider: Attempting to recreate chat document from local state');
        // Check if we have participantIds from local state
        final participantIds = _chats
            .where((chat) => chat.id == chatId)
            .map((chat) => chat.participantIds)
            .firstOrNull ?? [currentUserId];
        
        if (participantIds.length <= 1) {
          debugPrint('ChatProvider Error: Cannot create chat with only one participant');
          throw Exception('Failed to create chat - missing participants');
        }
        
        debugPrint('ChatProvider: Adding participants: $participantIds');
        
        // Validate all participants exist in users collection
        for (final participantId in participantIds) {
          if (participantId != currentUserId) {
            final userDoc = await _firestore.collection('users').doc(participantId).get();
            if (!userDoc.exists) {
              debugPrint('ChatProvider Error: Participant $participantId does not exist in users collection');
              throw Exception('Cannot create chat - one or more participants do not have valid user accounts');
            }
          }
        }
        
        // Create new chat
        await chatRef.set({
          'participantIds': participantIds,
          'createdAt': Timestamp.fromDate(timestamp),
          'createdBy': currentUserId,
          'lastMessageText': content,
          'lastMessageTime': Timestamp.fromDate(timestamp),
          'lastMessageSenderId': currentUserId,
          'isGroupChat': participantIds.length > 2,
          'readBy': [currentUserId],
        });
      }
      
      debugPrint('ChatProvider: Adding message to Firestore with ID: ${messageRef.id}');
      // Add message
      await messageRef.set(message);
      debugPrint('ChatProvider: Message sent successfully with ID: ${messageRef.id}');
      
      // Make sure the message shows up in the UI immediately without waiting for listener
      if (_messages.containsKey(chatId)) {
        final currentMessages = _messages[chatId] ?? [];
        final newMessage = ChatMessage(
          id: messageRef.id,
          senderId: currentUserId,
          content: content,
          timestamp: timestamp,
          isRead: true,
          reactions: null,
        );
        
        debugPrint('ChatProvider: Adding message to local state immediately');
        _messages[chatId] = [...currentMessages, newMessage];
        notifyListeners();
      } else {
        debugPrint('ChatProvider: Chat $chatId not in _messages map, will wait for listener');
      }
    } catch (e, stackTrace) {
      debugPrint('ChatProvider Error: Error sending message: $e');
      debugPrint('ChatProvider Error: Stack trace: $stackTrace');
      rethrow; // Re-throw the exception to be caught by the UI
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

  // Reset and reload messages for a chat
  Future<void> resetAndReloadMessages(String chatId) async {
    debugPrint('ChatProvider: Reloading messages for chat: $chatId');
    
    if (chatId.isEmpty) {
      debugPrint('ChatProvider Error: Cannot reset messages - chat ID is empty');
      return;
    }
    
    try {
      // Don't clear existing messages yet - keep them displayed while loading new ones
      // This prevents the screen from looking empty during reloads
      final existingMessages = _messages[chatId] ?? [];
      if (existingMessages.isNotEmpty) {
        debugPrint('ChatProvider: Preserving ${existingMessages.length} existing messages while reloading');
      }
      
      // Create a reference to the chat document for use in the query
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // Load messages from Firestore directly (one-time)
      debugPrint('ChatProvider: Querying Firestore for messages in chat: $chatId');
      final messagesQuery = await _firestore
          .collection('messages')
          .where(Filter.or(
              Filter('chatId', isEqualTo: chatId),
              Filter('chatRef', isEqualTo: chatRef)
          ))
          .orderBy('timestamp', descending: false)
          .get();
      
      debugPrint('ChatProvider: Found ${messagesQuery.docs.length} messages for chat $chatId');
      
      if (messagesQuery.docs.isNotEmpty) {
        final newMessages = messagesQuery.docs.map((doc) {
          final data = doc.data();
          debugPrint('ChatProvider: Message ${doc.id}: ${data['content']} from ${data['senderId']}');
          
          // Extract content, defaulting to empty string if missing
          final String content = data['content'] ?? '';
          
          // Extract senderId, either from direct field or reference
          String senderId = data['senderId'] ?? '';
          if (senderId.isEmpty && data['senderRef'] != null) {
            // Try to extract ID from document reference path
            try {
              final senderRef = data['senderRef'];
              
              // Handle both DocumentReference and serialized path string
              if (senderRef is DocumentReference) {
                senderId = senderRef.id;
                debugPrint('ChatProvider: Extracted senderId from DocumentReference: $senderId');
              } else {
                final senderRefStr = senderRef.toString();
                // Expected format: DocumentReference(users/userId)
                final pathParts = senderRefStr.split('/');
                if (pathParts.length >= 2) {
                  senderId = pathParts.last.replaceAll(')', '');
                  debugPrint('ChatProvider: Extracted senderId from reference string: $senderId');
                }
              }
            } catch (e) {
              debugPrint('ChatProvider Error: Error extracting senderId from reference: $e');
            }
          }
          
          // Check if this is actually a coach's associated user
          senderId = _checkForCoachUserId(senderId);
          
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
          );
        }).toList();
        
        // Only update messages if we got new ones, otherwise keep existing
        if (newMessages.isNotEmpty) {
          debugPrint('ChatProvider: Setting ${newMessages.length} messages in local state for chat $chatId');
          _messages[chatId] = newMessages;
          notifyListeners();
        } else if (existingMessages.isEmpty) {
          // If we had no existing messages and found none, initialize with empty array
          _messages[chatId] = [];
          notifyListeners();
        }
      } else if (existingMessages.isEmpty) {
        // Only set empty array if we had no existing messages
        _messages[chatId] = [];
        notifyListeners();
      }
      
      // Mark chat as read
      await markChatAsRead(chatId);
      
      // Start listening for future updates (even if we have existing messages)
      _ensureMessageListener(chatId);
      
    } catch (e, stackTrace) {
      debugPrint('ChatProvider Error: Failed to reload messages for chat $chatId: $e');
      debugPrint('ChatProvider Error: Stack trace: $stackTrace');
      
      // In case of error, make sure we have at least an empty array initialized
      if (!_messages.containsKey(chatId)) {
        _messages[chatId] = [];
        notifyListeners();
      }
    }
  }
  
  // Ensure a message listener is active for this chat
  void _ensureMessageListener(String chatId) {
    // We'll use a static set to track which chats have active listeners
    // to avoid setting up duplicate listeners
    _activeListenerChats ??= <String>{};
    
    if (_activeListenerChats!.contains(chatId)) {
      debugPrint('ChatProvider: Chat $chatId already has an active listener, skipping setup');
      return;
    }
    
    debugPrint('ChatProvider: Setting up message listener for chat: $chatId');
    _activeListenerChats!.add(chatId);
    
    _listenForMessages(chatId);
  }
  
  // Static set to track which chats have active listeners
  static Set<String>? _activeListenerChats;

  // Set up message listener without all the checks and initialization
  void _listenForMessages(String chatId) {
    debugPrint('ChatProvider: Setting up dedicated message listener for chat: $chatId');
    
    try {
      // Create a reference to the chat document for use in the query
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // Query messages by either chatId field or chatRef field, same as in resetAndReloadMessages
      _firestore.collection('messages')
          .where(Filter.or(
              Filter('chatId', isEqualTo: chatId),
              Filter('chatRef', isEqualTo: chatRef)
          ))
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) {
        debugPrint('ChatProvider: Message listener update: ${snapshot.docs.length} messages for chat $chatId');
        
        // Log the message content for debugging
        for (var doc in snapshot.docs) {
          final data = doc.data();
          String contentDebug = data['content'] ?? 'NO CONTENT';
          String senderDebug = data['senderId'] ?? 'NO SENDER';
          if (data['senderRef'] != null) senderDebug += " (has senderRef)";
          debugPrint('ChatProvider: Message listener found: ${doc.id}: $contentDebug from $senderDebug');
        }
        
        if (snapshot.docs.isEmpty) {
          debugPrint('ChatProvider: WARNING - No messages found for chat $chatId by listener');
        }
        
        final messages = snapshot.docs.map((doc) {
          final data = doc.data();
          
          // Extract content, defaulting to empty string if missing
          final String content = data['content'] ?? '';
          
          // Extract senderId, either from direct field or reference
          String senderId = data['senderId'] ?? '';
          if (senderId.isEmpty && data['senderRef'] != null) {
            // Try to extract ID from document reference path
            try {
              final senderRef = data['senderRef'];
              
              // Handle both DocumentReference and serialized path string
              if (senderRef is DocumentReference) {
                senderId = senderRef.id;
                debugPrint('ChatProvider: Extracted senderId from DocumentReference: $senderId');
              } else {
                final senderRefStr = senderRef.toString();
                // Expected format: DocumentReference(users/userId)
                final pathParts = senderRefStr.split('/');
                if (pathParts.length >= 2) {
                  senderId = pathParts.last.replaceAll(')', '');
                  debugPrint('ChatProvider: Extracted senderId from reference string: $senderId');
                }
              }
            } catch (e) {
              debugPrint('ChatProvider Error: Error extracting senderId from reference: $e');
            }
          }
          
          // Check if this is actually a coach's associated user
          senderId = _checkForCoachUserId(senderId);
          
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
          );
        }).toList();
        
        debugPrint('ChatProvider: Listener updating UI with ${messages.length} messages for chat $chatId');
        _messages[chatId] = messages;
        notifyListeners();
      }, onError: (e, stackTrace) {
        debugPrint('ChatProvider Error: Message listener error for chat $chatId: $e');
        debugPrint('ChatProvider Error: Stack trace: $stackTrace');
      });
    } catch (e, stackTrace) {
      debugPrint('ChatProvider Error: Failed to set up message listener for chat $chatId: $e');
      debugPrint('ChatProvider Error: Stack trace: $stackTrace');
    }
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
              debugPrint('User is in cache: ${_userCache[userId]?.name}, ID: ${_userCache[userId]?.id}');
            } else {
              debugPrint('User is NOT in cache');
            }
            
            // Check if coach is in the cache
            if (_userCache.containsKey(coachId)) {
              debugPrint('Coach is in cache: ${_userCache[coachId]?.name}, ID: ${_userCache[coachId]?.id}');
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
} 