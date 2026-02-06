#!/bin/bash
# One-liner for quick pushes
git add . && \
git commit -m "$1" && \
git push https://oauth2:glpat-MKSU1G1GCocTdCtGz-VlB286MQp1Omd5aHc5Cw.01.120tu1inv@gitlab.com/ruby-telegem/telegem.git HEAD:feature1