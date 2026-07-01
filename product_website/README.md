# TechCare Product Website

Promotional website for **TechCare: Airost Inventory Manager**, a Flutter mobile application created for Airost Club. The site presents the product problem, solution, features, app screenshots, benefits, project team, and course information.

## Project structure

```text
product_website/
├── assets/images/   # Logo and mobile app screenshots
├── index.html       # Website content and structure
├── style.css        # Responsive layout and visual styling
├── script.js        # Navigation, reveal effects, and gallery controls
└── README.md
```

## Run locally

The website has no build step or backend. Open `index.html` directly in a browser, or serve the folder locally:

```bash
cd product_website
python -m http.server 8000
```

Then visit `http://localhost:8000`.

## Customization before publishing

- Replace each team member placeholder in `index.html` with a real `<img>` when team photos are ready.
- Replace `your-email@example.com` with the team's contact email.
- Screenshot references are grouped in the App Preview section and can be replaced while retaining their current filenames.
- The Google Fonts import in `style.css` gracefully falls back to system fonts if unavailable.

## Deployment

### GitHub Pages

1. Push the project to GitHub.
2. In the repository settings, open **Pages**.
3. Choose **Deploy from a branch** and select the branch/folder containing `product_website`.
4. If Pages must deploy from the repository root, copy this folder's contents to the selected publishing folder or use a GitHub Actions Pages workflow.

### Netlify

Drag the `product_website` folder into Netlify Drop, or connect the repository and set `product_website` as the publish directory. No build command is required.

### Vercel

Import the repository, set the root directory to `product_website`, and deploy as a static site. No build command is required.
