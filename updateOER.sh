#!/bin/bash


#Make sure we are in the right directory on the server
cd /var/www/

#Get the latest update from github
git pull

#Move into the Precalculus html directory
#cd /var/www/html/PreCalculus/

#Run xsltproc
#xsltproc --xinclude /var/www/html/PreCalculus/mfg-html.xsl /var/www/OERSource/PreCalc/2019-2020/update.xml 

#Add the Google Analytics code
#perl /var/www/html/PreCalculus/GoogleAnalytics.pl 


#Move into the Calculus html directory
cd /var/www/html/Calculus/

#Run xsltproc
xsltproc --stringparam debug.chapter.start '0' --stringparam --xinclude /var/www/html/Calculus/mfg-html.xsl /var/www/OERSource/Calc/2019-2020/index.xml 

#Add the Google Analytics code
perl /var/www/html/Calculus/GoogleAnalytics.pl 

#Move into the Contemporary html directory
#cd /var/www/html/Contemporary/

#Run xsltproc
#xsltproc --xinclude /var/www/html/Contemporary/mfg-html.xsl /var/www/OERSource/Contemporary/2019-2020/index.xml 

#Add the Google Analytics code
#perl /var/www/html/Contemporary/GoogleAnalytics.pl 


echo "OER Compile Successful: $(date)" >> /var/www/OERupdate.log
