git add --all
git diff-index --quiet HEAD || git commit -m "upload latest changes"
git push
PAUSE