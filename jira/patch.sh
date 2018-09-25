#!/bin/bash
pwd|\
echo "Delete atlassian-extras-3.2.jar!"
rm -f /opt/atlassian/jira/atlassian-jira/WEB-INF/lib/atlassian-extras-3.2.jar|\
echo "Get New atlassian-extras-3.2.jar!"
wget -P /opt/atlassian/jira/atlassian-jira/WEB-INF/lib/ https://github.com/YahuiWong/Usefulfiles/raw/master/jira/atlassian-extras-3.2.jar|\
echo "Patch Done!"
