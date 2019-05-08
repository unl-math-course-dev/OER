<?php
# This file controls the configuration of the CASAuth extension.  The defaults
# for these options are defined in CASAuth.php, and are only defined here as
# well for the sake of documentation.  It is highly suggested you should not
# modify the CASAuth defaults unless you know what you are doing.

# Location of the phpCAS library, which is required for this Extension.  For
# more information, see https://wiki.jasig.org/display/CASC/phpCAS for more
# information.
#
# Default: $CASAuth["phpCAS"]="$IP/extensions/CASAuth/CAS";
$CASAuth["phpCAS"]="$IP/extensions/CASAuth/CAS-1.3.4";

# Location of the CAS authentication server.  You must set this to the location
# of your CAS server.  You have a CAS server right?
#
# Default: $CASAuth["Server"]="auth.example.com";
$CASAuth["Server"]="shib.unl.edu/idp/profile";

# An array of servers that are allowed to make use of the Single Sign Out
# feature.  Leave to false if you do not support this feature, of if you dont
# want to use it.  Otherwise, add servers on individual lines.
#  Example:
#    $CASAuth["LogoutServers"][]='cas-logout-01.example.com';
#    $CASAuth["LogoutServers"][]='cas-logout-02.example.com';
#
# Default: $CASAuth["LogoutServers"]=false;
$CASAuth["LogoutServers"]=false;

# Server port for communicating with the CAS server.
#
# Default: $CASAuth["Port"]=443;
$CASAuth["Port"]=443;

# URI Path to the CAS authentication service
#
# Default: $CASAuth["Url"]="/cas/";
$CASAuth["Url"]="/cas";

# CAS Version.  Available versions are "1.0" and "2.0".
#
# Default: $CASAuth["Version"]="2.0";
$CASAuth["Version"]="2.0";

# Enable auto-creation of users when signing in via CASAuth. This is required
# if the users do not already exist in the MediaWiki use database.  If accounts
# are not regularly being creating, it is recommended that this be set to false
#
# Default: $CASAuth["CreateAccounts"]=false
$CASAuth["CreateAccounts"]=true;

# If the "CreateAccounts" option is set "true", the string below is used as a
# salt for generating passwords for the users.  This salt is not used by
# the normal Mediawiki authentication and is only in place to prevent someone
# from cracking passwords in the database.  This should be changed to something
# long and horrendous to remember.
#
# Default: $CASAuth["PwdSecret"]="Secret";
$CASAuth["PwdSecret"]="Secret";

# The email domain is appended to the end of the username when the user logs
# in.  This does not affect their email address, and is for aesthetic purposes
# only.
#
# Default: $CASAuth["EmailDomain"]="example.com";
$CASAuth["EmailDomain"]="example.com";

# Restrict which users can login to the wiki?  If set to true, only the users
# in the $CASAuth["AllowedUsers"] array can login.
#
# Default: $CASAuth["RestrictUsers"]=false
$CASAuth["RestrictUsers"]=true;

# Should CAS users be logged in with the "Remember Me" option?
#
# Default: $CASAuth["RememberMe"]=true;
$CASAuth["RememberMe"]=true;

# If $CASAuth["RestrictUsers"] is set to true, the list of users below are the
# users that are allowed to login to the wiki.
#
# Default: $CASAuth["AllowedUsers"] = false;

#$CASAuth["AllowedUsers"][] = 'egilliland2 ';
#$CASAuth["AllowedUsers"][1] = 'nwakefield2';

$faculty = array('nwakefield2','pradu3','mfoss3','bharbourne1','wsmith5','alarios2','adonsig1','s-jbrumme8','shermiller2','mhomp3');
$undergrads = array('tguice2','jjanvrin2','lquiring3','sdeng5','etyler2','nbreen2','eschneider2','jott1','aschroeck2','ahaar2','mwade7','isafarik2','nbreen2');
$twentyeighteen = array('avo6','tanderson54','aganger2','tguice2','shootman-ng2','bjohnson205','nkuzmanovski2','clamb4','klee29','dlieberman2','nmeyer15','jmorris19','smyers7','lseminario-romero2','ktademy2','jvanderwoude2','cvictor2');
$grads = array('jkang3','abeemer2','rzigterman2','kkelly12','mhass3','lawadalla2','mbachmann2','abecklin2','sbecklin2','abeemer2','jbolkema2','nbuczkowski2','jbukoski2','ecanton2','ecarlson10','aconner2','mdebellevue2','gdeclerk2','ddesantis2','jdesilva2','bdrabkin2','pegging2','aeide2','afrideres2','tfunk2','sgensler2','mgheibi2','cgodfrey3','sgravelle2','s-cgrooth1','mhamidi2','mhass3','mhaver4','ahayes11','kholmes4','shong3','ehopkins2','whu4','rhuben2','aikram2','lismert2',' jjamieson2','wjamieson2','jiekang3','nkass2','jkettinger2','rkirsch2','dlacey2','slindokken2','vlongo2','amarks4','amartin22','cmayer3','dmcknight24','emcmillon2','dmcmorris3','egilliland2','mmills29','jmoeller7','jmoon16','jmurphree3','emusgrave2','gnasr2','jnir2','holson6','npackauskas2','lpai2','jpollitz2','npoppelreiter2','sprahl2','kquigley2','mreichenbach2','srobertson10','aseideman2','asetniker2','nsteinburg2','mswaidan2','ktucker4','kkelly12','avolk3','kwells4','lwhite13','awhittemore2 ','mwilliams26','awright14','cwright11','rzigterman2','fzimmitti2','s-kroeber2','jott4','mbills7');
$staff = array('isafarik2');
$instructors = array('sburns7','s-kroeber2','Rogge.Bill2','jscheffler4','seckman2','swest7','kgonzales9','jemery1','sscofield2','jdepue3');

$old = array('s-kroeber2','nsmith25','egilliland2');


$CASAuth["AllowedUsers"]= array_merge($faculty,$undergrads,$grads,$staff,$old,$twentyeighteen,$instructors);

# If a user is not allowed to login, where should we redirect them to?
#
# Default: $CASAuth["RestrictRedirect"]="http://www.example.com";
$CASAuth["RestrictRedirect"]="http://www.math.unl.edu/~nwakefield2/FYM/index.php/Main_Page";




    	

# If you dont like the uid that CAS returns (ie. it returns a number) you can
# modify the routine below to return a customized username instead.
#
# Default: Returns the username, untouched
function casNameLookup($username) {
  return $username;
}

# If your users aren't all on the same email domain you can
# modify the routine below to return their email address
#
# Default: Returns $username@EmailDomain
function casEmailLookup($username) {
  global $CASAuth;
  return $username."@".$CASAuth["EmailDomain"];
}

# If you dont like the uid that CAS returns (ie. it returns a number) you can
# modify the routine below to return a customized real name instead.
#
# Default: Returns the username, untouched
function casRealNameLookup($username) {
  return $username;
}

/*
# If you would like to use ldap to retrieve real names, you can use these
# functions instead. Remember to fill in appropriate parameters for ldap.
function casRealNameLookup($username) {
  return @casRealNameLookupFromLDAP($username);
}

function casRealNameLookupFromLDAP($username) {
  try {
    # login to the LDAP server
    $ldap = ldap_connect("host");
    $bind = ldap_bind($ldap, "bind_rdn", "bind_password");

    # look up the user's name by user id
    $result = ldap_search($ldap, "base_dn", "(uid=$username)");
    $info = ldap_get_entries($ldap, $result);

    $first_name = $info[0]["givenname"][0];
    $last_name  = $info[0]["sn"][0];

    # log out of the server
    ldap_unbind($ldap);

    $realname = $first_name . " " . $last_name;
  } catch (Exception $e) {}

  if ($realname == " " || $realname == "" || $realname == NULL) {
    $realname = $username;
  }

  return $realname;
}
*/
