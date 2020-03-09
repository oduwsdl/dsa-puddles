#!/bin/bash

set -e
set -x

if [ -z $1 ]; then
    working_directory=`mktemp -d -t storygraph-stories-`
else
    working_directory=$1
    mkdir -p ${working_directory}
fi

echo "`date` --- using working directory ${working_directory}"

sg_date=`gdate --date="2 hours ago" '+%Y-%m-%dT%H:%M:%SZ'`
hr_sg_date=`gdate --date="2 hours ago" '+%Y-%m-%d'`
# generate mementos from storygraph with hc

if [ ! -e ${working_directory}/story-mementos.tsv ]; then
    memento_selection_cmd="hc identify mementos -i storygraph -a 1;${sg_date} -o ${working_directory}/story-mementos.tsv -cs mongodb://localhost/csStoryGraph"
    echo "`date` --- executing command::: ${memento_selection_cmd}"
    $memento_selection_cmd
else
    echo "already discovered ${working_directory}/story-mementos.tsv so moving on to next command..."
fi

# generate image analysis for story image

if [ ! -e ${working_directory}/imagedata.json ]; then
    image_analysis_cmd="hc report image-data -i mementos -a ${working_directory}/story-mementos.tsv -cs mongodb://localhost/csStoryGraph -o ${working_directory}/imagedata.json"
    echo "`date` --- executing command::: ${image_analysis_cmd}"
    ${image_analysis_cmd}
else
    echo "already discovered ${working_directory}/imagedata.json so moving on to next command..."
fi

# sort by publication date
if [ ! -e ${working_directory}/sorted-story-mementos.tsv ]; then
    echo "`date` --- executing command:::"
    hc order pubdate-else-memento-datetime -i mementos -a ${working_directory}/story-mementos.tsv -o ${working_directory}/sorted-story-mementos.tsv -cs mongodb://localhost/csStoryGraph
else
    echo "already discovered ${working_directory}/sorted-story-mementos.tsv so moving on to next command..."
fi

# generate story JSON for raintale with hc

if [ ! -e ${working_directory}/raintale-story.json ]; then
    echo "`date` --- executing command:::"
    hc synthesize raintale-story -i mementos -a ${working_directory}/story-mementos.tsv -o ${working_directory}/raintale-story.json -cs mongodb://localhost/csStoryGraph --imagedata ${working_directory}/imagedata.json --title "StoryGraph Biggest Story ${hr_sg_date}"
else
    echo "already discovered ${working_directory}/raintale-story.json so moving on to next command..."
fi

# tellstory using story JSON, save to _posts
post_date=`date '+%Y-%m-%d'`
tellstory -i ${working_directory}/raintale-story.json --storyteller template --story-template raintale-templates/storygraph-story.html -o _posts/${post_date}-storygraph-bigstory.html

# commit
# push