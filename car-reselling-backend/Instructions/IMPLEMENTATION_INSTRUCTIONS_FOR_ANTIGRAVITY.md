# CHAT SYSTEM REFACTORING - IMPLEMENTATION INSTRUCTIONS FOR ANTIGRAVITY

## 🎯 OBJECTIVE

Refactor the entire chat system codebase to follow the enterprise-level PostgreSQL architecture outlined in `MARKETPLACE_CHAT_ARCHITECTURE.md`. This involves analyzing existing code, planning the migration, and systematically implementing the new architecture WITHOUT breaking existing functionality.

---

## ⚠️ CRITICAL INSTRUCTIONS

**YOU MUST:**
1. ✅ **ANALYZE FIRST** - Read all existing chat-related files before making ANY changes
2. ✅ **CREATE ROADMAP** - Document current state and migration plan in a .md file
3. ✅ **FOLLOW EXISTING PATTERNS** - Use the same naming conventions, folder structure, and coding style already in the project
4. ✅ **PRESERVE API CONTRACTS** - Keep existing API endpoints, request/response formats unless explicitly broken
5. ✅ **TEST INCREMENTALLY** - Verify each step works before proceeding

**YOU MUST NOT:**
1. ❌ **NO HARDCODING** - Do not invent folder names, file names, API paths, or function names
2. ❌ **NO ASSUMPTIONS** - Do not assume project structure without reading the code
3. ❌ **NO BREAKING CHANGES** - Do not change API contracts without explicit migration plan
4. ❌ **NO SKIPPING ANALYSIS** - Do not start coding before understanding current implementation
5. ❌ **NO NEW ENDPOINTS** - Do not create new API routes unless the current ones are fundamentally broken

---

## 📋 PHASE 1: DISCOVERY & ANALYSIS

### Step 1.1: Map the Current Codebase

**Action:** Systematically explore and document the existing chat implementation.

**What to find and document:**

1. **File Structure**
   - Locate ALL files related to chat functionality (controllers, services, repositories, models, handlers, etc.)
   - Document the directory structure
   - Note any naming conventions used (e.g., `chatController.go` vs `chat_controller.go`)

2. **Database Models**
   - Find current model/struct definitions for conversations, messages, participants
   - Document all fields, types, GORM tags
   - Identify which fields are causing the JSONB scan error
   - Check if custom Scanner/Valuer implementations exist

3. **Repository/Database Layer**
   - Locate all database query functions
   - Document each query: what it does, which file/line, any performance issues
   - Identify duplicate or redundant queries
   - Find the problematic queries mentioned in error logs (line 80, 27, 36, 62, 120, 128)

4. **Service/Business Logic Layer**
   - Find where business logic resides
   - Document transaction handling patterns
   - Identify any data transformation logic

5. **API/Handler Layer**
   - Document all existing endpoints (exact paths, methods, request/response formats)
   - Note any middleware or authorization checks
   - Identify the endpoint patterns (RESTful vs custom)

6. **Database Schema**
   - Document current table structures (run `SHOW CREATE TABLE` or equivalent)
   - List all indexes currently defined
   - Note any foreign keys, constraints, defaults

**Deliverable:** Create `CURRENT_STATE_ANALYSIS.md` in the server project root with:
```markdown
# Current Chat System Analysis

## File Structure
- Controllers: [list files and paths]
- Services: [list files and paths]
- Repositories: [list files and paths]
- Models: [list files and paths]

## Database Schema
[Paste actual CREATE TABLE statements]

## Current Models/Structs
[Document actual struct definitions with types]

## API Endpoints
[List all endpoints with methods, paths, purpose]

## Known Issues
[List specific problems identified, including the JSONB scan error]

## Query Inventory
[List all database queries with file:line references]
```

---

### Step 1.2: Gap Analysis

**Action:** Compare current implementation against the enterprise architecture.

**What to analyze:**

1. **Schema Differences**
   - Which columns are missing from current schema?
   - Which columns exist but shouldn't (according to architecture)?
   - Are data types aligned (UUID vs INT, VARCHAR sizes, etc.)?
   - Is JSONB being used correctly or incorrectly?

2. **Code Pattern Differences**
   - Does a custom JSONB Scanner/Valuer exist? If not, this is why scan fails
   - Are queries optimized or doing unnecessary joins?
   - Are transactions used correctly?
   - Is denormalized data (car_title, car_seller_id) present?

3. **Missing Optimizations**
   - Which indexes from the architecture are missing?
   - Are queries paginated properly?
   - Is there N+1 query problem anywhere?

4. **Breaking Changes Required**
   - Will any API response formats need to change?
   - Will database schema changes affect existing data?
   - Are there any backwards-incompatible changes necessary?

**Deliverable:** Add to `CURRENT_STATE_ANALYSIS.md`:
```markdown
## Gap Analysis

### Schema Gaps
- Missing columns: [list]
- Incorrect types: [list]
- Missing indexes: [list]

### Code Gaps
- JSONB handling: [current vs required]
- Query inefficiencies: [specific examples]
- Missing patterns: [list]

### Required Changes
- Breaking changes: [list with justification]
- Non-breaking changes: [list]
- New features needed: [list]
```

---

## 📋 PHASE 2: IMPLEMENTATION ROADMAP

### Step 2.1: Create Detailed Migration Plan

**Action:** Create `CHAT_REFACTORING_ROADMAP.md` in the server project root.

**Structure the roadmap as follows:**

```markdown
# Chat System Refactoring Roadmap

## Migration Strategy: [Choose One]

Option A: **Big Bang** - Replace everything at once (if system is small/new)
Option B: **Gradual Migration** - Phase-by-phase with backward compatibility (recommended for production)
Option C: **Parallel Run** - New system alongside old, switch over when ready

[Explain which option and WHY based on current system state]

## Pre-Migration Checklist
- [ ] Backup current database
- [ ] Document all existing API contracts
- [ ] Set up test environment
- [ ] Create rollback plan
- [ ] Notify stakeholders (if applicable)

## Phase 1: Fix JSONB Scanning Issue (CRITICAL - Do First)
**Goal:** Stop the immediate errors without changing schema

**Steps:**
1. Create custom JSONB type with Scanner/Valuer
2. Update conversation model to use custom type
3. Test that scan errors disappear
4. Verify existing functionality still works

**Files to modify:** [List specific files from analysis]
**Estimated time:** [realistic estimate]
**Rollback plan:** [how to undo if it fails]

## Phase 2: Database Schema Alignment
**Goal:** Update tables to match enterprise architecture

**Steps:**
1. Generate migration files for schema changes
2. Test migrations on copy of production data
3. Add new columns with defaults (non-breaking)
4. Backfill denormalized data (car_title, car_seller_id, etc.)
5. Add NOT NULL constraints after backfill
6. Create new indexes
7. Remove unused indexes/columns (if any)

**Migration sequence:** [Detailed SQL migration steps]
**Data transformation:** [How to backfill data]
**Rollback plan:** [Reverse migrations]

## Phase 3: Repository Layer Refactoring
**Goal:** Replace inefficient queries with optimized patterns

**Steps:**
1. Implement new repository methods following architecture
2. Replace old queries one function at a time
3. Test each replacement thoroughly
4. Remove old/unused repository methods

**Query mapping:** [Old query → New query for each function]
**Testing strategy:** [How to verify correctness]

## Phase 4: Model Layer Updates
**Goal:** Align Go structs with new database schema

**Steps:**
1. Update struct field definitions
2. Add/update GORM tags
3. Add helper methods if needed
4. Update any DTO/response structs

**Backwards compatibility:** [How to maintain API responses]

## Phase 5: Service Layer Adjustments
**Goal:** Use new repository methods, improve transaction handling

**Steps:**
1. Update service functions to call new repository methods
2. Wrap multi-step operations in transactions
3. Add proper error handling
4. Remove any business logic from repository layer (if present)

## Phase 6: API Layer Verification
**Goal:** Ensure all endpoints still work correctly

**Steps:**
1. Test each endpoint with current contracts
2. Update response formatting if needed
3. Add new endpoints only if required
4. Update API documentation

## Phase 7: Performance Optimization
**Goal:** Verify improvements and tune as needed

**Steps:**
1. Run EXPLAIN ANALYZE on all major queries
2. Verify indexes are being used
3. Load test critical endpoints
4. Adjust indexes if needed
5. Add caching if applicable

## Phase 8: Cleanup
**Goal:** Remove old code, update documentation

**Steps:**
1. Remove deprecated/unused code
2. Update code comments
3. Update API documentation
4. Update database schema documentation
5. Document new patterns for future developers

## Testing Strategy for Each Phase
- Unit tests: [what to test]
- Integration tests: [what to test]
- Manual testing: [what to verify]
- Rollback testing: [verify rollback works]

## Success Metrics
- [ ] No JSONB scan errors in logs
- [ ] All API endpoints return correct responses
- [ ] Query performance improved by [X]%
- [ ] No duplicate/redundant queries
- [ ] All tests passing
- [ ] Code follows project conventions
- [ ] Documentation updated

## Risk Mitigation
- Risk: [potential issue] → Mitigation: [how to handle]
- Risk: [potential issue] → Mitigation: [how to handle]

## Timeline
- Phase 1: [estimate]
- Phase 2: [estimate]
- [etc.]
- Total: [total estimate]
```

---

## 📋 PHASE 3: IMPLEMENTATION GUIDELINES

### Step 3.1: Fix JSONB Scanning (Immediate Priority)

**Goal:** Stop the `unsupported Scan, storing driver.Value type []uint8 into type *map[string]interface {}` error.

**Research Required:**
1. Find where the conversation model/struct is defined
2. Identify how metadata field is currently typed
3. Check if Scanner/Valuer interfaces are implemented

**Implementation Pattern:**

1. **Create Custom JSONB Type**
   - Location: Create in the same package where models are defined (DO NOT hardcode package name)
   - Name it according to project conventions (e.g., if project uses `PascalCase`, use `Metadata`; if `snake_case`, use `metadata_type`)
   - Implement both `sql.Scanner` and `driver.Valuer` interfaces
   - Handle nil values correctly
   - Handle empty JSON object as default
   - Add proper error handling

2. **Update Model Definition**
   - Find the struct representing conversations table
   - Change the metadata field from `map[string]interface{}` to your custom type
   - Ensure GORM tag specifies `type:jsonb`
   - Add default value in GORM tag: `default:'{}'`

3. **Test Immediately**
   - Run the app and trigger the same flow (click chat button on car details)
   - Verify scan errors disappear from logs
   - Verify conversation creation still works
   - Verify metadata is stored and retrieved correctly

**DO NOT:**
- Change any other models yet
- Modify database schema yet
- Change any queries yet
- Create new API endpoints

**Success Criteria:**
- No scan errors in logs
- Existing functionality works identically
- Metadata correctly stored as JSONB in database

---

### Step 3.2: Analyze and Optimize Queries

**Goal:** Eliminate duplicate and inefficient queries.

**Research Required:**
1. Review the error log and identify duplicate queries
2. Map each query to its purpose
3. Identify which queries can be combined

**Analysis Pattern:**

For each endpoint (e.g., GET /api/chat/conversations):
1. Document what queries currently execute (trace through code)
2. Document what data the endpoint needs to return
3. Design a single optimized query that gets all needed data
4. Compare before/after query count and execution time

**Example Process:**
```
Current: GET /conversations endpoint
- Queries: 5 separate queries (conversations, participants, users, messages, car details)
- Problem: N+1 query pattern
- Solution: Single query with JOINs and LATERAL subquery
- Expected improvement: 5 queries → 1 query
```

**Implementation:**
1. Create new repository method with optimized query
2. Add comprehensive comments explaining the query
3. Test that it returns same data as before
4. Update service layer to use new method
5. Remove old method only after verification
6. Document the change in roadmap

**DO NOT:**
- Copy-paste queries from example architecture without adapting to your schema
- Change column names without migration
- Assume table names without checking actual database

---

### Step 3.3: Schema Migration Strategy

**Goal:** Add missing columns and indexes without downtime.

**Safe Migration Pattern:**

**For Adding Columns:**
```
Step 1: Add column with DEFAULT and nullable
Step 2: Backfill data (UPDATE existing rows)
Step 3: Add NOT NULL constraint (after backfill complete)
Step 4: Update application code to use new column
```

**For Adding Denormalized Data (e.g., car_title to conversations):**
```
Step 1: Add car_title column as nullable VARCHAR
Step 2: Write backfill query:
        UPDATE conversations 
        SET car_title = (SELECT title FROM cars WHERE id = conversations.car_id)
        WHERE car_title IS NULL
Step 3: Verify all rows have car_title populated
Step 4: Add NOT NULL constraint
Step 5: Update Go models to include car_title field
Step 6: Update repository to populate car_title on INSERT
```

**For Adding Indexes:**
```
Use CREATE INDEX CONCURRENTLY (PostgreSQL)
- Allows index creation without locking table
- Essential for production databases
```

**Create Migration Files:**
- Use whatever migration tool the project already uses (check existing migrations folder)
- Name migrations descriptively: `YYYYMMDDHHMMSS_add_car_title_to_conversations.sql`
- Include both UP and DOWN migrations (rollback)
- Test DOWN migration in dev environment

**DO NOT:**
- Drop columns without verifying they're unused
- Change primary key types without careful planning
- Add NOT NULL constraints before backfilling data
- Run migrations on production without testing on copy first

---

### Step 3.4: Code Refactoring Pattern

**Goal:** Update code to use new schema while maintaining quality.

**Layer-by-Layer Approach:**

**1. Models Layer:**
```
For each model struct:
- Add new fields matching schema additions
- Update GORM tags (type, index, default)
- Keep old fields temporarily if migration is gradual
- Mark deprecated fields with comments
- Ensure struct tags match actual database column names
```

**2. Repository Layer:**
```
For each repository function:
- Start with most-used functions first (conversation list, send message)
- Write new optimized query based on architecture
- Create new function name: e.g., `GetUserConversationsV2`
- Keep old function temporarily
- Add extensive comments explaining query
- Use raw SQL for complex queries (better than GORM's query builder)
- Always use placeholders for values (prevent SQL injection)
- Return same data structure for backward compatibility
```

**3. Service Layer:**
```
For each service function:
- Switch to call new repository function
- Add transaction wrapping if multi-step
- Ensure error handling propagates correctly
- Keep business logic here, not in repository
- Log important operations for debugging
```

**4. Handler/Controller Layer:**
```
For each API endpoint:
- Should need minimal changes (just calling updated service)
- Verify request validation still works
- Verify response formatting unchanged (unless intentional)
- Test with actual HTTP requests
- Check authorization logic still applies
```

**Refactoring Checklist per Function:**
- [ ] Read and understand current implementation
- [ ] Write new implementation following architecture
- [ ] Add comprehensive tests
- [ ] Verify backward compatibility
- [ ] Document any breaking changes
- [ ] Update function comments
- [ ] Remove old implementation only after verification

---

### Step 3.5: Transaction Handling Pattern

**Goal:** Ensure data consistency in multi-step operations.

**When to Use Transactions:**
- Creating conversation + participants (atomic)
- Sending message + updating conversation timestamp + incrementing unread count (atomic)
- Any operation that modifies multiple tables

**Pattern to Follow:**

Look for existing transaction patterns in the codebase:
- Does project use GORM's `db.Transaction()`?
- Or manual `db.Begin()`, `tx.Commit()`, `tx.Rollback()`?
- Follow the existing pattern for consistency

**Key Principles:**
1. Keep transactions short (only DB operations, no external API calls inside)
2. Always handle errors properly (rollback on error)
3. Don't nest transactions unnecessarily
4. Log transaction boundaries for debugging

**DO NOT:**
- Make HTTP calls inside transactions
- Keep transactions open while waiting for user input
- Ignore transaction errors

---

## 📋 PHASE 4: TESTING & VERIFICATION

### Step 4.1: Create Test Plan

**Action:** Document how you'll verify each change works.

**Testing Levels:**

**1. Unit Tests (Repository Layer)**
```
For each repository function:
- Test with valid inputs → verify correct query execution
- Test with edge cases (empty results, null values)
- Test error conditions (database connection failure)
- Verify JSONB serialization/deserialization
- Mock database for isolation
```

**2. Integration Tests (Service + Repository)**
```
- Test full flow: create conversation → send message → retrieve messages
- Test transaction rollback scenarios
- Test concurrent operations (race conditions)
- Use test database with actual PostgreSQL
```

**3. API Tests (End-to-End)**
```
For each endpoint:
- Test happy path with sample data
- Test authentication/authorization
- Test error responses (404, 400, 500)
- Test pagination boundaries
- Compare response format with documentation
```

**4. Performance Tests**
```
- Use EXPLAIN ANALYZE on critical queries
- Verify indexes are used (check query plans)
- Load test with realistic data volume
- Measure query execution time before/after
- Check for N+1 query patterns (use query logging)
```

**5. Manual Testing**
```
- Click through UI: car details → chat button → send message
- Verify no errors in server logs
- Verify message appears in both sender and recipient conversations
- Verify unread counts update correctly
- Test with multiple browser sessions (concurrent users)
```

---

### Step 4.2: Verification Checklist

Before considering refactoring complete, verify:

**Functional Requirements:**
- [ ] Users can start new conversations from car details page
- [ ] Users can send messages in conversations
- [ ] Users can view their conversation list
- [ ] Users can view messages in a conversation
- [ ] Unread counts display correctly
- [ ] Last message preview shows in conversation list
- [ ] Conversations sort by recency

**Technical Requirements:**
- [ ] No JSONB scan errors in logs
- [ ] No duplicate queries (check logs)
- [ ] All queries use appropriate indexes (EXPLAIN ANALYZE)
- [ ] Transaction isolation works correctly
- [ ] API responses match expected format
- [ ] Response times are acceptable (<200ms for list, <100ms for send)

**Code Quality:**
- [ ] Follows existing project conventions
- [ ] Functions have clear comments
- [ ] Error handling is comprehensive
- [ ] No hardcoded values (use config/env vars)
- [ ] No SQL injection vulnerabilities (use placeholders)
- [ ] Logging is appropriate (errors logged, debug statements useful)

**Database:**
- [ ] Schema matches architecture design
- [ ] All necessary indexes exist
- [ ] Foreign keys enforce referential integrity
- [ ] Constraints prevent invalid data
- [ ] Migration scripts work both ways (up and down)

**Documentation:**
- [ ] API endpoints documented (request/response examples)
- [ ] Database schema documented
- [ ] Code comments explain complex logic
- [ ] README updated if setup process changed

---

## 📋 PHASE 5: DOCUMENTATION & HANDOFF

### Step 5.1: Update Documentation

**Action:** Ensure future developers can understand the system.

**Documents to Create/Update:**

1. **Database Schema Documentation**
   - Create/update `DATABASE_SCHEMA.md`
   - Include table descriptions, column purposes
   - Document indexes and their rationale
   - Include ER diagram if possible
   - Explain JSONB usage and limitations

2. **API Documentation**
   - Update endpoint documentation
   - Include request/response examples
   - Document authentication requirements
   - Note rate limits or pagination defaults
   - Include error response formats

3. **Code Architecture Documentation**
   - Create/update `ARCHITECTURE.md`
   - Explain layer separation (model, repository, service, handler)
   - Document transaction patterns used
   - Explain custom types (JSONB Scanner/Valuer)
   - Include code examples for common patterns

4. **Migration History**
   - Document what was changed and why
   - Include before/after comparisons
   - Note any breaking changes
   - Provide rollback instructions

---

### Step 5.2: Create Troubleshooting Guide

**Action:** Document common issues and solutions.

**Include:**

1. **JSONB Issues**
   - Problem: Scan error on metadata column
   - Cause: Missing Scanner/Valuer implementation
   - Solution: [reference to custom type implementation]

2. **Performance Issues**
   - Problem: Slow conversation list loading
   - Diagnosis: Check EXPLAIN ANALYZE output
   - Solution: Verify indexes exist and are being used

3. **Data Integrity Issues**
   - Problem: Orphaned messages (conversation deleted but messages remain)
   - Prevention: ON DELETE CASCADE foreign keys
   - Solution: [cleanup query if needed]

4. **Common Errors**
   - Each error message from logs with explanation and fix

---

## 🎯 FINAL IMPLEMENTATION CHECKLIST

Before considering the refactoring complete:

### Planning Phase
- [ ] Created CURRENT_STATE_ANALYSIS.md with thorough codebase analysis
- [ ] Created CHAT_REFACTORING_ROADMAP.md with detailed migration plan
- [ ] Identified all files that need modification
- [ ] Documented all API endpoints and their contracts
- [ ] Listed all database queries and their purposes
- [ ] Identified breaking vs non-breaking changes

### Implementation Phase
- [ ] Fixed JSONB scanning issue (custom Scanner/Valuer)
- [ ] Created and tested database migration files
- [ ] Updated database schema to match architecture
- [ ] Refactored repository layer with optimized queries
- [ ] Updated model layer with new fields
- [ ] Updated service layer to use new repository methods
- [ ] Verified API layer still works correctly
- [ ] Added appropriate indexes to database
- [ ] Implemented proper transaction handling

### Testing Phase
- [ ] Written and passed unit tests for custom JSONB type
- [ ] Written and passed repository layer tests
- [ ] Written and passed service layer tests
- [ ] Written and passed API integration tests
- [ ] Performed manual testing of all user flows
- [ ] Verified query performance with EXPLAIN ANALYZE
- [ ] Load tested critical endpoints
- [ ] Tested rollback procedures

### Quality Phase
- [ ] Code follows existing project conventions
- [ ] No hardcoded values introduced
- [ ] All functions have appropriate comments
- [ ] Error handling is comprehensive
- [ ] Logging is appropriate and useful
- [ ] No security vulnerabilities introduced
- [ ] No SQL injection risks
- [ ] Memory leaks checked (especially in JSONB handling)

### Documentation Phase
- [ ] Updated/created DATABASE_SCHEMA.md
- [ ] Updated/created API documentation
- [ ] Updated/created ARCHITECTURE.md
- [ ] Created troubleshooting guide
- [ ] Documented migration process
- [ ] Added code comments to complex sections
- [ ] Updated README if necessary

### Verification Phase
- [ ] No errors in server logs during normal operation
- [ ] No JSONB scan errors
- [ ] No duplicate/unnecessary queries
- [ ] All API endpoints return correct responses
- [ ] Response times meet performance targets
- [ ] Database indexes are being used (verified with EXPLAIN)
- [ ] Concurrent operations work correctly
- [ ] Edge cases handled properly

---

## 🚨 CRITICAL REMINDERS

1. **NEVER start coding without completing Phase 1 (Discovery & Analysis)**
   - You cannot refactor what you don't understand
   - Analysis prevents breaking existing functionality
   - Roadmap prevents scope creep

2. **ALWAYS follow existing project patterns**
   - Don't introduce new frameworks/libraries without justification
   - Use existing naming conventions
   - Follow existing folder structure
   - Match existing code style

3. **PRESERVE backward compatibility when possible**
   - Keep old API response formats unless they're fundamentally broken
   - Don't break mobile apps that depend on current API
   - Provide migration path for breaking changes

4. **TEST incrementally, not at the end**
   - Test each phase before moving to next
   - Verify rollback works before deploying
   - Catch issues early when they're easy to fix

5. **DOCUMENT as you go, not at the end**
   - Update documentation when you change code
   - Future you (or other developers) will thank you
   - Documentation is part of the deliverable, not optional

---

## 📊 SUCCESS METRICS

The refactoring is complete when:

1. ✅ **Functional:** All user flows work without errors
2. ✅ **Performance:** Query count reduced, execution time improved
3. ✅ **Quality:** Code follows best practices and project conventions
4. ✅ **Maintainable:** Future developers can understand and modify the system
5. ✅ **Documented:** Schema, API, and code are well-documented
6. ✅ **Tested:** Comprehensive tests prevent regressions
7. ✅ **Scalable:** Architecture can handle growth in users and data

**Specific Targets:**
- Zero JSONB scan errors in logs
- Zero duplicate queries in common user flows
- All critical queries under 100ms execution time
- All API endpoints respond under 200ms
- Test coverage >80% for repository and service layers
- All architectural decisions documented

---

## 📝 DELIVERABLES SUMMARY

By the end of this refactoring, you should have:

1. **CURRENT_STATE_ANALYSIS.md** - Complete analysis of existing codebase
2. **CHAT_REFACTORING_ROADMAP.md** - Detailed implementation plan
3. **Refactored codebase** - Following enterprise architecture
4. **Migration scripts** - Database schema updates with up/down migrations
5. **Tests** - Comprehensive test suite
6. **DATABASE_SCHEMA.md** - Schema documentation
7. **ARCHITECTURE.md** - Code architecture documentation
8. **Updated API docs** - Endpoint documentation
9. **TROUBLESHOOTING.md** - Common issues and solutions

---

## 🎓 GUIDING PRINCIPLES

Remember these principles throughout the refactoring:

**1. Understand Before Changing**
"Weeks of coding can save you hours of planning."

**2. Test Before Trusting**
"Code that isn't tested doesn't work, even if it runs."

**3. Document Before Forgetting**
"If it's not documented, it doesn't exist."

**4. Preserve Before Breaking**
"Backward compatibility is a feature, not a constraint."

**5. Measure Before Optimizing**
"Premature optimization is the root of all evil."

**6. Review Before Merging**
"Your future self is your first code reviewer."

---

**START WITH PHASE 1: DISCOVERY & ANALYSIS**

Do not proceed to implementation until you have thoroughly analyzed the existing codebase and created detailed documentation of the current state and migration plan.

Good luck! 🚀
