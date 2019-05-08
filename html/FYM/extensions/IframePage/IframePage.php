<?php
# Alert the user that this is not a valid access point to MediaWiki
# if they try to access the special pages file directly.
if ( !defined( 'MEDIAWIKI' ) ) {
	echo <<<EOT
To install this extension, put the following line in LocalSettings.php:
require_once( "\$IP/extensions/IframePage/IframePage.php" );
EOT;
	exit( 1 );
}

$wgExtensionCredits['specialpage'][] = array(
	'path' => __FILE__,
	'name' => 'IframePage',
	'author' => 'Ike Hecht for [//www.wikiworks.com WikiWorks]',
	'url' => 'https://www.mediawiki.org/wiki/Extension:IframePage',
	'descriptionmsg' => 'iframepage-desc',
	'version' => '0.2.1',
);

/**
 * An associative array containing the iframe src. Mandatory.
 * The key in this array is expected to be a simple string that will be used as the title of a
 * subpage of Special:IframePage. The value should contain the actual iframe src URL.
 * The key can be omitted. That is because navigating to Special:Iframepage will simply pull the
 * URL contained in the first value in the array.
 */
$wgIframePageSrc = array();

/**
 * If set to true, users can set path= in the call to the special page.
 * This will allow adding to the iframe path set by $wgIframePageSrc in LocalSettings.
 * There is a slight security risk in this in case the iframe source's server was compromised
 * or something, so default to false.
 * (Maybe there's an iframe "farm" out there where only some scripts are trustworthy.)
 */
$wgIframePageAllowPath = false;

$wgAutoloadClasses['SpecialIframePage'] = __DIR__ . '/SpecialIframePage.php';
$wgExtensionMessagesFiles['IframePage'] = __DIR__ . '/IframePage.i18n.php';
$wgExtensionMessagesFiles['IframePageAlias'] = __DIR__ . '/IframePage.alias.php';
$wgMessagesDirs['IframePage'] = __DIR__ . '/i18n';
$wgSpecialPages['IframePage'] = 'SpecialIframePage';

$wgResourceModules['ext.IframePage'] = array(
	'styles' => 'IframePage.css',
	'localBasePath' => __DIR__,
	'remoteExtPath' => 'IframePage',
);
