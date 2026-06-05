# World Cup 2026 Prediction

React/Vite app for a private World Cup 2026 prediction game with Supabase auth, per-user match guesses, tournament futures, group ranking, bracket prediction, and leaderboard scoring rules.

## Local Setup

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open the URL Vite prints, usually:

```text
http://localhost:5173/worldcup-guess/
```

If that port is busy, Vite may print `5174` or another nearby port.

## Supabase Setup

1. Create a Supabase project.
2. Copy `.env.example` to `.env.local`.
3. Replace the values with your project URL and publishable key:

```bash
VITE_SUPABASE_URL=https://YOUR-PROJECT.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=YOUR-PUBLISHABLE-KEY
```

4. Run the schema in:

```text
supabase/migrations/001_worldcup_guess_schema.sql
```

5. Run the seed data in:

```text
supabase/seed.sql
```

The schema creates:

- `profiles`
- `matches`
- `players`
- `guesses`
- `player_artifacts`
- `prediction_states`

It also enables RLS, creates per-user write policies, blocks late match guesses, and creates profiles automatically when users sign up.

## Auth Redirects

In Supabase Auth settings, add your local and deployed URLs as allowed redirect URLs:

```text
http://localhost:5173/worldcup-guess/
http://localhost:5174/worldcup-guess/
https://YOUR-USERNAME.github.io/worldcup-guess/
```

For this hosted version, the deployed URL is:

```text
https://haoming-chen2006.github.io/worldcup-guess/
```

## Deploy

This source project builds to `../worldcup-guess/`, which is the static folder served by the GitHub Pages repo.

```bash
npm run build
```

Commit and push the generated `worldcup-guess/` folder to a GitHub Pages-enabled repo.

## Separate Repo

The source copy for people who want to host their own version lives at:

```text
https://github.com/haoming-chen2006/worldcup_prediction
```

The hosted page links there from the bottom-left corner.
