#!/bin/bash

for story_date in "$@"; do
    echo "Generating story for ${story_date}"

    scripts/create_storygraph_story.sh ${story_date} ~/tmp/working-multiple-stories
    status=$?

    if [ ${status} -ne 0 ]; then
        echo "Failed to complete StoryGraph story for date ${story_date}"
    fi
done