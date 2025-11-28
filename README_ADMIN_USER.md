# Creating Admin User: treebites@stanford.edu

## Quick Method (Terminal)

### Option 1: Using Supabase Management API (Recommended)

1. Get your Supabase Access Token:
   ```bash
   # Go to: https://supabase.com/dashboard/account/tokens
   # Copy your access token
   export SUPABASE_ACCESS_TOKEN=your_access_token_here
   ```

2. Run the script:
   ```bash
   ./create_admin_user_final.sh
   ```

### Option 2: Using Python Script (Requires Service Role Key)

1. Get your Service Role Key:
   ```bash
   # Go to: https://supabase.com/dashboard/project/duluhjkiqoahshxhiyqz/settings/api
   # Copy the 'service_role' key (keep it secret!)
   export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
   ```

2. Install supabase-py if needed:
   ```bash
   pip3 install supabase
   ```

3. Run the Python script:
   ```bash
   python3 create_admin_user.py
   ```

### Option 3: Manual Method (Dashboard + SQL)

1. Create auth user via Dashboard:
   - Go to: https://supabase.com/dashboard/project/duluhjkiqoahshxhiyqz/auth/users
   - Click "Add User" → "Create new user"
   - Email: `treebites@stanford.edu`
   - Password: `treebites`
   - Check "Auto Confirm User"
   - Click "Create user"

2. Run SQL to create profile:
   ```bash
   # Copy the SQL from create_admin_simple.sql
   # Or run via Supabase CLI (if linked):
   cat create_admin_simple.sql | supabase db execute
   ```

## Verification

After creating the user, verify it works:
- Email: treebites@stanford.edu
- Password: treebites
- Role: admin (has access to both administrator and student features)

You can verify in:
- Supabase Dashboard > Authentication > Users
- Supabase Dashboard > Table Editor > profiles (check role = 'admin')
