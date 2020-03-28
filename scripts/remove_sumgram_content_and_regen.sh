#!/bin/bash

working_directory=$1
post_date=$2

rm ${working_directory}/${post_date}/sumgram_data.tsv
rm ${working_directory}/${post_date}/raintale-story.json
rm _posts/${post_date}-storygraph-bigstory.html

./scripts/create_storygraph_story.sh ${post_date} ${working_directory}