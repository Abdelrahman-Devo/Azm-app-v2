# Supabase setup (optional)

The app works fully offline without this. Cloud accounts need your own project.

1. Create a project at https://supabase.com.
2. Copy the project URL and the **anon public** key (Settings -> API).
   Never use the `service_role` key in the app.
3. Build with the values passed at build time (nothing is stored in the repo):

   flutter build apk --release \
     --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY

   In GitHub Actions, add repository secrets `SUPABASE_URL` and
   `SUPABASE_ANON_KEY`; the workflow passes them automatically when present.
4. `schema.sql` is a draft for friends/challenges and is not used by the app yet.

Status: sign-in / sign-up are implemented. Data sync, friends, challenges and
leaderboards are **not implemented**.
