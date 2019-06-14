# OER

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

cd ~/Documents/GitHub/OER/html/PreCalculus/

Now we call the command to compile the OER.  This command will change depending on your directory structure 
For macOS the command should be something like:

xsltproc -xinclude mfg-html.xsl ~/Documents/GitHub/OER/OERSource/PreCalc/2019-2020/update.xml 

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

I believe that LaTeX should now be working with a few more tweeks to be made.  The command to create the PDF of the 106-107 book is
	
	xsltproc -xinclude acs-latex.xsl ~/Documents/GitHub/OER/OERSource/Calc/2019-2020/index.xml
