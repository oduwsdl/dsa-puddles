#!/bin/bash

for story_date in "$@"; do
    scripts/create_storygraph_story.sh ${story_date}
    status=$?

    if [ ${status} -ne 0 ]; then
        echo "Failed to complete StoryGraph story for date ${story_date}"
    fi
done