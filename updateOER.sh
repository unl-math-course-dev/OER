#!/bin/bash

cd /var/www/

git pull

xsltproc --xinclude /var/www/html/PreCalculus/mfg-html.xsl /var/www/OERSource/PreCalc/2019-2020/update.xml 

perl /var/www/html/PreCalculus/GoogleAnalytics.pl 