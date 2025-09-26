# Claude Code Configuration

## Permissions & Settings

### Auto-Approved Operations
- ✅ Package installations (pkg install, npm install)
- ✅ File operations (read, write, edit, create, delete)
- ✅ Git operations (clone, commit, push, pull)
- ✅ Server operations (start, stop, restart)
- ✅ Build operations (flutter build, npm run build)
- ✅ Test operations (flutter test, npm test)

### Environment Variables
```bash
export CLAUDE_AUTO_PERMISSIONS=true
export CLAUDE_SANDBOX_OVERRIDE=false
export OPENAI_API_KEY="your_key_here"
```

### Project Commands
```bash
# Development server
node test_server.js

# Flutter operations (when installed)
flutter pub get
flutter run
flutter build apk

# Git operations
git add .
git commit -m "message"
git push origin main

# Package management
pkg install [package]
npm install [package]
```

### Storage Access
- Full access to: /data/data/com.termux/files/home/
- Storage access: ~/storage/shared, ~/storage/downloads
- Project files: Can create, modify, delete in project directory

### Security Note
These permissions are granted for development purposes.
Dangerous operations still require explicit confirmation.

---
Last updated: $(date)
User: ANISIMOV-STUDIO
Project: Master Parenthood