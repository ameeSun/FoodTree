# Setup Admin User: treebites@stanford.edu

## Step 1: Create Auth User in Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/duluhjkiqoahshxhiyqz/auth/users
2. Click **"Add User"** → **"Create new user"**
3. Fill in:
   - **Email**: `treebites@stanford.edu`
   - **Password**: `treebites`
   - **Auto Confirm User**: ✅ (Check this box - IMPORTANT!)
4. Click **"Create user"**

## Step 2: Create Admin Profile

After creating the auth user, run this SQL in Supabase Dashboard:

1. Go to: https://supabase.com/dashboard/project/duluhjkiqoahshxhiyqz/sql/new
2. Copy and paste the contents of `create_user_now.sql`
3. Click **"Run"**

Or via terminal (if you have the project linked):
```bash
cat create_user_now.sql | supabase db execute
```

## Verification

After completing both steps:
- Email: `treebites@stanford.edu`
- Password: `treebites`
- Role: `admin` (has access to both administrator and student features)

You should now be able to log in to the app!

