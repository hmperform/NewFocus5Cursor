# Firebase Implementation Details

This document provides expanded implementation details to supplement the main Firebase Integration Plan. It focuses on practical steps and considerations based on Firebase best practices.

## Platform-Specific Setup

### Android Configuration
1. Update `android/app/build.gradle`:
   ```gradle
   android {
       defaultConfig {
           // ...
           minSdkVersion 21 // Firebase requires minimum SDK 21
           multiDexEnabled true
       }
       // ...
   }
   ```

2. Add Google Services plugin in `android/app/build.gradle`:
   ```gradle
   dependencies {
       // ...
       implementation platform('com.google.firebase:firebase-bom:32.3.1')
       // Add the dependencies for desired Firebase products
   }
   apply plugin: 'com.google.gms.google-services'
   ```

3. Add plugin to project level `android/build.gradle`:
   ```gradle
   buildscript {
       dependencies {
           // ...
           classpath 'com.google.gms:google-services:4.3.15'
       }
   }
   ```

### iOS Configuration
1. Update `ios/Podfile` with minimum iOS version:
   ```ruby
   platform :ios, '12.0' # Firebase requires iOS 11+
   ```

2. Add Firebase pods:
   ```ruby
   # Add the Firebase pod for Google Analytics
   pod 'Firebase/Analytics'
   # Add other Firebase pods as needed
   ```

3. Update `ios/Runner/Info.plist` for any required permissions

## Comprehensive Data Model for Firebase

Based on a thorough analysis of the codebase, here are the complete entity models that need to be stored in Firebase, including all fields and relationships:

### User Collection
Document ID: User's Firebase Auth UID
Fields:
```
{
  "id": String,                   // User's Firebase Auth UID
  "email": String,                // User's email
  "username": String,             // Username for display
  "fullName": String,             // User's full name
  "profileImageUrl": String,      // URL to profile image (stored in Firebase Storage)
  "sport": String,                // User's primary sport
  "university": String,           // University name if applicable
  "universityCode": String,       // University code for exclusive content access
  "isIndividual": Boolean,        // Whether user is individual or university
  "isAdmin": Boolean,             // Whether user has admin privileges (for FireCMS)
  "focusAreas": Array<String>,    // Areas of mental training focus
  "xp": Number,                   // Experience points for gamification
  "streak": Number,               // Current daily streak
  "lastActive": Timestamp,        // When user was last active
  "completedCourses": Array<String>, // IDs of completed courses
  "completedAudios": Array<String>,  // IDs of completed audio sessions
  "completedModules": Array<String>, // IDs of completed modules
  "savedCourses": Array<String>,     // IDs of bookmarked courses
  "createdAt": Timestamp,         // When account was created
  "lastLoginAt": Timestamp,       // Last login timestamp
  "deviceTokens": Array<String>,  // FCM tokens for push notifications
  "settings": {                   // User preferences
    "notifications": {
      "dailyReminder": Boolean,
      "newContent": Boolean,
      "coaching": Boolean
    },
    "theme": String,              // "light", "dark", or "system"
    "audioQuality": String        // "high", "medium", or "low"
  },
  "completedArticles": Array<String> // IDs of completed articles
}
```

### Badges Collection
Document ID: Badge ID
Fields:
```
{
  "id": String,                // Badge ID
  "name": String,              // Badge name ("Fast Learner", "Mental Athlete", etc.)
  "description": String,       // Badge description
  "imageUrl": String,          // Badge image URL
  "xpValue": Number,           // XP awarded for earning this badge
  "criteria": String,          // Description of how to earn the badge
  "requiredActions": {         // Requirements to earn the badge
    "type": String,            // "course_completion", "streak", "login", etc.
    "count": Number,           // Required count to earn
    "specificIds": Array<String> // Specific item IDs if applicable
  }
}
```

### User Badges Collection
Document ID: Auto-generated
Fields:
```
{
  "userId": String,           // User who earned the badge
  "badgeId": String,          // Reference to badge
  "earnedAt": Timestamp       // When badge was earned
}
```

### Coaches Collection
Document ID: Coach ID
Fields:
```
{
  "id": String,                   // Coach ID
  "fullName": String,             // Coach's full name
  "bio": String,                  // Detailed biography
  "profileImageUrl": String,      // URL to profile image
  "specialty": String,            // Coach's specialty ("Discipline", "Mental Training", etc.)
  "location": String,             // Coach's location
  "experience": String,           // Experience description
  "focusAreas": Array<String>,    // Areas of focus/expertise
  "courseIds": Array<String>,     // Related courses
  "audioIds": Array<String>,      // Related audio content
  "articlesIds": Array<String>,   // IDs of authored articles
  "verified": Boolean,            // Whether coach is verified
  "universityExclusive": Boolean, // Whether exclusive to university members
  "universityAccess": Array<String>, // University codes with access
  "bookingUrl": String,           // TidyCal or Calendly booking link
  "contactEmail": String,         // Contact email
  "socialLinks": {                // Social media links
    "instagram": String,
    "twitter": String,
    "linkedin": String,
    "website": String
  },
  "podcastEpisodes": [{           // Coach's podcast episodes
    "id": String,
    "title": String,
    "duration": String,
    "imageUrl": String,
    "audioUrl": String,
    "description": String
  }],
  "modules": [{                   // Coach's modules
    "id": String,
    "title": String,
    "lessons": Number,
    "description": String
  }]
}
```

### Courses Collection
Document ID: Course ID
Fields:
```
{
  "id": String,                   // Course ID
  "title": String,                // Course title
  "description": String,          // Full description
  "thumbnailUrl": String,         // Cover image URL
  "creatorId": String,            // ID of coach/creator
  "creatorName": String,          // Name of coach/creator
  "creatorImageUrl": String,      // Creator profile image
  "tags": Array<String>,          // Categorization tags
  "focusAreas": Array<String>,    // Mental skills focus areas
  "durationMinutes": Number,      // Total course duration
  "lessonsCount": Number,         // Total number of lessons
  "xpReward": Number,             // XP earned for completion
  "createdAt": Timestamp,         // When course was created
  "updatedAt": Timestamp,         // When last updated
  "universityExclusive": Boolean, // Whether exclusive to university members
  "universityAccess": Array<String>, // University codes with access
  "difficulty": String,           // "Beginner", "Intermediate", "Advanced"
  "featured": Boolean,            // Whether course is featured
  "popularity": Number,           // Popularity score (for ranking)
  "completionCount": Number,      // How many users completed
  "avgRating": Number,            // Average rating
  "reviewCount": Number,          // Number of reviews
  "summary": String               // Short summary for listings
}
```

### Modules Collection
Document ID: Module ID
Fields:
```
{
  "id": String,                   // Module ID
  "courseId": String,             // ID of parent course
  "title": String,                // Module title
  "description": String,          // Module description
  "type": String,                 // "video", "audio", "text", "quiz"
  "videoUrl": String,             // Video URL if video type
  "audioUrl": String,             // Audio URL if audio type
  "textContent": String,          // Text content if text type
  "durationMinutes": Number,      // Duration in minutes
  "sortOrder": Number,            // Order within course
  "thumbnailUrl": String,         // Thumbnail image
  "xpReward": Number,             // XP for completing this module
  "hasQuestions": Boolean,        // Whether module has post-completion questions
  "transcriptUrl": String,        // URL to transcript if available
  "downloadableResources": [{     // Additional resources
    "name": String,
    "description": String,
    "url": String,
    "type": String                // "pdf", "audio", etc.
  }]
}
```

### DailyAudio Collection
Document ID: Audio ID
Fields:
```
{
  "id": String,                   // Audio ID
  "title": String,                // Audio title
  "description": String,          // Full description
  "audioUrl": String,             // Audio file URL
  "imageUrl": String,             // Cover image URL
  "creatorId": String,            // ID of coach/creator
  "creatorName": String,          // Name of coach/creator
  "durationMinutes": Number,      // Duration in minutes
  "focusAreas": Array<String>,    // Focus areas
  "xpReward": Number,             // XP for completion
  "datePublished": Timestamp,     // Publication date
  "universityExclusive": Boolean, // University exclusive
  "universityAccess": Array<String>, // University codes with access
  "category": String,             // "Pregame", "Postgame", etc.
  "transcriptUrl": String,        // URL to transcript
  "isFeatured": Boolean,          // Featured status
  "recommendedTime": String,      // "Morning", "Pre-game", etc.
  "hasQuestions": Boolean,        // Post-completion questions
  "likeCount": Number,            // Number of likes
  "completionCount": Number       // Times completed
}
```

### Articles Collection
Document ID: Article ID
Fields:
```
{
  "id": String,                   // Article ID
  "title": String,                // Article title
  "authorId": String,             // Author ID
  "authorName": String,           // Author name
  "authorImageUrl": String,       // Author image
  "content": String,              // Full HTML/markdown content
  "summary": String,              // Short summary
  "thumbnailUrl": String,         // Cover image URL
  "publishedDate": Timestamp,     // Publication date
  "updatedDate": Timestamp,       // Last update date
  "tags": Array<String>,          // Categories/tags
  "readTimeMinutes": Number,      // Estimated read time
  "focusAreas": Array<String>,    // Focus areas
  "universityExclusive": Boolean, // University exclusive
  "universityAccess": Array<String>, // University codes with access
  "viewCount": Number,            // Number of views
  "likeCount": Number,            // Number of likes
  "relatedArticleIds": Array<String>, // Related articles
  "relatedCourseIds": Array<String>,  // Related courses
  "featured": Boolean             // Featured status
}
```

### Questions Collection
Document ID: Question ID
Fields:
```
{
  "id": String,                   // Question ID
  "moduleId": String,             // Module this question belongs to
  "questionText": String,         // Question text
  "questionType": String,         // "multiple_choice", "text_entry", "scale"
  "options": Array<String>,       // Options for multiple choice
  "correctAnswer": String,        // Optional correct answer
  "minScale": Number,             // For scale questions
  "maxScale": Number,             // For scale questions
  "sortOrder": Number,            // Order of questions
  "required": Boolean,            // Whether answer is required
  "category": String,             // Question category
  "allowMultipleSelections": Boolean, // For multiple choice
  "placeholderText": String,      // For text inputs
  "maxLength": Number,            // For text inputs
  "scaleLabels": {                // Labels for scale endpoints
    "min": String,
    "max": String
  }
}
```

### User Responses Collection
Document ID: Auto-generated
Fields:
```
{
  "id": String,                   // Response ID
  "userId": String,               // User who answered
  "courseId": String,             // Course ID
  "moduleId": String,             // Module ID
  "timestamp": Timestamp,         // When submitted
  "responses": [{                 // Array of question responses
    "questionId": String,         // Question ID
    "answer": Any                 // Response (string, number, etc.)
  }],
  "completionTime": Number,       // Time to complete in seconds
  "deviceInfo": {                 // Device information
    "platform": String,
    "deviceModel": String
  },
  "feedbackGiven": Boolean        // Whether user gave feedback
}
```

### Chats Collection
Document ID: Chat ID
Fields:
```
{
  "id": String,                   // Chat ID
  "participantIds": Array<String>, // IDs of participants
  "lastMessageText": String,      // Preview of last message
  "lastMessageTime": Timestamp,   // When last message was sent
  "lastMessageSenderId": String,  // Who sent last message
  "readBy": Array<String>,        // Users who read the latest message
  "hasUnreadMessages": Boolean,   // Quick check for unread
  "isGroupChat": Boolean,         // Group or direct message
  "groupName": String,            // For group chats
  "groupAvatarUrl": String,       // For group chats
  "createdAt": Timestamp,         // When chat was created
  "isActive": Boolean             // Whether chat is active
}
```

### Messages Collection
Document ID: Auto-generated
Fields:
```
{
  "chatId": String,               // Parent chat ID
  "senderId": String,             // Message sender ID
  "content": String,              // Message text
  "timestamp": Timestamp,         // Send time
  "isRead": Boolean,              // Whether message is read
  "reactions": Map<String, Array<String>>, // Emoji reactions
  "attachments": [{               // Optional attachments
    "type": String,               // "image", "audio", "video", "file"
    "url": String,                // URL to attachment
    "name": String,               // Filename
    "size": Number,               // Size in bytes
    "previewUrl": String          // Thumbnail for previews
  }],
  "deletedBy": Array<String>,     // Users who deleted message
  "editedAt": Timestamp           // When message was edited
}
```

### Journal Entries Collection
Document ID: Entry ID
Fields:
```
{
  "id": String,                   // Entry ID
  "userId": String,               // User ID
  "title": String,                // Entry title
  "content": String,              // Entry content
  "tags": Array<String>,          // Tags/categories
  "createdAt": Timestamp,         // Creation time
  "updatedAt": Timestamp,         // Last edit time
  "mood": String,                 // User's mood
  "relatedModuleId": String,      // If entry is from a module
  "isPrivate": Boolean,           // Privacy setting
  "location": String,             // Optional location
  "mediaUrls": Array<String>      // Attached media
}
```

### Universities Collection
Document ID: University code
Fields:
```
{
  "code": String,                 // University code
  "name": String,                 // University name
  "domain": String,               // Email domain for verification
  "logoUrl": String,              // University logo
  "primaryColor": String,         // Brand color
  "secondaryColor": String,       // Secondary brand color
  "adminUserIds": Array<String>,  // University admin users
  "activeUntil": Timestamp,       // Subscription end date
  "maxUsers": Number,             // Maximum allowed users
  "currentUserCount": Number,     // Current user count
  "teams": [{                     // Sports teams
    "id": String,
    "name": String,
    "sport": String,
    "coachIds": Array<String>     // Team coaches
  }]
}
```

## Detailed Firestore Data Structure

### Security Rules
Create proper security rules to protect your data:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Authenticated users can read their own data
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Course access rules based on university exclusivity
    match /courses/{courseId} {
      allow read: if 
        !resource.data.universityExclusive || 
        (request.auth != null && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.universityCode in resource.data.universityAccess);
    }
    
    // Chat permissions - users can only access chats they're part of
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
    }
    
    // Message permissions
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/chats/$(resource.data.chatId)).data.participantIds;
    }
    
    // Question responses - users can create their own and admins can read all
    match /user_responses/{responseId} {
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.userId || 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true
      );
    }
  }
}
```

### Firestore Indexes
Define necessary composite indexes for your queries:

1. Chats by participants and last message time:
   - Collection: `chats`
   - Fields: `participantIds` (array), `lastMessageTime` (descending)

2. Messages by chat ID and timestamp:
   - Collection: `messages`
   - Fields: `chatId`, `timestamp` (ascending)

3. Modules by course ID and sort order:
   - Collection: `modules`
   - Fields: `courseId`, `sortOrder` (ascending)

4. Questions by module ID and sort order:
   - Collection: `questions`
   - Fields: `moduleId`, `sortOrder` (ascending)

## Optimizing Firebase Usage

### Batch Operations for Data Migration
Use batched writes when migrating existing data to Firestore:

```dart
Future<void> migrateCoursesToFirestore(List<Course> courses) async {
  final batch = _firestore.batch();
  
  for (var course in courses) {
    // Add course document
    final courseRef = _firestore.collection('courses').doc(course.id);
    batch.set(courseRef, {
      'id': course.id,
      'title': course.title,
      // ... other course fields
    });
    
    // Add each module as a separate document
    for (var module in course.modules) {
      final moduleRef = _firestore.collection('modules').doc(module.id);
      batch.set(moduleRef, {
        'id': module.id,
        'courseId': course.id,
        // ... other module fields
      });
    }
  }
  
  // Commit the batch
  await batch.commit();
}
```

### Offline Data Persistence
Enable offline persistence for better user experience:

```dart
FirebaseFirestore.instance.settings = 
    Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
```

### Optimizing Queries with StartAfter/Limit
Implement pagination for large collections:

```dart
// Initial query
final firstQuery = await _firestore
    .collection('modules')
    .where('courseId', isEqualTo: courseId)
    .orderBy('sortOrder')
    .limit(10)
    .get();
    
// Get next batch using the last document
final lastDoc = firstQuery.docs.last;
final nextQuery = await _firestore
    .collection('modules')
    .where('courseId', isEqualTo: courseId)
    .orderBy('sortOrder')
    .startAfterDocument(lastDoc)
    .limit(10)
    .get();
```

## Integration with Video/Audio Players

### Video Player Completion Detection
Enhance the current video player with Firebase functionality:

```dart
class VideoPlayerScreenWithQuestionnaire extends StatefulWidget {
  final String moduleId;
  final String courseId;
  
  @override
  _VideoPlayerScreenWithQuestionnaireState createState() => _VideoPlayerScreenWithQuestionnaireState();
}

class _VideoPlayerScreenWithQuestionnaireState extends State<VideoPlayerScreenWithQuestionnaireState> {
  final VideoPlayerController _controller = VideoPlayerController.network('...');
  bool _hasShownQuestionnaire = false;
  
  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      _controller.addListener(_checkForCompletion);
    });
  }
  
  void _checkForCompletion() {
    if (_controller.value.position >= _controller.value.duration * 0.95) {
      if (!_hasShownQuestionnaire) {
        _hasShownQuestionnaire = true;
        _showQuestionsForModule(widget.moduleId);
      }
    }
  }
  
  Future<void> _showQuestionsForModule(String moduleId) async {
    final questions = await _fetchQuestionsForModule(moduleId);
    if (questions.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => QuestionnaireSheet(
          questions: questions,
          moduleId: moduleId,
          courseId: widget.courseId,
          onComplete: _handleQuestionnaireComplete,
        ),
      );
    }
  }
}
```

### Audio Player Completion
Similar implementation for the audio player:

```dart
// In AudioPlayerScreen
_audioPlayer.positionStream.listen((position) {
  if (position.inSeconds >= _totalDuration * 0.95 && !_hasShownQuestionnaire) {
    _hasShownQuestionnaire = true;
    _showQuestionsForModule(widget.moduleId);
  }
});
```

## Firebase Analytics Integration

Add Analytics to track user behavior:

```dart
// In main.dart
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  runApp(MyApp(analytics: analytics));
}

// Tracking events
void _trackCourseStarted(String courseId, String courseName) {
  FirebaseAnalytics.instance.logEvent(
    name: 'course_started',
    parameters: {
      'course_id': courseId,
      'course_name': courseName,
    },
  );
}

void _trackQuestionAnswered(String questionId, String moduleId) {
  FirebaseAnalytics.instance.logEvent(
    name: 'question_answered',
    parameters: {
      'question_id': questionId,
      'module_id': moduleId,
    },
  );
}
```

## Questionnaire UI Components

### Multiple Choice Question
```dart
class MultipleChoiceQuestion extends StatefulWidget {
  final ModuleQuestion question;
  final Function(String questionId, dynamic answer) onChange;
  
  const MultipleChoiceQuestion({
    Key? key, 
    required this.question,
    required this.onChange,
  }) : super(key: key);
  
  @override
  _MultipleChoiceQuestionState createState() => _MultipleChoiceQuestionState();
}

class _MultipleChoiceQuestionState extends State<MultipleChoiceQuestion> {
  int? _selectedIndex;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question.questionText,
          style: Theme.of(context).textTheme.headline6,
        ),
        const SizedBox(height: 16),
        ...List.generate(widget.question.options!.length, (index) {
          return RadioListTile<int>(
            title: Text(widget.question.options![index]),
            value: index,
            groupValue: _selectedIndex,
            onChanged: (value) {
              setState(() {
                _selectedIndex = value;
              });
              widget.onChange(widget.question.id, value);
            },
          );
        }),
      ],
    );
  }
}
```

### Text Entry Question
```dart
class TextEntryQuestion extends StatefulWidget {
  final ModuleQuestion question;
  final Function(String questionId, dynamic answer) onChange;
  
  const TextEntryQuestion({
    Key? key, 
    required this.question,
    required this.onChange,
  }) : super(key: key);
  
  @override
  _TextEntryQuestionState createState() => _TextEntryQuestionState();
}

class _TextEntryQuestionState extends State<TextEntryQuestion> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      widget.onChange(widget.question.id, _controller.text);
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question.questionText,
          style: Theme.of(context).textTheme.headline6,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Enter your answer...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
```

## Deployment and Testing Considerations

### Gradual Rollout Strategy
1. **Development Environment**: Set up a separate Firebase project for development
2. **Testing Environment**: Configure testing environment with Firestore in test mode
3. **Production Environment**: Deploy to production with appropriate security rules

### A/B Testing
Implement A/B testing for questionnaire formats using Firebase Remote Config:

```dart
// Fetch remote config
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();

// Get questionnaire format from remote config
final questionnaireFormat = remoteConfig.getString('questionnaire_format');
if (questionnaireFormat == 'format_a') {
  // Show format A
} else {
  // Show format B
}
```

### Performance Monitoring
Add Firebase Performance Monitoring to track critical operations:

```dart
// Track time to load questions
final trace = FirebasePerformance.instance.newTrace('load_questions');
await trace.start();

final questions = await _fetchQuestionsForModule(moduleId);

await trace.stop();
```

## Error Handling and Recovery

Implement robust error handling for Firebase operations:

```dart
Future<void> saveUserResponse(UserResponse response) async {
  try {
    await FirebaseFirestore.instance
        .collection('user_responses')
        .doc(response.id)
        .set(response.toJson());
    
    // Update user's completed modules
    await FirebaseFirestore.instance
        .collection('users')
        .doc(response.userId)
        .update({
          'completedModules': FieldValue.arrayUnion([response.moduleId])
        });
        
  } catch (e) {
    // Log error
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    
    // Store locally for retry
    await _storeResponseForRetry(response);
    
    // Show user friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to save your response. We'll try again later.'))
    );
  }
}

// Retry mechanism
Future<void> retryFailedOperations() async {
  final pendingResponses = await _loadPendingResponses();
  for (var response in pendingResponses) {
    try {
      await FirebaseFirestore.instance
          .collection('user_responses')
          .doc(response.id)
          .set(response.toJson());
      
      await _markResponseAsSynced(response.id);
    } catch (e) {
      // Still failing, will retry later
      print('Failed to sync response: ${e.toString()}');
    }
  }
}
```

## Cloud Functions Integration

Consider using Firebase Cloud Functions for complex operations:

```javascript
// Create an aggregation of responses for a module
exports.aggregateModuleResponses = functions.firestore
  .document('user_responses/{responseId}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const moduleId = data.moduleId;
    
    // Get aggregation document
    const aggregateRef = admin.firestore()
      .collection('response_aggregations')
      .doc(moduleId);
      
    // Update the aggregation in a transaction
    return admin.firestore().runTransaction(async (transaction) => {
      const aggregateDoc = await transaction.get(aggregateRef);
      
      if (!aggregateDoc.exists) {
        // Create new aggregation
        transaction.set(aggregateRef, {
          moduleId: moduleId,
          responseCount: 1,
          // Initialize other aggregation fields
        });
      } else {
        // Update existing aggregation
        transaction.update(aggregateRef, {
          responseCount: admin.firestore.FieldValue.increment(1),
          // Update other aggregation fields
        });
      }
    });
  });
```