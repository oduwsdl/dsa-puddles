#!/bin/bash

export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
source /usr/local/bin/virtualenvwrapper.sh

post_date=$1
working_directory=$2

workon storygraph-stories
cd /Users/smj/Unsynced-Projects/dsa-puddles
/Users/smj/Unsynced-Projects/dsa-puddles/scripts/create_storygraph_story.sh ${post_date} ${working_directory} > /Users/smj/Unsynced-Projects/dsa-puddles-logs/storygraph-biggest-`date '+%Y%m%d%H%M%S'`.log 2>&1
