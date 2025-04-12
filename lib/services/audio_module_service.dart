  print('🎵 AUDIO MODULE: Found $count modules ordered by Firestore "orderIndex" field.');
  
  // Log modules with their Firestore-provided order
  for (var i = 0; i < count; i++) {
    final doc = availableModules[i];
    final data = doc.data();
    final title = data['title'] as String;
    final orderIndex = data['orderIndex'] ?? 'N/A'; // Log the order index
    print('🎵 AUDIO MODULE: Firestore Index $i = Module ${doc.id} ($title), OrderIndex: $orderIndex'); 
  }
  
  // Calculate index using modulo on the Firestore-ordered list
  final moduleIndex = totalLoginDays > 0 ? (totalLoginDays - 1) % count : 0;
  print('🎵 AUDIO MODULE: Calculated moduleIndex = ($totalLoginDays > 0 ? ($totalLoginDays - 1) % $count : 0) = $moduleIndex');
  
  // Validate index before access
  if (moduleIndex < 0 || moduleIndex >= count) {
    print('🎵 AUDIO MODULE ERROR: Calculated invalid module index: $moduleIndex for $count modules.');
    return null; 
  }
  
  // --- Explicitly log the element being accessed --- 
  final selectedDocId = availableModules[moduleIndex].id;
  final selectedOrderIndex = availableModules[moduleIndex].data()['orderIndex'] ?? 'N/A';
  print('🎵 AUDIO MODULE: Accessing Firestore-ordered list at index $moduleIndex -> Document ID: $selectedDocId, OrderIndex: $selectedOrderIndex');
  
  // Get the actual document
  final doc = availableModules[moduleIndex];
  final selectedModule = doc.data();
  final selectedTitle = selectedModule['title'] as String;
  
  print('🎵 AUDIO MODULE: Final Selected module ${doc.id} ($selectedTitle) '
        'for login day $totalLoginDays (using index: $moduleIndex on "orderIndex" sorted list)'); 