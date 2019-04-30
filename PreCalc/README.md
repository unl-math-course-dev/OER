# OER

The folder HTML contains all the HTML and image files and is the forward facing folder for the book.



To get ti the HTML folder.
cd ~/Documents/GitHub/OER/PreCalc/HTML
from the html folder run the command
xsltproc -xinclude mfg-html.xsl ~/Documents/GitHub/OER/PreCalc/2019-2020/PreCalculusAtNebraska.xml 


For the entire book 
xsltproc -xinclude mfg-html.xsl ~/Documents/GitHub/OER/PreCalc/2019-2020/test.xml 


