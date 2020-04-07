#!/bin/bash

export PATH=/usr/local/bin:$PATH

stop_mementoembed () {
    docker stop mementoembed
    docker rm mementoembed
}

restart_mementoembed () {
    stop_mementoembed
    docker run -d --name mementoembed -p 5550:5550 oduwsdl/mementoembed:latest
    sleep 20
}

export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
source /usr/local/bin/virtualenvwrapper.sh

post_date=$1
working_directory=$2

jekyll_story_file="/Users/smj/Unsynced-Projects/dsa-puddles/_posts/${post_date}-storygraph-bigstory.html"
small_striking_image="/Users/smj/Unsynced-Projects/dsa-puddles/assets/img/storygraph_striking_images/${post_date}.png"

if [ -n ${3+x} ]; then
    if [ "$3" == "--purge" ]; then
        rm -rf ${working_directory}
        rm ${jekyll_story_file}
        rm ${small_striking_image}
        mkdir -p ${working_directory}
    fi
fi

restart_mementoembed

workon storygraph-stories
cd /Users/smj/Unsynced-Projects/dsa-puddles

# first run
/Users/smj/Unsynced-Projects/dsa-puddles/scripts/create_storygraph_story.sh ${post_date} ${working_directory} > /Users/smj/Unsynced-Projects/dsa-puddles-logs/storygraph-biggest-`date '+%Y%m%d%H%M%S'`.log 2>&1

# # second run to potentially encourage the Internet Archive to archive some images
sleep 1800
rm ${jekyll_story_file}
restart_mementoembed
/Users/smj/Unsynced-Projects/dsa-puddles/scripts/create_storygraph_story.sh ${post_date} ${working_directory} > /Users/smj/Unsynced-Projects/dsa-puddles-logs/storygraph-biggest-`date '+%Y%m%d%H%M%S'`.log 2>&1

# # third run to potentially encourage the Internet Archive to archive some images
sleep 1800
rm ${jekyll_story_file}
restart_mementoembed
/Users/smj/Unsynced-Projects/dsa-puddles/scripts/create_storygraph_story.sh ${post_date} ${working_directory} > /Users/smj/Unsynced-Projects/dsa-puddles-logs/storygraph-biggest-`date '+%Y%m%d%H%M%S'`.log 2>&1

cd /Users/smj/Unsynced-Projects/dsa-puddles
git pull
git add ${jekyll_story_file}
git add ${small_striking_image}
git commit -m "adding storygraph story for ${post_date}"
git push

stop_mementoembed