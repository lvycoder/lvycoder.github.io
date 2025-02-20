#!/bin/bash
mkdocs build
rsync -av docs/*  ~/Desktop/lixie-work/note-k8s/docs
