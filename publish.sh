#!/bin/bash

# Move a draft blog post into production

title=$(grep "^title:" $1 | sed 's/.*"\(.*\)".*/\1/' | tr A-Z a-z | tr ' ' - | tr -cd '[:alnum:]-_')
mv $1 _posts/$(date +%Y-%m-%d)-$title.md

