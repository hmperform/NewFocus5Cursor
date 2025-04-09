import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participantIds;
  final List<DocumentReference> participantRefs;
  final String lastMessageText;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final DocumentReference? lastMessageSenderRef;
  final bool hasUnreadMessages;
  final bool isGroupChat;
  final String? groupName;
  final String? groupAvatarUrl;
  final DocumentReference? createdByRef;

  Chat({
    required this.id,
    required this.participantIds,
    this.participantRefs = const [],
    required this.lastMessageText,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.lastMessageSenderRef,
    required this.hasUnreadMessages,
    this.isGroupChat = false,
    this.groupName,
    this.groupAvatarUrl,
    this.createdByRef,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert references to List<DocumentReference>
    List<DocumentReference> refs = [];
    if (data['participantRefs'] != null) {
      refs = List<DocumentReference>.from(data['participantRefs'] ?? []);
    }
    
    return Chat(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantRefs: refs,
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageTime: (data['lastMessageTime'] is Timestamp) 
          ? (data['lastMessageTime'] as Timestamp).toDate() 
          : DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      lastMessageSenderRef: data['lastMessageSenderRef'],
      hasUnreadMessages: data['lastMessageSenderId'] != null && 
          data['readBy'] != null &&
          !(data['readBy'] as List).contains(data['lastMessageSenderId']),
      isGroupChat: data['isGroupChat'] ?? false,
      groupName: data['groupName'],
      groupAvatarUrl: data['groupAvatarUrl'],
      createdByRef: data['createdByRef'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'participantRefs': participantRefs,
      'lastMessageText': lastMessageText,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderRef': lastMessageSenderRef,
      'isGroupChat': isGroupChat,
      'groupName': groupName,
      'groupAvatarUrl': groupAvatarUrl,
      'createdByRef': createdByRef,
    };
  }
}

class ChatUser {
  final String userId;
  final String name;
  final String? profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isCoach;
  final bool isAdmin;
  final Map<String, dynamic>? coachRef;

  ChatUser({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    this.isOnline = false,
    this.lastSeen,
    this.isCoach = false,
    this.isAdmin = false,
    this.coachRef,
  });

  factory ChatUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatUser(
      userId: doc.id,
      name: data['fullName'] ?? data['username'] ?? 'User',
      profileImageUrl: data['profileImageUrl'],
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null 
          ? (data['lastSeen'] as Timestamp).toDate() 
          : null,
      isCoach: data['isCoach'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      coachRef: data['coachRef'] as Map<String, dynamic>?,
    );
  }
  
  String get coachId => coachRef?['id'] as String? ?? '';
  bool get hasCoachProfile => isCoach && coachRef != null;
} 