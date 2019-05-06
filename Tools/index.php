<?php 
error_reporting(E_ERROR | E_PARSE); 

echo "<html>
  <head>
    <title>UNL OER Administration Panel</title>
  </head>
  <body>";

require_once "phpCAS/CAS.php";
 //Initialize phpCAS
phpCAS::client(CAS_VERSION_2_0,'shib.unl.edu',443,'/idp/profile/cas');


// For quick testing you can disable SSL validation of the CAS server.
phpCAS::setNoCasServerValidation();

if (isset($_REQUEST['logout'])) {
    phpCAS::logout();
}
if (isset($_REQUEST['login'])) {
    phpCAS::forceAuthentication();
}
// check CAS authentication
$auth = phpCAS::checkAuthentication();

if ($auth) {
$uname=phpCAS::getUser();
echo "<h1>Welcom</h1>";
$admins = array('nwakefield2');

if (in_array()){$uname , $admins
echo "You are logged in as ".$uname;
} else {
echo "You are logged in as ".$uname." but you are not allowed toa ccess this resource.  If you believe you need access please contact Nathan";

}


}  else {
                                        
    echo "<h1>Please Login</h1>";
    echo "<p><a href=\"?login=\">Login</a></p>";
}



    echo "
    
    <a href=\"index.php\">Home</a>
    
    
    <p><a href=\"?logout=\">Logout</a></p> </body>";
?>