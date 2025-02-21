# Pull remote changes and allow unrelated histories
git pull origin main --allow-unrelated-histories

# Resolve conflicts in README.md (or other files)
# Open the file, fix the conflict, and save it

# Mark the conflict as resolved
git add README.md

# Commit the merge
git commit -m "Merge remote changes and resolve conflicts in README.md"

# Push your changes
git push -u origin main