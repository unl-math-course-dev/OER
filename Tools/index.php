<?php 
error_reporting(E_ERROR | E_PARSE); 

echo "<html>
  <head>
    <title>UNL OER Administration Panel</title>
  </head>
  <body>";

require_once "../phpCAS/CAS.php";
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


    echo "
    
    <a href=\"index.php\">Home</a>
    
    
    <p><a href=\"?logout=\">Logout</a></p> </body>";
?>