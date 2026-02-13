# WEBSOCKET CONNECTION FAILURE - DIAGNOSIS & FIX INSTRUCTIONS

## 🔴 PROBLEM SUMMARY

**Symptom:** WebSocket connection to Railway-deployed backend is failing with the following error pattern:

```
Initial attempt: wss://turbocar-backend-production.up.railway.app/api/chat/ws?token=...
Actual failure:  https://turbocar-backend-production.up.railway.app:0/api/chat/ws?token=...
Error: "Connection was not upgraded to websocket"
```

**Key Issues Identified:**
1. Protocol changes from `wss://` to `https://` (WebSocket requires wss/ws protocol)
2. Invalid port `:0` being appended to URL
3. Server receives HTTP request instead of WebSocket upgrade request

---

## ⚠️ CRITICAL INSTRUCTIONS FOR ANTIGRAVITY

**YOU MUST:**
1. ✅ Analyze existing WebSocket connection code in Flutter app
2. ✅ Identify where and how WebSocket URL is constructed
3. ✅ Find the root cause of protocol and port corruption
4. ✅ Test backend WebSocket endpoint independently
5. ✅ Verify Railway deployment configuration
6. ✅ Follow existing code patterns and conventions

**YOU MUST NOT:**
1. ❌ Hardcode URLs, file names, or function names
2. ❌ Make assumptions about code structure without reading it
3. ❌ Copy-paste solutions without understanding the problem
4. ❌ Skip the diagnostic phase
5. ❌ Change working parts of the codebase

---

## 📋 PHASE 1: DIAGNOSTIC INVESTIGATION

### Step 1.1: Locate WebSocket Connection Code

**Action:** Find all code related to WebSocket connection in the Flutter app.

**Search patterns to use:**
- Search for WebSocket package imports (e.g., `web_socket_channel`, `socket_io_client`)
- Search for `wss://` or `ws://` in the codebase
- Search for "WebSocket" or "socket" in file names
- Search for the specific URL domain in the codebase
- Find where chat connection is initiated

**Document findings:**
- Which file(s) contain WebSocket connection logic?
- Which package is being used for WebSocket?
- Where is the connection established (service, provider, repository)?
- Is there a WebSocket manager or service class?

**Create:** `WEBSOCKET_DIAGNOSTIC_REPORT.md` and document all findings.

---

### Step 1.2: Trace WebSocket URL Construction

**Action:** Understand exactly how the WebSocket URL is being built.

**Investigation steps:**

1. **Find the URL construction logic:**
   - Look for where WebSocket URL is created
   - Check if it's built from environment variables
   - Check if it's derived from HTTP base URL
   - Check if it's hardcoded or from configuration

2. **Trace the URL through the code:**
   - Where is the base URL defined?
   - How is the WebSocket protocol determined?
   - How is the path appended?
   - How are query parameters (token) added?
   - Are there any URL transformations or manipulations?

3. **Check for Uri class usage:**
   - Is `Uri.parse()` being used?
   - Is `Uri.replace()` being used?
   - Is there any scheme or port manipulation?
   - How is the final URL converted to string?

**Look for patterns like these:**

```dart
// Pattern A: Direct string concatenation
final wsUrl = baseUrl + '/path/to/ws';

// Pattern B: Uri manipulation
final wsUrl = Uri.parse(baseUrl).replace(scheme: 'wss', path: '/path');

// Pattern C: String replacement
final wsUrl = baseUrl.replaceAll('https', 'wss') + '/path';

// Pattern D: Multiple transformations
final uri = Uri.parse(httpUrl);
final wsUri = uri.replace(scheme: 'wss');
final finalUrl = wsUri.toString();
```

**Document in report:**
- Exact sequence of URL construction steps
- Any Uri parsing or manipulation
- Where protocol changes happen
- Where port might be getting set or changed

---

### Step 1.3: Add Diagnostic Logging

**Action:** Insert comprehensive logging to capture exact URL values at each step.

**What to log:**

1. **Before any URL construction:**
   - Log the base URL or source URL
   - Log any environment variables used
   - Log configuration values

2. **During URL construction (at each step):**
   - Log after each transformation
   - Log the URL at each manipulation point
   - Log individual URL components (scheme, host, port, path)

3. **Before WebSocket connection attempt:**
   - Log the final URL being used for connection
   - Parse the URL and log each component separately:
     - Scheme (should be 'wss')
     - Host (should be your Railway domain)
     - Port (should be empty or default, NOT :0)
     - Path (should be your WebSocket endpoint path)
     - Query parameters

**Logging pattern:**

```
Add at each significant point:
- Print/log descriptive message
- Print/log the variable value
- If it's a URL, parse and print components
- Print a separator for readability
```

**Why this is important:**
This logging will immediately reveal:
- Where the protocol changes from 'wss' to 'https'
- Where the ':0' port gets added
- Which transformation causes the corruption

---

### Step 1.4: Reproduce and Capture Logs

**Action:** Run the app with diagnostic logging and capture output.

**Steps:**
1. Rebuild the Flutter app with logging added
2. Launch the app and navigate to chat
3. Trigger WebSocket connection
4. Capture all log output
5. Analyze the logs to find the exact point of corruption

**What to look for in logs:**
- First appearance of incorrect protocol ('https' instead of 'wss')
- First appearance of ':0' port
- Any error messages before the connection failure
- Any warnings about URL parsing

**Document in report:**
- Full log output from URL construction to connection attempt
- Exact line/step where corruption occurs
- Any patterns or causes identified

---

### Step 1.5: Identify Root Cause Category

**Based on diagnostic findings, categorize the root cause:**

**Category A: Flutter Uri Manipulation Issue**
- URL starts correct but gets corrupted during Uri operations
- Likely causes:
  - `Uri.parse()` + `Uri.replace()` combination issue
  - Port being explicitly set to 0 somewhere
  - Scheme being changed incorrectly
- Solution path: Fix Uri manipulation logic

**Category B: Base URL Configuration Issue**
- WebSocket URL derived from HTTP base URL incorrectly
- Likely causes:
  - Base URL is HTTP/HTTPS, trying to convert to WebSocket
  - Port from HTTP URL (443) being carried over incorrectly
  - URL string manipulation errors
- Solution path: Separate WebSocket URL configuration from HTTP

**Category C: WebSocket Library Issue**
- Correct URL provided but library corrupts it
- Likely causes:
  - Wrong connection method being called
  - Library bug or version issue
  - Proxy or interceptor interfering
- Solution path: Fix library usage or update library

**Category D: Environment/Configuration Issue**
- URL loaded from wrong environment or config
- Likely causes:
  - Dev URL being used instead of production
  - Missing environment variable
  - Configuration not updated for Railway deployment
- Solution path: Fix environment configuration

**Document:** Add root cause category to diagnostic report with evidence.

---

## 📋 PHASE 2: BACKEND VERIFICATION

### Step 2.1: Verify Backend WebSocket Endpoint

**Action:** Confirm the backend WebSocket endpoint is working correctly.

**Independent testing methods:**

1. **Using wscat (command-line tool):**
   - Install wscat if available in development environment
   - Test direct connection to WebSocket endpoint
   - Use actual JWT token from app
   - Observe connection success/failure

2. **Using online WebSocket testing tool:**
   - Use browser-based WebSocket testers
   - Enter full WebSocket URL with token
   - Attempt connection
   - Check for successful handshake

3. **Using Postman (if available):**
   - Create new WebSocket request
   - Enter full URL with authentication
   - Connect and observe response

**What to verify:**
- Does backend accept WebSocket connections at all?
- Is the path correct?
- Is authentication working (token in query param)?
- Does WebSocket upgrade succeed?
- Are there any CORS or security errors?

**Document findings:**
- Can you connect from external tools? (Yes/No)
- Any error messages from server?
- Authentication success/failure?
- If connection fails externally, problem is in backend
- If connection succeeds externally, problem is in Flutter app

---

### Step 2.2: Check Railway WebSocket Configuration

**Action:** Verify Railway deployment supports WebSocket properly.

**Railway WebSocket requirements:**

1. **Port Binding:**
   - Backend must bind to `0.0.0.0` (not localhost)
   - Backend must use PORT environment variable from Railway
   - WebSocket should use same port as HTTP server

2. **HTTP Server Configuration:**
   - Server must support WebSocket upgrade
   - Upgrade headers must be handled correctly
   - No middleware blocking WebSocket upgrade

3. **Railway Service Configuration:**
   - No special WebSocket config needed typically
   - But verify service is using correct start command
   - Check if health checks interfere with WebSocket

**Check in backend code:**
- Is server binding to `0.0.0.0:$PORT`?
- Is WebSocket handler registered before other routes?
- Are WebSocket upgrade headers checked?
- Is CORS configured to allow WebSocket origin?

**Document findings:**
- Backend port binding configuration
- WebSocket handler registration details
- Any configuration issues found

---

### Step 2.3: Test Backend Locally vs Railway

**Action:** Compare WebSocket behavior in local dev vs Railway deployment.

**Local testing:**
1. Run backend locally
2. Update Flutter app to use localhost WebSocket URL
3. Test WebSocket connection
4. Does it work locally?

**Railway testing:**
1. Use Railway deployment URL
2. Test WebSocket connection
3. Does it fail only on Railway?

**Comparison findings:**

**If works locally but not on Railway:**
- Problem is Railway-specific
- Check Railway logs for errors
- Check Railway network configuration
- Check Railway environment variables

**If fails both locally and Railway:**
- Problem is in backend WebSocket implementation
- Or problem is in Flutter WebSocket connection code
- Not Railway-specific

---

## 📋 PHASE 3: FIX IMPLEMENTATION STRATEGY

### Strategy A: Fix Flutter URL Construction (Most Likely)

**When to use:** If diagnostic shows URL corruption happens during Flutter URL building.

**Analysis required:**
1. Find the exact line/function where URL gets corrupted
2. Understand the intended URL building logic
3. Identify why Uri operations are causing issues

**Fix approaches based on findings:**

**Approach A1: Replace Uri manipulation with direct string building**

**When:** If using `Uri.parse().replace()` causes issues

**Pattern to look for:**
```
Current (problematic):
- Parse HTTP URL
- Replace scheme to 'wss'
- Results in port :0 or protocol issues
```

**Fix pattern:**
```
New approach:
- Define WebSocket URL separately
- Don't derive from HTTP URL
- Build as complete string or proper Uri
```

**Implementation steps:**
1. Locate URL construction code
2. Remove Uri.parse/replace chain if present
3. Build URL directly from components:
   - Scheme: 'wss'
   - Host: (Railway domain)
   - Path: (WebSocket endpoint path)
   - Query: (token parameter)
4. Test that URL is correct at this point

---

**Approach A2: Fix Uri.replace() usage**

**When:** If Uri manipulation is necessary but implemented incorrectly

**Common mistakes to look for:**
```
❌ Wrong:
Uri.parse(httpUrl).replace(scheme: 'wss')
// This might preserve HTTP port or cause issues

❌ Wrong:
Uri(scheme: 'wss', host: httpUri.host, port: httpUri.port, path: '/ws')
// Explicitly setting port from HTTP URL

❌ Wrong:
Uri.https(host, path).replace(scheme: 'wss')
// Uri.https sets port 443, which conflicts with wss
```

**Fix pattern:**
```
✅ Correct approach:
Build Uri for WebSocket directly without deriving from HTTP:
- Don't copy port from HTTP Uri
- Don't parse HTTP URL first
- Build WebSocket Uri fresh
```

**Implementation steps:**
1. Identify incorrect Uri operations
2. Replace with correct Uri construction
3. Ensure port is NOT explicitly set (let it be default)
4. Ensure scheme is 'wss' from the start

---

**Approach A3: Separate WebSocket configuration**

**When:** If WebSocket URL should be independent of HTTP API base URL

**Pattern:**
```
Current (problematic):
- Single base URL configuration (HTTPS)
- Try to derive WebSocket URL from it

Better approach:
- Separate configuration for HTTP and WebSocket
- HTTP base URL: https://...
- WebSocket base URL: wss://...
- No derivation needed
```

**Implementation steps:**
1. Add separate WebSocket URL configuration
2. Store in environment variables or config file
3. Use directly for WebSocket connections
4. Don't perform any protocol transformation
5. Update deployment/environment configuration

---

### Strategy B: Fix Backend WebSocket Handler

**When to use:** If external testing shows backend doesn't accept WebSocket connections.

**Investigation required:**
1. Locate WebSocket upgrade handler in backend
2. Check WebSocket library usage (e.g., Gorilla WebSocket in Go)
3. Verify upgrade headers are checked
4. Check CORS and authentication

**Common backend issues:**

**Issue B1: WebSocket handler not properly registered**
- Handler exists but not accessible
- Route not registered or path incorrect
- Middleware blocking WebSocket upgrade

**Fix approach:**
- Verify route registration
- Check route order (WebSocket before other handlers)
- Ensure middleware allows WebSocket upgrade

**Issue B2: WebSocket upgrade not performed**
- Handler receives request but doesn't upgrade
- Missing upgrade header check
- Missing upgrade response

**Fix approach:**
- Ensure proper WebSocket upgrade implementation
- Check that upgrade headers are sent in response
- Verify WebSocket connection is established

**Issue B3: Authentication blocking connection**
- Token validation fails
- Token not extracted from query parameter
- CORS blocking WebSocket origin

**Fix approach:**
- Verify token extraction from query parameter
- Check token validation logic
- Configure CORS for WebSocket connections

---

### Strategy C: Fix Railway Deployment Configuration

**When to use:** If WebSocket works locally but fails on Railway.

**Investigation required:**
1. Check Railway service logs for errors
2. Verify environment variables are set correctly
3. Check Railway networking configuration

**Common Railway issues:**

**Issue C1: Port binding incorrect**
- Backend binding to localhost instead of 0.0.0.0
- Backend not using PORT environment variable

**Fix approach:**
- Update backend to bind to 0.0.0.0
- Use PORT from environment variable
- Redeploy to Railway

**Issue C2: Start command incorrect**
- Backend not starting properly
- WebSocket server not initialized

**Fix approach:**
- Verify Railway start command
- Check Railway logs for startup errors
- Update start command if needed

**Issue C3: Environment variables missing**
- Configuration values not set in Railway
- Using wrong environment

**Fix approach:**
- Add missing environment variables in Railway dashboard
- Verify all required config is present
- Redeploy after configuration changes

---

## 📋 PHASE 4: IMPLEMENTATION STEPS

### Step 4.1: Create Fix Plan Document

**Action:** Based on diagnostic findings and chosen strategy, create detailed fix plan.

**Create:** `WEBSOCKET_FIX_PLAN.md` with following sections:

```markdown
# WebSocket Connection Fix Plan

## Root Cause Identified
[Specific root cause from diagnostic phase]

## Root Cause Category
- [ ] Flutter Uri Manipulation Issue
- [ ] Base URL Configuration Issue
- [ ] WebSocket Library Issue
- [ ] Backend WebSocket Handler Issue
- [ ] Railway Deployment Configuration Issue

[Mark the applicable category and explain]

## Affected Components
- Flutter App: [specific files and functions]
- Backend: [specific files and functions, if applicable]
- Configuration: [environment variables, config files]
- Deployment: [Railway settings, if applicable]

## Fix Strategy
[Describe the chosen fix approach]

## Detailed Implementation Steps

### Flutter App Changes
1. [Specific step with file/function to modify]
2. [What to change and why]
3. [How to verify the change]

### Backend Changes (if needed)
1. [Specific step]
2. [What to change]
3. [How to verify]

### Configuration Changes (if needed)
1. [Environment variables to add/update]
2. [Config files to modify]
3. [Deployment settings to change]

## Testing Plan
1. [Step-by-step testing procedure]
2. [Expected results at each step]
3. [How to verify fix is successful]

## Rollback Plan
[How to undo changes if fix causes new issues]

## Success Criteria
- [ ] WebSocket URL constructed with 'wss://' protocol (not 'https://')
- [ ] WebSocket URL does not contain ':0' port
- [ ] WebSocket connection succeeds from Flutter app
- [ ] Chat functionality works end-to-end
- [ ] No connection errors in logs
```

---

### Step 4.2: Implement Fix Incrementally

**Action:** Make changes one at a time and test after each change.

**General implementation pattern:**

1. **Make one small change:**
   - Fix one specific issue (e.g., URL construction)
   - Don't change multiple things at once
   - Follow existing code patterns and conventions

2. **Add verification logging:**
   - Log the change's effect
   - Log variables before and after change
   - Keep diagnostic logging in place

3. **Test immediately:**
   - Rebuild and run the app
   - Check logs for verification
   - Verify the specific issue is fixed

4. **Document the change:**
   - Note what was changed
   - Note the result
   - Update fix plan with progress

5. **Proceed to next change only if current one works**

**Important principles:**
- One change at a time
- Test after each change
- Don't remove diagnostic logging yet
- Document everything
- If a change breaks something, revert immediately

---

### Step 4.3: Specific Implementation Guidelines

**For URL Construction Fix:**

**Before making changes:**
1. Document current URL construction code
2. Test and capture current behavior
3. Identify exact lines to modify

**During implementation:**
1. Locate the problematic URL construction
2. Replace or fix the specific operations causing corruption
3. Ensure the new code:
   - Uses 'wss' scheme from the start
   - Does not manipulate port
   - Does not convert from HTTP URL
   - Properly handles token parameter
4. Add comments explaining the change
5. Keep the code style consistent with rest of project

**After implementation:**
1. Rebuild Flutter app
2. Check logs for URL being constructed
3. Verify URL components are all correct
4. Test WebSocket connection
5. Verify connection succeeds

---

**For Backend Fix:**

**Before making changes:**
1. Document current WebSocket handler code
2. Test backend independently (wscat, Postman)
3. Review WebSocket library documentation

**During implementation:**
1. Locate WebSocket upgrade handler
2. Fix specific issues found (upgrade, auth, CORS)
3. Follow existing backend code patterns
4. Add logging for WebSocket connections
5. Ensure proper error handling

**After implementation:**
1. Redeploy to Railway (if needed)
2. Test backend independently again
3. Verify WebSocket upgrade succeeds
4. Check Railway logs for errors
5. Test from Flutter app

---

**For Configuration Fix:**

**Before making changes:**
1. Document current configuration
2. Identify what needs to change
3. Backup current values

**During implementation:**
1. Update configuration files or environment variables
2. Use separate WebSocket URL if needed
3. Ensure production/development environments are correct
4. Update Railway environment variables (if needed)

**After implementation:**
1. Verify configuration is loaded correctly
2. Log configuration values on app startup
3. Test with new configuration
4. Verify correct URLs are being used

---

## 📋 PHASE 5: VERIFICATION & TESTING

### Step 5.1: Verify URL Construction

**Action:** Confirm WebSocket URL is now correct at all stages.

**Verification checklist:**
- [ ] Diagnostic logging shows 'wss://' scheme (not 'https://')
- [ ] No ':0' port in URL
- [ ] Host is correct Railway domain
- [ ] Path is correct WebSocket endpoint
- [ ] Token parameter is properly included
- [ ] No extra or missing slashes
- [ ] URL is valid WebSocket URL format

**If any check fails:**
- Review the URL construction code again
- Add more detailed logging
- Trace through each step of URL building
- Fix the specific issue found

---

### Step 5.2: Test WebSocket Connection

**Action:** Verify WebSocket connection succeeds from Flutter app.

**Testing procedure:**
1. Launch Flutter app
2. Log in with valid credentials
3. Navigate to chat screen
4. Observe connection attempt in logs
5. Verify connection succeeds (no errors)
6. Check that "Connecting" changes to "Connected"

**Success indicators:**
- No "WebSocketChannelException" errors
- No "was not upgraded to websocket" errors
- Connection established successfully
- App state changes from "Connecting" to "Connected"
- Can send and receive messages

**If connection still fails:**
- Check Railway logs for server-side errors
- Verify backend is receiving connection request
- Check authentication (token validation)
- Verify WebSocket upgrade is performed
- Test backend independently again

---

### Step 5.3: Test End-to-End Functionality

**Action:** Verify entire chat functionality works correctly.

**Test scenarios:**
1. **New conversation:**
   - Start chat from car details page
   - Verify conversation created
   - Verify WebSocket connected

2. **Send message:**
   - Type and send message
   - Verify message appears immediately
   - Verify message saved to database
   - Verify other user receives message (if possible)

3. **Receive message:**
   - Have another user send message (if possible)
   - Verify message appears in real-time
   - Verify notification/indicator updates

4. **Connection recovery:**
   - Close app and reopen
   - Verify reconnection works
   - Verify messages load correctly

5. **Poor network conditions:**
   - Test with slow/intermittent connection
   - Verify reconnection logic works
   - Verify messages don't get lost

**All scenarios should pass without errors.**

---

### Step 5.4: Performance Verification

**Action:** Ensure fix doesn't introduce performance issues.

**Check:**
- Connection establishment time (should be <2 seconds)
- Message delivery latency (should be near real-time)
- App memory usage (no leaks from WebSocket)
- Battery usage (WebSocket not draining battery)

**Monitor logs for:**
- Excessive reconnection attempts
- Memory leaks or resource issues
- Any new errors or warnings

---

### Step 5.5: Cross-Platform Testing

**Action:** Test on multiple devices/platforms if applicable.

**Test on:**
- Different Android devices (if applicable)
- Different network conditions (WiFi, mobile data)
- Different Android versions (if applicable)

**Verify:**
- WebSocket connection works consistently
- No platform-specific issues
- Performance is acceptable on all devices

---

## 📋 PHASE 6: CLEANUP & DOCUMENTATION

### Step 6.1: Clean Up Diagnostic Code

**Action:** Remove excessive diagnostic logging but keep useful logs.

**Keep these logs:**
- Connection state changes (connecting, connected, disconnected)
- Connection errors (for debugging future issues)
- Reconnection attempts

**Remove these logs:**
- Detailed URL construction steps
- URL component parsing logs
- Debug-level verbose logging

**Result:** App has appropriate logging for production without being verbose.

---

### Step 6.2: Update Documentation

**Action:** Document the fix for future reference.

**Create/Update:** `WEBSOCKET_TROUBLESHOOTING.md`

Include:
1. **Problem description:** What was the issue
2. **Root cause:** Why it happened
3. **Solution:** What was changed to fix it
4. **Prevention:** How to avoid similar issues
5. **Testing:** How to verify it's working

**Update code comments:**
- Add comments explaining WebSocket URL construction
- Note any non-obvious implementation details
- Document any workarounds or special handling

---

### Step 6.3: Update Configuration Documentation

**Action:** Document WebSocket configuration for deployment.

**Document:**
- WebSocket URL format and structure
- Environment variables required
- Railway deployment considerations
- Backend WebSocket endpoint requirements
- Authentication mechanism (token in query param)

**Include examples:**
- Development WebSocket URL format
- Production WebSocket URL format
- Environment variable examples

---

## 🎯 COMMON ROOT CAUSES & SOLUTIONS SUMMARY

Based on the error pattern, here are most likely causes and their fixes:

### Root Cause 1: Uri.replace() Port Issue (MOST LIKELY)

**Problem:**
```
Using Uri.parse(httpUrl).replace(scheme: 'wss') 
causes port to become :0 or preserves HTTP port
```

**Solution:**
- Don't derive WebSocket URL from HTTP URL using Uri manipulation
- Build WebSocket URL directly from components
- Don't use Uri.replace() to change scheme from HTTP to WebSocket

---

### Root Cause 2: Base URL Derivation

**Problem:**
```
WebSocket URL derived from HTTP base URL incorrectly
String replacements or Uri parsing causing issues
```

**Solution:**
- Use separate configuration for WebSocket URL
- Don't transform HTTP URL to WebSocket URL
- Define WebSocket URL independently

---

### Root Cause 3: WebSocket Library Misuse

**Problem:**
```
Passing URL to WebSocket library incorrectly
Library expecting different URL format
```

**Solution:**
- Review WebSocket library documentation
- Pass URL as proper Uri object or String (depending on library)
- Ensure no proxy or interceptor interferes

---

### Root Cause 4: Backend Configuration

**Problem:**
```
Backend not properly handling WebSocket upgrade
Railway deployment issues
```

**Solution:**
- Fix WebSocket upgrade implementation
- Ensure proper Railway port binding (0.0.0.0:$PORT)
- Configure CORS for WebSocket

---

## 📊 SUCCESS CRITERIA

The fix is complete and successful when ALL of these are true:

### Technical Criteria
- [ ] WebSocket URL constructed with 'wss://' protocol throughout
- [ ] No ':0' or incorrect port in WebSocket URL
- [ ] WebSocket connection establishes successfully
- [ ] No "was not upgraded to websocket" errors
- [ ] Connection state changes from "Connecting" to "Connected"

### Functional Criteria
- [ ] Can start new conversations from car details
- [ ] Can send messages in real-time
- [ ] Can receive messages in real-time
- [ ] Messages persist across app restarts
- [ ] Connection recovers after network issues

### Code Quality Criteria
- [ ] Code follows existing project patterns
- [ ] Appropriate logging for production
- [ ] Code is documented with comments
- [ ] Fix is documented in troubleshooting guide
- [ ] No hardcoded values (use configuration)

### Testing Criteria
- [ ] Tested on multiple devices (if applicable)
- [ ] Tested with poor network conditions
- [ ] Tested reconnection scenarios
- [ ] Tested end-to-end chat functionality
- [ ] No regressions in other features

---

## 🚨 CRITICAL REMINDERS

### Before Starting
1. ✅ Read all existing WebSocket-related code
2. ✅ Add comprehensive diagnostic logging
3. ✅ Test and document current behavior
4. ✅ Create diagnostic report
5. ✅ Identify root cause before fixing

### During Implementation
1. ✅ Make one change at a time
2. ✅ Test after each change
3. ✅ Follow existing code patterns
4. ✅ Don't remove diagnostic logging yet
5. ✅ Document each change

### After Implementation
1. ✅ Verify all success criteria met
2. ✅ Clean up excessive logging
3. ✅ Update documentation
4. ✅ Test thoroughly on multiple scenarios
5. ✅ Create troubleshooting guide

### Never Do
1. ❌ Make multiple changes without testing each
2. ❌ Hardcode URLs or configuration
3. ❌ Skip diagnostic phase
4. ❌ Remove all logging (keep useful logs)
5. ❌ Assume without verifying

---

## 📝 DELIVERABLES

After completing this fix, you should have:

1. **WEBSOCKET_DIAGNOSTIC_REPORT.md**
   - Complete analysis of URL construction
   - Root cause identified with evidence
   - Logs showing URL corruption points

2. **WEBSOCKET_FIX_PLAN.md**
   - Detailed fix implementation plan
   - Step-by-step changes made
   - Testing results

3. **WEBSOCKET_TROUBLESHOOTING.md**
   - Problem description and solution
   - Configuration requirements
   - Future debugging guide

4. **Fixed code**
   - WebSocket URL construction corrected
   - Appropriate logging in place
   - Code comments added

5. **Updated configuration**
   - Environment variables documented
   - Railway deployment notes
   - WebSocket endpoint documentation

---

## 🎓 DEBUGGING MINDSET

**Remember:**
- **Diagnose before fixing** - Understand the problem completely
- **Logging is your friend** - Add logs to see what's happening
- **Test incrementally** - Verify each change works
- **Documentation matters** - Help future developers (including yourself)
- **Follow patterns** - Match existing code style and architecture

**The goal is not just to fix this specific issue, but to:**
1. Understand why it happened
2. Fix it properly at the root cause
3. Document it for future reference
4. Prevent similar issues

---

**START WITH PHASE 1: DIAGNOSTIC INVESTIGATION**

Do not proceed to fixing until you have completed thorough diagnostics and identified the specific root cause with evidence from logs and code analysis.

Good luck! 🔍🔧
