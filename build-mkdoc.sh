#!/bin/bash
mkdocs build
git add .
git commit -m "feat(docs):update docs"
git push -f 
