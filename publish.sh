#!/bin/bash

title=$(grep "^title:" $1 | sed 's/.*"\(.*\)".*/\1/' | tr A-Z a-z | tr ' ' -)
cp $1 _posts/$(date +%Y-%m-%d)-$title.md

