# Delete Auth User Edge Function

## Purpose

This Supabase Edge Function securely deletes users from Supabase Auth using admin privileges. It's called as part of the complete account deletion flow in JES-171.

## Security

- **Authentication Required**: User must be logged in with valid JWT
- **Self-Service Only**: Users can only delete their own accounts
- **Admin Privileges**: Uses `SUPABASE_SERVICE_ROLE_KEY` to delete from auth.users

## Deployment

### Prerequisites

1. Install Supabase CLI:
   ```bash
   brew install supabase/tap/supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link to your project:
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```

### Deploy the Function

```bash
cd "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
supabase functions deploy delete-auth-user
```

### Set Environment Variables

The function requires the following environment variables (automatically available in Supabase):
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key with admin privileges

These are automatically injected by Supabase when the function runs.

## Testing

### Test Locally

1. Start Supabase locally:
   ```bash
   supabase start
   ```

2. Serve the function:
   ```bash
   supabase functions serve delete-auth-user
   ```

3. Test with curl:
   ```bash
   curl -i --location --request POST 'http://localhost:54321/functions/v1/delete-auth-user' \
     --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
     --header 'Content-Type: application/json' \
     --data '{"userId":"USER_UUID_HERE"}'
   ```

### Test in Production

The function is automatically called by `LiveSettingsRepository.deleteAccount()` when a user deletes their account.

## API

### Endpoint

```
POST /functions/v1/delete-auth-user
```

### Headers

- `Authorization: Bearer <JWT_TOKEN>` - User's auth token
- `Content-Type: application/json`
- `apikey: <ANON_KEY>` - Supabase anon key

### Request Body

```json
{
  "userId": "uuid-string"
}
```

### Response

**Success (200)**:
```json
{
  "success": true,
  "message": "User successfully deleted from authentication system"
}
```

**Error (401)**:
```json
{
  "error": "Unauthorized"
}
```

**Error (403)**:
```json
{
  "error": "You can only delete your own account"
}
```

**Error (500)**:
```json
{
  "error": "Failed to delete user from authentication system",
  "details": "Error message"
}
```

## Integration

This function is called from `LiveSettingsRepository.deleteAccount()` as Step 2 of the account deletion process:

1. Delete all database data (via `delete_user_account` RPC)
2. **Delete auth user (via this Edge Function)** ← You are here
3. Sign out from Supabase
4. Clear local session
5. Clear caches

## Error Handling

If the Edge Function fails, the account deletion process continues anyway (user is signed out). This ensures users aren't stuck if the Edge Function is temporarily unavailable.

The error is logged but doesn't block the deletion:

```swift
do {
    try await deleteAuthUser(userId: userId, client: client)
    logger.info("✅ Auth user deleted")
} catch {
    logger.warning("⚠️ Failed to delete auth user (will sign out anyway): \(error.localizedDescription)")
}
```

## Monitoring

Check Edge Function logs in Supabase Dashboard:
1. Go to your project dashboard
2. Navigate to Edge Functions
3. Click on `delete-auth-user`
4. View logs and invocations

## Troubleshooting

### Function not found (404)
- Ensure function is deployed: `supabase functions list`
- Redeploy if needed: `supabase functions deploy delete-auth-user`

### Unauthorized (401)
- Check JWT token is valid
- Ensure user is logged in

### Forbidden (403)
- User is trying to delete a different user's account
- Security check is working correctly

### Internal Server Error (500)
- Check function logs in Supabase Dashboard
- Verify `SUPABASE_SERVICE_ROLE_KEY` is set correctly
- Ensure user exists in auth.users table

## Security Considerations

1. **Service Role Key**: Never expose this key in client code. It's only used server-side in the Edge Function.

2. **User Verification**: The function verifies the JWT token and ensures users can only delete their own accounts.

3. **Audit Trail**: All deletions are logged in the Edge Function logs for audit purposes.

4. **Graceful Degradation**: If the function fails, users are still signed out and their data is deleted from the database.

## Future Enhancements

1. **Email Notification**: Send confirmation email after account deletion
2. **Soft Delete**: Implement 30-day grace period before permanent deletion
3. **Data Export**: Allow users to export their data before deletion (GDPR compliance)
4. **Webhook**: Trigger webhook for external systems when account is deleted

## Related Files

- **Swift Client**: `I Do Blueprint/Domain/Repositories/Live/LiveSettingsRepository.swift`
- **Database Function**: `supabase/migrations/*_add_complete_account_deletion.sql`
- **UI**: `I Do Blueprint/Views/Settings/Sections/DangerZoneView.swift`

## Support

For issues or questions:
1. Check Supabase Edge Function logs
2. Review Swift app logs (AppLogger.repository)
3. Check Sentry for error tracking
4. Contact support if needed
