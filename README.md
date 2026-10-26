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

Progress (streak and quiz scores) is stored in the visitor's browser with `localStorage`.
