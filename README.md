# The Strange Quark

A fact a day for the scientifically curious. Each physics or math fact comes with a deep dive, the mathematics behind it, the history of its discovery, links to the original papers, and a short quiz.

## Run locally

It's a single static file with no build step. Open `index.html` in a browser, or serve the folder:

```sh
python -m http.server 8000
```

## Deploy

Any static host works. With GitHub Pages: push this repo, then go to **Settings → Pages**, set the source to the `main` branch and `/ (root)`, and save. The site appears at `https://<your-username>.github.io/<repo-name>/`.

## Adding facts

Facts live in the `FACTS` array inside `index.html`. Add an entry with the same fields as the others, then add its `id` to the `ORDER` array. The daily fact rotates through `ORDER`, changing at local midnight.

Equations use MathJax (loaded from jsDelivr). Write inline math as `\( ... \)` and display math as `\[ ... \]`. Don't put backticks inside fact text, because each field is a JavaScript template string.

## Accounts and community facts

Accounts, synced progress and reader submissions run on [Supabase](https://supabase.com) (the free tier is plenty). The site stays a static file, so the browser talks to Supabase directly and row-level security protects the data. Until you add your keys, the site works as before: progress stays in the visitor's browser and the account and community features are hidden.

1. Create a Supabase project.
2. In **SQL Editor**, paste in [`supabase/schema.sql`](supabase/schema.sql) and run it.
3. In **Authentication → URL Configuration**, set **Site URL** to where the site is hosted (for example `https://<your-username>.github.io/<repo-name>/`). Confirmation emails link back there. Add `http://localhost:8000` under **Redirect URLs** if you test locally.
4. In **Project Settings → API**, copy the project URL and the `anon` public key into `SUPABASE_URL` and `SUPABASE_ANON_KEY` near the top of the script in `index.html`. The anon key is meant to be public, but never put the `service_role` key in the page.
5. Sign up on the site, then make yourself an admin by running this in the SQL editor:

   ```sql
   update public.profiles set is_admin = true where username = 'your_username';
   ```

What visitors get:

- **Accounts.** Sign up with a username, email and password. Any streak and quiz scores already in that browser move into the new account.
- **Progress.** The account dialog shows the current and longest streak, days visited, a four-week calendar, quizzes passed, overall accuracy, and the best and last score and number of attempts for each quiz.
- **Submissions.** Signed-in readers can send a fact or a topic idea for a future deep dive, with an optional source link. Each person can have up to 5 waiting at once, and can withdraw a submission until it's reviewed.
- **Review.** Admins see a review queue in the Community facts section. Approved submissions appear there for everyone, credited to the submitter's username.

Without accounts, progress (streak and quiz scores) is stored in the visitor's browser with `localStorage`.
