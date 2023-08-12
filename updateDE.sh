#!/bin/bash


#Make sure we are in the right directory on the server
cd /var/www/

#Get the latest update from github
git pull

#Move into the DifferentialEquations html directory
cd /var/www/html/DifferentialEquations/

#Run xsltproc
xsltproc --xinclude /var/www/html/DifferentialEquations/mfg-html.xsl /var/www/OERSource/DifferentialEquations/2023-2024/update.xml 

#Add the Google Analytics code
perl /var/www/html/DifferentialEquations/GoogleAnalytics.pl 




echo "OER Compile Successful: $(date)" >> /var/www/OERupdate.log
