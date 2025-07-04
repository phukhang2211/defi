# GitHub Book Setup Guide

## 🚀 How to Publish Your DeFi Learning Guide as a Book on GitHub

This guide will help you set up your repository to display as a beautiful, interactive book on GitHub Pages.

## 📋 Prerequisites

1. **GitHub Account**: You need a GitHub account
2. **Repository**: Create a new repository or use an existing one
3. **Git**: Git installed on your local machine

## 🛠️ Setup Steps

### Step 1: Create Your Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Name it something like `defi-learning-guide` or `odoo-to-defi`
3. Make it public (required for GitHub Pages)
4. Clone it to your local machine

### Step 2: Upload Your Content

```bash
# Clone your repository
git clone https://github.com/yourusername/defi-learning-guide.git
cd defi-learning-guide

# Copy all the files from this guide
# (README.md, 90-day-plan/, book.json, etc.)

# Add and commit your files
git add .
git commit -m "Initial commit: DeFi Learning Guide"
git push origin main
```

### Step 3: Enable GitHub Pages

You have several options for deployment. **Due to GitBook CLI compatibility issues, I recommend starting with Option C:**

#### Option A: GitBook with Node 16 (Try if you want GitBook features)
1. Go to your repository on GitHub
2. Click on **Settings** tab
3. Scroll down to **Pages** section (in left sidebar)
4. Under **Source**, select **GitHub Actions**
5. This will use the workflow in `.github/workflows/deploy-book.yml`

#### Option B: GitBook with Traditional Actions (Alternative GitBook)
1. Go to your repository on GitHub
2. Click on **Settings** tab
3. Scroll down to **Pages** section (in left sidebar)
4. Under **Source**, select **GitHub Actions**
5. Rename `.github/workflows/deploy-traditional.yml` to `.github/workflows/deploy-book.yml`
6. This uses a more compatible approach

#### Option C: Simple Jekyll (Recommended - Most Reliable)
1. Go to your repository on GitHub
2. Click on **Settings** tab
3. Scroll down to **Pages** section (in left sidebar)
4. Under **Source**, select **GitHub Actions**
5. Rename `.github/workflows/deploy-jekyll.yml` to `.github/workflows/deploy-book.yml`
6. This is the most reliable option

**Start with Option C for the most reliable deployment.**

### Step 4: Configure Repository Settings

1. In **Settings** → **General**:
   - Enable **Issues** (for community feedback)
   - Enable **Discussions** (for community support)
   - Enable **Wiki** (for additional resources)

2. In **Settings** → **Pages**:
   - Source: **GitHub Actions**
   - Your book will be available at: `https://yourusername.github.io/defi-learning-guide`

## 📚 Book Features

Once deployed, your book will have:

### **Navigation**
- **Table of Contents**: Auto-generated from SUMMARY.md
- **Search**: Full-text search across all content
- **Previous/Next**: Navigation between chapters
- **Breadcrumbs**: Show current location

### **Reading Experience**
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Dark/Light Theme**: Toggle between themes
- **Font Settings**: Adjust font size and family
- **Copy Code**: One-click code copying
- **Social Sharing**: Share chapters on social media

### **Interactive Elements**
- **Checkboxes**: For tracking progress
- **Code Highlighting**: Syntax highlighting for Solidity
- **Expandable Chapters**: Collapsible sections
- **Back to Top**: Quick navigation

## 🎨 Customization

### Update Repository Information

Edit `package.json`:
```json
{
  "repository": {
    "url": "https://github.com/yourusername/defi-learning-guide.git"
  },
  "homepage": "https://yourusername.github.io/defi-learning-guide"
}
```

### Custom Domain (Optional)

1. Buy a domain (e.g., `defi-learning.com`)
2. Add it to your repository settings
3. Update the workflow file:
```yaml
cname: your-domain.com
```

### Custom Styling

Edit `styles/website.css` to customize:
- Colors and fonts
- Layout and spacing
- Code block styling
- Navigation appearance

## 📖 Reading Your Book

### Online
- Visit: `https://yourusername.github.io/defi-learning-guide`
- Read directly in your browser
- Use search and navigation features

### Offline
- Download as PDF: `npm run pdf`
- Download as EPUB: `npm run epub`
- Download as MOBI: `npm run mobi`

### Local Development
```bash
# Install dependencies
npm install

# Serve locally
npm run serve

# Build for production
npm run build
```

## 🔄 Updating Your Book

### Add New Content
1. Create new markdown files
2. Update `SUMMARY.md` to include new chapters
3. Commit and push changes
4. GitHub Actions will automatically rebuild and deploy

### Example: Adding a New Day
```bash
# Create new day file
touch 90-day-plan/month-1/day-08.md

# Add content to the file
# Update SUMMARY.md to include the new day

# Commit and push
git add .
git commit -m "Add Day 8: Advanced Solidity Patterns"
git push origin main
```

## 🌟 Advanced Features

### Analytics
Add Google Analytics to track readers:
1. Get your tracking ID from Google Analytics
2. Add it to `book.json`:
```json
{
  "plugins": ["ga"],
  "pluginsConfig": {
    "ga": {
      "token": "UA-XXXXXXXXX-X"
    }
  }
}
```

### Comments
Add Disqus for reader comments:
```json
{
  "plugins": ["disqus"],
  "pluginsConfig": {
    "disqus": {
      "shortName": "your-disqus-shortname"
    }
  }
}
```

### Social Media
Customize social sharing:
```json
{
  "pluginsConfig": {
    "sharing": {
      "facebook": true,
      "twitter": true,
      "linkedin": true
    }
  }
}
```

## 🎯 Success Metrics

Track your book's success:
- **GitHub Stars**: Repository popularity
- **Page Views**: GitHub Pages analytics
- **Community Engagement**: Issues and discussions
- **Contributions**: Pull requests from readers

## 🆘 Troubleshooting

### Common Issues

1. **Book not building**: Check GitHub Actions logs
2. **Missing chapters**: Verify SUMMARY.md links
3. **Styling issues**: Check CSS file syntax
4. **Deployment fails**: Ensure repository is public
5. **Node.js cache errors**: Use the updated workflow files

### Workflow Issues

If you get errors like "Dependencies lock file is not found":
- Use the updated `.github/workflows/deploy-book.yml` file
- Or switch to the simple Jekyll workflow: `.github/workflows/deploy-simple.yml`

### Getting Help
- Check [GitBook documentation](https://toolchain.gitbook.com/)
- Review GitHub Actions logs
- Ask in GitHub Discussions
- Create an issue for bugs

## 🚀 Next Steps

1. **Share Your Book**: Post on social media and forums
2. **Gather Feedback**: Encourage readers to open issues
3. **Iterate**: Update based on community feedback
4. **Expand**: Add more content and features

---

**Your DeFi Learning Guide is now ready to help others transition from Odoo to DeFi!** 🎉 