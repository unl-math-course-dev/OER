CASAuth(entication) Extension for Mediawiki
===========================================

A CAS Authentication extension for Mediawiki 1.27, 1.23 (and possibly
earlier).

Introduction
------------

The CASAuth extension facilitates CAS authentication for your Mediawiki
installation.  This particular code is derived from work found
[here](http://www.mediawiki.org/wiki/Extension:CASAuthentication).

This code is customized towards usage for private wikis, with the ability to
restrict access to the wiki to specific usernames.

This extension is currently written for and tested against Mediawiki 1.27 and
1.23 with phpCAS 1.3.3. However, if you find it works well against a different
version of Mediawiki and/or phpCAS, please feel free to let me know and I will
keep track of it in this README.

Installation
------------

Assuming a working CAS system, installation should take under 15 minutes.
Assume $WIKI is the directory for your wiki.

1.  Create folder $WIKI/extensions/CASAuth/

2.  Download this source code into that directory

3.  Download the [phpCAS](https://wiki.jasig.org/display/CASC/phpCAS) extension
    and extract it to the folder $WIKI/extensions/CASAuth/CAS/

4.  Add the following line to your LocalSettings.php

    ```php
    require_once( "$IP/extensions/CASAuth/CASAuth.php" );
    ```

5.  In the $WIKI/extensions/CASAuth/ directory, copy the
    CASAuthSettings.php.template file to CASAuthSettings.php and modify it for
    your environment.

6.  You should now have working CAS authentication for your wiki!

Credits
-------

Source code found here is derived from the extension found
[here](http://www.mediawiki.org/wiki/Extension:CASAuthentication), originally
written by Ioannis Yessios.
