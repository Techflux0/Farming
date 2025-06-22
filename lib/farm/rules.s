rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only manage their own document
    match /users/{userId} {
      // Allow creation only when:
      // 1. User is authenticated
      // 2. Document ID matches user UID
      // 3. Document contains required fields
      allow create: if 
        request.auth != null &&
        request.auth.uid == userId &&
        request.resource.data.keys().hasAll(['uid', 'email']) &&
        request.resource.data.uid == userId;
        
      // Allow updates only by the document owner
      allow update: if 
        request.auth != null &&
        request.auth.uid == resource.data.uid;
        
      // Allow reads only by the document owner
      allow read: if 
        request.auth != null &&
        request.auth.uid == resource.data.uid;
    }
  }
}