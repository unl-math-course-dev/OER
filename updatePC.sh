#!/bin/bash


#Make sure we are in the right directory on the server
cd /var/www/

#Get the latest update from github
git pull

#Move into the Precalculus html directory
cd /var/www/html/PreCalculus/

#Run xsltproc
xsltproc --xinclude /var/www/html/PreCalculus/mfg-html.xsl /var/www/OERSource/PreCalc/2020-2021/update.xml 

#Add the Google Analytics code
perl /var/www/html/PreCalculus/GoogleAnalytics.pl 




echo "OER Compile Successful: $(date)" >> /var/www/OERupdate.log
