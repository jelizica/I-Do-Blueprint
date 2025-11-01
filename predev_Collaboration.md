## Executive Summary

I Do Blueprint is a macOS SwiftUI wedding planning app using MVVM, repository pattern, DI, and a V2 Store for state. Backend is Supabase (Postgres w/ RLS). Current features include budget, guest management, vendors, tasks, timeline, documents (Google Drive), visual planning, and settings. The new scoped work adds a comprehensive real-time collaboration system leveraging Supabase Realtime and Presence: real-time data sync, presence indicators, collaborative editing for guest lists/budgets/etc., activity feed, conflict resolution, multi-tenant RLS enforcement, optimistic updates with rollback, and integration into existing repository, store, and caching patterns. Expected outcomes: low-latency collaborative UX, secure multi-tenant isolation, resilient sync via NetworkRetry and caching, and visibility into collaborator activity. Complexity ~6.9/10; roles: partners, wedding planner, viewer.

## Core Functionalities

- **Real-time Collaboration**: Real-time data synchronization across devices using Supabase Realtime, presence tracking, broadcast channels, and optimistic updates for guest lists, budgets, vendors, tasks, and visual planning. (Priority: **High**)
- **Presence & Conflict Resolution**: User presence indicators, edit ownership, conflict detection and resolution strategies (last-write-wins, merge UI, or operational transforms for complex merges). (Priority: **High**)
- **Activity Feed & Notifications**: Audit trail of changes, real-time activity feed, push/local notifications for updates, and filters for change types and users. (Priority: **Medium**)
- **Secure Multi-tenant Data Access**: Enforce Row Level Security (RLS) by couple_id, secure realtime channels authorization, and ensure SSRF/file access protections for documents. (Priority: **High**)
- **Collaboration UI & UX**: UI components for collaborative editing (presence avatars, live cursors, edit locks), conflict resolution dialogs, and accessible design following WCAG. (Priority: **Medium**)



# API Documentation Reference

Make sure to leverage the following API documentation to understand how to use the respective APIs:

## https://supabase.com/docs/guides/realtime

### Realtime | Supabase Docs

Realtime

# Realtime

## Send and receive messages to connected clients.

* * *

Supabase provides a globally distributed [Realtime](https://github.com/supabase/realtime) service with the following features:

- [Broadcast](https://supabase.com/docs/guides/realtime/broadcast): Send low-latency messages between clients. Perfect for real-time messaging, database changes, cursor tracking, game events, and custom notifications.
- [Presence](https://supabase.com/docs/guides/realtime/presence): Track and synchronize user state across clients. Ideal for showing who's online, or active participants.
- [Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes): Listen to database changes in real-time.

## What can you build? [\#](https://supabase.com/docs/guides/realtime\#what-can-you-build)

- **Chat applications** \- Real-time messaging with typing indicators and online presence
- **Collaborative tools** \- Document editing, whiteboards, and shared workspaces
- **Live dashboards** \- Real-time data visualization and monitoring
- **Multiplayer games** \- Synchronized game state and player interactions
- **Social features** \- Live notifications, reactions, and user activity feeds

Check the [Getting Started](https://supabase.com/docs/guides/realtime/getting_started) guide to get started.

## Examples [\#](https://supabase.com/docs/guides/realtime\#examples)

[Multiplayer.dev\\
\\
Showcase application displaying cursor movements and chat messages using Broadcast.](https://multiplayer.dev/)

[Chat\\
\\
Supabase UI chat component using Broadcast to send message between users.](https://supabase.com/ui/docs/nextjs/realtime-chat)

[Avatar Stack\\
\\
Supabase UI avatar stack component using Presence to track connected users.](https://supabase.com/ui/docs/nextjs/realtime-avatar-stack)

[Realtime Cursor\\
\\
Supabase UI realtime cursor component using Broadcast to share users' cursors to build collaborative applications.](https://supabase.com/ui/docs/nextjs/realti...

[Overview truncated for brevity]

### Available Documentation Pages (19 total)

- https://supabase.com/docs/guides/realtime/architecture
- https://supabase.com/docs/guides/realtime
- https://supabase.com/docs/guides/realtime/pricing
- https://supabase.com/docs/guides/realtime/benchmarks
- https://supabase.com/docs/guides/realtime/postgres-changes
- https://supabase.com/docs/guides/realtime/getting_started
- https://supabase.com/docs/guides/realtime/subscribing-to-database-changes
- https://supabase.com/docs/guides/realtime/presence
- https://supabase.com/docs/guides/realtime/authorization
- https://supabase.com/docs/guides/realtime/broadcast
- https://supabase.com/docs/guides/realtime/concepts
- https://supabase.com/docs/guides/realtime/error_codes
- https://supabase.com/docs/guides/realtime/protocol
- https://supabase.com/docs/guides/realtime/quotas
- https://supabase.com/docs/guides/realtime/realtime-listening-flutter
- https://supabase.com/docs/guides/realtime/realtime-user-presence
- https://supabase.com/docs/guides/realtime/realtime-with-nextjs
- https://supabase.com/docs/guides/realtime/settings
- https://supabase.com/docs/guides/realtime/troubleshooting

---

## https://supabase.com/docs/guides/realtime/presence

### Presence | Supabase Docs

Realtime

# Presence

## Share state between users with Realtime Presence.

* * *

Let's explore how to implement Realtime Presence to track state between multiple users.

## Usage [\#](https://supabase.com/docs/guides/realtime/presence\#usage)

You can use the Supabase client libraries to track Presence state between users.

### Initialize the client [\#](https://supabase.com/docs/guides/realtime/presence\#initialize-the-client)

Go to your Supabase project's [API Settings](https://supabase.com/dashboard/project/_/settings/api) and grab the `URL` and `anon` public API key.

JavaScriptDartSwiftKotlinPython

```flex

```

### Sync and track state [\#](https://supabase.com/docs/guides/realtime/presence\#sync-and-track-state)

JavaScriptDartSwiftKotlinPython

Listen to the `sync`, `join`, and `leave` events triggered whenever any client joins or leaves the channel or changes their slice of state:

```flex

```

### Sending state [\#](https://supabase.com/docs/guides/realtime/presence\#sending-state)

You can send state to all subscribers using `track()`:

JavaScriptDartSwiftKotlinPython

```flex

```

A client will receive state from any other client that is subscribed to the same topic (in this case `room_01`). It will also automatically trigger its own `sync` and `join` event handlers.

### Stop tracking [\#](https://supabase.com/docs/guides/realtime/presence\#stop-tracking)

You can stop tracking presence using the `untrack()` method. This will trigger the `sync` and `leave` event handlers.

JavaScriptDartSwiftKotlinPython

```flex

```

## Presence options [\#](https://supabase.com/docs/guides/realtime/presence\#presence-options)

You can pass configuration options while initializing the Supabase Client.

### Presence key [\#](https://supabase.com/docs/guides/realtime/presence\#presence-key)

By default, Presence will generate a unique `UUIDv1` key on the server to track a client channel's state. If you prefer, you can provide a custom key when creating the channel...

[Overview truncated for brevity]

### Available Documentation Pages (1 total)

- https://supabase.com/docs/guides/realtime/presence

---

## https://supabase.com/docs/guides/realtime/broadcast

### Broadcast | Supabase Docs

Realtime

# Broadcast

## Send low-latency messages using the client libs, REST, or your Database.

* * *

You can use Realtime Broadcast to send low-latency messages between users. Messages can be sent using the client libraries, REST APIs, or directly from your database.

## Subscribe to messages [\#](https://supabase.com/docs/guides/realtime/broadcast\#subscribe-to-messages)

You can use the Supabase client libraries to receive Broadcast messages.

### Initialize the client [\#](https://supabase.com/docs/guides/realtime/broadcast\#initialize-the-client)

Go to your Supabase project's [API Settings](https://supabase.com/dashboard/project/_/settings/api) and grab the `URL` and `anon` public API key.

JavaScriptDartSwiftKotlinPython

```flex

```

### Receiving Broadcast messages [\#](https://supabase.com/docs/guides/realtime/broadcast\#receiving-broadcast-messages)

You can provide a callback for the `broadcast` channel to receive messages. This example will receive any `broadcast` messages that are sent to `test-channel`:

JavaScriptDartSwiftKotlinPython

```flex

```

## Send messages [\#](https://supabase.com/docs/guides/realtime/broadcast\#send-messages)

### Broadcast using the client libraries [\#](https://supabase.com/docs/guides/realtime/broadcast\#broadcast-using-the-client-libraries)

You can use the Supabase client libraries to send Broadcast messages.

JavaScriptDartSwiftKotlinPython

```flex

```

### Broadcast from the Database [\#](https://supabase.com/docs/guides/realtime/broadcast\#broadcast-from-the-database)

This feature is in Public Beta. [Submit a support ticket](https://supabase.help/) if you have any issues.

All the messages sent using Broadcast from the Database are stored in `realtime.messages` table and will be deleted after 3 days.

You can send messages directly from your database using the `realtime.send()` function:

```flex

```

It's a common use case to broadcast messages when a record is created, updated, or deleted. We provide a...

[Overview truncated for brevity]

### Available Documentation Pages (1 total)

- https://supabase.com/docs/guides/realtime/broadcast

---

## https://supabase.com/docs/guides/auth/row-level-security

### Row Level Security | Supabase Docs

Database

# Row Level Security

## Secure your data using Postgres Row Level Security.

* * *

When you need granular authorization rules, nothing beats Postgres's [Row Level Security (RLS)](https://www.postgresql.org/docs/current/ddl-rowsecurity.html).

## Row Level Security in Supabase [\#](https://supabase.com/docs/guides/database/postgres/row-level-security\#row-level-security-in-supabase)

Supabase allows convenient and secure data access from the browser, as long as you enable RLS.

RLS _must_ always be enabled on any tables stored in an exposed schema. By default, this is the `public` schema.

RLS is enabled by default on tables created with the Table Editor in the dashboard. If you create one in raw SQL or with the SQL editor, remember to enable RLS yourself:

```flex

```

RLS is incredibly powerful and flexible, allowing you to write complex SQL rules that fit your unique business needs. RLS can be combined with [Supabase Auth](https://supabase.com/docs/guides/auth) for end-to-end user security from the browser to the database.

RLS is a Postgres primitive and can provide " [defense in depth](https://en.wikipedia.org/wiki/Defense_in_depth_(computing))" to protect your data from malicious actors even when accessed through third-party tooling.

## Policies [\#](https://supabase.com/docs/guides/database/postgres/row-level-security\#policies)

[Policies](https://www.postgresql.org/docs/current/sql-createpolicy.html) are Postgres's rule engine. Policies are easy to understand once you get the hang of them. Each policy is attached to a table, and the policy is executed every time a table is accessed.

You can just think of them as adding a `WHERE` clause to every query. For example a policy like this ...

```flex

```

.. would translate to this whenever a user tries to select from the todos table:

```flex

```

## Enabling Row Level Security [\#](https://supabase.com/docs/guides/database/postgres/row-level-security\#enabling-row-level-security)

You can enable...

[Overview truncated for brevity]

### Available Documentation Pages (1 total)

- https://supabase.com/docs/guides/auth/row-level-security

---

## Tech Stack

- **Backend**: Supabase Realtime, Supabase Auth, Repository Pattern, Realtime DB Triggers, AppLogger
- **Database**: PostgreSQL Row-Level Security (RLS) Policies, activity_events (Activity Feed Table), Database migrations (Custom SQL with sqitch/pg-migrate), Postgres logical replication
- **Frontend**: SwiftUI, Optimistic UI Updates
- **Data Management**: Combine
- **Realtime**: Supabase Realtime Presence, Supabase Broadcast
- **Sync**: CRDTs (Conflict-free Replicated Data Types)
- **Error Monitoring**: Sentry
- **Security**: Security-scoped resource access (App Sandbox)
- **Networking**: NetworkRetry
- **Testing**: XCTest
- **Concurrency**: Background processing (Combine + Swift Concurrency Task)

## Development Guidelines & Best Practices

Follow these guidelines while implementing the project:

- **Placeholder Images**: Use [Unsplash](https://unsplash.com) or [Picsum Photos](https://picsum.photos) for placeholder images
  - Example: `https://source.unsplash.com/random/800x600?nature`
  - Example: `https://picsum.photos/800/600`
- **Code Quality**: Write clean, maintainable code with proper comments and documentation
- **Testing**: Test each feature thoroughly before marking it as complete
- **Commit Messages**: Use clear, descriptive commit messages that reference the task/story ID
- **Error Handling**: Implement proper error handling and user-friendly error messages
- **Responsive Design**: Ensure all UI components work across mobile, tablet, and desktop devices
- **Accessibility**: Follow WCAG guidelines for accessible UI components
- **Performance**: Optimize images, minimize bundle sizes, and implement lazy loading where appropriate
- **Security**: Never commit API keys or sensitive credentials; use environment variables
- **API & Model Versions**: Always use the latest available APIs and models unless the user explicitly specifies a different version
- **Progress Updates**: Update task checkboxes in real-time as you work through the plan

## Project Timeline

This plan lays out your roadmap in **Milestones**, **Stories** with acceptance criteria, and **Subtasks**. Follow the plan task by task and update progress on milestones, stories, and subtasks immediately as you work on them based on the legend below.

**Progress Legend:**
- `- [ ]` = To-do (not started)
- `- [~]` = In progress (currently working on)
- `- [x]` = Completed (finished)
- `- [/]` = Skipped (not needed)

Tasks are categorized by complexity to guide time estimations: XS, S, M, L, XL, XXL.

### - [ ] **Milestone 1**: **Realtime infrastructure: Supabase realtime, presence, and broadcast channels, auth integration**

- [ ] **Show Online Users** - (S): As a: presence panel user, I want to: Show online users, So that: I can see who is currently available
  - **Acceptance Criteria:**
    - [ ] User sees a live list of online users
System updates online status in real-time or near real-time
Online users count is accurate
UI gracefully handles zero users
Performance: list renders within 200ms
  - [ ] DB: Add presence table and migration (presence_table) - (M)
  - [ ] DB: Add RLS policies and realtime triggers for presence updates (table_users, table_sessions) - (M)
  - [ ] API: Implement PresenceManager in backend repository to publish/subscribe presence (presence_service) - (M)
  - [ ] API: Add realtime broadcast channel integration using Supabase Realtime (supabase_realtime) - (M)
  - [ ] Frontend: Implement PresencePanel SwiftUI component to display live list and count (presence_panel_component) - (M)
  - [ ] Frontend: Implement client-side presence subscription and repository methods (presence_repository) - (M)
  - [ ] Quality: Add unit tests for PresenceManager and repository (testing) - (M)
  - [ ] Quality: Add UI tests for PresencePanel including zero-state handling (testing) - (M)
  - [ ] Quality: Add performance tests ensuring render <200ms under typical load (testing) - (M)
  - [ ] Documentation: Update feature docs and README for presence feature (documentation) - (M)
- [ ] **Indicate Editing User** - (M): As a: presence panel user, I want to: Indicate which user is editing a shared item, So that: I can avoid conflicts and know who is making changes
  - **Acceptance Criteria:**
    - [ ] Show editing indicator next to user in real-time
Indicator clears when user stops editing
Supports multiple editors with separate indicators
No false positives on presence state
Latency under 300ms
  - [ ] DB: Add editing_state columns and activity_events migration - (M)
  - [ ] API: Implement Realtime presence channel and broadcast on edit start/stop - (M)
  - [ ] Backend: Add DB trigger to write activity_events on edit state changes - (M)
  - [ ] Client: Integrate Supabase Realtime presence subscription and CRDT merge logic - (M)
  - [ ] Frontend: Build SwiftUI PresencePanel editor-indicator component - (M)
  - [ ] Performance: Implement low-latency update path and NetworkRetry with <300ms goal - (M)
  - [ ] Quality: Add XCTest and integration tests for multi-editor scenarios and false-positive avoidance - (M)
  - [ ] Docs: Document presence protocol and RLS considerations for editing indicators - (M)
- [ ] **Presence State Sync** - (M): As a: presence panel user, I want to: Sync presence state across clients, So that: All participants have a consistent view of presence
  - **Acceptance Criteria:**
    - [ ] Presence state synchronized across all clients
Conflict handling when two updates same time
Graceful fallback when offline
Initial state loads on join within 1s
Event log of presence changes
  - [ ] DB: Create presence table migration and activity_events entries - (M)
  - [ ] INFRA: Add RLS policies for presence access and Supabase Realtime config - (M)
  - [ ] API: Implement initial state fetch and presence reconciliation endpoint - (M)
  - [ ] API: Implement realtime broadcaster and DB trigger for presence changes - (M)
  - [ ] DEV: Implement CRDT-based merge logic and conflict resolution - (M)
  - [ ] DEV: Frontend: PresencePanel component with Combine/optimistic UI and offline queue - (M)
  - [ ] DEV: Implement initial load within 1s and reconciliation on join - (M)
  - [ ] QUALITY: Integration tests for realtime sync, conflicts, and offline fallback - (M)
  - [ ] QUALITY: Performance test for initial load <1s - (M)
  - [ ] DOC: Document presence model, conflict strategy, and retry behavior - (M)
- [ ] **Presence Connection Status** - (XS): As a: presence panel user, I want to: Show connection status for presence feed, So that: Users know if the presence feed is connected
  - **Acceptance Criteria:**
    - [ ] Connection status indicator shows connected/disconnected
Automatic retry on failure
Status updates at least every 5 seconds
Accessible status semantics
No crash on network fluctuations
  - [ ] System: Add presence connection monitor service - (M)
  - [ ] API: Integrate Supabase Realtime presence client and connection hooks - (M)
  - [ ] Business: Implement retry/backoff policy for presence connection (NetworkRetry) - (M)
  - [ ] Frontend: Build PresenceStatusIndicator component (accessible semantics) - (M)
  - [ ] Integration: Emit status updates at >=5s cadence and on state change - (M)
  - [ ] Logging: Add Sentry/AppLogger hooks for connection state and failures - (M)
  - [ ] Testing: Unit tests for monitor, retry, and UI states (XCTest) - (M)
  - [ ] Docs: Document behavior, accessibility notes, and failure modes - (M)
- [ ] **Display Role Badges** - (S): As a: presence panel user, I want to: Display role badges for users, So that: Roles (admin/editor/viewer) are visible
  - **Acceptance Criteria:**
    - [ ] Role badge rendered for each user
Badge reflects current role
Accessible labels for badges (aria)
Badge styling consistent with design system
No impact on performance when many users present
  - [ ] DB: Verify user roles exist and migrations for table_user_roles - (M)
  - [ ] API: Ensure presence_service exposes role on presence payload - (M)
  - [ ] Frontend: Create RoleBadge component to render role badge variants - (M)
  - [ ] Frontend: Integrate RoleBadge into PresencePanel rendering logic - (M)
  - [ ] Frontend: Add accessible labels (aria-label) for badges and keyboard focus - (M)
  - [ ] Frontend: Implement design-system-consistent styling for badges - (M)
  - [ ] Testing: Unit tests for role mapping and RoleBadge variants - (M)
  - [ ] Testing: Integration test for presence stream with many users (performance) - (M)
  - [ ] Quality: Update docs and component usage examples for RoleBadge - (M)

### - [ ] **Milestone 2**: **Collaborative editing core: shared boards, guest list, budget with optimistic updates and conflict resolution**

- [ ] **Open Shared Board** - (S): As a: user, I want to: open a shared board, So that: I can view and begin interacting with it within the shared collaborative space
  - **Acceptance Criteria:**
    - [ ] User can open a specific shared board by ID
Board loads within 2 seconds
System handles non-existent board gracefully with appropriate error message
Board data is loaded with correct couple_id and access permissions
Real-time presence initializes when board is opened (presence indicator shows in UI)
  - [ ] API: Implement CollabBoardController.openBoard to fetch board by ID and validate permissions - (M)
  - [ ] API: Implement CollabBoardService.getBoard(coupleId, userId) with permission checks and couple_id validation - (M)
  - [ ] DB: Add/verify board access queries and RLS policies for boards and couple_id - (M)
  - [ ] Frontend: Add SharedBoardStore.loadInitialState to load board by ID and set loadingState - (M)
  - [ ] Frontend: Implement SharedBoardViewController.openBoard + connectToBoard to initialize UI and realtime subscriptions - (M)
  - [ ] Realtime: Initialize Supabase Realtime presence on board open and notify PresenceService.notifyJoin - (M)
  - [ ] Cache: Ensure Presence Cache starts tracking active collaborators when board loads - (M)
  - [ ] Testing: Create integration tests for opening board, non-existent board handling, permission denial, and load time <2s - (M)
  - [ ] Monitoring: Add Sentry timing for openBoard flow and log load durations - (M)
- [ ] **View Collaborators** - (S): As a: user, I want to: view collaborators on the shared board, So that: I can see who else is editing or viewing in real-time
  - **Acceptance Criteria:**
    - [ ] Collaborator list renders with user names and avatars
Real-time presence data reflects current viewers/editors
Access controls ensure only to authorized members can view collaborators
Presence updates debounce to avoid flicker
System handles empty collaborator list gracefully
  - [ ] DB: Add presence table migration and RLS policies - (M)
  - [ ] API: Implement getCollaborators() in PresenceController - (M)
  - [ ] API: Implement subscribePresence endpoint and Supabase Realtime wiring - (M)
  - [ ] Backend: Add PresenceStateTracker logic and debounce broadcasting - (M)
  - [ ] Frontend: Build CollaboratorListView rendering names and avatars - (M)
  - [ ] Frontend: Integrate PresenceManager to subscribe and debounce updates - (M)
  - [ ] Security: Enforce access controls in PresenceController and DB RLS - (M)
  - [ ] Cache: Implement PresenceCache sync hooks - (M)
  - [ ] QA: Add unit tests for PresenceService and PresenceManager - (M)
  - [ ] Docs: Update API and frontend docs for collaborators feature - (M)
- [ ] **Real-time Presence** - (M): As a: user, I want to: see real-time presence indicators for collaborators in a shared board, So that: I am aware of who is editing or viewing
  - **Acceptance Criteria:**
    - [ ] Presence indicators update within 1-2 seconds
Users see active status (online/offline) and last seen
Presence events integrate with back-end real-time channel
Presence data respects access permissions
System gracefully handles temporary connectivity loss during presence updates
  - [ ] DB: Add presence table/migration and RLS policies for board-level access - (M)
  - [ ] API: Implement PresenceRepository.upsertPresence / findActiveByCouple and broadcast hooks - (M)
  - [ ] API: Implement PresenceService.trackPresence, notifyJoin, notifyLeave and onSync hooks - (M)
  - [ ] API: Add realtime DB trigger + broadcast to comp_broadcast_channel for presence changes - (M)
  - [ ] Gateway: Integrate RealtimeGateway.connect/subscribeToTable for presence channels - (M)
  - [ ] Frontend: Implement PresenceManager.startTracking/stopTracking and onPresenceUpdate handlers - (M)
  - [ ] Frontend: Build UI presence indicators (online/offline, lastSeen) in Shared Board View - (M)
  - [ ] Cache: Implement PresenceCacheActor.getActive, update, invalidateExpired integration - (M)
  - [ ] Infra: Configure Supabase Realtime presence keys and logical replication slot subscriptions - (M)
  - [ ] Quality: Add unit + integration tests for presence timing, permission enforcement, and connectivity loss - (M)
  - [ ] Quality: Add e2e test simulating intermittent connectivity and reconnection handling - (M)
  - [ ] Docs: Document presence API, permissions, and client integration guidelines - (M)
- [ ] **Resolve Conflicts** - (L): As a: user, I want to: resolve conflicting edits in real-time collaborative boards, So that: changes are consistent and conflict-free
  - **Acceptance Criteria:**
    - [ ] Conflicts are detected and surfaced to users
Users can choose which version to keep per conflicting item
Auto-merge rules apply for simple conflicts with clear resolution
Audit trail records conflict resolutions
System performance remains acceptable under conflicts
  - [ ] DB: Add conflict_hints table and migration (detect/store local_state & remote_state) - (M)
  - [ ] DB: Add collaborative_locks table and lock queries support - (M)
  - [ ] API: Implement ConflictResolver.detectConflict and mergeChanges in api_collab_gateway - (M)
  - [ ] API: Integrate ConflictResolver into CollabBoardService.publishChange/applyRemoteChange - (M)
  - [ ] Worker: CRDT Sync Worker auto-merge simple conflicts using mergeOperationalTransform - (M)
  - [ ] Realtime: Emit conflict hints via Realtime Broadcast Channel when detected - (M)
  - [ ] Frontend: Surface conflict UI allowing user to choose version and preview merges - (M)
  - [ ] Frontend: Apply user's chosen resolution back to CollabBoardService and optimistic update - (M)
  - [ ] Audit: Record conflict events and resolutions to activity_events and conflict_hints - (M)
  - [ ] Performance: Add metrics, rate-limit conflict detection, and fallback LWW under load - (M)
  - [ ] Testing: Add unit tests for ConflictResolver and integration tests for end-to-end conflict flows - (M)
  - [ ] Monitoring: Add Sentry/AppLogger hooks for conflict resolution failures - (M)
- [ ] **Live Sync** - (XL): As a: guest list collaborator, I want to: live sync guest list changes in real time, So that: all collaborators see updates instantly and avoid conflicts
  - **Acceptance Criteria:**
    - [ ] Real-time updates propagate to all connected clients within 1-2 seconds
Presence indicators show who is currently viewing/editing
Edits by one user are reflected without manual refresh
System handles late joins gracefully without data loss
  - [ ] Infra: Configure Supabase Realtime & Auth keys and env vars - (M)
  - [ ] API: Add subscribeRealtime endpoint in GuestlistController to forward realtime events - (M)
  - [ ] API: Implement CollabService.syncResource to apply and broadcast patches - (M)
  - [ ] DB: Add conflict resolution triggers and activity_events integration - (M)
  - [ ] Frontend: Implement RealtimeService.connect() and subscribeToChannel() - (M)
  - [ ] Frontend: Update GuestRepository.subscribeToChanges and handleRemoteChange merge - (M)
  - [ ] Frontend: Add presence tracking and UI indicators in GuestListViewModel/RealtimeService - (M)
  - [ ] Service: Implement GuestlistService.syncFromRealtime and resolveConflict logic (use CRDT/patch) - (M)
  - [ ] Quality: Add XCTest integration tests for realtime sync, presence and late-join scenarios - (M)
  - [ ] Docs: Document realtime workflow, env setup, and troubleshooting steps - (M)
- [ ] **Conflict Resolve Prompt** - (L): As a: collaborator, I want to: resolve edit conflicts with prompts and autosave options, So that: changes are preserved and workflow remains uninterrupted
  - **Acceptance Criteria:**
    - [ ] Conflicts detected trigger non-blocking prompts
User can choose which version to keep or merge
Automatic retry applies after resolution
Conflict state is persisted for audit
  - [ ] Backend: Add conflict trigger creation and persistence for audit (createConflictTrigger) - (M)
  - [ ] API: Implement ConflictResolver.resolve(local, remote) and markResolved flow in api_collab_gateway - (M)
  - [ ] Frontend: Build non-blocking conflict prompt UI with choices keep-local/keep-remote/merge and autosave toggle - (M)
  - [ ] Frontend: Integrate prompt with GuestListViewModel.resolveConflict and GuestViewModel.onGuestEditConflict - (M)
  - [ ] Realtime: Wire Supabase Realtime events to trigger client-side detection and optimistic retry (CollabService.applyOptimisticUpdate) - (M)
  - [ ] Cache: Persist conflict state in local cache and ensure TTL invalidation (RepositoryCache ConflictResolver) - (M)
  - [ ] DB: Add ConflictResolutionTriggersSchema migration and queries for findUnresolvedByCouple and markResolved - (M)
  - [ ] Quality: Add unit/integration tests for detectConflict, threeWayMerge, prompt flow and automatic retry - (M)
- [ ] **Collaborative Edit Lock** - (M): As a: collaborator, I want to: lock the guest list while editing to prevent conflicting edits, So that: edits are serialized and data integrity maintained
  - **Acceptance Criteria:**
    - [ ] Only one user can edit at a time per guest list
Lock release on save or timeout
Notifications when lock is acquired/released
Fallback to optimistic edits if lock fails temporarily
  - [ ] DB: Create guest_list_locks table migration and TTL trigger - (M)
  - [ ] API: Add acquireLock/releaseLock endpoints in api_collab_gateway Guestlist Controller - (M)
  - [ ] Service: Implement lock management in GuestlistService with acquire/release/validate - (M)
  - [ ] Realtime: Broadcast lock state via Realtime Gateway and PresenceService events - (M)
  - [ ] Frontend: Add acquireLock/releaseLock and onLockChange handlers in CollaborativeLockManager - (M)
  - [ ] Frontend: Show lock notifications in GuestListView and fallback to optimistic edits - (M)
  - [ ] Infra: Implement lock timeout/cleanup worker using DB TTL or background task - (M)
  - [ ] Quality: Add tests for lock acquisition, release, timeout, and optimistic fallback - (M)
- [ ] **Activity Feed Entry** - (M): As a: user, I want to: see activity feed entries for guest list changes, So that: I can track who changed what and when
  - **Acceptance Criteria:**
    - [ ] Activity feed logs changes with timestamp and user
Real-time feed updates
Filter by user or action
Exportable activity history
  - [ ] DB: Create activity_events table migration (columns: id, couple_id, actor_id, action, payload, created_at) - (M)
  - [ ] DB: Add RLS policies and indexes for activity_events (ensure couple-level access) - (M)
  - [ ] DB: Add realtime DB trigger to publish guest list changes to activity_events - (M)
  - [ ] API: Implement ActivityFeedService.recordEvent(actorId, type, details) and logActivity() - (M)
  - [ ] API: Implement ActivityFeedService.fetchRecent(coupleId, limit) and formatActivity(entry) - (M)
  - [ ] API: Extend GuestlistController to call feed.logActivity on patch/update and expose GET /activities?coupleId&limit&filter - (M)
  - [ ] Realtime: Implement pushFromChange(change) in ActivityFeedService to broadcast via Supabase Realtime/Broadcast - (M)
  - [ ] Frontend: Update GuestListViewModel.handleRealtimeEvent to append activity entries and expose published activity list - (M)
  - [ ] Frontend: Build ActivityFeed SwiftUI component with realtime list, timestamp, actor display and filter controls - (M)
  - [ ] Frontend: Add filter by user/action in ViewModel and UI and wire to fetchRecent API - (M)
  - [ ] Feature: Implement export activity history (CSV/JSON) endpoint and frontend export action - (M)
  - [ ] Cache: Update ActivityFeedService in cache_repo_cache to subscribeFeedUpdates and serve cached recent entries - (M)
  - [ ] Infra: Configure Supabase Realtime presence/broadcast setup and logical replication settings - (M)
  - [ ] Quality: Add unit tests for ActivityFeedService methods (recordEvent, fetchRecent, serializeChange) - (M)
  - [ ] Quality: Add integration tests for realtime flow (DB trigger → broadcast → frontend update) - (M)
  - [ ] Quality: Add UI tests with XCTest for ActivityFeed component and filter/export flows - (M)
  - [ ] Docs: Document Activity Feed API, filters, export format and RLS requirements - (M)
- [ ] **View Collaborators Presence** - (S): As a: user, I want to: view which collaborators are currently viewing the Budget Page, So that: I can understand who isOnline and coordinate actions
  - **Acceptance Criteria:**
    - [ ] There is a visible presence indicator next to each collaborator's name in the Budget Page
Presence updates in real-time when collaborators join/leave or switch sections
Presence data respects privacy settings and only shows allowed collaborators
Presence indicators update within 1-2 seconds of changes
Presence state is persisted for the current session
  - [ ] DB: Add realtime presence table and queries (trackPresence, listActive, untrackPresence) - (M)
  - [ ] API: Implement Presence endpoints in api_collab_gateway (getPresence, trackPresence, streamPresence) - (M)
  - [ ] Service: Implement PresenceService in comp_realtime_gateway and api_collab_gateway to integrate Supabase Realtime - (M)
  - [ ] Frontend: Add presence integration in Budget View (subscribe to presence, show indicators, respect privacy) - (M)
  - [ ] Frontend Component: Build PresenceIndicator UI component and integrate with BudgetViewController - (M)
  - [ ] Cache: Persist session presence for current session and restore on app restart in cache_repo_cache - (M)
  - [ ] Testing: Add realtime presence unit and integration tests (latency, privacy, session persistence) - (M)
  - [ ] Infra/Monitoring: Add telemetry (Sentry/AppLogger) and monitoring for presence latency and errors - (M)
- [ ] **Live Budget Sync** - (M): As a: user, I want to: see live budget changes from collaborators reflected instantly, So that: I can work with up-to-date numbers and avoid conflicts
  - **Acceptance Criteria:**
    - [ ] Budget changes propagate to all connected clients in real time
Unchanged historical data remains consistent across clients
Edit conflicts are gracefully resolved or queued with notifications
Latency between edits and updates is under 1-2 seconds under nominal load
Audit trail of recent changes is visible to users
  - [ ] DB: Add budget change audit columns and activity_events entries migration - (M)
  - [ ] DB: Create realtime triggers and logical replication hooks for budget & expenses tables - (M)
  - [ ] API: Implement RealtimeGateway.subscribeToTable and broadcast channel handlers in api_collab_gateway - (M)
  - [ ] API: Implement BudgetCollabService.handleRemoteChange and syncBudget with ConflictResolver - (M)
  - [ ] Frontend: Implement BudgetSyncManager.pushLocalChange and reconcile logic - (M)
  - [ ] Frontend: Implement RealTimeSyncService.connect and handleDbChange + presence handling - (M)
  - [ ] Cache: Integrate CollaborationRepository to applyRemoteChange and saveDelta - (M)
  - [ ] Infra: Configure Supabase Realtime presence/broadcast and RLS policies for budget access - (M)
  - [ ] Testing: Add unit tests for ConflictResolver and optimistic update paths - (M)
  - [ ] Testing: Integration test for end-to-end realtime sync (latency <2s) using external_realtime and main_system - (M)
  - [ ] Quality: Add audit trail UI feed and activity_events consumption - (M)
  - [ ] Monitoring: Add Sentry/AppLogger instrumentation and latency metrics for sync paths - (M)
- [ ] **Inline Conflict Resolver** - (XL): As a: user, I want to: resolve conflicts inline when simultaneous edits occur on the Budget Page, So that: changes from multiple collaborators are merged safely without data loss
  - **Acceptance Criteria:**
    - [ ] Conflicting edits are detected and surfaced to user with clear resolution options
Merge strategy is defined (last-writer-wins or custom merge) and applied
Resolved changes are propagated to all clients in real time
No data loss occurs during conflict resolution
UI provides undo for last action within a short window
  - [ ] API: Implement ConflictResolver.detectConflict and mergeChanges logic - (M)
  - [ ] API: Add ConflictResolver.resolveLocalRemote and resolution strategy selection - (M)
  - [ ] API: Integrate ConflictResolver with BudgetCollabService.handleRemoteChange and applyOptimisticUpdate - (M)
  - [ ] DB: Add conflict records and detection queries in ConflictResolutionQueries - (M)
  - [ ] Realtime: Emit conflict events via Realtime Gateway when conflicts detected - (M)
  - [ ] Frontend: Build inline conflict UI prompt with resolution options and undo window - (M)
  - [ ] Frontend: Wire ConflictResolver to BudgetRepository and Budget View for optimistic updates - (M)
  - [ ] Infra: Add Sentry logging and AppLogger events for conflict and resolution actions - (M)
  - [ ] Quality: Add unit tests for merge strategies and integration tests for realtime conflict flow - (M)
- [ ] **Edit Lock Indicator** - (M): As a: user, I want to: see an indicator when someone is currently editing a budget item, So that: I avoid editing conflicts and coordinate with collaborators
  - **Acceptance Criteria:**
    - [ ] Edit lock is shown per budget item when someone is editing
Lock state updates in real time as users start/finish editing
Users attempting to edit a locked item are shown a helpful message
Lock ownership and time remaining are visible to all users
Locks are released if user disconnects or after timeout
  - [ ] DB: Add presence/locks table and TTL column - (M)
  - [ ] DB: Add RLS policies and migration for lock ownership - (M)
  - [ ] API: Implement acquireLock/releaseLock endpoints in Budget Controller - (M)
  - [ ] Service: Implement PresenceService.trackPresence and handleLeave logic - (M)
  - [ ] Service: Implement EditLockManager acquire/release/isLocked behaviors - (M)
  - [ ] Realtime: Subscribe/broadcast lock events via Supabase Realtime (presence & broadcast) - (M)
  - [ ] Frontend: Update PresenceManager to join/leave channels and emit local state - (M)
  - [ ] Frontend: Update BudgetCollaborationStore to observe lock state and expose lock info - (M)
  - [ ] Frontend: Implement EditLockIndicator UI to show locker, remaining TTL, and helpful messages - (M)
  - [ ] Infra: Configure Supabase Realtime presence channels and TTL cleanup jobs - (M)
  - [ ] Quality: Add unit tests for EditLockManager and PresenceService - (M)
  - [ ] Quality: Add integration tests for realtime lock propagation and disconnect handling - (M)

### - [ ] **Milestone 3**: **Activity feed and notifications: record and display changes across resources**

- [ ] **Presence Indicators** - (M): As a: admin, I want to: view presence indicators for users actively viewing or editing the dashboard, So that: I can coordinate collaborative work and reduce conflicts
  - **Acceptance Criteria:**
    - [ ] Presence indicator shows which users are currently viewing the dashboard in real-time
Presence indicator updates within 2 seconds of user activity
System handles multiple concurrent viewers without significant performance degradation
Presence data is persisted in aリアl-time feed for auditing (optional)
  - [ ] DB: Add/verify presence table and upsert + cleanup queries (ensure PresenceQueries methods) - (M)
  - [ ] API: Implement PresenceService realtime handlers and tracking logic (trackUser, untrackUser, syncPresenceJoin/Leave) - (M)
  - [ ] API: Expose presence endpoints for list/getCurrentPresence and subscribe endpoints in ActivityController - (M)
  - [ ] Infra: Configure Supabase Realtime channels and presence settings (external_realtime) and RLS policies - (M)
  - [ ] Frontend: Implement PresenceManager start/stop tracking and onPresenceUpdate integration - (M)
  - [ ] Frontend: Build PresenceIndicator and PresenceAvatar UI and PresenceStore integration - (M)
  - [ ] Quality: Add tests for <2s update latency, concurrent viewers load test, and persistence audit feed - (M)
- [ ] **Real-time Sync** - (XL): As a: admin, I want to: synchronize dashboard state across clients in real-time, So that: all users see consistent data during collaboration
  - **Acceptance Criteria:**
    - [ ] Dashboard state is synchronized across all connected clients within 1-2 seconds
Conflicts are resolved gracefully with last-writer-wins or operational transform
Offline edits are queued and applied when connectivity returns
No data loss during reconnection
  - [ ] INFRA: Configure Supabase Realtime (presence & broadcast) and enable logical replication - (M)
  - [ ] DB: Add Postgres realtime triggers and activity_feed message schema for dashboard state changes - (M)
  - [ ] API: Implement ActivityService.subscribeToRealtime(coupleId) and processIncomingChange(change) to handle broadcasts - (M)
  - [ ] API: Implement PresenceService.trackPresence and broadcastChange to manage presence and emit state updates - (M)
  - [ ] DEV: Build ConflictResolver (LWW/CRDT) with merge logic and tests - (M)
  - [ ] FRONTEND: Implement ActivityFeedStore.subscribeRealtime(), applyRemoteUpdate(update), dispatchLocalChange(change) and offline queueing - (M)
  - [ ] FRONTEND: Add RealtimeServiceAdapter.connect(channel), onDatabaseChange and presenceTrack integration - (M)
  - [ ] TESTING: Add integration tests for realtime sync (latency, conflict scenarios, offline/reconnect) using XCTest and backend integration - (M)
  - [ ] MONITORING: Integrate Sentry/AppLogger hooks for realtime failures and add metrics for sync latency - (M)
- [ ] **Conflict Resolution** - (L): As a: admin, I want to: resolve conflicting edits on the dashboard in real-time, So that: data integrity is maintained and users are informed
  - **Acceptance Criteria:**
    - [ ] Conflict detection triggers on concurrent edits
Users are notified of conflicts with guidance to resolve
Automated or user-assisted merge strategies available
Conflict resolution preserves data integrity and audit trail
  - [ ] DB: Add trigger/query to detect concurrent edits and mark conflict candidates - (M)
  - [ ] API: Implement ConflictResolver.resolveConflict(resource, local, remote) and merge strategies - (M)
  - [ ] API: Add endpoint/processIncomingChange to surface conflicts and apply merges - (M)
  - [ ] Realtime: Broadcast conflict events and presence updates to clients - (M)
  - [ ] Frontend: Build conflict notification UI and guided resolution dialog - (M)
  - [ ] Frontend: Implement optimistic UI rollback and user-assisted merge flow - (M)
  - [ ] DB: Add audit trail entries for conflict detections and resolutions - (M)
  - [ ] Testing: Unit tests for ConflictResolver and integration tests with Supabase Realtime - (M)
  - [ ] Docs: Document conflict resolution strategies and admin guidance - (M)
- [ ] **Activity Feed** - (M): As a: admin, I want to: see an activity feed of changes to dashboard-related data, So that: I can track edits and rollback if necessary
  - **Acceptance Criteria:**
    - [ ] Activity feed records timestamped changes across dashboard modules
Feed supports filtering by user, type of change, and time range
Undo/rollback capability for recent changes (where feasible)
Feed performance scales with number of edits
  - [ ] DB: Create activity_events table migration and indexes - (M)
  - [ ] DB: Add RLS policies and migration for activity_events - (M)
  - [ ] API: Implement ActivityFeedQueries listRecent/findByCouple and aggregateUnreadCounts - (M)
  - [ ] API: Implement ActivityService.publishActivity and getFeed endpoints - (M)
  - [ ] API: Implement realtime trigger and ActivityPublisher broadcastChange - (M)
  - [ ] API: Implement undo/rollback endpoint with safety checks - (M)
  - [ ] Frontend: Implement ActivityFeedRepository.fetchActivities and realtime subscription - (M)
  - [ ] Frontend: Implement ActivityViewModel.loadInitial and filtering by user/type/time - (M)
  - [ ] Frontend: Build ActivityFeedView with filtering UI and pagination - (M)
  - [ ] Infra: Configure Supabase Realtime channels and presence for activity feed - (M)
  - [ ] Quality: Add unit tests for ActivityService and ActivityFeedQueries - (M)
  - [ ] Quality: Add integration tests for realtime subscription and undo flow - (M)
  - [ ] Quality: Performance testing and add pagination/indices tuning - (M)
