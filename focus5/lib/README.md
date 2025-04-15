# Focus5 App - Badge System Documentation

## Overview

The Focus5 app includes a badge system to gamify the user experience and encourage engagement. Badges are awarded to users for completing various achievements such as completing courses, maintaining streaks, and reaching milestone XP levels.

## Badge Model

Badges are represented by the `AppBadge` class in `lib/models/user_model.dart`. Each badge includes:

- `id`: Unique identifier
- `name`: Name of the badge
- `description`: Explanation of how the badge is earned
- `imageUrl`: URL to the badge image in Firebase Storage
- `earnedAt`: DateTime when the badge was earned (null if not yet earned)
- `xpValue`: XP points awarded when the badge is earned

## Badge UI Components

### Badge Detail Screen
`lib/screens/badges/badge_detail_screen.dart`

This screen displays a full detailed view of a badge, including:
- Badge image with Hero animation
- Badge name and description
- XP value
- Date earned
- Progress indicator (for level-based badges)

To navigate to this screen:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BadgeDetailScreen(badge: badgeInstance),
  ),
);
```

### All Badges Screen
`lib/screens/home/all_badges_screen.dart`

Grid view of all badges earned by the user with:
- Badge images with Hero animation
- Badge names
- Earned dates
- XP values

### Profile Tab Badge Display
`lib/screens/home/profile_tab.dart`

Horizontal scrollable list showing the most recent badges earned by the user.

## Badge Service

The `BadgeService` class in `lib/services/badge_service.dart` handles:
- Loading badge definitions from Firestore
- Checking if a user has earned new badges
- Awarding badges to users
- Updating user records in Firestore

## Usage Example

```dart
// Navigate to badge detail from a badge item
void onBadgeTap(AppBadge badge) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BadgeDetailScreen(badge: badge),
    ),
  );
}

// Display a badge with Hero animation
Widget buildBadgeItem(AppBadge badge) {
  return GestureDetector(
    onTap: () => onBadgeTap(badge),
    child: Hero(
      tag: 'badge_${badge.id}',
      child: CachedNetworkImage(
        imageUrl: badge.imageUrl ?? '',
        // ...
      ),
    ),
  );
}
```

## Badge Styling

Badges use a consistent visual style:
- Circular images with drop shadows
- Hero animations for smooth transitions
- Consistent color theme based on app's light/dark mode 