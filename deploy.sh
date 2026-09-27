#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

set -e

cd "$(dirname "$0")"
bundle update
# rake
committed=0
trap 'if [ "${committed}" -eq 1 ]; then git reset HEAD~1; fi; rm -f config.yml; git checkout -- .gitignore' EXIT
sed -i -s 's|Gemfile.lock||g' .gitignore
cp /code/home/assets/0rsk/config.yml .
git add -f config.yml
git add Gemfile.lock
git add .gitignore
git commit -m 'config.yml for heroku'
committed=1
git push heroku master -f
