---
description: Verify build after code changes
---

# Build Verification Workflow

This workflow should be executed after making any code changes to ensure the project compiles successfully.

## When to Use

Run this verification after:
- Modifying Swift files
- Updating dependencies
- Making database schema changes that affect models
- Refactoring code
- Any other changes that could affect compilation

## Steps

// turbo
1. Run the build command:
```bash
xcodebuild -project marketmate.xcodeproj -scheme marketmate -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.0.1' build
```

2. Check for compilation errors:
- If build succeeds: `** BUILD SUCCEEDED **`
- If build fails: Review error messages and fix issues

3. For faster error checking only (without full build):
```bash
xcodebuild -project marketmate.xcodeproj -scheme marketmate -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.0.1' build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED)"
```

## Best Practices

- **Always verify build** before completing a task involving code changes
- Check for both errors and warnings
- Fix all compilation errors before moving on
- Document any warnings that are intentionally left unresolved
