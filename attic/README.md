# OER

Note:  If you are working on a windows machine there is some work to do before you will be able to run any of this.  You need ot install the relevant software.  A guide is availible at http://mathbook.pugetsound.edu/doc/pnw/html/software.html  In particular, you should look at step 5, installing xsltproc


The folder mathbook contains all the mathbook xml template files that give the book it's structure.

The OERsource folder contains source files for each course
The mathbook folder contains all of the style sheets that we use to generate the HTML.  
The HTML folder contains the html webcode that resides on the server.
The Tools folder contains some tools that we have made to clean up some of our work.




Compiling the Calculus Text:

Once you have made changes and want to see a compiled version of the text you should complete the following steps.

Change into the html directory and choose the appropriate course. 
(Note:  This step is important because the html output will be generated in whatever directory you are in when 
you issue the compile commands.)

This command will change depending on your directory structure 
For macOS you will be issuing a command of the form

%First compile with this
cd ~/Documents/GitHub/OER/html/Calculus/

Now we call the command to compile the OER.  This command will change depending on your directory structure 
For macOS the command should be something like:
%Second compile with this
xsltproc -xinclude mfg-html.xsl ~/Documents/GitHub/OER/OERSource/Calc/2019-2020/update.xml 
xsltproc -xinclude mfg-html.xsl ~/Documents/GitHub/OER/OERSource/Calc/2019-2020/index.xml 
%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%
Please only worry about the following lines if you are a server administrator

In order to update to the most recent version on the mathbooks unl server you need change directories into /var/www and then run "git pull" to get the most update versions of the files.

The actual websites will be available at 
http://mathbooks-web.unl.edu/Calculus/
http://mathbooks-web.unl.edu/Contemporary/
http://mathbooks-web.unl.edu/PreCalculus/


Note to set this up I ran
git clone https://github.com/nwakefield2/OER.git www

Finally, there is a script that can be run from /var/www that handles everything including git pull, compiling, and google analytics.
./updateOER.sh


I found out that some browsers cannot display PDFs as images.  The following command will convert all PDFs in a directory to jpg files so that they can be displayed.

for i in *.pdf; do if [ -f "${i%.*}.jpg" ] || [ -f "${i%.*}.svg" ]; then echo ""; else echo "${i%.*}.jpg";  convert -density 600  "$i" "${i%.*}.jpg"; echo "*************file Created***********"; fi; done

That is

for i in \*.pdf; do if [ -f "${i%.\*}.jpg" ] || [ -f "${i%.\*}.svg" ]; then echo ""; else echo "${i%.\*}.jpg";  convert -density 600  "$i" "${i%.\*}.jpg"; echo "\*\*\*\*\*\*\*\*\*\*\*\*\*file Created\*\*\*\*\*\*\*\*\*\*\*"; fi; done


followed by 
git status
git add .
git commit
git push



I believe that LaTeX should now be working with a few more tweeks to be made.  The command to create the PDF of the 106-107 book is
	
	xsltproc -xinclude acs-latex.xsl ~/Documents/GitHub/OER/OERSource/Calc/2019-2020/index.xml
