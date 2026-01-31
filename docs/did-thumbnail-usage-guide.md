
# 📘 Using Thumbnails in Minimal Mistakes (Guide for DataInsideData™)

Thumbnails add visual clarity, reinforce one's brand, and make blogs feel polished and intentional. This guide walks you through how to use, create, and structure thumbnails across your site.

## 🧠 Why Thumbnails Matter

Thumbnails help readers:

- Quickly understand what a post or project is about
- Visually scan your blog index
- Recognize categories or themes at a glance
- Experience a more polished, professional site
- See clean previews when your posts are shared on social platforms

### **They also help**:

- Build a consistent visual identity
- Differentiate content types (DevOps, analytics, ML, tutorials, etc.)
- Reinforce your DataInsideData™ brand

## 🛠 How to Use Thumbnails in Minimal Mistakes

Minimal Mistakes supports thumbnails through front matter fields.

- Option 1 — Thumbnail for cards, lists, and related posts

```yaml
thumbnail: /assets/images/thumbnails/my-thumbnail.png
```

- Option 2 — Header image (large banner)

```yaml
header:
  image: /assets/images/thumbnails/my-header.png
```

- Option 3 — Social preview (Open Graph)

```yaml
og_image: /assets/images/thumbnails/my-social-preview.png
```

- You can use one or all three depending on the post.

## 📁 Recommended Folder Structure

Keep thumbnails organized and predictable:

```Code
assets/
  images/
    thumbnails/
      jekyll-zero-to-live.png
      coffee-weather-analysis.png
      wholesale-sql-analysis.png
      brand-logo.svg
```

This keeps your repo clean and makes linking easy.

## 📐 Recommended Sizes & Formats

- Thumbnails (card images)
  - 600 × 400 px
  - PNG or JPG
  - SVG if it's icon‑style or logo‑based
- Social previews (Open Graph)
  - 1200 × 630 px
  - PNG or JPG
  - Logos / icons
  - SVG (best for crisp scaling and transparency)

## 🎨 How to Create Thumbnails

- Styles can be mixed depending on the post type.

These options fit my brand:

1. Logo‑based thumbnails
Use your transparent logo on a solid or gradient background.

Great for:

- Announcements
- Meta posts
- Brand‑focused content

2. Title‑card thumbnails

- A clean rectangle with:
- The post title
- A short subtitle
- Your logo in a corner

### **Perfect for**

- Tutorials
- Project breakdowns
- DevOps guides

3. Icon‑based thumbnails
Use simple icons to represent categories:

- 🛠 DevOps
- ☁️ Cloud
- 📊 Analytics
- 🧪 Experiments
- 🔍 SQL

4. Screenshot‑based thumbnails
Use a cropped screenshot of:

- A chart
- A terminal
- A diagram
- A UI

### **Great for**

- Data analysis
- Dashboards
- Visual walkthroughs

## 🧪 Example Front Matter for a Post

```yaml
---
title: "From Zero to Live: Jekyll + GitHub Pages + Route 53"
layout: single
thumbnail: /assets/images/thumbnails/jekyll-zero-to-live.png
header:
  image: /assets/images/thumbnails/jekyll-zero-to-live-header.png
og_image: /assets/images/thumbnails/jekyll-zero-to-live-social.png
---
```

## 🧪 Example Front Matter for a Project

```yaml
---
title: "Coffee Weather Analysis for Coffee Producers"
layout: single
thumbnail: /assets/images/thumbnails/coffee-weather.png
og_image: /assets/images/thumbnails/coffee-weather-social.png
---
```

## 🌐 Optional: Social Sharing Setup

Add this to your _config.yml if you want consistent social previews:

```yaml
defaults:
  - scope:
      path: ""
      type: posts
    values:
      og_image: /assets/images/thumbnails/default-social.png
```

This ensures every post has a fallback preview image.

## 🎯 Final Notes

You don’t need thumbnails for every post — use them where they add clarity.

- Consistency matters more than complexity.
- SVGs are perfect for your logo and icon‑style thumbnails.
- PNGs are best for screenshots or title cards.