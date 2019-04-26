# OER

The folder HTML contains all the HTML and image files and is the forward facing folder for the book



from the html folder run the command
cd ~/Documents/GitHub/OER/Calc/HTML
xsltproc -xinclude mfg-html.xsl ~/Documents/GitHub/OER/Calc/2019-2020/PreCalculusAtNebraska.xml 


For the entire book 
xsltproc -xinclude mfg-html.xsl ~/Documents/GitHub/OER/Calc/2019-2020/index.xml 
