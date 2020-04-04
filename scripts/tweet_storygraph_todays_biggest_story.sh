#!/bin/bash

post_date=`date '+%Y-%m-%d'`
human_readable_date=`date '+%A, %B %e, %Y'`
directory_date=`date '+%Y/%m/%d'`

post_url="https://oduwsdl.github.io/dsa-puddles/stories/shari/${directory_date}/storygraph_biggest_story_${post_date}/"
post_message="StoryGraph's Biggest News Story so far for Today, ${human_readable_date}, is now available. Check back at this URL, because it will be updated as the day goes on. ${post_url}"

export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
source /usr/local/bin/virtualenvwrapper.sh
workon storygraph-stories
cd /Users/smj/Unsynced-Projects/dsa-puddles
python ./scripts/tweet_if_post_present.py ~/Unsynced-Projects/dsa-credentials/twitter-credentials.yaml "${post_url}" "${post_message}" > /Users/smj/Unsynced-Projects/dsa-puddles-logs/tweeting-storygraph-biggest-`date '+%Y%m%d%H%M%S'`.log 2>&1