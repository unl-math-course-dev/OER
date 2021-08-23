#!/bin/bash


#Make sure we are in the right directory on the server
cd /var/www/

#Get the latest update from github
git pull


#Move into the Calculus html directory
cd /var/www/html/Calculus/

#Run xsltproc
xsltproc --xinclude /var/www/html/Calculus/mfg-html.xsl /var/www/OERSource/Calc/2020-2021/index.xml 

#Add the Google Analytics code
perl /var/www/html/Calculus/GoogleAnalytics.pl 



echo "OER Compile Successful: $(date)" >> /var/www/OERupdate.log
