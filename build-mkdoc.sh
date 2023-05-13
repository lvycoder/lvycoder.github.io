#!/bin/bash
mkdocs build
git add site/
git commit -m "feat(docs):update docs"
git push origin lixie -f 


