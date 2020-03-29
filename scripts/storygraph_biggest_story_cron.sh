#!/bin/bash

workon storygraph-stories
/Users/smj/Unsynced-Projects/dsa-puddles/scripts/create_storygraph_story.sh > /Users/smj/Unsynced-Projects/dsa-puddles-logs/storygraph-biggest-`date '+%Y%m%d%H%M%S'`.log 2>&1
