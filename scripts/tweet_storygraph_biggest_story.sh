#!/bin/bash

post_date=$1

# post_url=$1
# post_message=$2

human_readable_date=`/usr/local/bin/gdate --date "${post_date}" '+%A, %B %e, %Y'`
directory_date=`/usr/local/bin/gdate --date "${post_date}" '+%Y/%m/%d'`

post_url="https://oduwsdl.github.io/dsa-puddles/stories/shari/${directory_date}/storygraph_biggest_story_${post_date}/"
post_message="SHARI: StoryGraph's Biggest Story of the day for ${human_readable_date} is now available ${post_url}"

export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
source /usr/local/bin/virtualenvwrapper.sh
workon storygraph-stories
cd /Users/smj/Unsynced-Projects/dsa-puddles
python ./scripts/tweet_if_post_present.py ~/Unsynced-Projects/raintale-credentials/twitter-credentials.yaml "${post_url}" "${post_message}" > /Users/smj/Unsynced-Projects/dsa-puddles-logs/tweeting-storygraph-biggest-`date '+%Y%m%d%H%M%S'`.log 2>&1