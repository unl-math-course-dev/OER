#!/bin/bash


#Make sure we are in the right directory on the server
cd /var/www/

#Get the latest update from github
git pull

#Move into the BCalc html directory
cd /var/www/html/BCalculus/

#Run xsltproc
xsltproc --xinclude /var/www/html/BCalculus/mfg-html.xsl /var/www/OERSource/BCalc/2020-2021/index.xml 

#Add the Google Analytics code
perl /var/www/html/BCalculus/GoogleAnalytics.pl 


echo "OER Compile Successful: $(date)" >> /var/www/OERupdate.log

