#!/bin/bash


#Make sure we are in the right directory on the server
cd /var/www/

#Get the latest update from github
git pull


#Move into the Contemporary html directory
cd /var/www/html/Contemporary/

#Run xsltproc
xsltproc --xinclude /var/www/html/Contemporary/mfg-html.xsl /var/www/OERSource/Contemporary/2019-2020/index.xml 

#Add the Google Analytics code
perl /var/www/html/Contemporary/GoogleAnalytics.pl 


echo "OER Compile Successful: $(date)" >> /var/www/OERupdate.log

