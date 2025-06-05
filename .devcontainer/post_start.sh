#!/bin/bash

# https://github.com/yegor256/0rsk/issues/152
nohup bash -c 'ruby 0rsk.rb -p $SINATRA_PORT -e development &' >$WORKSPACE_DIR/sinatra.log 2>&1

echo "Sinatra should have been started at http://localhost:$SINATRA_PORT"
