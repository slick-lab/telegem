#!/bin/bash
# Clean Git history and push fresh

echo "🧹 Cleaning Git history..."
echo "⚠️  This removes ALL Git history but keeps your code"

# Remove .git directory
rm -rf .git

# Reinitialize fresh Git
git init

# Add your files
git add .

# Commit
git commit -m "Telegem v3.0.0 
          - Major rewrite
          -introduced async 
          - removed thread_poll
          "

# Set GitLab remote
git remote add origin https://oauth2:glpat-31Bznn8ioRy85WZ5lDwGJ286MQp1Omd5aHc5Cw.01.1217avfnk@gitlab.com/ruby-telegem/telegem.git

# Force push (since new repo)
git push -u origin main --force

echo "✅ Fresh push complete!"
echo "🌐 View at: https://gitlab.com/ruby-telegem/telegem.git"