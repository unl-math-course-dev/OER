# OER

The folder HTML contains all the HTML and image files and is the forward facing folder for the book



from the html folder run the command
cd ~/Documents/GitHub/OER/PreCalc/HTML
xsltproc -xinclude mfg-html.xsl /net/mathstat/Users/Fac/nwakefield2/Library/OERSource/PreCalculusAtNebraska.xml 


For the entire book 
xsltproc -xinclude mfg-html.xsl ~/Documents/GitHub/OER/PreCalc/2019-2020/test.xml 
