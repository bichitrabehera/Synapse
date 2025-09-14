# TODO: Transform Flutter Project to Google Sign-In without Firebase

## Current Status
- [x] Update pubspec.yaml: Remove firebase_core and firebase_auth dependencies
- [ ] Update main.dart: Remove Firebase initialization
- [ ] Update AuthProvider: Replace Firebase Auth with direct Google Sign-In
- [ ] Test Google Sign-In flow
- [ ] Verify backend accepts Google ID tokens

# TODO: Fix 307 Temporary Redirect on POST /api/user/social-links

## Current Status
- [x] Update tapcard-backend/main.py: Add redirect_slashes=False and change social_links prefix to "/api/user"
- [x] Update tapcard-backend/routers/social_links.py: Change routes to "/social-links" and "/social-links/{link_id}"
- [x] Update Synapse/lib/screens/edit_profile_screen.dart: Change POST to '/user/social-links'
- [x] Update Synapse/lib/screens/profile_screen.dart: Change GET to '/user/social-links'
- [ ] Test API endpoints
