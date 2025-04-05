# Firebase Integration Plan for Focus5

## Overview
This document outlines the planned integration of Firebase into the Focus5 app, including:
1. Converting all existing data models to Firestore
2. Implementing user authentication with Firebase Auth
3. Adding post-completion questionnaires for modules
4. Setting up real-time messaging with Firestore
5. Using FireCMS for content management

## Firebase Setup

### Initial Configuration
- Uncomment the Firebase dependencies in pubspec.yaml:
  ```yaml
  firebase_core: ^2.15.0
  firebase_auth: ^4.7.2
  cloud_firestore: ^4.8.4
  firebase_storage: ^11.0.0 # For storing images and audio/video files
  ```
- Run `flutterfire configure` to generate Firebase configuration files
- Initialize Firebase in main.dart:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  }
  ```

## Data Migration Plan

### 1. User Authentication & Profiles

#### Migrate from AuthProvider to Firebase Auth
Replace the current authentication flow with Firebase Auth:

```dart
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  User? _currentUser;

  // Login with email/password
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserData(userCredential.user!.uid);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required bool isIndividual,
    String? university,
    String? universityCode,
    String? sport,
    required List<String> focusAreas,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user profile in Firestore
      final userData = {
        'id': userCredential.user!.uid,
        'email': email,
        'username': username,
        'fullName': fullName,
        'profileImageUrl': null,
        'sport': sport,
        'university': university,
        'universityCode': universityCode,
        'isIndividual': isIndividual,
        'focusAreas': focusAreas,
        'xp': 0,
        'badges': [],
        'completedCourses': [],
        'completedAudios': [],
        'savedCourses': [],
        'streak': 0,
        'lastActive': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
      await _loadUserData(userCredential.user!.uid);
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Registration failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
}
```

#### Firestore Collection: users
- Document ID: User's Firebase Auth UID
- Fields:
  - All fields from current User model
  - Added tracking fields (createdAt, lastLogin)

### 2. Course Content Migration

#### Firestore Collections Structure
- **courses**: Course information (metadata, no modules)
- **modules**: All modules with foreign key to course
- **daily_audio**: Daily audio content
- **articles**: Article content
- **coaches**: Coach profiles

#### Collection: courses
```dart
await _firestore.collection('courses').doc(course.id).set({
  'id': course.id,
  'title': course.title,
  'description': course.description,
  'thumbnailUrl': course.thumbnailUrl,
  'creatorId': course.creatorId,
  'creatorName': course.creatorName,
  'creatorImageUrl': course.creatorImageUrl,
  'tags': course.tags,
  'focusAreas': course.focusAreas,
  'durationMinutes': course.durationMinutes,
  'xpReward': course.xpReward,
  'createdAt': course.createdAt.toIso8601String(),
  'universityExclusive': course.universityExclusive,
  'universityAccess': course.universityAccess,
});
```

#### Collection: modules
```dart
// Store each module separately with courseId reference
await _firestore.collection('modules').doc(module.id).set({
  'id': module.id,
  'courseId': courseId, // Reference to parent course
  'title': module.title,
  'description': module.description,
  'type': module.type.toString().split('.').last,
  'videoUrl': module.videoUrl,
  'audioUrl': module.audioUrl,
  'textContent': module.textContent,
  'durationMinutes': module.durationMinutes,
  'sortOrder': module.sortOrder,
});
```

#### Updating ContentProvider
```dart
class ContentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Course> _courses = [];
  List<DailyAudio> _audioModules = [];
  List<Article> _articles = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _universityCode;

  // Load courses from Firestore
  Future<void> loadCourses() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Query courses
      QuerySnapshot coursesSnapshot = await _firestore.collection('courses').get();
      
      // Convert to Course objects
      List<Course> courses = [];
      for (var doc in coursesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Get modules for this course
        QuerySnapshot modulesSnapshot = await _firestore
            .collection('modules')
            .where('courseId', isEqualTo: doc.id)
            .orderBy('sortOrder')
            .get();
            
        List<Module> modules = modulesSnapshot.docs.map((moduleDoc) {
          Map<String, dynamic> moduleData = moduleDoc.data() as Map<String, dynamic>;
          return Module.fromJson(moduleData);
        }).toList();
        
        // Create course with modules
        courses.add(Course(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          thumbnailUrl: data['thumbnailUrl'],
          creatorId: data['creatorId'],
          creatorName: data['creatorName'],
          creatorImageUrl: data['creatorImageUrl'],
          tags: List<String>.from(data['tags']),
          focusAreas: List<String>.from(data['focusAreas']),
          durationMinutes: data['durationMinutes'],
          xpReward: data['xpReward'],
          modules: modules,
          createdAt: DateTime.parse(data['createdAt']),
          universityExclusive: data['universityExclusive'],
          universityAccess: data['universityAccess'] != null 
              ? List<String>.from(data['universityAccess']) 
              : null,
        ));
      }
      
      _courses = courses;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading courses: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Similar methods for loading audio modules and articles
}
```

### 3. Chat/Messaging System

#### Firestore Collections for Messaging
- **chats**: Chat metadata (participants, last message info)
- **messages**: Individual messages, linked to chats

#### Collection: chats
```dart
await _firestore.collection('chats').doc(chatId).set({
  'id': chatId,
  'participantIds': [userId1, userId2], // Array of participant UIDs
  'lastMessageText': 'Hello!',
  'lastMessageTime': FieldValue.serverTimestamp(),
  'lastMessageSenderId': userId1,
  'isGroupChat': false,
  'groupName': null,
  'groupAvatarUrl': null,
  'createdAt': FieldValue.serverTimestamp(),
});
```

#### Collection: messages
```dart
await _firestore.collection('messages').add({
  'chatId': chatId, // Reference to parent chat
  'senderId': senderId,
  'content': messageText,
  'timestamp': FieldValue.serverTimestamp(),
  'isRead': false,
  'reactions': {}, // Map of reaction emoji -> list of user IDs
});
```

#### ChatProvider Implementation
```dart
class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Chat> _chats = [];
  Map<String, List<ChatMessage>> _messages = {};
  List<ChatUser> _users = [];
  bool _isLoading = false;
  
  // Get current user ID
  String get currentUserId => _auth.currentUser!.uid;
  
  // Load chats for current user
  Future<void> loadChats() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Listen for chats where current user is a participant
      _firestore
          .collection('chats')
          .where('participantIds', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .listen((snapshot) {
        _chats = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          return Chat(
            id: doc.id,
            participantIds: List<String>.from(data['participantIds']),
            lastMessageText: data['lastMessageText'] ?? '',
            lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
            lastMessageSenderId: data['lastMessageSenderId'] ?? '',
            hasUnreadMessages: data['lastMessageSenderId'] != currentUserId &&
                (data['readBy'] == null || !(data['readBy'] as List).contains(currentUserId)),
            isGroupChat: data['isGroupChat'] ?? false,
            groupName: data['groupName'],
            groupAvatarUrl: data['groupAvatarUrl'],
          );
        }).toList();
        
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      print('Error loading chats: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get messages for a specific chat
  void getMessagesForChat(String chatId) {
    _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      _messages[chatId] = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'],
          content: data['content'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isRead: data['isRead'] ?? false,
          reactions: data['reactions'] != null
              ? Map<String, List<String>>.from(data['reactions'])
              : null,
        );
      }).toList();
      
      notifyListeners();
    });
  }
  
  // Send a message
  Future<void> sendMessage(String chatId, String content) async {
    try {
      // Add message to Firestore
      await _firestore.collection('messages').add({
        'chatId': chatId,
        'senderId': currentUserId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'reactions': {},
      });
      
      // Update chat's last message info
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageText': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }
  
  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'readBy': FieldValue.arrayUnion([currentUserId]),
      });
      
      // Mark all messages as read
      QuerySnapshot unreadMessages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      
      WriteBatch batch = _firestore.batch();
      unreadMessages.docs.forEach((doc) {
        batch.update(doc.reference, {'isRead': true});
      });
      
      await batch.commit();
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }
}
```

### 4. Post-Completion Questionnaires

#### Question Types
Create a flexible model to handle different question types:

```dart
// Question model to be stored in Firestore
class ModuleQuestion {
  final String id;
  final String moduleId;    // Which module this question belongs to
  final String questionText;
  final String questionType; // "multiple_choice", "text_entry", "scale", etc.
  final List<String>? options; // For multiple choice questions
  final String? correctAnswer; // Optional, for questions with right/wrong answers
  final int? minScale; // For scale questions
  final int? maxScale; // For scale questions
  final int sortOrder; // Order of questions

  ModuleQuestion({
    required this.id,
    required this.moduleId,
    required this.questionText,
    required this.questionType,
    this.options,
    this.correctAnswer,
    this.minScale,
    this.maxScale,
    required this.sortOrder,
  });

  factory ModuleQuestion.fromJson(Map<String, dynamic> json) {
    return ModuleQuestion(
      id: json['id'],
      moduleId: json['moduleId'],
      questionText: json['questionText'],
      questionType: json['questionType'],
      options: json['options'] != null 
          ? List<String>.from(json['options']) 
          : null,
      correctAnswer: json['correctAnswer'],
      minScale: json['minScale'],
      maxScale: json['maxScale'],
      sortOrder: json['sortOrder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moduleId': moduleId,
      'questionText': questionText,
      'questionType': questionType,
      'options': options,
      'correctAnswer': correctAnswer,
      'minScale': minScale,
      'maxScale': maxScale,
      'sortOrder': sortOrder,
    };
  }
}
```

#### User Response Model

```dart
class UserResponse {
  final String id;
  final String userId;
  final String courseId;
  final String moduleId;
  final DateTime timestamp;
  final List<QuestionResponse> responses;

  UserResponse({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.moduleId,
    required this.timestamp,
    required this.responses,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      userId: json['userId'],
      courseId: json['courseId'],
      moduleId: json['moduleId'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      responses: (json['responses'] as List)
          .map((r) => QuestionResponse.fromJson(r))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'moduleId': moduleId,
      'timestamp': timestamp,
      'responses': responses.map((r) => r.toJson()).toList(),
    };
  }
}

class QuestionResponse {
  final String questionId;
  final dynamic answer; // String for text, int for selection index, etc.

  QuestionResponse({
    required this.questionId,
    required this.answer,
  });

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      questionId: json['questionId'],
      answer: json['answer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answer': answer,
    };
  }
}
```

#### Firestore Collections
- **questions**: Stores all questions organized by moduleId
- **user_responses**: Stores all user responses to questions

#### Post-Completion Questionnaire Flow

1. **Detect Content Completion**:
   - Add listeners to video/audio players to detect when content finishes playing
   - For VideoPlayerScreen:
   ```dart
   player.positionStream.listen((position) {
     if (position >= player.duration && !_hasShownQuestions) {
       _hasShownQuestions = true;
       _showQuestionsForModule(widget.moduleId);
     }
   });
   ```

2. **Fetch Questions**:
   - Query Firestore for questions associated with the completed module
   ```dart
   Future<List<ModuleQuestion>> _fetchQuestionsForModule(String moduleId) async {
     final querySnapshot = await FirebaseFirestore.instance
         .collection('questions')
         .where('moduleId', isEqualTo: moduleId)
         .orderBy('sortOrder')
         .get();
     
     return querySnapshot.docs
         .map((doc) => ModuleQuestion.fromJson(doc.data()))
         .toList();
   }
   ```

3. **Display Dynamic Question UI**:
   - Create UI components for each question type (multiple choice, text entry, etc.)
   - Show appropriate UI based on question type
   ```dart
   Widget _buildQuestionWidget(ModuleQuestion question) {
     switch (question.questionType) {
       case 'multiple_choice':
         return MultipleChoiceQuestion(question: question, onChange: _handleAnswer);
       case 'text_entry':
         return TextEntryQuestion(question: question, onChange: _handleAnswer);
       case 'scale':
         return ScaleQuestion(question: question, onChange: _handleAnswer);
       default:
         return TextEntryQuestion(question: question, onChange: _handleAnswer);
     }
   }
   ```

4. **Save Responses**:
   - Collect user responses
   - Save to Firestore when user completes the questionnaire
   ```dart
   Future<void> _saveResponses() async {
     final userResponse = UserResponse(
       id: const Uuid().v4(),
       userId: FirebaseAuth.instance.currentUser!.uid,
       courseId: widget.courseId,
       moduleId: widget.moduleId,
       timestamp: DateTime.now(),
       responses: _collectedResponses,
     );
     
     await FirebaseFirestore.instance
         .collection('user_responses')
         .doc(userResponse.id)
         .set(userResponse.toJson());
   }
   ```

## FireCMS Integration

### Setting Up FireCMS
1. Create a FireCMS instance connected to your Firebase project
2. Define collection schemas for all data types
3. Configure access controls and permissions

### Collection Schemas for FireCMS

#### Users Collection
```javascript
{
  name: "users",
  singularName: "user",
  path: "users",
  properties: {
    id: { dataType: "string", isRequired: true },
    email: { dataType: "string", isRequired: true },
    fullName: { dataType: "string", isRequired: true },
    profileImageUrl: { dataType: "string" },
    sport: { dataType: "string" },
    university: { dataType: "string" },
    universityCode: { dataType: "string" },
    isIndividual: { dataType: "boolean", isRequired: true },
    focusAreas: { dataType: "array", of: { dataType: "string" } },
    xp: { dataType: "number" },
    streak: { dataType: "number" },
    lastActive: { dataType: "timestamp" },
  }
}
```

#### Courses Collection
```javascript
{
  name: "courses",
  singularName: "course",
  path: "courses",
  properties: {
    title: { dataType: "string", isRequired: true },
    description: { dataType: "string", isRequired: true },
    thumbnailUrl: { dataType: "string", isRequired: true },
    creatorId: { dataType: "string", isRequired: true },
    creatorName: { dataType: "string", isRequired: true },
    creatorImageUrl: { dataType: "string", isRequired: true },
    tags: { dataType: "array", of: { dataType: "string" } },
    focusAreas: { dataType: "array", of: { dataType: "string" } },
    durationMinutes: { dataType: "number", isRequired: true },
    xpReward: { dataType: "number", isRequired: true },
    createdAt: { dataType: "timestamp", isRequired: true },
    universityExclusive: { dataType: "boolean", isRequired: true },
    universityAccess: { dataType: "array", of: { dataType: "string" } },
  }
}
```

#### Modules Collection
```javascript
{
  name: "modules",
  singularName: "module",
  path: "modules",
  properties: {
    courseId: { dataType: "string", isRequired: true },
    title: { dataType: "string", isRequired: true },
    description: { dataType: "string", isRequired: true },
    type: { 
      dataType: "string", 
      isRequired: true,
      enumValues: {
        video: "Video",
        audio: "Audio",
        text: "Text",
        quiz: "Quiz"
      }
    },
    videoUrl: { dataType: "string" },
    audioUrl: { dataType: "string" },
    textContent: { dataType: "string" },
    durationMinutes: { dataType: "number", isRequired: true },
    sortOrder: { dataType: "number", isRequired: true },
  }
}
```

#### Questions Collection
```javascript
{
  name: "questions",
  singularName: "question",
  path: "questions",
  properties: {
    moduleId: { dataType: "string", isRequired: true },
    questionText: { dataType: "string", isRequired: true },
    questionType: { 
      dataType: "string", 
      isRequired: true,
      enumValues: {
        multiple_choice: "Multiple Choice",
        text_entry: "Text Entry",
        scale: "Scale"
      }
    },
    options: { dataType: "array", of: { dataType: "string" } },
    correctAnswer: { dataType: "string" },
    minScale: { dataType: "number" },
    maxScale: { dataType: "number" },
    sortOrder: { dataType: "number", isRequired: true },
  }
}
```

## Implementation Steps

1. **Firebase Project Setup**
   - Create Firebase project
   - Configure authentication options
   - Set up Firestore database

2. **Integrate Firebase SDK**
   - Add dependencies to pubspec.yaml
   - Initialize Firebase in main.dart
   - Configure platform-specific files

3. **Migrate Data Models**
   - Convert user authentication to Firebase Auth
   - Set up Firestore data structure
   - Implement data providers using Firestore queries

4. **Implement Real-time Features**
   - Chat/messaging system
   - Content updates

5. **Add Post-Completion Questionnaires**
   - Create question models and UI components
   - Implement completion detection
   - Build response collection and storage

6. **FireCMS Setup**
   - Configure collection schemas
   - Set up admin access
   - Create custom views for content management

7. **Testing**
   - Test authentication flows
   - Verify real-time updates
   - Test questionnaire functionality
   - Check admin tools

## Future Enhancements

- **Analytics**: Implement Firebase Analytics for user behavior tracking
- **Push Notifications**: Add Firebase Cloud Messaging for alerts
- **A/B Testing**: Use Firebase Remote Config for testing different features
- **Performance Monitoring**: Add Firebase Performance for tracking app metrics
- **Advanced Queries**: Create custom queries for personalized content recommendations
- **Data Export**: Add functionality to export user responses for analysis 