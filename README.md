# OER

The folder mathbook contains all the mathbook xml template files that give the book it's structure.

The source folder contains source files for each course
The HTML folder contains the html webcode that resides on the server.




Compiling the Calculus Text
xsltproc -xinclude mfg-html.xsl ~/Documents/GitHub/OER/OERSource/Calc/2019-2020/update.xml 


In order to update to the most recent version on the mathbooks unl server you need to run
git clone https://github.com/nwakefield2/OER.git www

From within /var/www run git pull to get the most update versions of the files.