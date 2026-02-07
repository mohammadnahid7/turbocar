# CHAT SYSTEM ISSUES - TROUBLESHOOTING & FIX INSTRUCTIONS

## 🔴 CRITICAL: ANALYZE BEFORE FIXING

**YOU MUST:**
1. ✅ Read all chat-related code (Flutter app + Backend API)
2. ✅ Test each issue manually to reproduce the problem
3. ✅ Identify root cause through debugging, not guessing
4. ✅ Document findings before implementing fixes
5. ✅ Test fixes incrementally

**YOU MUST NOT:**
1. ❌ Assume API endpoint names or structures
2. ❌ Hardcode any file paths, function names, or variable names
3. ❌ Skip the analysis phase
4. ❌ Fix symptoms without understanding root causes

---

## 🐛 ISSUE #1: Messages Disappear After App Data Clear & Re-login

### Problem Statement
**Symptom:** 
- User sends messages in chat
- Messages appear correctly in the app
- User clears app data and re-logs in
- Chat conversation still appears in list
- BUT when opening the chat, previous messages are gone

### Root Cause Analysis Required

**Action:** Debug step-by-step to find where the problem originates.

#### Step 1.1: Verify Backend Data Persistence

**Check if messages are actually saved in database:**

1. **During Active Session (Before Data Clear):**
   - Send test messages in the app
   - Immediately check database directly (using SQL client or admin panel)
   - Query: Check if messages exist in messages table for that conversation_id
   - Query: Check if conversation exists in conversations table
   - Query: Check if participants are correctly linked

2. **After App Data Clear:**
   - Clear app data and re-login
   - Check database again (same queries)
   - **Question:** Are the messages still in the database?
   
**Possible Findings:**

**Finding A: Messages ARE in database**
- ✅ Backend is working correctly (data persists)
- ❌ Problem is in Flutter app (data retrieval or display)
- → Proceed to Step 1.2

**Finding B: Messages are NOT in database**
- ❌ Backend is not saving messages correctly
- Problem could be: transactions not committing, soft deletes, wrong user_id matching
- → Proceed to Step 1.3

---

#### Step 1.2: Debug Flutter App Message Retrieval (If Data IS in Database)

**Hypothesis:** App is not correctly fetching or displaying messages after re-login.

**Investigation Steps:**

1. **Check Local Storage/Cache:**
   - Find where the app stores chat data locally (SharedPreferences, SQLite, Hive, etc.)
   - When app data is cleared, local cache is wiped
   - **Question:** Is the app trying to load from local cache instead of API?
   - **Question:** Is there a cache invalidation issue?

2. **Check User ID Consistency:**
   - **Critical:** When user re-logs in, is their user_id the same?
   - Print/log the user_id before data clear and after re-login
   - If user_id changes, app won't find messages linked to old user_id
   - **Check:** Does your authentication system maintain consistent user_ids?

3. **Check API Request Parameters:**
   - Add logging to the message fetch API call
   - Log the conversation_id being sent in the request
   - Log the response from the server
   - **Question:** Is the app sending the correct conversation_id?
   - **Question:** Is the server responding with messages?
   - **Question:** Is the response being parsed correctly in the app?

4. **Check Authorization/Permissions:**
   - **Question:** Does the API verify user has access to that conversation?
   - After re-login, new auth token might have different claims
   - Check if authorization header is correctly set in API calls
   - Check if server-side authorization checks are too strict or have bugs

**How to Debug:**

```
In Flutter App:
1. Find the function that fetches messages (likely in a service or repository)
2. Add extensive logging:
   - Log API endpoint being called
   - Log conversation_id being used
   - Log user_id/auth token being sent
   - Log full API response
   - Log any errors or exceptions
3. Trigger the fetch after re-login
4. Examine logs to identify where the breakdown occurs
```

**Common Issues & Fixes:**

**Issue:** App using cached conversation_id that's wrong after re-login
- **Fix:** Clear conversation list cache on logout/login
- **Fix:** Always fetch conversation list from server, not cache

**Issue:** Conversation_id is tied to old session/user_id
- **Fix:** Conversations should be tied to user entities, not session tokens
- **Fix:** Use persistent user_id across sessions

**Issue:** API response contains messages but app fails to parse/display
- **Fix:** Check JSON parsing logic
- **Fix:** Check if response structure changed after backend refactoring
- **Fix:** Handle empty arrays correctly (don't show error for empty chats)

**Issue:** Pagination bug - fetching wrong page after re-login
- **Fix:** Reset pagination offset when opening conversation
- **Fix:** Always fetch latest messages (page 1) when entering chat room

---

#### Step 1.3: Debug Backend Message Persistence (If Data is NOT in Database)

**Hypothesis:** Backend is not correctly saving messages to database.

**Investigation Steps:**

1. **Check Transaction Handling:**
   - Find the "send message" endpoint in backend
   - Locate the repository/service function that handles message creation
   - **Question:** Is the operation wrapped in a transaction?
   - **Question:** Is the transaction being committed?
   - **Question:** Are there any errors being silently swallowed?

2. **Check Message Table Constraints:**
   - Review messages table foreign keys
   - **Question:** Is conversation_id valid when inserting message?
   - **Question:** Is sender_id valid?
   - **Question:** Are there any constraint violations preventing insert?

3. **Check Soft Delete Logic:**
   - **Question:** Is there a deleted_at column on messages?
   - **Question:** Are messages being "soft deleted" immediately after creation?
   - **Question:** Do queries filter by deleted_at IS NULL?

4. **Check User ID Matching:**
   - When conversation is created, which user_ids are stored?
   - When messages are sent, which user_id is used as sender_id?
   - **Question:** Is there a mismatch between user_id in JWT token vs database?

**How to Debug:**

```
In Backend:
1. Find "send message" endpoint handler
2. Add extensive logging:
   - Log incoming request payload
   - Log user_id from authentication context
   - Log before database transaction starts
   - Log after database transaction commits
   - Log the message_id returned from database
   - Log any errors
3. Send test message from app
4. Check server logs
5. Immediately query database to verify message was saved
```

**Common Issues & Fixes:**

**Issue:** Transaction not committed (error occurs and rollback happens)
- **Fix:** Check transaction error handling
- **Fix:** Ensure transaction commits on success
- **Fix:** Log transaction errors properly

**Issue:** Wrong user_id being used (mismatch between JWT and database)
- **Fix:** Verify user_id extraction from JWT token
- **Fix:** Ensure user_id consistency across authentication and database
- **Fix:** Use UUID/permanent IDs, not session-based IDs

**Issue:** Foreign key constraint failure (conversation doesn't exist)
- **Fix:** Verify conversation exists before allowing message send
- **Fix:** Use find-or-create pattern for conversations
- **Fix:** Check that conversation_id in app matches database

**Issue:** Messages created but deleted immediately by some cleanup job
- **Fix:** Check for any scheduled tasks that delete messages
- **Fix:** Check soft delete logic - ensure deleted_at stays NULL

---

#### Step 1.4: Create Fix Implementation Plan

**After identifying root cause, document the fix:**

Create `ISSUE_1_FIX_PLAN.md`:

```markdown
# Issue #1 Fix Plan: Messages Disappear After Re-login

## Root Cause Identified
[Document what you found - be specific]

## Affected Components
- Backend: [list specific files/functions]
- Flutter App: [list specific files/functions]
- Database: [any schema issues]

## Fix Strategy
[Describe the fix approach]

## Implementation Steps
1. [Specific step]
2. [Specific step]
3. [Specific step]

## Testing Plan
1. Send messages before clearing data
2. Verify messages in database
3. Clear app data and re-login
4. Verify messages still in database
5. Verify messages appear in app
6. Success criteria: All previous messages load correctly

## Rollback Plan
[How to undo if fix causes issues]
```

---

## 🐛 ISSUE #2: Chat Titles Not Displaying Correctly

### Problem Statement
**Symptom:**
- Chat list shows conversations
- BUT titles are not meaningful (should show car title or seller name)
- Chat context (car details) should be visible

### Root Cause Analysis Required

**Action:** Trace data flow from database → backend API → Flutter app → UI

#### Step 2.1: Verify Data in Database

**Check what's actually stored:**

1. **Query conversations table:**
   - Check if `car_title` column exists and is populated
   - Check if `car_id` exists (to fetch car details if title not denormalized)
   - Check metadata JSONB field - does it contain car info?
   
2. **Query users/sellers table:**
   - Check if seller name is accessible
   - Identify how to get seller info (from user_id or car_seller_id)

**Possible Findings:**

**Finding A: car_title exists and is populated in conversations table**
- ✅ Data is available in database
- ❌ Backend API might not be returning it
- ❌ Flutter app might not be using it
- → Proceed to Step 2.2

**Finding B: car_title does NOT exist in conversations table**
- ❌ Database schema missing denormalized data
- Need to add car_title column and backfill data
- → Proceed to Step 2.3

**Finding C: car_title exists but is NULL or empty**
- ❌ Data not populated during conversation creation
- Need to fix conversation creation logic
- → Proceed to Step 2.4

---

#### Step 2.2: Debug Backend API Response (If Data Exists in DB)

**Hypothesis:** Backend has the data but not sending it to Flutter app.

**Investigation Steps:**

1. **Find Conversation List API Endpoint:**
   - Locate the endpoint that returns list of conversations (e.g., GET /conversations)
   - Find the repository/service function that builds the response
   - Check the SQL query or GORM query

2. **Check if car_title is Selected:**
   - **Question:** Does the SELECT query include car_title?
   - **Question:** Is car_title in the response struct/model?
   - **Question:** Is car_title serialized to JSON response?

3. **Check API Response Structure:**
   - Make actual API call (using Postman, curl, or browser)
   - Log in as test user
   - Call the conversation list endpoint
   - **Examine JSON response:**
     - Is car_title field present?
     - Is it populated with correct value?
     - Is the JSON key named correctly (camelCase vs snake_case)?

**How to Debug:**

```
In Backend:
1. Find conversation list query
2. Check if car_title is in SELECT clause
3. Check if response struct includes car_title field
4. Check JSON serialization tags (json:"car_title" or json:"carTitle")
5. Add logging to print response before sending
6. Test API directly (not through app)
```

**Common Issues & Fixes:**

**Issue:** car_title not included in SELECT query
- **Fix:** Add car_title to the query (check MARKETPLACE_CHAT_ARCHITECTURE.md for reference query)
- **Fix:** If using GORM Select(), add the field
- **Fix:** If using raw SQL, add column to SELECT list

**Issue:** Response struct missing car_title field
- **Fix:** Add field to the struct used for API response
- **Fix:** Add JSON tag: `json:"car_title"` or `json:"carTitle"` (match Flutter expectation)

**Issue:** car_title in struct but not serialized to JSON
- **Fix:** Ensure field is exported (starts with capital letter in Go)
- **Fix:** Check if there's custom JSON marshaling logic that's excluding it

**Issue:** car_title present but Flutter app expects different key name
- **Fix:** Check Flutter model - what field name does it expect?
- **Fix:** Either change backend JSON tag or Flutter model to match

---

#### Step 2.3: Add car_title to Database Schema (If Missing)

**Action:** Add denormalized car_title column to conversations table.

**Implementation Steps:**

1. **Create Migration to Add Column:**
   - Create migration file (follow project's migration naming convention)
   - Add car_title column as nullable VARCHAR initially:
     ```sql
     ALTER TABLE conversations 
     ADD COLUMN car_title VARCHAR(255);
     ```

2. **Backfill Existing Data:**
   - Write query to populate car_title for existing conversations:
     ```sql
     UPDATE conversations c
     SET car_title = (SELECT title FROM cars WHERE id = c.car_id)
     WHERE car_title IS NULL;
     ```
   - **Important:** Test on staging/dev database first!

3. **Make Column NOT NULL (After Backfill):**
   - After verifying all rows have car_title populated:
     ```sql
     ALTER TABLE conversations 
     ALTER COLUMN car_title SET NOT NULL;
     ```

4. **Update Conversation Creation Logic:**
   - Find backend code that creates new conversations
   - Ensure car_title is populated when conversation is created
   - Fetch car_title from cars table and include in INSERT

5. **Update Model/Struct:**
   - Add car_title field to conversation model in backend
   - Add appropriate GORM tags
   - Add to API response struct

6. **Update Queries:**
   - Ensure conversation list query includes car_title
   - Update any other queries that need car_title

---

#### Step 2.4: Fix Conversation Creation to Populate car_title

**Hypothesis:** car_title column exists but isn't populated during conversation creation.

**Investigation Steps:**

1. **Find Conversation Creation Code:**
   - Locate "create conversation" or "find-or-create conversation" function
   - Typically called when user clicks chat button on car details page

2. **Check Current Logic:**
   - **Question:** Is car_id being passed from Flutter app?
   - **Question:** Is backend fetching car details using car_id?
   - **Question:** Is car_title being included in the INSERT statement?

3. **Trace Data Flow:**
   - Flutter app sends car_id to backend (verify this)
   - Backend should fetch car details from cars table
   - Backend should extract car_title
   - Backend should include car_title in conversation creation

**Fix Implementation:**

```
In Backend (Conversation Creation Function):
1. Receive car_id from request
2. Query cars table to get car details:
   - car_title
   - car_seller_id (if not already passed)
   - any other denormalized data needed
3. Create conversation with all denormalized fields:
   - car_id
   - car_title ← Ensure this is included
   - car_seller_id
4. Insert into database
5. Return conversation with all fields populated
```

**Testing:**
1. Create new conversation from app
2. Immediately query database
3. Verify car_title is populated in conversations table
4. Verify API returns car_title in response

---

#### Step 2.5: Debug Flutter App Display Logic (If Backend Returns Data)

**Hypothesis:** Backend sends car_title but Flutter app doesn't display it.

**Investigation Steps:**

1. **Check Flutter Conversation Model:**
   - Find the Dart class that represents a conversation
   - **Question:** Does it have a field for car_title/carTitle?
   - **Question:** Is the field mapped correctly from JSON?

2. **Check JSON Deserialization:**
   - Look for `fromJson` factory constructor
   - Verify car_title field is parsed from JSON
   - Check for typos in JSON key names
   - Verify null handling (if car_title might be null)

3. **Check UI Widget:**
   - Find the widget that displays conversation list
   - Find where title text is set
   - **Question:** What value is being used for title?
   - **Question:** Is it using conversation.carTitle or something else?

**How to Debug:**

```
In Flutter App:
1. Find conversation list screen/widget
2. Find where conversation title is displayed
3. Add print statements:
   - Print entire conversation object
   - Print the field being used for title
   - Print car_title specifically
4. Rebuild app and check console logs
5. Verify car_title is present in conversation object
6. Verify UI widget is using correct field
```

**Common Issues & Fixes:**

**Issue:** Conversation model missing car_title field
- **Fix:** Add field to Dart class
- **Fix:** Add to fromJson constructor
- **Fix:** Handle null case (provide default or show loading state)

**Issue:** UI displaying wrong field (e.g., conversation ID instead of car title)
- **Fix:** Update Text widget to use conversation.carTitle
- **Fix:** Add fallback: `conversation.carTitle ?? 'Chat'`

**Issue:** Field name mismatch (backend sends "car_title", app expects "carTitle")
- **Fix:** Update fromJson to handle correct JSON key
- **Fix:** Or use json_serializable with @JsonKey annotation

---

#### Step 2.6: Additional Enhancement - Show Seller Name

**Requirement:** Show seller name in addition to or instead of car title.

**Implementation Approach:**

**Option A: Denormalize seller name in conversations table**
- Add `seller_name` column to conversations table
- Populate during conversation creation
- Include in API response
- Display in Flutter app

**Option B: Fetch seller details via JOIN in query**
- JOIN conversations with users table
- Include seller name in query result
- Include in API response struct
- Display in Flutter app

**Option C: Show car title in list, seller name in chat room header**
- Keep conversation list showing car title (context of chat)
- In chat room, fetch and display seller details at top
- This separates concerns: list = what, room = who

**Recommended:** Option C for best UX
- Conversation list shows car context (what you're chatting about)
- Chat room shows seller context (who you're chatting with)
- Car image and details pinned in chat room header

**Implementation for Option C:**

1. **Conversation List:**
   - Display car_title as main title
   - Optionally show car thumbnail image
   - Show last message preview

2. **Chat Room Header:**
   - Fetch seller details when opening chat
   - Display seller name, avatar
   - Display car title, image (pinned at top)
   - This gives full context within the chat

---

#### Step 2.7: Create Fix Implementation Plan

Create `ISSUE_2_FIX_PLAN.md`:

```markdown
# Issue #2 Fix Plan: Chat Titles Not Displaying Correctly

## Root Cause Identified
[Document what you found]

## Current State
- Database: [car_title exists/missing, populated/empty]
- Backend API: [includes car_title/missing]
- Flutter App: [displays car_title/displays wrong value]

## Target State
- Conversation list shows: [car title / seller name / both]
- Chat room header shows: [full car details + seller info]

## Implementation Steps

### Backend Changes
1. [Specific step]
2. [Specific step]

### Database Changes
1. [Migration if needed]
2. [Backfill if needed]

### Flutter App Changes
1. [Model updates]
2. [UI updates]

## Testing Plan
1. Create new conversation → verify title shows immediately
2. Fetch conversation list → verify all titles are correct
3. Open chat room → verify header shows car + seller details
4. Test with multiple conversations (same car, different sellers)

## Success Criteria
- All conversation titles are meaningful (car title or seller name)
- Chat room shows full context (car details + seller info)
- No "undefined" or placeholder titles
```

---

## 🐛 ISSUE #3: "Connecting" Ribbon Stuck / Chat List Not Loading

### Problem Statement
**Symptom:**
- Chat page shows "Connecting" ribbon continuously
- Chat list may not be loading from server
- This indicates a connection or data fetching problem

### Root Cause Analysis Required

**Action:** Determine if this is a WebSocket issue, API issue, or UI state issue.

#### Step 3.1: Identify Connection Type

**Question:** What type of connection is the app using for chat?

**Possibility A: WebSocket/Socket.IO Connection**
- Real-time chat typically uses WebSocket
- "Connecting" suggests WebSocket connection state
- → Proceed to Step 3.2

**Possibility B: HTTP Polling / REST API**
- Some apps use HTTP polling instead of WebSocket
- "Connecting" might be app waiting for initial API response
- → Proceed to Step 3.3

**Possibility C: UI State Bug**
- Connection actually works but UI stuck showing "Connecting"
- → Proceed to Step 3.4

**How to Determine:**

```
In Flutter App:
1. Search codebase for WebSocket/Socket.IO imports
   - socket_io_client package
   - web_socket_channel package
2. Search for "Connecting" text in UI code
3. Find what triggers the "Connecting" state
4. Trace back to see what connection type is used
```

---

#### Step 3.2: Debug WebSocket Connection (If Using WebSocket)

**Hypothesis:** WebSocket not connecting to backend.

**Investigation Steps:**

1. **Check WebSocket Server Running:**
   - **Question:** Is your backend running a WebSocket server?
   - **Question:** Is it on a different port than HTTP API?
   - **Question:** Is it behind a proxy (nginx) that needs WebSocket config?

2. **Check WebSocket URL:**
   - In Flutter app, find where WebSocket connection is initialized
   - Check the URL being used (ws:// or wss://)
   - **Common mistakes:**
     - Using localhost when should be actual IP/domain
     - Using http:// instead of ws://
     - Using wss:// when server doesn't have SSL
     - Port number incorrect or missing

3. **Check Network Logs:**
   - Enable network logging in Flutter app
   - Attempt to connect
   - Look for WebSocket connection attempt in logs
   - **Check for errors:**
     - Connection refused (server not running)
     - Connection timeout (firewall/network issue)
     - SSL/TLS error (certificate issue with wss://)
     - 404 error (wrong URL path)

4. **Check Backend WebSocket Handler:**
   - Locate WebSocket endpoint in backend code
   - Verify it's registered and accessible
   - Check for authentication requirements
   - Test WebSocket endpoint directly (using wscat or Postman)

**How to Debug:**

```
Backend:
1. Verify WebSocket server is running
2. Log when WebSocket connections are received
3. Check if authentication is blocking connections
4. Test WebSocket endpoint with wscat tool

Flutter App:
1. Add connection state logging
2. Log connection URL being used
3. Log any connection errors
4. Check if auth token is being sent correctly
```

**Common Issues & Fixes:**

**Issue:** WebSocket URL uses localhost but running on physical device
- **Fix:** Use actual IP address or domain name
- **Fix:** Configure backend URL as environment variable

**Issue:** WebSocket server not running
- **Fix:** Start WebSocket server (might be separate from HTTP server)
- **Fix:** Check if process is running on expected port

**Issue:** Authentication failing on WebSocket connection
- **Fix:** Ensure JWT token or auth credentials are sent during connection
- **Fix:** Check backend WebSocket middleware for auth logic
- **Fix:** Verify token format and validity

**Issue:** Firewall blocking WebSocket port
- **Fix:** Open port in firewall
- **Fix:** Use same port as HTTP server (some servers support both)

**Issue:** Proxy (nginx/Apache) not configured for WebSocket
- **Fix:** Add WebSocket upgrade headers to proxy config
- **Fix:** Example nginx: 
   ```
   proxy_set_header Upgrade $http_upgrade;
   proxy_set_header Connection "upgrade";
   ```

---

#### Step 3.3: Debug HTTP API Connection (If Using REST API)

**Hypothesis:** Initial conversation list API call failing or slow.

**Investigation Steps:**

1. **Check Network Request:**
   - In Flutter app, find where conversation list is fetched
   - Add logging before and after API call
   - Check if request is being sent
   - Check if response is received

2. **Check API Response:**
   - Make API call directly (Postman/curl)
   - Verify endpoint is working
   - Check response time (should be <2 seconds)
   - Check response format (valid JSON)

3. **Check Error Handling:**
   - In Flutter app, find error handling for API call
   - **Question:** Are errors being caught but not logged?
   - **Question:** Is app showing "Connecting" instead of showing error?
   - Add logging to all error paths

4. **Check Authorization:**
   - Verify auth token is valid after re-login
   - Check if token is being sent in request headers
   - Verify backend accepts the token

**How to Debug:**

```
Flutter App:
1. Find conversation list fetch function
2. Wrap in try-catch and log everything:
   try {
     print('Fetching conversations...');
     final response = await api.getConversations();
     print('Response: $response');
   } catch (e, stackTrace) {
     print('Error: $e');
     print('Stack: $stackTrace');
   }
3. Rebuild and check logs
4. Determine if request is sent, and if response is received
```

**Common Issues & Fixes:**

**Issue:** API endpoint URL incorrect after re-login
- **Fix:** Verify base URL configuration
- **Fix:** Check if environment changed (dev vs prod)

**Issue:** Auth token not being sent
- **Fix:** Verify token storage after login
- **Fix:** Check if API client is using correct token
- **Fix:** Ensure token is in Authorization header

**Issue:** API timeout (takes too long)
- **Fix:** Check backend query performance
- **Fix:** Add loading indicator instead of "Connecting"
- **Fix:** Optimize database queries (see Issue #1)

**Issue:** API returns 401/403 (authorization failure)
- **Fix:** Verify user_id in token matches database
- **Fix:** Check if session expired
- **Fix:** Re-authenticate and retry

**Issue:** API returns empty array but app shows "Connecting"
- **Fix:** Handle empty list case (show "No chats yet" message)
- **Fix:** Don't show "Connecting" when data is loaded (even if empty)

---

#### Step 3.4: Debug UI State Management (If Connection Works)

**Hypothesis:** Data loads successfully but UI stuck in "Connecting" state.

**Investigation Steps:**

1. **Find Connection State Logic:**
   - Search for "Connecting" text in Flutter codebase
   - Find the state variable that controls this display
   - Trace where this state is set and cleared

2. **Check State Transitions:**
   - **Initial state:** Disconnected or Connecting
   - **After connection:** Connected
   - **After data load:** Ready or Loaded
   - **Question:** Is state transition logic correct?
   - **Question:** Is state being updated when data arrives?

3. **Check Async State Handling:**
   - If using FutureBuilder or StreamBuilder, check implementation
   - Verify ConnectionState cases are handled correctly
   - Check for missing state updates

**How to Debug:**

```
Flutter App:
1. Find widget that shows "Connecting"
2. Find the conditional that displays it
3. Add print statements for all state changes:
   setState(() {
     print('State changing from $oldState to $newState');
     _connectionState = newState;
   });
4. Trigger connection and watch state changes in logs
5. Identify if state gets stuck at a particular value
```

**Common Issues & Fixes:**

**Issue:** State variable not updated after successful connection
- **Fix:** Add setState() call when connection succeeds
- **Fix:** Update state variable when data loads

**Issue:** FutureBuilder doesn't recognize data loaded
- **Fix:** Check if Future completes successfully
- **Fix:** Verify ConnectionState.done case is handled
- **Fix:** Check for errors that prevent completion

**Issue:** StreamBuilder doesn't receive data
- **Fix:** Verify stream is emitting data
- **Fix:** Check if stream is being listened to correctly
- **Fix:** Add logging to stream events

**Issue:** Conditional logic error
- **Fix:** Review if-else conditions for showing "Connecting"
- **Fix:** Ensure all success paths clear the "Connecting" state
- **Fix:** Add explicit checks for loaded state

---

#### Step 3.5: Check Data Transformation Issues

**Hypothesis:** Data loads but parsing fails, causing app to think it's still loading.

**Investigation Steps:**

1. **Check Response Parsing:**
   - Log raw API response
   - Log parsed conversation list
   - **Question:** Is JSON being parsed correctly?
   - **Question:** Are all required fields present?

2. **Check for Parsing Exceptions:**
   - Look for try-catch around JSON parsing
   - Check if exceptions are silently caught
   - Add logging to all catch blocks

3. **Check Model Compatibility:**
   - Verify Flutter conversation model matches API response
   - Check for missing fields or type mismatches
   - Handle nullable fields correctly

**How to Debug:**

```
Flutter App:
1. In conversation list fetch function:
   final response = await api.getConversations();
   print('Raw response: ${response.body}'); // or response.data
   
2. In conversation model fromJson:
   factory Conversation.fromJson(Map<String, dynamic> json) {
     print('Parsing conversation: $json');
     try {
       return Conversation(
         id: json['id'],
         // ... other fields
       );
     } catch (e) {
       print('Parse error: $e');
       rethrow;
     }
   }
   
3. After parsing list:
   print('Parsed ${conversations.length} conversations');
   conversations.forEach((c) => print('Conversation: ${c.id}'));
```

**Common Issues & Fixes:**

**Issue:** JSON key mismatch (snake_case vs camelCase)
- **Fix:** Update fromJson to use correct JSON keys
- **Fix:** Or use json_serializable with @JsonKey annotations

**Issue:** Required field is null in response
- **Fix:** Make field nullable in Dart model
- **Fix:** Provide default value
- **Fix:** Handle null case in UI

**Issue:** Type mismatch (expecting String, got int)
- **Fix:** Update model field type
- **Fix:** Add type conversion in fromJson

**Issue:** List parsing fails (wrong structure)
- **Fix:** Check API response structure
- **Fix:** Verify if response is nested (e.g., {data: [...]} vs [...])
- **Fix:** Update parsing logic to match structure

---

#### Step 3.6: Create Fix Implementation Plan

Create `ISSUE_3_FIX_PLAN.md`:

```markdown
# Issue #3 Fix Plan: "Connecting" Ribbon Stuck

## Root Cause Identified
[Document specific cause found]

## Connection Type
- [ ] WebSocket
- [ ] HTTP API
- [ ] Other: [specify]

## Problem Category
- [ ] Connection not establishing
- [ ] Connection establishes but data not loading
- [ ] Data loads but UI state not updating
- [ ] Data parsing failing

## Affected Components
- Backend: [specific files/services]
- Flutter App: [specific widgets/services]
- Network: [any infrastructure issues]

## Fix Strategy
[Describe the fix approach]

## Implementation Steps

### Backend Changes (if needed)
1. [Specific step]
2. [Specific step]

### Flutter App Changes
1. [Specific step]
2. [Specific step]

### Infrastructure Changes (if needed)
1. [Specific step]

## Testing Plan
1. Fresh app install → login → navigate to chat page
2. Verify "Connecting" changes to "Connected" or disappears
3. Verify conversation list loads
4. Test with poor network (3G simulation)
5. Test with no conversations (empty list handling)
6. Test connection recovery (kill app, reopen)

## Success Criteria
- "Connecting" ribbon appears only during actual connection attempt
- "Connecting" disappears when connected or shows error message
- Conversation list loads and displays correctly
- Empty list shows appropriate message (not "Connecting")
- Connection errors show user-friendly message
```

---

## 🎯 OVERALL DEBUGGING METHODOLOGY

### Step-by-Step Debugging Process

**For Each Issue:**

1. **Reproduce the Problem**
   - Follow exact steps to trigger issue
   - Note any error messages
   - Check both app UI and server logs

2. **Isolate the Problem**
   - Is it backend, frontend, or network?
   - Test each layer independently
   - Use direct API calls to bypass app logic

3. **Identify Root Cause**
   - Don't guess - use logging and debugging
   - Trace data flow from source to destination
   - Find the exact point where things break

4. **Plan the Fix**
   - Document root cause clearly
   - Design fix that addresses root cause (not symptoms)
   - Consider side effects and edge cases

5. **Implement the Fix**
   - Make minimal changes
   - Add logging for future debugging
   - Follow existing code patterns

6. **Test Thoroughly**
   - Test happy path
   - Test edge cases
   - Test error scenarios
   - Verify no regressions

7. **Document the Fix**
   - Update code comments
   - Document in fix plan
   - Add to troubleshooting guide

---

## 🔧 DEBUGGING TOOLS & TECHNIQUES

### Backend Debugging

**Add Comprehensive Logging:**
```
At every significant point:
- Log input parameters
- Log database queries (GORM log mode)
- Log query results
- Log before/after transactions
- Log any errors with full stack traces
```

**Database Inspection:**
```
- Query tables directly after operations
- Use EXPLAIN ANALYZE to check query performance
- Check for constraint violations
- Verify foreign key relationships
```

**API Testing:**
```
- Use Postman/Insomnia for direct API calls
- Test with different user tokens
- Check response headers and status codes
- Verify JSON structure
```

### Flutter Debugging

**Add Print Debugging:**
```
- Print at start/end of each async function
- Print API request URLs and parameters
- Print API responses (full JSON)
- Print state changes
- Print any exceptions with stack traces
```

**Use Flutter DevTools:**
```
- Network tab to see API calls
- Logging tab to see print statements
- Widget inspector for UI debugging
```

**Check Logs:**
```
- Flutter run with --verbose
- Check for exceptions or warnings
- Look for network errors
- Check for state management issues
```

### Network Debugging

**Check Network Layer:**
```
- Use Charles Proxy or Proxyman to inspect traffic
- Verify requests are being sent
- Check request headers (auth tokens)
- Verify response status and body
- Check for timeout issues
```

**Test Connectivity:**
```
- Ping backend server from device
- Check firewall rules
- Verify device can reach backend
- Test on WiFi vs mobile data
```

---

## 📝 DELIVERABLES

After completing investigation and fixes:

1. **Root Cause Analysis Document** for each issue
2. **Fix Implementation Plans** (ISSUE_1_FIX_PLAN.md, etc.)
3. **Test Results Documentation**
4. **Updated Code** with fixes implemented
5. **Updated Comments** in code explaining fixes
6. **Troubleshooting Guide** for future reference

---

## ⚠️ CRITICAL REMINDERS

**Before Making Any Changes:**
1. ✅ Create a backup or new branch
2. ✅ Document current behavior (screenshots, logs)
3. ✅ Understand root cause completely
4. ✅ Plan fix strategy

**While Implementing Fixes:**
1. ✅ Make one change at a time
2. ✅ Test after each change
3. ✅ Add logging for future debugging
4. ✅ Follow existing code patterns

**After Implementing Fixes:**
1. ✅ Test all affected functionality
2. ✅ Verify no regressions
3. ✅ Update documentation
4. ✅ Create troubleshooting guide

**DO NOT:**
1. ❌ Make multiple changes at once
2. ❌ Skip testing intermediate steps
3. ❌ Assume without verifying
4. ❌ Remove logging after fixing (keep for future)

---

## 🎓 SUCCESS CRITERIA

All three issues are considered fixed when:

### Issue #1: Messages Persist
- ✅ Messages sent before app data clear still appear after re-login
- ✅ Messages are in database and correctly retrieved
- ✅ Conversation history is complete
- ✅ No data loss on app restart

### Issue #2: Titles Display Correctly
- ✅ All conversations show meaningful titles (car title or seller name)
- ✅ Chat room header shows full car context
- ✅ Multiple chats about same car are distinguishable
- ✅ No "undefined" or placeholder titles

### Issue #3: Connection Works
- ✅ "Connecting" ribbon appears only during connection
- ✅ Ribbon disappears when connected
- ✅ Conversation list loads correctly
- ✅ Empty list shows appropriate message
- ✅ Connection errors show user-friendly message

**Overall System Health:**
- ✅ No errors in server logs
- ✅ No exceptions in app logs
- ✅ All user flows work end-to-end
- ✅ Performance is acceptable
- ✅ System is stable and reliable

---

**START WITH ISSUE #1: Root cause analysis using systematic debugging**

Do not proceed to fixes until you have clearly identified and documented the root cause of each issue. Debugging beats guessing every time.

Good luck! 🐛🔧
