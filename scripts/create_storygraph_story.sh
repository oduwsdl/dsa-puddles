#!/bin/bash

set -e
set -x

if [ -z $1 ]; then
    working_directory=`mktemp -d -t storygraph-stories-`
else
    working_directory=$1
    mkdir -p ${working_directory}
fi

if [ -z $2 ]; then
    sg_month=`date '+%m'`
    sg_date=`date '+%d'`
    sg_year=`date '+%Y'`
else
    sg_date=`echo $2 | awk -F- '{ print $3 }'`
    sg_month=`echo $2 | awk -F- '{ print $2 }'`
    sg_year=`echo $2 | awk -F- '{ print $1 }'`
fi

echo "`date` --- using working directory ${working_directory}"
echo "`date` --- using year: ${sg_year} ; month: ${sg_month}; date: ${sg_date}"


hr_sg_date="${sg_year}-${sg_month}-${sg_date}"
echo hr_sg_date=$hr_sg_date
# generate mementos from storygraph with sgtk

if [ ! -e ${working_directory}/story-mementos.tsv ]; then

    sg_file="${working_directory}/sgtk-maxgraph-${sg_year}${sg_month}${sg_date}.json"

    echo "creating StoryGraph file ${sg_file}"

    sgtk --pretty-print -o ${sg_file} maxgraph \
        --start-mm-dd ${sg_month}-${sg_date} --end-mm-dd ${sg_month}-${sg_date} \
        --daily-maxgraph-count 1 --year ${sg_year}
    sg_url=`grep '"graph_uri":' ${sg_file} | sed 's/^[ ]*"graph_uri": "//g' | sed 's/"[,]*$//g'`

    echo "URI-Rs" > ${working_directory}/story-original-resources.tsv
    grep '"link":' ${sg_file} | sed 's/^[ ]*"link": "//g' | sed 's/"$//g' >> ${working_directory}/story-original-resources.tsv

    hc identify mementos -i original-resources -a ${working_directory}/story-original-resources.tsv -cs mongodb://localhost/csStoryGraph -o ${working_directory}/story-mementos.tsv

else
    echo "already discovered ${working_directory}/story-mementos.tsv so moving on to next command..."
fi

# perform image analysis for story image
if [ ! -e ${working_directory}/imagedata.json ]; then
    image_analysis_cmd="hc report image-data -i mementos -a ${working_directory}/story-mementos.tsv -cs mongodb://localhost/csStoryGraph -o ${working_directory}/imagedata.json"
    echo "`date` --- executing command::: ${image_analysis_cmd}"
    ${image_analysis_cmd}
else
    echo "already discovered ${working_directory}/imagedata.json so moving on to next command..."
fi

# perform sumgram analysis
if [ ! -e ${working_directory}/sumgram_data.tsv ]; then
    echo "`date` --- executing command"
    hc report terms -i mementos -a ${working_directory}/story-mementos.tsv -cs mongodb://localhost/csStoryGraph -o ${working_directory}/sumgram_data.tsv --sumgrams
else
    echo "already discovered ${working_directory}/sumgram_data.tsv so moving on to next command..."
fi

# perform entity analysis
if [ ! -e ${working_directory}/entity_data.tsv ]; then
    echo "`date` --- executing command"
    hc report entities -i mementos -a ${working_directory}/story-mementos.tsv -cs mongodb://localhost/csStoryGraph -o ${working_directory}/entity_data.tsv
else
    echo "already discovered ${working_directory}/entity_data.tsv so moving on to next command..."
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
    hc synthesize raintale-story -i mementos -a ${working_directory}/story-mementos.tsv -o ${working_directory}/raintale-story.json -cs mongodb://localhost/csStoryGraph --imagedata ${working_directory}/imagedata.json --title "StoryGraph Biggest Story ${hr_sg_date}" --termdata ${working_directory}/sumgram_data.tsv --entitydata ${working_directory}/entity_data.tsv
else
    echo "already discovered ${working_directory}/raintale-story.json so moving on to next command..."
fi

post_date=`date '+%Y-%m-%d'`
# tellstory using story JSON, save to _posts
if [ ! -e _posts/${post_date}-storygraph-bigstory.html ]; then
    echo "`date` --- executing command:::"
    tellstory -i ${working_directory}/raintale-story.json --storyteller template --story-template raintale-templates/storygraph-story.html -o _posts/${post_date}-storygraph-bigstory.html
else
    echo "already created story at _posts/${post_date}-storygraph-bigstory.html"
fi

# commit
git pull
git add _posts/${post_date}-storygraph-bigstory.html
git commit -m "adding storygraph story for ${post_date}"

# push
git push
