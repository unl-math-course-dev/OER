#!/bin/bash


#Make sure we are in the right directory on the server
cd /var/www/

#Get the latest update from github
git pull

#Move into the MultiVarCalc html directory
cd /var/www/html/MultiVarCalc/

#Run xsltproc
xsltproc --xinclude /var/www/html/MultiVarCalc/mfg-html.xsl /var/www/OERSource/MultiVarCalc/2022-2023/update.xml 

#Add the Google Analytics code
perl /var/www/html/MultiVarCalc/GoogleAnalytics.pl 




echo "OER Compile Successful: $(date)" >> /var/www/OERupdate.log
