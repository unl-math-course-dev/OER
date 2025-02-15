<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2013 Robert A. Beezer

This file is part of MathBook XML.

MathBook XML is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

MathBook XML is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<!-- We choose to not include a default namespace       -->
<!-- (in particular  http://www.w3.org/1999/xhtml),     -->
<!-- even if this complicates adding namespaces onto    -->
<!-- derivatives, such as HTML destined for EPUB output -->
<!-- xmlns="http://www.w3.org/1999/xhtml"               -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    exclude-result-prefixes="b64"
    extension-element-prefixes="exsl date str"
>

<xsl:import href="./mathbook-common.xsl" />

<!-- Base 64 Library, MIT License -->
<!-- Used to encode WeBWork problems           -->
<!-- Will also read  base64_binarydatamap.xml  -->
<xsl:include href="./xslt_base64/base64.xsl"/>


<!-- We create HTML5 output.  The @doctype-system attribute will    -->
<!-- create a header in the old style that browsers will recognize  -->
<!-- as signaling HTML5.  However  xsltproc  does one better and    -->
<!-- writes the super-simple <!DOCTYPE html> header.  See all of    -->
<!-- https://stackoverflow.com/questions/3387127/                   -->
<!-- (set-html5-doctype-with-xslt)                                  -->
<!--                                                                -->
<!-- Indentation is weak, it is just strategic newlines.  This is   -->
<!-- explained late in the thread by Daniel Veillard:               -->
<!-- http://docbook-apps.oasis-open.narkive.com/tDqyEc91/           -->
<!-- (two-issues-with-xslt-processors-xsltproc-and-xalan)           -->
<!--                                                                -->
<!-- Since we write output into multiple files, likely this         -->
<!-- declaration is never active, but it serves as a model here for -->
<!-- subsequent exsl:document elements.                             -->

<xsl:output method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat" />

<!-- Parameters -->
<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!-- See more generally applicable parameters in mathbook-common.xsl file     -->

<!-- Content as Knowls -->
<!-- These parameters control if content is      -->
<!-- hidden in a knowl on first appearance       -->
<!-- The happens automatically sometimes,        -->
<!-- eg content of a footnote is always hidden   -->
<!-- Some things never are hidden,               -->
<!-- eg an entire section (too big),             -->
<!-- or a bibliographic item (pointless)         -->
<!-- These switches often control a whole group  -->
<!-- of similar items, for example the "theorem" -->
<!-- switch will similarly affect corrolaries,   -->
<!-- lemmas, etc - anything that can be proved   -->
<!-- NB: figures and tables inside of            -->
<!-- side-by-side panels are never born hidden,  -->
<!-- no matter how the switches below are set.   -->
<!-- You may elect to have entire side-by-side   -->
<!-- panels born as knowls, using the switch.    -->
<!-- PROJECT-LIKE gets own switch here           -->
<!-- "example" are set to 'yes' by default       -->
<!-- so new authors know that knowls exist       -->
<!-- "webwork" are inside "exercise" always,     -->
<!-- and they are set to 'yes' due to their      -->
<!-- overhead in rendering                       -->
<xsl:param name="html.knowl.theorem" select="'no'" />
<xsl:param name="html.knowl.proof" select="'yes'" />
<xsl:param name="html.knowl.definition" select="'no'" />
<xsl:param name="html.knowl.example" select="'yes'" />
<xsl:param name="html.knowl.project" select="'no'" />
<xsl:param name="html.knowl.task" select="'no'" />
<xsl:param name="html.knowl.list" select="'no'" />
<xsl:param name="html.knowl.remark" select="'no'" />
<xsl:param name="html.knowl.objectives" select="'no'" />
<xsl:param name="html.knowl.figure" select="'no'" />
<xsl:param name="html.knowl.table" select="'no'" />
<xsl:param name="html.knowl.listing" select="'no'" />
<xsl:param name="html.knowl.webwork.inline" select="'no'" />
<xsl:param name="html.knowl.webwork.sectional" select="'no'" />
<xsl:param name="html.knowl.exercise.inline" select="'no'" />
<xsl:param name="html.knowl.exercise.sectional" select="'yes'" />
<xsl:param name="html.knowl.exercise.solution" select="'no'" />
<!-- html.knowl.example.solution: always "yes", could be implemented -->

<!-- CSS and Javascript Servers -->
<!-- We allow processing paramteers to specify new servers   -->
<!-- or to specify the particular CSS file, which may have   -->
<!-- different color schemes.  The defaults should work      -->
<!-- fine and will not need changes on initial or casual use -->
<!-- #0 to #5 on mathbook-modern for different color schemes -->
<!-- We just like #3 as the default                          -->
<!-- N.B.:  This scheme is transitional and may change             -->
<!-- N.B.:  without warning and without any deprecation indicators -->
<xsl:param name="html.js.server"  select="'https://aimath.org'" />
<xsl:param name="html.css.server" select="'https://aimath.org'" />
<xsl:param name="html.css.file"   select="'mathbook-3.css'" />
<!-- A space-separated list of CSS URLs (points to servers or local files) -->
<xsl:param name="html.css.extra"  select="''" />

<!-- Annotation -->
<xsl:param name="html.annotation" select="''" />
<xsl:variable name="b-activate-hypothesis" select="boolean($html.annotation='hypothesis')" />

<!-- Navigation -->
<!-- Navigation may follow two different logical models:                     -->
<!--   (a) Linear, Prev/Next - depth-first search, linear layout like a book -->
<!--       Previous and Next take you to the adjacent "page"                 -->
<!--   (b) Tree, Prev/Up/Next - explicitly traverse the document tree        -->
<!--       Prev and Next remain at same depth/level in tree                  -->
<!--       Must follow a summary link to descend to finer subdivisions       -->
<!--   'linear' is the default, 'tree' is an option                          -->
<xsl:param name="html.navigation.logic"  select="'linear'" />
<!-- The "up" button is optional given the contents sidebar, default is to have it -->
<!-- An up button is very desirable if you use the tree-like logic                 -->
<xsl:param name="html.navigation.upbutton"  select="'yes'" />
<!-- There are also "compact" versions of the navigation buttons in the top right -->
<xsl:param name="html.navigation.style"  select="'full'" />

<!-- WeBWorK -->
<!-- There is no default server provided         -->
<!-- Interactions are with an "anonymous" course -->
<xsl:param name="webwork.server" select="'https://math-webwork2.unl.edu/webwork2/'"/>
<xsl:param name="webwork.version" select="'2.12'"/>
<xsl:param name="webwork.course" select="'OERSystem'" />
<xsl:param name="webwork.userID" select="'anonymous'" />
<xsl:param name="webwork.password" select="'anonymous'" />

<!-- Permalinks -->
<!-- Next to subdivision headings a "paragraph" symbol     -->
<!-- (a pilcrow) along with internationalized text         -->
<!-- ("permalink") indicates a link to that section.       -->
<!-- It is useful if you want to right-click on it to      -->
<!-- capture a link for use somewhere else.  (Similar      -->
<!-- behavior for theorems, examples, etc is planned.)     -->
<!--                                                       -->
<!-- "Permalink" is a bit of an exaggeration.  Site        -->
<!-- domain name is relative to wherever content is        -->
<!-- hosted.  We say a link is "stable" if there is        -->
<!-- an  xml:id  on the enclosing page AND an  xml:id      -->
<!-- on the subdivision (which could be the same).         -->
<!-- If you change the chunking level, then the enclosing  -->
<!-- page could change and these links will be affected.   -->
<!--                                                       -->
<!-- 'none' - no permalinks anywhere                       -->
<!-- 'stable' - only stable links (see paragraph above)    -->
<!-- 'all' - every section heading, even if links are poor -->
<xsl:param name="html.permalink"  select="'stable'" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->
<!-- Variables that affect HTML creation -->
<!-- More in the common file             -->

<!-- We leave the global $latex-processing variable    -->
<!-- set to its default value, which will manipulate   -->
<!-- clause-ending punctuation immediately after       -->
<!-- inline mathematics.  So we need to do half of the -->
<!-- job here, absorbing punctuation into mathematics  -->

<!-- This is cribbed from the CSS "max-width"-->
<!-- Design width, measured in pixels        -->
<!-- NB: the exact same value, for similar,  -->
<!-- but not identical, reasons is used in   -->
<!-- the formation of WeBWorK problems       -->
<xsl:variable name="design-width" select="'600'" />

<!-- We generally want to chunk longer HTML output -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk.level != ''">
            <xsl:value-of select="$chunk.level" />
        </xsl:when>
        <!-- HTML-specific deprecated 2015/06      -->
        <!-- But still effective if not superseded -->
        <xsl:when test="$html.chunk.level != ''">
            <xsl:value-of select="$html.chunk.level" />
        </xsl:when>
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: HTML chunk level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Local versions of navigation options -->
<!-- Fatal errors if not recognized       -->
<xsl:variable name="nav-logic">
    <xsl:choose>
        <xsl:when test="$html.navigation.logic='linear'">
            <xsl:text>linear</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.logic='tree'">
            <xsl:text>tree</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate='yes'>MBX:ERROR: 'html.navigation.logic' must be 'linear' or 'tree', not '<xsl:value-of select="$html.navigation.logic" />.'  Quitting...</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="nav-upbutton">
    <xsl:choose>
        <xsl:when test="$html.navigation.upbutton='yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.upbutton='no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate='yes'>MBX:ERROR: 'html.navigation.upbutton' must be 'yes' or 'no', not '<xsl:value-of select="$html.navigation.upbutton" />.'  Quitting...</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="nav-style">
    <xsl:choose>
        <xsl:when test="$html.navigation.style='full'">
            <xsl:text>full</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.style='compact'">
            <xsl:text>compact</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate='yes'>MBX:ERROR: 'html.navigation.style' must be 'full' or 'compact', not '<xsl:value-of select="$html.navigation.style" />.'  Quitting...</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- WW problem presentation needs the assistance of a server -->
<xsl:variable name="webwork-server">
    <xsl:if test="//webwork[@*|node()] and $webwork.server=''">
        <xsl:message>
            <xsl:text>MBX:WARNING: WeBWorK problems will not render with out the use of a properly configured server.  Provide a webwork server with --stringparam webwork.server as something like  https://webwork.bigstateu.edu</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:value-of select="$webwork.server" />
</xsl:variable>

<!-- Permalink display options -->
<xsl:variable name="permalink">
    <xsl:choose>
        <xsl:when test="$html.permalink='none'">
            <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:when test="$html.permalink='all'">
            <xsl:text>all</xsl:text>
        </xsl:when>
        <xsl:when test="$html.permalink='stable'">
            <xsl:text>stable</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate='yes'>MBX:ERROR: 'html.permalink' must be 'none', 'stable' or 'all', not '<xsl:value-of select="$html.permalink" />.'  Quitting...</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- HTML files as output -->
<xsl:variable name="file-extension" select="'.html'" />

<!-- A boolean variable for Google Custom Search Engine add-on -->
<xsl:variable name="b-google-cse" select="boolean($docinfo/search/google)" />

<!-- "presentation" mode is experimental, target        -->
<!-- is in-class presentation of a textbook             -->
<!--   (1) clickable mathematics (MathJax) at 300% zoom -->
<!-- boolean variable $b-html-presentation              -->
<xsl:param name="html.presentation" select="'no'" />
<xsl:variable name="b-html-presentation" select="$html.presentation = 'yes'" />

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <!-- temporary - while Hypothesis annotation is beta -->
    <xsl:if test="$b-activate-hypothesis">
        <xsl:call-template name="banner-warning">
            <xsl:with-param name="warning">Hypothes.is annotation is experimental</xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:apply-templates select="mathbook|pretext" mode="generic-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings" />
    <xsl:apply-templates />
</xsl:template>

<!-- We process structural nodes via chunking routine in xsl/mathbook-common.xsl    -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<!-- The xref-knowl templates run independently on content node of document tree    -->
<xsl:template match="/mathbook|/pretext">
    <xsl:apply-templates mode="chunking" />
    <xsl:apply-templates select="*[not(self::docinfo)]" mode="xref-knowl" />
</xsl:template>

<!-- However, some MBX document types do not have    -->
<!-- universal conversion, so these default warnings -->
<!-- should be overridden by supported conversions   -->
<xsl:template match="letter" mode="chunking">
    <xsl:message terminate="yes">
        <xsl:text>MBX:ERROR:  HTML conversion does not support the "letter" document type.  Quitting...</xsl:text>
    </xsl:message>
</xsl:template>

<xsl:template match="memo" mode="chunking">
    <xsl:message terminate="yes">
        <xsl:text>MBX:ERROR:  HTML conversion does not support the "memo" document type.  Quitting...</xsl:text>
    </xsl:message>
</xsl:template>

<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Read the code and documentation for "chunking" in xsl/mathbook-common.xsl  -->
<!-- This will explain document structure (not XML structure) and has the       -->
<!-- routines which employ the realizations below of two abstract templates.    -->

<!-- Default template for content of a complete page -->
<xsl:template match="&STRUCTURAL;">
    <!-- location info for debugging efforts -->
    <xsl:apply-templates select="." mode="debug-location" />
    <!-- Heading, div for this structural subdivision -->
    <xsl:variable name="ident">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <section class="{local-name(.)}" id="{$ident}">
        <xsl:apply-templates select="." mode="section-header" />
        <xsl:apply-templates />
    </section>
</xsl:template>

<!-- Modal template for content of a summary page   -->
<!-- Introduction (etc.) and conclusion realized as -->
<!-- normal, then links to subsidiary divisions     -->
<!-- occur between, as a group of button/hyperlinks -->
<xsl:template match="&STRUCTURAL;" mode="summary">
    <!-- location info for debugging efforts -->
    <xsl:apply-templates select="." mode="debug-location" />
    <!-- Heading, div for this structural subdivision -->
    <xsl:variable name="ident">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <section class="{local-name(.)}" id="{$ident}">
        <xsl:apply-templates select="." mode="section-header" />
        <xsl:apply-templates select="author|objectives|introduction|titlepage|abstract" />
        <nav class="summary-links">
            <ul>
                <xsl:apply-templates select="*" mode="summary-nav" />
            </ul>
        </nav>
        <xsl:apply-templates select="conclusion"/>
    </section>
</xsl:template>

<!-- Navigation -->
<!-- Structural nodes on a summary page  -->
<!-- become attractive button/hyperlinks -->
<xsl:template match="&STRUCTURAL;" mode="summary-nav">
    <xsl:variable name="num">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:variable name="url">
        <xsl:apply-templates select="." mode="url" />
    </xsl:variable>
    <li>
        <a href="{$url}">
            <!-- important not include codenumber span -->
            <xsl:if test="$num!=''">
                <span class="codenumber">
                    <xsl:value-of select="$num" />
                </span>
            </xsl:if>
            <!-- title is required on structural elements -->
            <span>
                <xsl:apply-templates select="." mode="title-attributes" />
                <xsl:apply-templates select="." mode="title-simple" />
            </span>
        </a>
    </li>
</xsl:template>

<!-- introduction (etc.) and conclusion get dropped -->
<xsl:template match="*" mode="summary-nav" />

<!-- ############### -->
<!-- Bits and Pieces -->
<!-- ############### -->

<!-- Header for Document Nodes -->
<!-- Every document node goes the same way, a    -->
<!-- heading followed by its subsidiary elements -->
<!-- hit with templates.  This is the header.    -->
<!-- Only "chapter" ever gets shown generically  -->
<!-- Subdivisions have titles, or not            -->
<!-- and other parts have default titles         -->
<xsl:template match="*" mode="section-header">
    <!-- The "division-name" template accomodates non-standard -->
    <!-- divisions like "exercises", "references", divisional  -->
    <!-- "introduction" and "conclusion", and "appendix".      -->
    <!-- Result is strict part -> subsubsection hierachy.      -->
    <!-- Find it in mathbook-common.xsl                        -->
    <xsl:variable name="normalized-division-name">
        <xsl:apply-templates select="." mode="division-name" />
    </xsl:variable>
    <xsl:variable name="heading-level">
        <xsl:choose>
            <xsl:when test="$normalized-division-name = 'part'">
                <xsl:text>h1</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-division-name = 'chapter'">
                <xsl:text>h1</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-division-name = 'section'">
                <xsl:text>h2</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-division-name = 'subsection'">
                <xsl:text>h3</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-division-name = 'subsubsection'">
                <xsl:text>h4</xsl:text>
            </xsl:when>
            <!-- any bug will be exposed by "division-name" template -->
            <xsl:otherwise />
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$heading-level}">
        <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="self::chapter">
                    <xsl:text>heading</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>heading hide-type</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="alt">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="header-content" />
    </xsl:element>
    <xsl:apply-templates select="." mode="permalink" />
    <xsl:if test="author">
        <p class="byline"><xsl:apply-templates select="author" mode="name-list"/></p>
    </xsl:if>
</xsl:template>

<!-- The front and back matter have their own style -->
<xsl:template match="frontmatter|backmatter" mode="section-header" />

<!-- A book or article is the top level, so the   -->
<!-- masthead might suffice, else an author can   -->
<!-- provide a frontmatter/titlepage to provide   -->
<!-- more specific information.  In either event, -->
<!-- a typical section header is out of place.    -->
<xsl:template match="book|article" mode="section-header" />

<!-- ######## -->
<!-- Headings -->
<!-- ######## -->

<!-- Both environments and sections have a "type,"         -->
<!-- a "codenumber," and a "title."  We format these       -->
<!-- consistently here with a modal template.  We can hide -->
<!-- components with classes on the enclosing "heading"    -->
<xsl:template match="*" mode="header-content">
    <span class="type">
        <xsl:apply-templates select="." mode="type-name" />
    </span>
    <span class="codenumber">
        <xsl:apply-templates select="." mode="number" />
    </span>
    <span>
        <xsl:apply-templates select="." mode="title-attributes" />
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- References and Exercises are universal subdivisions       -->
<!-- We give them a localized "type" computed from their level -->
<xsl:template match="exercises|references" mode="header-content">
    <span class="type">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id">
                <xsl:apply-templates select="." mode="division-name" />
            </xsl:with-param>
        </xsl:call-template>
    </span>
    <span class="codenumber">
        <xsl:apply-templates select="." mode="number" />
    </span>
    <span>
        <xsl:apply-templates select="." mode="title-attributes" />
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- Permalinks on section headings are configurable              -->
<!-- "stable" implies there is an xml:id on the element. However, -->
<!-- the filename will change with different chunking levels      -->
<xsl:template match="*" mode="permalink">
    <xsl:variable name="has-permalink">
        <xsl:choose>
            <xsl:when test="$permalink='none'">
                <xsl:value-of select="false()" />
            </xsl:when>
            <xsl:when test="$permalink='all'">
                <xsl:value-of select="true()" />
            </xsl:when>
            <!-- now in case of $permalink='stable' due to input sanitation -->
            <xsl:when test="not(@xml:id)">
                <xsl:value-of select="false()" />
            </xsl:when>
            <!-- now just need xml:id for the page URL, or not      -->
            <!-- NOTE: the element and the enclosure might be equal -->
            <!--       but double 'true' is not a problem           -->
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="has-id-on-enclosure" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$has-permalink='true'">
        <xsl:variable name="url">
            <xsl:apply-templates select="." mode="url" />
        </xsl:variable>
        <!-- pilchrow only  -->
        <a href="{$url}" class="permalink">
            <xsl:text>&#xb6;</xsl:text>
        </a>
    </xsl:if>
</xsl:template>

<!-- Recursively finds enclosing structural node -->
<!-- and reports if it has an xml:id on it       -->
<!-- Note: from mode="containing-filename", can we return a node-set? -->
<xsl:template match="*" mode="has-id-on-enclosure">
    <xsl:variable name="intermediate"><xsl:apply-templates select="." mode="is-intermediate" /></xsl:variable>
    <xsl:variable name="chunk"><xsl:apply-templates select="." mode="is-chunk" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true' or $chunk='true'">
            <!-- found it, is there an xml:id? -->
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="true()" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="has-id-on-enclosure" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ####################### -->
<!-- Front Matter Components -->
<!-- ####################### -->

<!-- Title Page -->
<!-- A frontmatter has no title, so we reproduce the       -->
<!-- title of the work (book or article) here              -->
<!-- NB: this could done with a "section-header" template? -->
<!-- Other divisions (eg, colophon, preface) will follow   -->
<!-- This is all within a .frontmatter class for CSS       -->
<xsl:template match="titlepage">
    <h1 class="heading">
        <span>
            <xsl:apply-templates select="." mode="title-attributes" />
            <xsl:apply-templates select="parent::frontmatter/parent::*" mode="title-full" />
        </span>
        <xsl:if test="parent::frontmatter/parent::*/subtitle">
            <span class="subtitle">
                <xsl:apply-templates select="parent::frontmatter/parent::*" mode="subtitle" />
            </span>
        </xsl:if>
    </h1>
    <!-- We list authors and editors in document order -->
    <xsl:apply-templates select="author|editor" mode="full-info"/>
    <!-- A credit is subsidiary, so follows -->
    <xsl:apply-templates select="credit" />
    <xsl:apply-templates select="date" />
</xsl:template>

<!-- A "credit" required "title" followed by an author (or several)    -->
<!-- CSS should give lesser prominence to these (versus "full" author) -->
<xsl:template match="titlepage/credit">
    <div class="credit">
        <div class="title">
            <xsl:apply-templates select="." mode="title-full"/>
        </div>
        <xsl:apply-templates select="author" mode="full-info" />
    </div>
</xsl:template>

<!-- The time element has content that is "human readable" time -->
<xsl:template match="titlepage/date">
    <time class="date">
        <xsl:apply-templates />
    </time>
</xsl:template>

<!-- Authors, Editors, Creditors -->

<!-- Authors and editors with affiliations (eg, on title page) -->
<!-- CSS does not distinguish authors from editors             -->
<xsl:template match="author|editor" mode="full-info">
    <div class="author">
        <div class="author-name">
            <xsl:apply-templates select="personname" />
            <xsl:if test="self::editor">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="." mode="type-name" />
            </xsl:if>
        </div>
        <div class="author-info">
            <xsl:if test="department">
                <xsl:apply-templates select="department" />
                <xsl:if test="department/following-sibling::*">
                    <br />
                </xsl:if>
            </xsl:if>
            <xsl:if test="institution">
                <xsl:apply-templates select="institution" />
                <xsl:if test="institution/following-sibling::*">
                    <br />
                </xsl:if>
            </xsl:if>
            <xsl:if test="email">
                <xsl:apply-templates select="email" />
                <xsl:if test="email/following-sibling::*">
                    <br />
                </xsl:if>
            </xsl:if>
        </div>
    </div>
</xsl:template>

<!-- Departments and Institutions are free-form, or sequences of lines -->
<xsl:template match="department|institution">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="department[line]|institution[line]">
    <xsl:apply-templates select="line" />
</xsl:template>

<!-- Sneak in dedication line element here as well -->
<xsl:template match="department/line|institution/line|dedication/p/line">
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::*">
        <br />
    </xsl:if>
</xsl:template>

<!-- Authors, editors in serial lists for headers           -->
<!-- Presumes authors get selected first, so editors follow -->
<!-- TODO: Move to common -->
<xsl:template match="author[1]" mode="name-list" >
    <xsl:apply-templates select="personname" />
</xsl:template>
<xsl:template match="author" mode="name-list" >
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="personname" />
</xsl:template>
<xsl:template match="editor[1]" mode="name-list" >
    <xsl:if test="//frontmatter/titlepage/author" >
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="personname" />
    <xsl:text> (</xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text>)</xsl:text>
</xsl:template>
<xsl:template match="editor" mode="name-list" >
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="personname" />
    <xsl:text> (</xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Front Colophon -->
<!-- Licenses, ISBN, Cover Designer, etc -->
<!-- We process pieces, in document order -->
<!-- TODO: edition, publisher, production notes, cover design, etc -->
<!-- TODO: revision control commit hash -->
<xsl:template match="frontmatter/colophon/credit">
    <p class="credit">
        <b class="title">
            <xsl:apply-templates select="role" />
        </b>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="entity"/>
    </p>
</xsl:template>

<xsl:template match="frontmatter/colophon/edition">
    <p class="credit">
        <b class="title">
            <xsl:apply-templates select="." mode="type-name" />
        </b>
        <xsl:text> </xsl:text>
        <xsl:apply-templates />
    </p>
</xsl:template>

<!-- website for the book -->
<xsl:template match="frontmatter/colophon/website">
    <p class="credit">
        <b class="title">
            <xsl:apply-templates select="." mode="type-name" />
        </b>
        <xsl:text> </xsl:text>
        <xsl:variable name="web-address">
            <xsl:apply-templates select="address" />
        </xsl:variable>
        <a href="{$web-address}">
            <xsl:apply-templates select="name" />
        </a>
    </p>
</xsl:template>

<xsl:template match="frontmatter/colophon/copyright">
    <p class="copyright">
        <!-- Unicode copyright symbol -->
        <xsl:text>&#xa9;</xsl:text>
        <xsl:apply-templates select="year" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="holder" />
    </p>
    <xsl:if test="shortlicense">
        <p class="license">
            <xsl:apply-templates select="shortlicense" />
        </p>
    </xsl:if>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after           -->
<!-- explicit subdivisions, to introduce or summarize      -->
<!-- Title optional, typically just a few paragraphs       -->
<!-- Also occur in "smaller" units (elsewhere), so the     -->
<!-- HTML element varies from a "section" to an "article"  -->

<!-- Not knowlable as a component of bigger things, a      -->
<!-- pure container.  This is the component of a division. -->
<!-- Tunnel the duplication flag, drop id if duplicate     -->
<xsl:template match="introduction[parent::*[&STRUCTURAL-FILTER;]]|conclusion[parent::*[&STRUCTURAL-FILTER;]]">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="section">
        <!-- cheap, but it works -->
        <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)" />
        </xsl:attribute>
        <xsl:if test="$b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="title">
            <h6 class="heading">
                <xsl:apply-templates select="." mode="title-full" />
                <span> </span>
            </h6>
        </xsl:if>
        <xsl:apply-templates  select="*">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- ####################### -->
<!-- Back Matter Components -->
<!-- ####################### -->

<!-- Back Colophon -->
<!-- Nothing special, so just process similarly to front -->


<xsl:template match="index-list">
    <xsl:call-template name="print-index" />
</xsl:template>



<!-- Solutions List -->
<!-- We construct one huge list of solutions, organized      -->
<!-- as divisions, one per "exercises" section.  Seperate    -->
<!-- parameters control visibility. We eventually appeal     -->
<!-- to the environment/knowl code to realize each hint, etc -->
<!-- as a knowl for decent page-loading time.                -->

<!-- This is a hack that should go away when backmatter exercises are rethought -->
<xsl:template match="title" mode="backmatter" />

<xsl:template match="solution-list">
    <xsl:apply-templates select="//exercises" mode="backmatter" />
</xsl:template>

<xsl:template match="exercises" mode="backmatter">
    <!-- see if an "exercises" section has any solutions -->
    <xsl:variable name="nonempty" select="(.//hint and $exercise.backmatter.hint='yes') or
                                          (.//answer and $exercise.backmatter.answer='yes') or
                                          (.//solution and $exercise.backmatter.solution='yes')" />

    <xsl:if test="$nonempty='true'">
        <!-- these sections do not have HTML id, so no way to point to them -->
        <!-- maybe there is a way to generate a reasonable internal-id      -->
        <section class="exercises">
            <h1 class="heading">
                <span class="type">Exercises</span>
                <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
                <span>
                    <xsl:apply-templates select="." mode="title-attributes" />
                    <xsl:apply-templates select="." mode="title-full" />
                </span>
            </h1>
            <!-- ignore introduction, conclusion, exercise groups -->
            <xsl:apply-templates select=".//exercise" mode="backmatter" />
        </section>
    </xsl:if>
</xsl:template>

<!-- Print exercises with some solution component -->
<!-- Respect switches about visibility            -->
<xsl:template match="exercise" mode="backmatter">
    <xsl:if test="hint or answer or solution">
        <!-- Lead with the problem number and some space -->
        <xsl:variable name="xref">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:variable>
        <article class="exercise-like" id="{$xref}">
            <h6 class="heading hidden-type">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
            <span class="codenumber"><xsl:apply-templates select="." mode="serial-number" /></span>
            <xsl:if test="title">
                <span>
                    <xsl:apply-templates select="." mode="title-attributes" />
                    <xsl:apply-templates select="." mode="title-full" />
                </span>
            </xsl:if>
            </h6>
            <xsl:if test="$exercise.backmatter.statement='yes'">
                <xsl:apply-templates select="statement" />
            </xsl:if>
            <!-- default templates will produce hidden knowls -->
            <div class="solutions">
                <xsl:if test="hint and $exercise.backmatter.hint='yes'">
                    <xsl:apply-templates select="hint" />
                </xsl:if>
                <xsl:if test="answer and $exercise.backmatter.answer='yes'">
                    <xsl:apply-templates select="answer" />
                </xsl:if>
                <xsl:if test="solution and $exercise.backmatter.solution='yes'">
                    <xsl:apply-templates select="solution" />
                </xsl:if>
            </div>
        </article>
    </xsl:if>
</xsl:template>

<!--               -->
<!-- Notation List -->
<!--               -->

<!-- At actual location, we do nothing since  -->
<!-- the cross-reference will always be a     -->
<!-- knowl to the containing structure        -->
<xsl:template match="notation" />

<!-- Build the table infrastructure, then    -->
<!-- populate with all the notation entries, -->
<!-- in order of appearance                  -->
<xsl:template match="notation-list">
    <table>
        <tr>
            <th style="text-align:left;">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'symbol'" />
                </xsl:call-template>
            </th>
            <th style="text-align:left;">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'description'" />
                </xsl:call-template>
            </th>
            <th style="text-align:left;">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'location'" />
                </xsl:call-template>
            </th>
        </tr>
        <xsl:apply-templates select="//notation" mode="backmatter" />
    </table>
</xsl:template>

<!-- We wrap the sample usage as mathematics       -->
<!-- Duplicate the provided description            -->
<!-- Create a cross-reference to enclosing content -->
<xsl:template match="notation" mode="backmatter">
    <tr>
        <td style="text-align:left; vertical-align:top;">
            <xsl:call-template name="begin-inline-math" />
            <xsl:value-of select="usage" />
            <xsl:call-template name="end-inline-math" />
        </td>
        <td style="text-align:left; vertical-align:top;">
            <xsl:apply-templates select="description" />
        </td>
        <td style="text-align:left; vertical-align:top;">
            <xsl:apply-templates select="." mode="enclosure-xref" />
        </td>
    </tr>
</xsl:template>

<!-- Experimental: maybe belongs in -common -->
<!-- Not -md, know where the link lives     -->
<xsl:template match="*" mode="enclosure-xref">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="." mode="is-block" />
    </xsl:variable>
    <xsl:choose>
        <!-- found a structural or block parent -->
        <!-- we fashion a cross-reference link  -->
        <!-- TODO: xref-link's select is a fiction, maybe lead to bugs? -->
        <xsl:when test="$structural='true' or $block='true'">
            <xsl:apply-templates select="." mode="xref-link">
                <xsl:with-param name="target" select="." />
                <xsl:with-param name="content">
                    <xsl:apply-templates select="." mode="type-name" />
                    <xsl:variable name="enclosure-number">
                        <xsl:apply-templates select="." mode="number" />
                    </xsl:variable>
                    <xsl:if test="not($enclosure-number = '')">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$enclosure-number" />
                    </xsl:if>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <!-- nothing interesting here, so step up a level -->
        <!-- Eventually we find the top-level structure   -->
        <!-- eg article, book, etc                        -->
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="enclosure-xref" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- See general routine in  xsl/mathbook-common.xsl -->
<!-- which expects the two named templates and the  -->
<!-- two division'al and element'al templates below,  -->
<!-- it contains the logic of constructing such a list -->

<!-- List-of entry/exit hooks -->
<!-- No ops for HTML          -->
<xsl:template name="list-of-begin" />
<xsl:template name="list-of-end" />

<!-- Subdivision headings in list-of's -->
<!-- Amalgamation of "section-header" and "header-content" -->
<!--   (1) No author credit                                -->
<!--   (2) No permalink                                    -->
<xsl:template match="*" mode="list-of-header">
    <xsl:element name="h1">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
         <xsl:attribute name="alt">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
         <xsl:attribute name="title">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <span class="codenumber">
            <xsl:apply-templates select="." mode="number" />
        </span>
        <span>
            <xsl:apply-templates select="." mode="title-attributes" />
            <xsl:apply-templates select="." mode="title-full" />
        </span>
    </xsl:element>
</xsl:template>

<!-- Entries in list-of's -->
<!-- Partly borrowed from common routines -->
<!-- TODO: CSS styling of the div forcing the knowl to open in the right place -->
<!-- And spacing should be done with .type, .codenumber, .title                -->
<xsl:template match="*" mode="list-of-element">
    <!-- Name and number as a knowl/link, div to open against -->
    <!-- TODO: xref-link's select is a fiction, maybe lead to bugs? -->
    <div>
        <xsl:apply-templates select="." mode="xref-link">
            <xsl:with-param name="target" select="." />
            <xsl:with-param name="content">
                <xsl:apply-templates select="." mode="type-name" />
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="number" />
            </xsl:with-param>
        </xsl:apply-templates>
        <!-- title plain, separated -->
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
    </div>
</xsl:template>

<!-- ################ -->
<!-- Contributor List -->
<!-- ################ -->

<!-- Not much happening here, will drop -->
<!-- into environment manufacture       -->
<xsl:template match="contributors">
    <xsl:apply-templates select="contributor" />
</xsl:template>

<!-- ############## -->
<!-- Index Creation -->
<!-- ############## -->

<!-- "print-index":                                          -->
<!--     build a sorted list of every "index" in text        -->
<!-- "group-by-letter":                                      -->
<!--     accumale common first-letter entries,               -->
<!--     send to their own div for spacing, "jump to" device -->
<!-- "group-by-heading":                                     -->
<!--     consolidate/accumulate entries with common heading  -->
<!-- "knowl-list":                                           -->
<!--     output the cross-references                         -->
<xsl:template name="print-index">
    <!-- <index> with single mixed-content heading -->
    <!-- or replacement <idx> as mixed-content     -->
    <!-- start attribute is actual end of a        -->
    <!-- "page range", goodies at @finish          -->
    <xsl:variable name="unstructured-index">
        <xsl:for-each select="//index[not(main) and not(@start) and not(index-list)] | $document-root//idx[not(h) and not(@start)]">
            <xsl:variable name="content">
                <xsl:apply-templates select="*|text()" />
            </xsl:variable>
            <index>
                <!-- text, key-value for single index heading -->
                <text>
                    <xsl:copy-of select="$content" />
                </text>
                <key>
                    <xsl:choose>
                        <!-- salt prevents accidental key collisions -->
                        <xsl:when test="@sortby">
                            <xsl:value-of select="translate(@sortby, &UPPERCASE;, &LOWERCASE;)" />
                            <xsl:value-of select="generate-id(.)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="translate($content, &UPPERCASE;, &LOWERCASE;)" />
                        </xsl:otherwise>
                    </xsl:choose>
                </key>
                <!-- plus two more empty keys -->
                <key><text /></key>
                <key><text /></key>
                <!-- write/preserve info about the location's surroundings -->
                <!-- as "knowl" and "typename" temporary elements          -->
                <xsl:apply-templates select="." mode="index-enclosure" />
            </index>
        </xsl:for-each>
    </xsl:variable>
    <!-- index entries with structure, cant't be end of a "page range" -->
    <xsl:variable name="structured-index">
        <xsl:for-each select="//index[main and not(@start)] | $document-root//idx[h and not(@start)]">
            <index>
                <xsl:for-each select="main|sub|h">
                    <xsl:variable name="content">
                        <xsl:apply-templates select="*|text()" />
                    </xsl:variable>
                    <text>
                        <xsl:copy-of select="$content" />
                    </text>
                    <key>
                        <xsl:choose>
                            <!-- salt prevents accidental key collisions -->
                            <xsl:when test="@sortby">
                                <xsl:value-of select="translate(@sortby, &UPPERCASE;, &LOWERCASE;)" />
                                <xsl:value-of select="generate-id(.)" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="translate($content, &UPPERCASE;, &LOWERCASE;)" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </key>
                    <!-- if terminal, enhance final sort key -->
                    <!-- link type for final sort preference -->
                    <!-- this mimics LaTeX's ordering        -->
                    <!--   0 - has "see also"                -->
                    <!--   1 - has "see"                     -->
                    <!--   2 - is knowl/hyperlink reference  -->
                    <!-- condition on last level of headings -->
                    <xsl:if test="not(following-sibling::*[self::sub]) and not(following-sibling::*[self::h])">
                        <link>
                            <xsl:choose>
                                <xsl:when test="../seealso">
                                    <xsl:text>0</xsl:text>
                                </xsl:when>
                                <xsl:when test="../see">
                                    <xsl:text>1</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>2</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </link>
                    </xsl:if>
                </xsl:for-each>
                <!-- add empty strings in additional "missing" keys -->
                <xsl:if test="(count(h) = 1) or (count(h) = 2)">
                    <key><xsl:text /></key>
                </xsl:if>
                <xsl:if test="count(h) = 1">
                    <key><xsl:text /></key>
                </xsl:if>
                <xsl:if test="(main and not(sub[1]))">
                    <key><xsl:text /></key>
                </xsl:if>
                <xsl:if test="(main and not(sub[2]))">
                    <key><xsl:text /></key>
                </xsl:if>
                <!-- write/preserve info about the location's surroundings -->
                <!-- context will be lost as RTF is converted, so grab it  -->
                <!-- as "knowl" and "typename" temporary elements          -->
                <xsl:apply-templates select="." mode="index-enclosure" />
                <!-- there is at most one "see" or "seealso" total -->
                <!-- these replace the knowls, so perhaps condition here -->
                <xsl:for-each select="see">
                    <see>
                        <xsl:apply-templates select="*|text()" />
                    </see>
                </xsl:for-each>
                <xsl:for-each select="seealso">
                    <seealso>
                        <xsl:apply-templates select="*|text()" />
                    </seealso>
                </xsl:for-each>
            </index>
        </xsl:for-each>
    </xsl:variable>
    <!-- sort now that info from document tree ordering is recorded -->
    <!-- perhaps one big variable/RTF once deprecation takes place  -->
    <xsl:variable name="sorted-index">
        <xsl:for-each select="exsl:node-set($unstructured-index)/*|exsl:node-set($structured-index)/*">
            <xsl:sort select="./key[1]" />
            <xsl:sort select="./key[2]" />
            <xsl:sort select="./key[3]" />
            <xsl:sort select="./link" />
            <xsl:copy-of select="." />
        </xsl:for-each>
    </xsl:variable>
    <!-- ship start of a node-set to be grouped by letter   -->
    <!-- conversion to node-set is necessary for subsequent -->
    <xsl:apply-templates select="exsl:node-set($sorted-index)/*[1]" mode="group-by-letter">
        <xsl:with-param name="letter-group" select="/.." />
    </xsl:apply-templates>
</xsl:template>

<!-- Accumulate index entries with a common first letter   -->
<!-- in $letter-group and then pass to grouping by heading -->
<xsl:template match="*" mode="group-by-letter">
    <!-- Empty node list from parent of root node -->
    <xsl:param name="letter-group" select="/.."/>
    <!-- look ahead at next index entry -->
    <xsl:variable name="next-index" select="following-sibling::*[1]" />
    <!-- check if we have run out all of the index entries -->
    <xsl:if test=".">
        <!-- always accumulate context node in node-list (first, or $next-index inspected) -->
        <xsl:variable name="new-letter-group" select="$letter-group | ." />
        <xsl:choose>
            <!-- next index item has same lead letter, so iterate -->
            <xsl:when test="substring($next-index/key[1], 1, 1) = substring(key[1], 1,1)">
                <xsl:apply-templates select="$next-index" mode="group-by-letter">
                    <xsl:with-param name="letter-group" select="$new-letter-group" />
                </xsl:apply-templates>
            </xsl:when>
            <!-- next index item has different lead letter      -->
            <!-- wrap the letter-group in a div with correct id -->
            <!-- and course through to group by headings        -->
            <xsl:otherwise>
                <xsl:variable name="lead" select="substring(key[1], 1, 1)" />
                <div class="indexletter" id="indexletter-{$lead}">
                    <!-- send to group headings, pass letter-group through -->
                    <xsl:apply-templates select="$new-letter-group[1]" mode="group-by-heading">
                        <xsl:with-param name="heading-group" select="/.." />
                        <xsl:with-param name="letter-group" select="$new-letter-group" />
                    </xsl:apply-templates>
                </div>
                <!-- restart letter grouping with node having new letter -->
                <xsl:apply-templates select="$next-index" mode="group-by-letter">
                    <xsl:with-param name="letter-group" select="/.." />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- Accumulate index entries with identical heading -->
<!-- quit accumulating when next entry differs       -->
<!-- Output heading, xrefs, before restarting        -->
<xsl:template match="*" mode="group-by-heading">
    <!-- Empty node list from parent of root node -->
    <xsl:param name="heading-group" select="/.."/>
    <xsl:param name="letter-group" select="/.."/>
    <!-- look ahead at next index entry -->
    <xsl:variable name="next-index" select="following-sibling::*[1]" />
    <!-- check if context node is still in the letter-group -->
    <xsl:if test="count(. | $letter-group) = count($letter-group)">
        <xsl:variable name="new-heading-group" select="$heading-group | ." />
        <xsl:choose>
            <!-- same heading, accumulate and iterate -->
            <xsl:when test="($next-index/key[1] = ./key[1]) and ($next-index/key[2] = ./key[2]) and ($next-index/key[3] = ./key[3])">
                <xsl:apply-templates select="$next-index" mode="group-by-heading">
                    <xsl:with-param name="heading-group" select="$new-heading-group" />
                    <xsl:with-param name="letter-group" select="$letter-group"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- some key differs in next index entry,  -->
            <!-- write and restart heading accumulation -->
            <xsl:otherwise>
                <xsl:call-template name="output-one-heading">
                    <xsl:with-param name="heading-group" select="$new-heading-group" />
                </xsl:call-template>
                <!-- restart grouping by heading, pass through letter-group -->
                <xsl:apply-templates select="$next-index" mode="group-by-heading">
                    <xsl:with-param name="heading-group" select="/.." />
                    <xsl:with-param name="letter-group" select="$letter-group"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- Place the (possibly three) components of -->
<!-- the heading(s) into their proper divs.   -->
<!-- Do not duplicate prior components that   -->
<!-- match, do not write an empty heading.    -->
<xsl:template name="output-one-heading">
    <xsl:param name="heading-group" />
    <xsl:variable name="pattern" select="$heading-group[1]" />
    <xsl:variable name="pred" select="$pattern/preceding-sibling::*[1]" />
    <!-- booleans for analysis of format of heading, xrefs -->
    <xsl:variable name="match1" select="($pred/key[1] = $pattern/key[1]) and $pred" />
    <xsl:variable name="match2" select="($pred/key[2] = $pattern/key[2]) and $pred" />
    <xsl:variable name="match3" select="($pred/key[3] = $pattern/key[3]) and $pred" />
    <xsl:variable name="empty2" select="boolean($pattern/key[2] = '')" />
    <xsl:variable name="empty3" select="boolean($pattern/key[3] = '')" />
    <!-- write an "indexitem", "subindexitem", "subsubindexitem" as     -->
    <!-- necessary to identify chnages in headings, without duplicating -->
    <!-- headings from prior entries. Add xref when keys go blank       -->
    <!--  -->
    <!-- first key differs from predecessor, or leads letter group -->
    <xsl:if test="not($match1)">
        <div class="indexitem">
            <xsl:copy-of select="$pattern/text[1]/node()" />
            <!-- next key is blank, hence done, so write xrefs        -->
            <!-- the next outermost tests will fail so no duplication -->
            <xsl:if test="$empty2">
                <xsl:call-template name="knowl-list">
                    <xsl:with-param name="heading-group" select="$heading-group" />
                </xsl:call-template>
            </xsl:if>
        </div>
    </xsl:if>
    <!-- second key is substantial, and mis-match is in   -->
    <!-- the second key, or first key (ie to to the left) -->
    <xsl:if test="not($empty2) and (not($match1) or not($match2))">
        <div class="subindexitem">
            <xsl:copy-of select="$pattern/text[2]/node()" />
            <!-- next key is blank, hence done, so write xrefs       -->
            <!-- the next outermost test will fail so no duplication -->
            <xsl:if test="$empty3">
                <xsl:call-template name="knowl-list">
                    <xsl:with-param name="heading-group" select="$heading-group" />
                </xsl:call-template>
            </xsl:if>
        </div>
    </xsl:if>
    <!-- third key is substantial, and mis-match is in the first   -->
    <!-- key, the second key, or the third key (ie to to the left) -->
    <xsl:if test="not($empty3) and (not($match1) or not($match2) or not($match3))">
        <div class="subsubindexitem">
            <xsl:copy-of select="$pattern/text[3]/node()" />
            <!-- last chance to write xref list -->
            <xsl:call-template name="knowl-list">
                <xsl:with-param name="heading-group" select="$heading-group" />
            </xsl:call-template>
        </div>
    </xsl:if>
</xsl:template>

<!-- Place all the cross-references in the div -->
<!-- for the final (sub)item in its own span.  -->
<!-- N.B. Some commas may not be correct here  -->
<xsl:template name="knowl-list">
    <xsl:param name="heading-group" />
    <!-- range through node-list, making cross-references -->
    <!-- Use a comma after the heading, then prefix each  -->
    <!-- cross-reference with a space as separators       -->
    <span class="indexknowl">
        <xsl:text>,</xsl:text>
        <xsl:for-each select="$heading-group">
            <xsl:choose>
                <xsl:when test="see">
                    <xsl:text> </xsl:text>
                    <em class="see">
                        <xsl:call-template name="type-name">
                            <xsl:with-param name="string-id" select="'see'" />
                        </xsl:call-template>
                    </em>
                    <xsl:copy-of select="see/node()" />
                </xsl:when>
                <xsl:when test="seealso">
                    <xsl:text> </xsl:text>
                    <em class="see">
                        <xsl:call-template name="type-name">
                            <xsl:with-param name="string-id" select="'also'" />
                        </xsl:call-template>
                    </em>
                    <xsl:copy-of select="seealso/node()" />
                </xsl:when>
                <!-- else a real content reference, knowl or hyperlink -->
                <!-- TODO: split into two more when, otherwise as error? -->
                <xsl:otherwise>
                    <xsl:text> </xsl:text>
                    <xsl:element name="a">
                        <!-- knowl or traditional hyperlink     -->
                        <!-- mutually exclusive by construction -->
                        <xsl:if test="knowl">
                            <xsl:attribute name="knowl">
                                <xsl:value-of select="knowl" />
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:if test="hyperlink">
                            <xsl:attribute name="href">
                                <xsl:value-of select="hyperlink" />
                            </xsl:attribute>
                        </xsl:if>
                        <!-- content: replace with localized short-names -->
                        <xsl:value-of select="typename" />
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </span>
</xsl:template>

<!-- Climb the tree looking for an enclosing structure of        -->
<!-- interest and preserve the knowl-url, plus clickable text    -->
<!-- One notable case: paragraph must be "top-level", just below -->
<!-- a structural document node                                  -->
<!-- Recursion always halts, since "mathbook" is structural      -->
<!-- TODO: save knowl or section link                            -->
<xsl:template match="*" mode="index-enclosure">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="." mode="is-block" />
    </xsl:variable>
    <xsl:choose>
        <!-- found a structural parent first           -->
        <!-- collect a url for a traditional hyperlink -->
        <xsl:when test="$structural='true'">
            <hyperlink>
                <xsl:apply-templates select="." mode="url" />
            </hyperlink>
            <typename>
                <xsl:apply-templates select="." mode="type-name" />
            </typename>
        </xsl:when>
        <!-- found a block parent     -->
        <!-- collect a knowl filename -->
        <xsl:when test="$block='true'">
            <knowl>
                <xsl:apply-templates select="." mode="xref-knowl-filename" />
            </knowl>
            <typename>
                <xsl:apply-templates select="." mode="type-name" />
            </typename>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="index-enclosure" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################################### -->
<!-- Cross-Reference Knowls (xref-knowl) -->
<!-- ################################### -->

<!-- Many elements are candidates for cross-references     -->
<!-- and many of those are nicely implemented as knowls.   -->
<!-- We traverse the entire document tree with a modal     -->
<!-- "xref-knowl" template.  When it encounters an element -->
<!-- that needs a cross-reference target as a knowl file,  -->
<!-- that file is built and the tree traversal continues.  -->
<!--                                                       -->
<!-- See initiation in the entry template.  Default is to  -->
<!-- recurse through elements to children elements.        -->

<!-- recurse if not knowlizable -->
<xsl:template match="*" mode="xref-knowl">
    <xsl:apply-templates select="*" mode="xref-knowl" />
</xsl:template>

<!-- build xref-knowl, and optionally a hidden-knowl duplicate       -->
<!-- &SOLUTION-LIKE; is replaced by WW-avoiding versions             -->
<!-- NB: "me" has all the necessary templates, but is never a target -->
<!-- mrow is only ever an "xref" knowl, and has enclosing content    -->
<xsl:template match="&REMARK-LIKE;|&COMPUTATION-LIKE;|&DEFINITION-LIKE;|&ASIDE-LIKE;|poem|&FIGURE-LIKE;|assemblage|blockquote|paragraphs|objectives|&EXAMPLE-LIKE;|exercisegroup|exercise|&PROJECT-LIKE;|task|hint[not(ancestor::webwork)]|answer[not(ancestor::webwork)]|solution[not(ancestor::webwork)]|&THEOREM-LIKE;|&AXIOM-LIKE;|proof|case|fn|contributor|biblio|biblio/note|p|li|webwork[*|@*]|men|mrow" mode="xref-knowl">
    <!-- a generally available cross-reference knowl file, of duplicated content -->
    <xsl:apply-templates select="." mode="manufacture-knowl">
        <xsl:with-param name="knowl-type" select="'xref'" />
    </xsl:apply-templates>
    <!-- optionally, a file version of duplicated hidden-knowl content -->
    <xsl:variable name="hidden">
        <xsl:apply-templates select="." mode="is-hidden" />
    </xsl:variable>
    <xsl:if test="$hidden = 'true'">
        <xsl:apply-templates select="." mode="manufacture-knowl">
            <xsl:with-param name="knowl-type" select="'hidden'" />
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- Build one, or two, files for knowl content -->
<xsl:template match="*" mode="manufacture-knowl">
    <xsl:param name="knowl-type" />
    <xsl:variable name="knowl-file">
        <xsl:choose>
            <xsl:when test="$knowl-type = 'xref'">
                <xsl:apply-templates select="." mode="xref-knowl-filename" />
            </xsl:when>
            <xsl:when test="$knowl-type = 'hidden'">
                <xsl:apply-templates select="." mode="hidden-knowl-filename" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <!-- write file infrastructure first -->
    <exsl:document href="{$knowl-file}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <html lang="{$document-language}"> <!-- dir="rtl" here -->
            <!-- header since separate file -->
            <xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="converter-blurb-html" />
            <head>
                <!-- dissuade indexing duplicated content -->
                <meta name="robots" content="noindex, nofollow" />
                <!-- we need Sage cell configuration functions     -->
                <!-- in the knowl file itself, the main Javascript -->
                <!-- is being placed on *every* page, if present   -->
                <!-- anywhere in the document, and that is         -->
                <!-- sufficient for the external knowl             -->
                <xsl:apply-templates select="." mode="sagecell" />
            </head>
            <body>
                <!-- content, in xref style or hidden style     -->
                <!-- initiate tunneling duplication flag here   -->
                <!-- We send a flag to the "body" template      -->
                <!-- indicating the call is at the outermost    -->
                <!-- level of the knowl being constructed,      -->
                <!-- rather than to manufacture a child element -->
                <!-- Usually this parameter is ignored          -->
                <!-- An xref to an mrow results in a knowl      -->
                <!-- whose content is more than just the xref,  -->
                <!-- it is the entire containing md or mdn      -->
                <xsl:choose>
                    <xsl:when test="$knowl-type = 'xref'">
                        <xsl:choose>
                            <xsl:when test="self::mrow">
                                <xsl:apply-templates select="parent::*" mode="body">
                                    <xsl:with-param name="block-type" select="'xref'" />
                                    <xsl:with-param name="b-original" select="false()" />
                                    <xsl:with-param name="b-top-level" select="true()" />
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="." mode="body">
                                    <xsl:with-param name="block-type" select="'xref'" />
                                    <xsl:with-param name="b-original" select="false()" />
                                    <xsl:with-param name="b-top-level" select="true()" />
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$knowl-type = 'hidden'">
                        <xsl:apply-templates select="." mode="body">
                            <xsl:with-param name="block-type" select="'hidden'" />
                            <xsl:with-param name="b-original" select="false()" />
                            <xsl:with-param name="b-top-level" select="true()" />
                        </xsl:apply-templates>
                    </xsl:when>
                </xsl:choose>
                <!-- in-context link just for xref-knowl content -->
                <xsl:if test="$knowl-type = 'xref'">
                    <xsl:variable name="href">
                        <xsl:apply-templates select="." mode="url" />
                    </xsl:variable>
                    <span class="incontext">
                        <a href="{$href}">
                            <xsl:call-template name="type-name">
                                <xsl:with-param name="string-id" select="'incontext'" />
                            </xsl:call-template>
                        </a>
                    </span>
                </xsl:if>
            </body>
        </html>
    </exsl:document>  <!-- end file -->
    <!-- recurse the tree outside of the file-writing -->
    <xsl:apply-templates select="*" mode="xref-knowl" />
</xsl:template>

<!-- The directory of knowls that are targets of cross-references    -->
<!-- The file extension is *.html so recognized as OK by Moodle, etc -->
<xsl:template match="*" mode="xref-knowl-filename">
    <xsl:text>./knowl/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.html</xsl:text>
</xsl:template>

<xsl:template match="*" mode="hidden-knowl-filename">
    <xsl:text>./knowl/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>-hidden.html</xsl:text>
</xsl:template>

<!-- ######## -->
<!-- Headings -->
<!-- ######## -->

<!-- Titles get variable CSS to control punctuation -->
<!-- select on parent, checks title as child        -->
<xsl:template match="*" mode="title-attributes">
    <!-- true, false, or if no title, then empty -->
    <xsl:variable name="has-punctuation">
        <xsl:apply-templates select="title" mode="has-punctuation" />
    </xsl:variable>
    <xsl:attribute name="class">
        <xsl:text>title</xsl:text>
        <!-- if punctuated, add a class to this effect -->
        <xsl:if test="$has-punctuation = 'true'">
                <xsl:text> punctuated</xsl:text>
        </xsl:if>
    </xsl:attribute>
</xsl:template>

<!-- These are convenience methods for frequently-used headings -->

<!-- h6, type name, number (if exists), title (if exists) -->
<!-- REMARK-LIKE, COMPUTATION-LIKE, DEFINITION-LIKE, SOLUTION-LIKE, objectives (xref-content), EXAMPLE-LIKE, PROJECT-LIKE, exercise (inline), task (xref-content), fn (xref-content), biblio/note (xref-content)-->
<xsl:template match="*" mode="heading-full">
    <h6 class="heading">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <xsl:variable name="the-number">
            <xsl:apply-templates select="." mode="number" />
        </xsl:variable>
        <xsl:if test="not($the-number='')">
            <span class="codenumber">
                <xsl:value-of select="$the-number" />
            </span>
        </xsl:if>
        <xsl:if test="title">
            <span>
                <xsl:apply-templates select="." mode="title-attributes" />
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </h6>
</xsl:template>

<!-- h6, no type name, serial number, title (if exists) -->
<!-- exercise (sectional, as born) -->
<xsl:template match="*" mode="heading-sectional-exercise">
    <h6 class="heading">
        <span class="codenumber">
            <xsl:apply-templates select="." mode="serial-number" />
        </span>
        <xsl:if test="title">
            <span>
                <xsl:apply-templates select="." mode="title-attributes" />
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </h6>
</xsl:template>

<!-- h6, type name, serial number, title (if exists) -->
<!-- exercise (sectional, xref-content)      -->
<xsl:template match="*" mode="heading-sectional-exercise-typed">
    <h6 class="heading">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <span class="codenumber">
            <xsl:apply-templates select="." mode="serial-number" />
        </span>
        <xsl:if test="title">
            <span>
                <xsl:apply-templates select="." mode="title-attributes" />
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </h6>
</xsl:template>

<!-- h6, no type name, just simple list number, no title -->
<!-- task (when born) -->
<xsl:template match="*" mode="heading-list-number">
    <h6 class="heading">
        <span class="codenumber">
            <xsl:text>(</xsl:text>
            <xsl:apply-templates select="." mode="list-number" />
            <xsl:text>)</xsl:text>
        </span>
    </h6>
</xsl:template>

<!-- h6, type name, no number (even if exists), title (if exists)              -->
<!-- eg, objectives is one-per-subdivison, max, so no need to display at birth -->
<!-- objectives (when born) -->
<xsl:template match="*" mode="heading-full-implicit-number">
    <h6 class="heading">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <!-- codenumber is implicit via placement -->
        <xsl:if test="title">
            <span>
                <xsl:apply-templates select="." mode="title-attributes" />
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </h6>
</xsl:template>

<!-- Not normally titled, but knowl content gives some indication -->
<!-- blockquote, exercisegroup, proof -->
<xsl:template match="*" mode="heading-type">
    <h6 class="heading">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
    </h6>
</xsl:template>

<!-- Title only -->
<!-- ASIDE-LIKE, paragraphs -->
<!-- No title, then nothing happens     -->
<xsl:template match="*" mode="heading-title">
    <xsl:if test="title/*|title/text()">
        <h6 class="heading">
            <span>
                <xsl:apply-templates select="." mode="title-attributes" />
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </h6>
    </xsl:if>
</xsl:template>

<!-- Title only, paragraphs -->
<!-- h5 for paragraphs, lowest of the low -->
<!-- No title, then nothing happens       -->
<!-- TODO: titles will be mandatory sometime -->
<xsl:template match="*" mode="heading-title-paragraphs">
    <xsl:if test="title/*|title/text()">
        <h5 class="heading">
            <span>
                <xsl:apply-templates select="." mode="title-attributes" />
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </h5>
    </xsl:if>
</xsl:template>

<!-- A type, with maybe a serial number to disambiguate -->
<!-- No h6, optional title                              -->
<!-- SOLUTION-LIKE (xref-text), biblio/note (xref-text) -->
<xsl:template match="*" mode="heading-simple">
    <!-- the name of the object, its "type" -->
    <span class="type">
        <xsl:apply-templates select="." mode="type-name" />
    </span>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="non-singleton-number" />
    </xsl:variable>
    <!-- An empty value means element is a singleton -->
    <!-- else the serial number comes through        -->
    <xsl:if test="not($the-number = '')">
        <span class="codenumber">
            <xsl:apply-templates select="." mode="serial-number" />
        </span>
    </xsl:if>
    <xsl:if test="title">
        <span>
            <xsl:apply-templates select="." mode="title-attributes" />
            <xsl:apply-templates select="." mode="title-full" />
        </span>
    </xsl:if>
</xsl:template>

<!-- A case in a proof, eg "(=>) Necessity." -->
<!-- case -->
<xsl:template match="*" mode="heading-case">
    <h6 class="heading">
        <xsl:choose>
            <!-- 'RIGHTWARDS DOUBLE ARROW' (U+21D2) -->
            <xsl:when test="@direction='forward'">
                <xsl:comment>Style arrows in CSS?</xsl:comment>
                <xsl:text>(&#x21d2;)&#xa0;&#xa0;</xsl:text>
            </xsl:when>
            <!-- 'LEFTWARDS DOUBLE ARROW' (U+21D0) -->
            <xsl:when test="@direction='backward'">
                <xsl:comment>Style arrows in CSS?</xsl:comment>
                <xsl:text>(&#x21d0;)&#xa0;&#xa0;</xsl:text>
            </xsl:when>
            <!-- DTD will catch wrong values -->
            <xsl:otherwise />
        </xsl:choose>
        <xsl:if test="title">
            <xsl:apply-templates select="." mode="title-full" />
            <xsl:text>.</xsl:text>
        </xsl:if>
    </h6>
</xsl:template>

<!-- Heading (title) of a "poem" -->
<!-- This is a hack, which should go away whence there -->
<!-- is CSS for the class .poem which will surround    -->
<!-- this.  Likely replace use of this template        -->
<!-- by the template "heading-title" above             -->
<xsl:template match="poem" mode="heading-poem">
    <div class="poemtitle" style="font-weight: bold; text-align: center; font-size: 120%">
        <xsl:apply-templates select="." mode="title-full"/>
    </div>
</xsl:template>


<!-- ######################## -->
<!-- Block Production, Knowls -->
<!-- ######################## -->

<!-- Generically, a "block" is a child of a "division."  See the schema for more precision.  Blocks also have significant components.  An "example" is a block, and its "solution" is a significant component.  A "p" might be a block, but it could also be a significant component of an "example." -->

<!-- Some blocks and components can be realized in a hidden fashion, as knowls whose content is embedded within the page.  This may be automatic (footnotes, "fn", are a good example), elective ("theorem" is a good example), or banned (a "blockquote" is never hidden). -->

<!-- All blocks, and many of their significant components, are available as targets of cross-references, implemented as knowls, but now the content resides in external files.  These files contain duplicates of blocks and their components (rather than originals), so need to be free of the unique identifiers that are used in the original versions. -->

<!-- This suggests four modes for the initial production of a block or component, though some blocks may only be produced in two of the four modes: visible and original, hidden and original, a cross-reference knowl, an external knowl duplicating a hidden knowl. -->
<!-- (a) Visible and original (on a main page) -->
<!-- (b) Hidden and original (embedded knowl on a page) -->
<!-- (c) Visible and duplicate (in, or as, a cross-reference knowl) -->
<!-- (d) Hidden and duplicate (an external knowl, duplicating the hidden original knowl) -->

<!-- The generic (not modal) template matches any element that is a block or a significant component of some other element that is a block or a component. -->

<!-- Every such element is only output in one of two forms, and as few times as possible.  One form is the "original" and includes full identifying information, such as an HTML id attribute or a LaTeX label for rows of display mathematics.  The other form is a "duplicate", as an external file, for use by the knowl code to open and display.  As a duplicate of the orginal, it should be free of all identifying information and should recycle other duplicates as much as possible. -->

<!-- An element arrives here in one of four situations, two as originals and two as duplicates.  We describe those situations and what should happen. -->

<!-- Original, born visible.  The obvious situation, we render the element as part of the page, adding identifying information.  The template sets the "b-original" flag to true by default, for this reason.  Children of the element are incorporated (through the modal body templates) as originals (visible and/or hidden) by passing along the "b-original" flag. -->

<!-- Original, born hidden.  The element knows if it should be hidden on the page in an embedded knowl via the modal "is-hidden" template.  So a link is written on the page, and the main content is written onto the page as a hidden, embedded knowl.  The "b-original" flag (set to true) is passed through to templates for the children. -->

<!-- Duplicates.  Duplicated versions, sans identification, are created by an extra, specialized, traversal of the entire document tree with the "xref-knowl" modal templates.  When an element is first encountered the infrastructure for an external file is constructed and the modal "body" template of the element is called with the "b-original" flag set to false.  The content of the knowl should have an overall header, explaining what it is, since it is a target of the cross-reference.  Now the body template will pass along the "b-original" flag set to false, indicating the production mode should be duplication.  For a block that is born hidden, we build an additional external knowl that duplicates it, so without identification, without an overall header, and without an in-context link.  -->

<!-- Child elements born visible will be written into knowl files without identification.  Child elements born hidden will write a knowl link into the page, pointing to the duplicated (hidden) version.  -->

<!-- The upshot is that the main pages have visible content and hidden, embedded content (knowls) with full identification as original canonical versions.  Cross-references open external file knowls, whose hidden components are again accessed via knowls that use external files of duplicated content.  None of the knowl files contain any identification, so these identifiers remain unique in their appearances as part of the main pages. -->

<!-- This process is controlled by the boolean "b-original" parameter, which needs to be laboriously passed down and through templates, including containers like "sidebyside."  The XSLT 2.0 tunnel parameter would be a huge advantage here.  The parameter "block-type" can take on the values: 'visible', 'embed', 'xref', 'hidden'.  The four situations above can be identified with these parameters.  The block-type parameter is also used to aid in placement of identification.  For example, an element born visible will have an HTML id on its outermost element, such as an "article".  But as an embedded knowl, we put the id onto the visible link text instead, even if the same outermost element is employed for the hidden content. -->

<!-- The relevant templates controlling production of a block, and their use, are: -->

<!-- (1) "is-hidden":  mandatory, value is 'true' or 'false' (could move to a boolean), controls visible or hidden property, so usd in a variety of situations to control flow.  Often fixed, but also responds to options. (As boolean: do conditionals in global text variable, then check value in "select" of new global boolean variable.) -->

<!-- (2) "body-element", "body-css-class": useful for general production, but sometimes its employment leads to requiring exceptional templates (eg display math).  The outermost HTML element of a block.  Sometimes it gets an ID, sometimes not, which is its main purpose.  Employed in "body" templates (see below). -->

<!-- (3) "heading-birth": produces HTML immediately interior to the "body-element", for visible blocks, in both the original and duplication processes.  Similarly, it is the link-text of a knowl for a block that is hidden (again in original or duplication modes).  Employed in "body" templates. -->

<!-- (4) "birth-element": 'div' or 'span' to wrap hidden knowl links and contents so they appear correctly on a page (block or inline, basically). -->

<!-- (5) "heading-xref-knowl": when a knowl is a target of a cross-reference, sometimes a better heading is necessary to help identify it.  For example, a cross-refernce to a list item can be improved by providing the number of the item in a heading. -->

<!-- (6) "body": main template to produce the HTML "body" portion of a knowl, or the content displayed on a page.  Reacts to four modes: 'visible' (original or duplicate), 'embed', or 'xref'. -->

<!-- (7) TODO: "wrapped-content" called by "body" to separate code. -->

<!-- &SOLUTION-LIKE; is replaced by WW-avoiding versions -->
<xsl:template match="&REMARK-LIKE;|&COMPUTATION-LIKE;|&DEFINITION-LIKE;|&ASIDE-LIKE;|poem|&FIGURE-LIKE;|assemblage|blockquote|paragraphs|objectives|&EXAMPLE-LIKE;|exercisegroup|exercise|&PROJECT-LIKE;|task|hint[not(ancestor::webwork)]|answer[not(ancestor::webwork)]|solution[not(ancestor::webwork)]|&THEOREM-LIKE;|&AXIOM-LIKE;|proof|case|fn|contributor|biblio|biblio/note|p|li|webwork[*|@*]|me|men|md|mdn">
    <xsl:param name="b-original" select="true()" />
    <xsl:variable name="hidden">
        <xsl:apply-templates select="." mode="is-hidden" />
    </xsl:variable>
    <xsl:choose>
        <!-- born-hidden case -->
        <xsl:when test="$hidden = 'true'">
            <xsl:choose>
                <!-- primary occurrence, born hidden as embedded knowl     -->
                <!-- is original flag pass-thru necessary?  always true()? -->
                <xsl:when test="$b-original">
                    <xsl:apply-templates select="." mode="born-hidden">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- duplicating, so just make a xref-knowl in same style, -->
                <!-- but therefore clean of id's or other identification   -->
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="duplicate-born-hidden">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- born-visible case -->
        <xsl:otherwise>
            <!-- pass-thru of b-original mandatory -->
            <xsl:apply-templates select="." mode="born-visible">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="born-visible">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="." mode="body">
        <xsl:with-param name="block-type" select="'visible'" />
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="*" mode="born-hidden">
    <xsl:param name="b-original" select="true()" />
    <xsl:variable name="birth-elt">
        <xsl:apply-templates select="." mode="birth-element" />
    </xsl:variable>
    <!-- First: the link that is visible on the page         -->
    <xsl:variable name="body-elt">
        <xsl:apply-templates select="." mode="body-element" />
    </xsl:variable>
    <!-- If body-element is a span, that is an indicator that the   -->
    <!-- bare "a" link is sufficient and it needs no more wrapping. -->
    <!-- Presently: hint, answer, solution, footnote, biblio        -->
    <!-- TODO: use a better indicator, perhaps an empty body-element -->
    <xsl:element name="{$body-elt}">
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="body-css-class" />
        </xsl:attribute>
        <!-- this horrible hack should go away once better CSS is in place -->
        <!-- likely this particular version never gets used                -->
        <xsl:if test="self::poem">
            <xsl:attribute name="style">
                <xsl:text>display: table; width: auto; max-width: 90%; margin: 0 auto;</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="." mode="hidden-knowl-link" />
    </xsl:element>
    <!-- Second: the content of the knowl, to be revealed/parsed later -->
    <xsl:apply-templates select="." mode="hidden-knowl-content">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- An external file knowl, impersonating a hidden knowl -->
<xsl:template match="*" mode="duplicate-born-hidden">
    <xsl:param name="b-original" select="false()" />
    <xsl:variable name="birth-elt">
        <xsl:apply-templates select="." mode="birth-element" />
    </xsl:variable>
    <xsl:variable name="body-elt">
        <xsl:apply-templates select="." mode="body-element" />
    </xsl:variable>
    <xsl:element name="{$body-elt}">
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="body-css-class" />
        </xsl:attribute>
        <!-- this horrible hack should go away once better CSS is in place -->
        <!-- likely this particular version never gets used                -->
        <xsl:if test="self::poem">
            <xsl:attribute name="style">
                <xsl:text>display: table; width: auto; max-width: 90%; margin: 0 auto;</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="." mode="duplicate-hidden-knowl-link" />
    </xsl:element>
</xsl:template>

<!-- Hidden knowls are in two pieces.  This template -->
<!-- ensures consistency of the common, linking id.  -->
<xsl:template match="*" mode="hidden-knowl-id">
    <xsl:text>hk-</xsl:text>  <!-- "hidden-knowl" -->
    <xsl:apply-templates select="." mode="internal-id" />
</xsl:template>

<!-- The link portion of a hidden-knowl -->
<xsl:template match="*" mode="hidden-knowl-link">
    <!-- TODO: only being used here as block/inline signal -->
    <xsl:variable name="birth-elt">
        <xsl:apply-templates select="." mode="birth-element" />
    </xsl:variable>
    <xsl:element name="a">
        <xsl:choose>
            <!-- Hack: WW not working from embedded knowls,     -->
            <!-- so go with external file of duplicated content -->
            <!-- as the form og the "a" tag, preserving styling -->
            <xsl:when test="self::webwork">
                <!-- copied from "xref-link" template,  -->
                <!-- maybe build a 2-parameter template -->
                <xsl:attribute name="knowl">
                    <xsl:apply-templates select="." mode="hidden-knowl-filename" />
                </xsl:attribute>
                <!-- TODO: check if this "knowl-id" is needed, knowl.js implies it is -->
                <xsl:attribute name="knowl-id">
                    <xsl:text>hidden-</xsl:text>
                    <xsl:apply-templates select="." mode="internal-id" />
                </xsl:attribute>
                <!-- add HTML title and alt attributes to the link -->
                <xsl:attribute name="alt">
                    <xsl:apply-templates select="." mode="tooltip-text" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:apply-templates select="." mode="tooltip-text" />
                </xsl:attribute>
                <xsl:apply-templates select="." mode="heading-birth" />
            </xsl:when>
            <!-- this is the "real" code, bust out once WW fixed -->
            <xsl:otherwise>
                <!-- empty, indicates content *not* in a file -->
                <xsl:attribute name="knowl" />
                <!-- id-ref class means content is in div referenced by id -->
                <xsl:attribute name="class">
                    <xsl:text>id-ref</xsl:text>
                </xsl:attribute>
                <!-- and the id via a template for consistency -->
                <xsl:attribute name="refid">
                    <xsl:apply-templates select="." mode="hidden-knowl-id" />
                </xsl:attribute>
                <!-- make the anchor a target, eg of an in-context link -->
                <!-- label original -->
                <xsl:attribute name="id">
                    <xsl:apply-templates select="." mode="internal-id" />
                </xsl:attribute>
                <!-- marked-up knowl text link *inside* of knowl anchor to be effective -->
                <!-- heading in an HTML container -->
                <xsl:apply-templates select="." mode="heading-birth" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:element>
</xsl:template>

<!-- The content portion of a hidden knowl -->
<!-- *Always* as div.hidden-content"       -->
<!-- TODO: exception is a footnote until we  -->
<!-- move out of the interior of a paragraph -->
<xsl:template match="*" mode="hidden-knowl-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:variable name="hidden-content-type">
        <xsl:choose>
            <xsl:when test="self::fn">
                <xsl:text>span</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>div</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$hidden-content-type}">
        <!-- different id, for use by the knowl mechanism -->
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="hidden-knowl-id" />
        </xsl:attribute>
        <!-- .hidden-content is CSS for display: none           -->
        <!-- Stop MathJax from processing contents on page load -->
        <xsl:attribute name="class">
            <xsl:text>hidden-content tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <!-- should the b-original flag always be true() here -->
        <xsl:apply-templates select="." mode="body">
            <xsl:with-param name="block-type" select="'embed'" />
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- The link for a duplicate hidden knowl -->
<xsl:template match="*" mode="duplicate-hidden-knowl-link">
    <xsl:variable name="birth-elt">
        <xsl:apply-templates select="." mode="birth-element" />
    </xsl:variable>
    <xsl:element name="a">
        <xsl:attribute name="knowl">
            <xsl:apply-templates select="." mode="hidden-knowl-filename" />
        </xsl:attribute>
        <!-- TODO: check if this "knowl-id" is needed, knowl.js implies it is -->
        <xsl:attribute name="knowl-id">
            <xsl:text>hidden-</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <!-- add HTML title and alt attributes to the link -->
        <xsl:attribute name="alt">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
        <xsl:attribute name="title">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="heading-birth" />
    </xsl:element>
</xsl:template>


<!-- ##################### -->
<!-- Block Implementations -->
<!-- ##################### -->

<!-- We devise the more straightforward blocks first, -->
<!-- saving the exceptions for subsequent exposition  -->

<!-- REMARK-LIKE -->
<!-- A simple block with full titles and generic contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&REMARK-LIKE;" mode="is-hidden">
    <xsl:value-of select="$html.knowl.remark = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&REMARK-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&REMARK-LIKE;" mode="body-css-class">
    <xsl:text>remark-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&REMARK-LIKE;" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&REMARK-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&REMARK-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&REMARK-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- COMPUTATION-LIKE -->
<!-- A simple block with full titles, but more substantial contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&COMPUTATION-LIKE;" mode="is-hidden">
    <xsl:value-of select="$html.knowl.remark = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&COMPUTATION-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&COMPUTATION-LIKE;" mode="body-css-class">
    <xsl:text>remark-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&COMPUTATION-LIKE;" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&COMPUTATION-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&COMPUTATION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&COMPUTATION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- DEFINITION-LIKE -->
<!-- A simple block with full titles and generic contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&DEFINITION-LIKE;" mode="is-hidden">
    <xsl:value-of select="$html.knowl.definition = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&DEFINITION-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&DEFINITION-LIKE;" mode="body-css-class">
    <xsl:text>definition-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&DEFINITION-LIKE;" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&DEFINITION-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&DEFINITION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&DEFINITION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- ASIDE-LIKE -->
<!-- A simple block with a title (no number) and generic contents -->

<!-- Never born-hidden, other devices partially hide -->
<xsl:template match="&ASIDE-LIKE;" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&ASIDE-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&ASIDE-LIKE;" mode="body-css-class">
    <xsl:text>aside-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&ASIDE-LIKE;" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&ASIDE-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&ASIDE-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="&ASIDE-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Poem -->
<!-- Titled, not numbered, but with an author's name. -->
<!-- Knowled as a cross-reference target, but never born  -->
<!-- hidden (for now particular reason).  A complicated  -->
<!-- implementation, which should rely more on CSS. -->

<!-- Never born-hidden, other devices partially hide -->
<xsl:template match="poem" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- TODO: consider this being an article? -->
<xsl:template match="poem" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="poem" mode="body-css-class">
    <xsl:text>poem</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="poem" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="poem" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-poem" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="poem" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-poem" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="poem" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="stanza" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <!-- author comes early in schema, but is rendered below -->
    <xsl:apply-templates select="author" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- TODO: Address GitHub issues regarding poetry output:   -->
<!-- https://github.com/BooksHTML/mathbook-assets/issues/65 -->

<xsl:template match="poem/author">
    <xsl:variable name="alignment">
        <xsl:apply-templates select="." mode="poem-halign"/>
    </xsl:variable>
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>poemauthor</xsl:text>
            <xsl:value-of select="$alignment" />
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>font-style: italic; padding-bottom: 20px; text-align: </xsl:text>
            <xsl:value-of select="$alignment" />
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>

<xsl:template match="stanza">
    <div class="stanza" style="padding-bottom: 20px">
        <xsl:if test="title">
            <div class="stanzatitle" style="font-weight: bold; text-align: center">
                <xsl:apply-templates select="." mode="title-full"/>
            </div>
        </xsl:if>
        <xsl:apply-templates select="line"/>
    </div>
</xsl:template>

<xsl:template match="stanza/line">
    <xsl:variable name="alignment">
        <xsl:apply-templates select="." mode="poem-halign"/>
    </xsl:variable>
    <xsl:variable name="indentation">
        <xsl:apply-templates select="." mode="poem-indent"/>
    </xsl:variable>
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>poemline</xsl:text>
            <xsl:value-of select="$alignment" />
        </xsl:attribute>
        <xsl:attribute name="style">
            <!-- Hanging indentation for overly long lines -->
            <xsl:text>margin-left: 4em; text-indent: -4em; </xsl:text>
            <xsl:text>text-align: </xsl:text>
            <xsl:value-of select="$alignment" />
        </xsl:attribute>
        <xsl:if test="$alignment='left'"><!-- Left Alignment: Indent from Left -->
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count"><xsl:value-of select="$indentation"/></xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:apply-templates/><!-- Center Alignment: Ignore Indentation -->
        <xsl:if test="$alignment='right'"><!-- Right Alignment: Indent from Right -->
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count"><xsl:value-of select="$indentation"/></xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:element>
</xsl:template>

<xsl:template name="poem-line-indenting">
    <xsl:param name="count"/>
    <xsl:choose>
        <xsl:when test="(0 >= $count)"/>
        <xsl:otherwise>
            <span class="tab" style="margin-left: 2em"></span>
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- FIGURE-LIKE -->
<!-- Captioned, titled (heading) -->

<!-- Born-hidden behavior is configurable -->
<!-- On a per-element basis               -->
<xsl:template match="figure" mode="is-hidden">
    <xsl:value-of select="$html.knowl.figure = 'yes'" />
</xsl:template>

<xsl:template match="table" mode="is-hidden">
    <xsl:value-of select="$html.knowl.table = 'yes'" />
</xsl:template>

<xsl:template match="listing" mode="is-hidden">
    <xsl:value-of select="$html.knowl.listing = 'yes'" />
</xsl:template>

<xsl:template match="list" mode="is-hidden">
    <xsl:value-of select="$html.knowl.list = 'yes'" />
</xsl:template>

<!-- The optionally born-hidden items can be panels of -->
<!-- a sidebyside, where we should not be hiding them. -->
<!-- A figure wrapping the sidebyside could be knowled -->
<!-- if they need to be hidden.                        -->
<xsl:template match="sidebyside/figure|sidebyside/table|sidebyside/listing|sidebyside/list" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="&FIGURE-LIKE;" mode="body-element">
    <xsl:text>figure</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&FIGURE-LIKE;" mode="body-css-class">
    <xsl:text>figure-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&FIGURE-LIKE;" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- TODO - sort out title/caption -->
<!-- Use title for xref-link text  -->

<!-- When born use this heading -->
<!-- no heading, since captioned -->
<xsl:template match="&FIGURE-LIKE;" mode="heading-birth" />
<!-- Sort of for backward compatibility, &FIGURE-LIKE; should be similar -->
<xsl:template match="list" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<!-- no heading, since captioned -->
<xsl:template match="&FIGURE-LIKE;" mode="heading-xref-knowl" />

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Handle "caption" exceptionally               -->
<!-- "list" is historically different, integrate? -->
<xsl:template match="&FIGURE-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <xsl:when test="self::figure or self::table or self::listing">
            <!-- could we just kill captions as metadata?             -->
            <!-- and make a modal template to process them as needed? -->
            <xsl:apply-templates select="*[not(self::caption)]">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
            <xsl:apply-templates select="caption" />
        </xsl:when>
        <xsl:when test="self::list">
            <div class="named-list-content">
                <xsl:apply-templates select="*[not(self::caption)]">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </div>
            <!-- Exceptional for backward compatibility, 2017-08-25 -->
            <xsl:if test="title and not(caption)">
                <figcaption>
                    <span class="type">
                        <xsl:apply-templates select="." mode="type-name"/>
                    </span>
                    <span class="codenumber">
                        <xsl:apply-templates select="." mode="number"/>
                    </span>
                    <xsl:apply-templates select="." mode="title-full" />
                </figcaption>
            </xsl:if>
            <xsl:apply-templates select="caption" />
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- Assemblage -->
<!-- A simple block with an optional title and limited contents -->

<!-- Never born-hidden, simply by design -->
<xsl:template match="assemblage" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="assemblage" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="assemblage" mode="body-css-class">
    <xsl:text>assemblage-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="assemblage" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="assemblage" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="assemblage" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Primary content of generic "body" template    -->
<!-- Pass along b-original flag                    -->
<!-- Simply process contents, restrictions match   -->
<!-- schema, except schema says no captioned items -->
<!-- in the side-by-side                           -->
<xsl:template match="assemblage" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="p|blockquote|pre|sidebyside|sbsgroup" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Block Quote -->
<!-- A very simple block with just an enclosing div -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="blockquote" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="blockquote" mode="body-element">
    <xsl:text>blockquote</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="blockquote" mode="body-css-class">
    <xsl:text>blockquote</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="blockquote" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading         -->
<!-- Never hidden, never gets a heading -->
<xsl:template match="blockquote" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="blockquote" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-type" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="blockquote" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Paragraphs -->
<!-- Technically a division, but small enough to xref knowl -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="paragraphs" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="paragraphs" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="paragraphs" mode="body-css-class">
    <xsl:text>paragraphs</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="paragraphs" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="paragraphs" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title-paragraphs" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="paragraphs" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title-paragraphs" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="paragraphs" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Objectives -->
<!-- A special, and restricted block -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="objectives" mode="is-hidden">
    <xsl:value-of select="$html.knowl.objectives = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="objectives" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="objectives" mode="body-css-class">
    <xsl:text>objectives</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="objectives" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="objectives" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full-implicit-number" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="objectives" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template        -->
<!-- Pass along b-original flag                        -->
<!-- Simply process contents, with partial restriction -->
<xsl:template match="objectives" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="introduction|ol|ul|dl|conclusion" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- The next few implementations have hints, answers, -->
<!-- or solutions hanging off the ends.  Examples may  -->
<!-- elect to have these.  Exercises may have them and -->
<!-- they are more configurable.  Projects may have    -->
<!-- them prima facie, or associated with tasks.  In   -->
<!-- all cases the hints, answers, and solutions are   -->
<!-- presented as knowls.                              -->

<!-- EXAMPLE-LIKE -->
<!-- A simple block, but with possible appendages -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&EXAMPLE-LIKE;" mode="is-hidden">
    <xsl:value-of select="$html.knowl.example = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&EXAMPLE-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&EXAMPLE-LIKE;" mode="body-css-class">
    <xsl:text>example-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&EXAMPLE-LIKE;" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&EXAMPLE-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&EXAMPLE-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Process according to structure              -->
<xsl:template match="&EXAMPLE-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <!-- structured version with appendages -->
        <xsl:when test="statement">
            <xsl:apply-templates select="statement/*" >
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
            <xsl:if test="hint|answer|solution">
                <div class="solutions">
                    <xsl:apply-templates select="hint|answer|solution">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </div>
            </xsl:if>
        </xsl:when>
        <!-- Potential common mistake: no statement, but other structure -->
        <xsl:when test="prelude|hint|answer|solution|postlude">
            <xsl:message>MBX:WARNING: a &lt;prelude&gt;, &lt;hint&gt;, &lt;answer&gt;, &lt;solution&gt;, or &lt;postlude&gt; in an example-like block will need to also be structured with a &lt;statement&gt;.  Content will be missing from output.</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <!-- unstructured, no need to avoid dangerous misunderstandings -->
        <xsl:otherwise>
            <xsl:apply-templates select="*">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Exercise Group -->
<!-- A very simple block with just an enclosing div -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="exercisegroup" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="exercisegroup" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="exercisegroup" mode="body-css-class">
    <xsl:text>exercisegroup</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="exercisegroup" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading         -->
<!-- Never hidden, never gets a heading -->
<xsl:template match="exercisegroup" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="exercisegroup" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-type" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="exercisegroup" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="introduction">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>exercisegroup-exercises</xsl:text>
            <xsl:if test="@cols">
                <xsl:text> </xsl:text>
                <!-- HTML-specific, but in mathbook-common.xsl -->
                <xsl:apply-templates select="." mode="number-cols-CSS-class" />
            </xsl:if>
        </xsl:attribute>
        <xsl:apply-templates select="exercise">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
    <xsl:apply-templates select="conclusion">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Exercise -->
<!-- Inline and sectional, with appendages -->

<!-- Born-hidden behavior is configurable -->
<!-- Note match first on inline first, override if sectional -->
<xsl:template match="exercise" mode="is-hidden">
    <xsl:value-of select="$html.knowl.exercise.inline = 'yes'" />
</xsl:template>
<xsl:template match="exercises//exercise" mode="is-hidden">
    <xsl:value-of select="$html.knowl.exercise.sectional = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="exercise" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="exercise" mode="body-css-class">
    <xsl:text>exercise-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="exercise" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<!-- Note match first on inline, override if sectional -->
<xsl:template match="exercise" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>
<xsl:template match="exercises//exercise" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-sectional-exercise" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<!-- Note match first on inline, override if sectional -->
<xsl:template match="exercise" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>
<xsl:template match="exercises//exercise" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-sectional-exercise-typed" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Process according to structure              -->
<xsl:template match="exercise" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <!-- just an unstructured statement, no solutions -->
        <xsl:when test="not(statement or webwork or myopenmath)">
            <xsl:apply-templates select="*|text()">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- structured case -->
        <xsl:when test="statement">
            <xsl:if test="$exercise.text.statement='yes'">
                <xsl:apply-templates select="statement">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </xsl:if>
            <!-- after statement, div of hidden knowls -->
            <xsl:if test="(hint and $exercise.text.hint='yes') or (answer and $exercise.text.answer='yes') or (solution and $exercise.text.solution='yes')">
                <div class="solutions">
                    <xsl:if test="$exercise.text.hint='yes'">
                        <xsl:apply-templates select="hint">
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:if test="$exercise.text.answer='yes'">
                        <xsl:apply-templates select="answer">
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:if test="$exercise.text.solution='yes'">
                        <xsl:apply-templates select="solution">
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:if>
                </div>
            </xsl:if>
        </xsl:when>
        <!-- webwork case -->
        <xsl:when test="webwork">
            <xsl:apply-templates select="introduction|webwork|conclusion">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- MyOpenMath case -->
        <xsl:when test="myopenmath">
            <xsl:apply-templates select="introduction|myopenmath|conclusion">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- Project-LIKE -->
<!-- A complex block, possibly structured with task -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&PROJECT-LIKE;" mode="is-hidden">
    <xsl:value-of select="$html.knowl.project = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&PROJECT-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&PROJECT-LIKE;" mode="body-css-class">
    <xsl:text>example-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&PROJECT-LIKE;" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&PROJECT-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&PROJECT-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Process according to structure              -->
<xsl:template match="&PROJECT-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <!-- structured versions first      -->
        <!-- prelude?, introduction?, task+,   -->
        <!-- conclusion?, postlude? -->
        <xsl:when test="task">
            <xsl:apply-templates select="introduction|task|conclusion">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- Now no project/task possibility -->
        <!-- prelude?, statement, hint*,   -->
        <!-- answer*, solution*, postlude? -->
        <xsl:when test="statement">
            <xsl:apply-templates select="statement">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
            <!-- this could be a useful three-parameter template -->
            <xsl:if test="(hint and $project.text.hint='yes') or (answer and $project.text.answer='yes') or (solution and $project.text.solution='yes')">
                <!-- then can populate div full of solution -->
                <div class="solutions">
                    <xsl:if test="$project.text.hint='yes'">
                        <xsl:apply-templates select="hint">
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:if test="$project.text.answer='yes'">
                        <xsl:apply-templates select="answer">
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:if test="$project.text.solution='yes'">
                        <xsl:apply-templates select="solution">
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:if>
                </div>
            </xsl:if>
        </xsl:when>
        <!-- Potential common mistake: no statement, but other structure -->
        <xsl:when test="prelude|hint|answer|solution|postlude">
            <xsl:message>MBX:WARNING: a &lt;prelude&gt;, &lt;hint&gt;, &lt;answer&gt;, &lt;solution&gt;, or &lt;postlude&gt; in a project-like block will need to also be structured with a &lt;statement&gt;.  Content will be missing from output.</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <!-- unstructured, no need to avoid dangerous misunderstandings -->
        <xsl:otherwise>
            <xsl:apply-templates select="*">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Task -->
<!-- A division of a PROJECT-LIKE, with appendages -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="task" mode="is-hidden">
    <xsl:value-of select="$html.knowl.task = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="task" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="task" mode="body-css-class">
    <xsl:text>exercise-like</xsl:text>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="task" mode="birth-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="task" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-list-number" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="task" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Process according to structure               -->
<xsl:template match="task" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <!-- introduction?, task+, conclusion? -->
        <xsl:when test="task">
            <xsl:apply-templates select="introduction|task|conclusion">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- statement, hint*, answer*, solution* -->
        <xsl:when test="statement">
            <xsl:if test="$task.text.statement='yes'">
                <xsl:apply-templates select="statement">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </xsl:if>
            <!-- this could be a useful three-parameter template -->
            <xsl:if test="(hint and $project.text.hint='yes') or (answer and $project.text.answer='yes') or (solution and $project.text.solution='yes')">
                <!-- then can populate div full of solution -->
                <div class="solutions">
                    <xsl:if test="$project.text.hint='yes'">
                        <xsl:apply-templates select="hint">
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:if test="$project.text.answer='yes'">
                        <xsl:apply-templates select="answer">
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:if test="$project.text.solution='yes'">
                        <xsl:apply-templates select="solution">
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:if>
                </div>
            </xsl:if>
        </xsl:when>
        <!-- Potential common mistake: no statement, or no task, but other structure -->
        <xsl:when test="prelude|introduction|hint|answer|solution|conclusion|postlude">
            <xsl:message>MBX:WARNING: a &lt;prelude&gt;, &lt;introduction&gt;, &lt;hint&gt;, &lt;answer&gt;, &lt;solution&gt;, &lt;conclusion&gt;, or &lt;postlude&gt; in a task will need to also be structured with a &lt;statement&gt; or as a sequence of &lt;task&gt; with optional , &lt;introduction&gt; or &lt;conclusion&gt;.  Content will be missing from output.</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <!-- unstructured, no need to avoid dangerous misunderstandings -->
        <xsl:otherwise>
            <xsl:apply-templates select="*">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- SOLUTION-LIKE -->
<!-- A simple item hanging off others -->

<!-- Always born-hidden, by design -->
<xsl:template match="&SOLUTION-LIKE;" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&SOLUTION-LIKE;" mode="body-element">
    <xsl:text>span</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&SOLUTION-LIKE;" mode="body-css-class">
    <xsl:text>solution</xsl:text>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="&SOLUTION-LIKE;" mode="birth-element">
    <xsl:text>span</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&SOLUTION-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&SOLUTION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="&SOLUTION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- The next few implementions support theorems,       -->
<!-- which may have knowls containing proofs hanging    -->
<!-- off them.  A proof can be a block in its own right -->
<!-- (a "detached" proof).                              -->


<!-- THEOREM-LIKE, AXIOM-LIKE -->
<!-- Similar blocks, former may have a proof appendage -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="is-hidden">
    <xsl:value-of select="$html.knowl.theorem = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="body-css-class">
    <xsl:text>theorem-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*[not(self::proof)]" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Proof -->
<!-- A fairly simple block, though configurable -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="proof" mode="is-hidden">
    <xsl:value-of select="$html.knowl.proof = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="proof" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<!-- Only subsidiary item that is configurable -->
<!-- as visible or hidden in a knowl           -->
<xsl:template match="proof" mode="body-css-class">
    <xsl:choose>
        <xsl:when test="$html.knowl.proof = 'yes'">
            <xsl:text>hiddenproof</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>proof</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Trailing as a hidden knowl, or plainly  -->
<!-- visible, a proof is a block level item  -->
<xsl:template match="proof" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="proof" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-type" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="proof" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-type" />
</xsl:template>


<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Simply process contents, could restict here -->
<xsl:template match="proof" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Case (of a proof) -->
<!-- A simple block with an inline heading -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="case" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="case" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="case" mode="body-css-class">
    <xsl:text>case</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="case" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- When born use this specialized heading -->
<xsl:template match="case" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-case" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="case" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-case" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="case" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Next few implementations fit into general -->
<!-- framework, but have some one-off flavor   -->


<!-- Footnotes -->
<!-- A bit unusual, as inline with minimal appearance -->

<!-- Always born-hidden, by design -->
<xsl:template match="fn" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="fn" mode="body-element">
    <xsl:text>span</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="fn" mode="body-css-class">
    <xsl:text>footnote</xsl:text>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="fn" mode="birth-element">
    <xsl:text>span</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<!-- This could move to headings, but is one-off -->
<xsl:template match="fn" mode="heading-birth">
    <xsl:element name="sup">
        <xsl:text>&#x2009;</xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
        <xsl:text>&#x2009;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="fn" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Schema is TextLong, so need to process mixed -->
<xsl:template match="fn" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*|text()" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Contributor -->
<!-- A block with no subsidiary elements, no duplication -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="contributor" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="contributor" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="contributor" mode="body-css-class">
    <xsl:text>contributor</xsl:text>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="contributor" mode="birth-element">
    <xsl:text>span</xsl:text>
</xsl:template>

<!-- Heading is not needed -->
<xsl:template match="contributor" mode="heading-birth" />

<!-- xref-knowl content makes it obvious-->
<xsl:template match="contributor" mode="heading-xref-knowl" />

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="contributor" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <!-- not interpreting duplication flag here -->
    <div class="contributor-name">
        <xsl:apply-templates select="personname" />
    </div>
    <div class="contributor-info">
        <xsl:if test="department">
            <xsl:apply-templates select="department" />
            <xsl:if test="department/following-sibling::*">
                <br />
            </xsl:if>
        </xsl:if>
        <xsl:if test="institution">
            <xsl:apply-templates select="institution" />
            <xsl:if test="institution/following-sibling::*">
                <br />
            </xsl:if>
        </xsl:if>
        <xsl:if test="location">
            <xsl:apply-templates select="location" />
            <xsl:if test="location/following-sibling::*">
                <br />
            </xsl:if>
        </xsl:if>
        <xsl:if test="email">
            <xsl:apply-templates select="email" />
            <xsl:if test="email/following-sibling::*">
                <br />
            </xsl:if>
        </xsl:if>
    </div>
</xsl:template>


<!-- Bibliographic Entries -->
<!-- An obvious use for knowls, but occur inline -->

<!-- Never born-hidden, always in references -->
<xsl:template match="biblio" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="biblio" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="biblio" mode="body-css-class">
    <xsl:text>bib</xsl:text>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="biblio" mode="birth-element">
    <xsl:text>span</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="biblio" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<!-- Not necessary, obvious by appearance       -->
<xsl:template match="biblio" mode="heading-xref-knowl" />

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Schema is TextLong, so need to process mixed -->
<xsl:template match="biblio" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <!-- ignoring original flag at first, -->
    <!-- nothing interior gets duplicated -->
    <div class="bibitem">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
        <xsl:text>]</xsl:text>
    </div>
    <xsl:text>&#xa0;&#xa0;</xsl:text>
    <div class="bibentry">
        <xsl:apply-templates select="text()|*[not(self::note)]">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </div>
    <xsl:if test="note">
        <div class="knowl-container">
            <xsl:apply-templates select="note">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </div>
    </xsl:if>
</xsl:template>

<!-- Bibliographic Note -->
<!-- A simple item hanging off others -->

<!-- Always born-hidden, by design -->
<xsl:template match="biblio/note" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="biblio/note" mode="body-element">
    <xsl:text>span</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<!-- This is a temporary hack, which should go away -->
<xsl:template match="biblio/note" mode="body-css-class">
    <xsl:text>solution</xsl:text>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="biblio/note" mode="birth-element">
    <xsl:text>span</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="biblio/note" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="biblio/note" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Schema says just paragraphs, "p"             -->
<xsl:template match="biblio/note" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="p" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- All of the implementations above use the same   -->
<!-- template for their body, it relies on various   -->
<!-- templates but most of the work comes via the    -->
<!-- "wrapped-content" template.  Here is that       -->
<!-- "body" template.  The items in the "match"      -->
<!-- are in the order presented above: simple first, -->
<!-- and top-down when components are also knowled.  -->


<xsl:template match="&REMARK-LIKE;|&COMPUTATION-LIKE;|&DEFINITION-LIKE;|&ASIDE-LIKE;|poem|&FIGURE-LIKE;|assemblage|blockquote|paragraphs|objectives|&EXAMPLE-LIKE;|exercisegroup|exercise|&PROJECT-LIKE;|task|&SOLUTION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|proof|case|fn|contributor|biblio|biblio/note" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <!-- prelude beforehand, when original -->
    <xsl:if test="$b-original">
        <xsl:apply-templates select="prelude">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:if>
    <xsl:variable name="body-elt">
        <xsl:apply-templates select="." mode="body-element" />
    </xsl:variable>
    <xsl:element name="{$body-elt}">
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="body-css-class" />
        </xsl:attribute>
        <!-- Label original, but not if embedded            -->
        <!-- Then id goes onto the knowl text, so locatable -->
        <xsl:if test="$b-original and not($block-type = 'embed')">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
        </xsl:if>
        <!-- this horrible hack should go away once better CSS is in place -->
        <xsl:if test="self::poem">
            <xsl:attribute name="style">
                <xsl:text>display: table; width: auto; max-width: 90%; margin: 0 auto;</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <!-- If visible, heading interior to article -->
        <xsl:if test="$block-type = 'visible'">
            <xsl:apply-templates select="." mode="heading-birth" />
        </xsl:if>
        <!-- If xref-knowl, heading interior to article -->
        <xsl:if test="$block-type = 'xref'">
            <xsl:apply-templates select="." mode="heading-xref-knowl" />
        </xsl:if>
        <!-- Then actual content, respecting b-original flag -->
        <xsl:apply-templates select="." mode="wrapped-content">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
    <!-- Extraordinary: proofs are not displayed within their    -->
    <!-- parent theorem, but as a sibling, following.  It might  -->
    <!-- be a hidden knowl, it might just be the proof visible.  -->
    <!-- The conditional simply prevents abuse.                  -->
    <xsl:if test="(&THEOREM-FILTER;)">
        <xsl:apply-templates select="proof">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:if>
    <!-- postlude afterward, when original -->
    <xsl:if test="$b-original">
        <xsl:apply-templates select="postlude">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>


<!-- The following feed into the same framework,   -->
<!-- but have their own specific "body" templates  -->
<!-- due to their unique characteristics.  We have -->
<!-- paragraphs ("p"), list items ("li"), webwork  -->
<!-- exercises ("webwork"), and numbered           -->
<!-- mathematics ("men", "md", "mdn")              -->


<!-- Paragraph -->
<!-- These are never born hidden.  They are     -->
<!-- often xref targets (such as in the index). -->
<!-- Because we bust up some paragraphs into    -->
<!-- smaller ones, interleaved with displays    -->
<!-- (lists, math, code display), and because   -->
<!-- they do not have titles or heading,        -->
<!-- we process everything in the body.         -->

<xsl:template match="p" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="p" mode="body-element" />

<xsl:template match="p" mode="body-css-class" />

<xsl:template match="p" mode="heading-birth" />

<xsl:template match="p" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-type" />
</xsl:template>

<!-- Paragraphs, without lists within -->
<xsl:template match="p" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:if test="$block-type = 'xref'">
        <xsl:apply-templates select="." mode="heading-xref-knowl" />
    </xsl:if>
    <p>
        <!-- label original -->
        <xsl:if test="$b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="*|text()">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </p>
</xsl:template>

<!-- Paragraphs, with displays within                   -->
<!-- Later, so a higher priority match                  -->
<!-- Lists and display math are HTML blocks             -->
<!-- and so should not be within an HTML paragraph.     -->
<!-- We bust them out, and put the id for the paragraph -->
<!-- on the first one, even if empty.                   -->
<xsl:template match="p[ol|ul|dl|me|men|md|mdn|cd]" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:if test="$block-type = 'xref'">
        <xsl:apply-templates select="." mode="heading-xref-knowl" />
    </xsl:if>
    <!-- will later loop over displays within paragraph -->
    <xsl:variable name="displays" select="ul|ol|dl|me|men|md|mdn|cd" />
    <!-- content prior to first display is exceptional, but if empty,   -->
    <!-- as indicated by $initial, we do not produce an empty paragraph -->
    <!-- NB: this means first display must check for no predecessor,    -->
    <!-- and react accordingly to employ the real paragraph's id.  See  -->
    <!-- the modal "insert-paragraph-id" jsut below, and its employment -->
    <!--                                                                -->
    <!-- all interesting nodes of paragraph, before first display       -->
    <xsl:variable name="initial" select="$displays[1]/preceding-sibling::*|$displays[1]/preceding-sibling::text()" />
    <xsl:variable name="initial-content">
        <xsl:apply-templates select="$initial">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="not($initial-content='')">
        <p>
            <xsl:if test="$b-original">
                <xsl:attribute name="id">
                    <xsl:apply-templates select="." mode="internal-id" />
                </xsl:attribute>
            </xsl:if>
            <xsl:copy-of select="$initial-content" />
        </p>
    </xsl:if>
    <!-- for each display, output the display, plus trailing content -->
    <xsl:for-each select="$displays">
        <!-- do the display proper -->
        <xsl:apply-templates select=".">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <!-- look through remainder, all element and text nodes, and the next display -->
        <xsl:variable name="rightward" select="following-sibling::*|following-sibling::text()" />
        <xsl:variable name="next-display" select="following-sibling::*[self::ul or self::ol or self::dl or self::me or self::men or self::md or self::mdn or self::cd][1]" />
        <xsl:choose>
            <xsl:when test="$next-display">
                <xsl:variable name="leftward" select="$next-display/preceding-sibling::*|$next-display/preceding-sibling::text()" />
                <!-- device below forms set intersection -->
                <xsl:variable name="common" select="$rightward[count(. | $leftward) = count($leftward)]" />
                <!-- No id on these, as the first "p" got that    -->
                <!-- Careful, punctuation after display math      -->
                <!-- gets absorbed into display and so is a node  -->
                <!-- that produces no content (cannot just count) -->
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$common">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:variable>
                <!-- XSLT 1.0: string value of $common-content RTF is just first node? -->
                <!-- that is the most pressing case: trailing punctuation squashed     -->
                <xsl:if test="not($common-content = '')">
                    <p>
                        <xsl:copy-of select="$common-content" />
                    </p>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- finish the trailing content, if nonempty -->
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$rightward">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:variable>
                <!-- XSLT 1.0: string value of $common-content RTF is just first node? -->
                <!-- that is the most pressing case: trailing punctuation squashed     -->
                <xsl:if test="not($common-content = '')">
                    <p>
                        <xsl:copy-of select="$common-content" />
                    </p>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
</xsl:template>

<!-- We drop an empty "leading paragraph" above.  Whatever     -->
<!-- display comes next needs to grab the id of the enclosing  -->
<!-- paragraph and place it on the enclosing HTML element of   -->
<!-- that item.  So these displays should never have an id     -->
<!-- anyway.  Said differently, a paragraph should be atomic,  -->
<!-- and you cannot point to its constituents. The $b-original -->
<!-- flag is passed in by the enclosing paragraph and is not a -->
<!-- property of the display, per se, but instead is the       -->
<!-- paragraph's status.                                       -->
<xsl:template match="ul|ol|dl|me|men|md|mdn|cd" mode="insert-paragraph-id">
    <xsl:param name="b-original" select="true()" />
    <xsl:if test="parent::p and $b-original">
        <xsl:variable name="leading" select="preceding-sibling::*|preceding-sibling::text()" />
        <xsl:variable name="leading-content">
            <xsl:apply-templates select="$leading">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:if test="$leading-content = ''">
            <xsl:attribute name="id">
                <xsl:apply-templates select="parent::p" mode="internal-id" />
            </xsl:attribute>
        </xsl:if>
    </xsl:if>
</xsl:template>


<!-- List Items -->
<!-- A list item can be the target of a        -->
<!-- cross-reference, so we need to make       -->
<!-- a xref-knowl for that scenario.  Also,    -->
<!-- we produce the original versions here     -->
<!-- too.  The "ol, "ul", "dl" are pure        -->
<!-- containers and are implemented elsewhere. -->

<!-- Not applicable -->
<xsl:template match="li" mode="is-hidden" />

<xsl:template match="li" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- not yet supported, change this? -->
<xsl:template match="li" mode="body-css-class">
    <xsl:text>listitem</xsl:text>
</xsl:template>

<!-- Not applicable -->
<xsl:template match="li" mode="birth-element" />

<!-- Not applicable -->
<xsl:template match="li" mode="heading-birth" />

<xsl:template match="li" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Pass-through regular list items    -->
<!-- Allow paragraphs in larger items,  -->
<!-- or just snippets for smaller items -->
<!-- radically diffferent looks if part -->
<!-- of overall list versus being a     -->
<!-- standalone display of one item     -->
<xsl:template match="ol/li|ul/li" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <xsl:when test="$block-type = 'xref'">
            <article class="listitem">
                <xsl:apply-templates select="." mode="heading-xref-knowl" />
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </article>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="li">
                <!-- label original -->
                <xsl:if test="$b-original">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="internal-id" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Description list items have more structure -->
<!-- The id is placed on the title as a target  -->
<xsl:template match="dl/li" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <xsl:when test="$block-type = 'xref'">
            <article class="listitem">
                <!-- "title" of item is replicated in heading -->
                <xsl:apply-templates select="." mode="heading-xref-knowl" />
                <!-- a run of paragraphs, conceivably, title is killed -->
                <xsl:apply-templates select="*">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </article>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="dt">
                <!-- label original -->
                <xsl:if test="$b-original">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="internal-id" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates select="." mode="title-full" />
            </xsl:element>
            <xsl:element name="dd">
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################# -->
<!-- WeBWorK Exercises -->
<!-- ################# -->

<!-- Exceptional: mostly just "body" as alternate       -->
<!-- version, and control of hidden knowls via switches -->
<!-- We condition on non-empty version at entry points  -->

<xsl:template match="webwork" mode="is-hidden">
    <xsl:choose>
        <xsl:when test="ancestor::exercises and ($html.knowl.webwork.sectional='yes')">
            <xsl:text>true</xsl:text>
        </xsl:when>
        <xsl:when test="not(ancestor::exercises) and ($html.knowl.webwork.inline='yes')">
            <xsl:text>true</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>false</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Body element/css wraps hidden knowls -->
<!-- Here, not used to wrap for content   -->
<xsl:template match="webwork" mode="body-element">
    <xsl:text>span</xsl:text>
</xsl:template>

<xsl:template match="webwork" mode="body-css-class">
    <xsl:text>heading</xsl:text>
</xsl:template>

<xsl:template match="webwork" mode="birth-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- WeBWork exercises do not have titles of their own -->
<xsl:template match="webwork" mode="heading-birth">
    <xsl:text>Exercise</xsl:text>
</xsl:template>

<!-- When the knowl is opened, it is obvious what it is -->
<xsl:template match="webwork" mode="heading-xref-knowl" />

<!-- The guts of a WeBWork problem realized in HTML -->
<!-- This is heart of an external knowl version, or -->
<!-- what is born visible under control of a switch -->

<!-- Base64 resources for debugging encoding and transmission problems  -->
<!-- ASCII Table: http://www.rapidtables.com/code/text/ascii-table.htm  -->
<!-- Online Converter: http://www.freeformatter.com/base64-encoder.html -->

<xsl:template match="webwork" mode="body">
    <xsl:comment>use 'format=debug' on 'webwork' tag to debug problem</xsl:comment>
    <xsl:element name="iframe">
        <xsl:attribute name="width">100%</xsl:attribute> <!-- MBX specific -->
        <xsl:attribute name="src">
            <xsl:value-of select="concat($webwork-server,'/webwork2/html2xml?')"/>
            <xsl:text>&amp;answersSubmitted=0</xsl:text>
            <xsl:choose>
                <xsl:when test="@source">
                    <xsl:text>&amp;sourceFilePath=</xsl:text>
                    <xsl:value-of select="@source" />
                </xsl:when>
                <xsl:when test="not(. = '')">
                    <xsl:text>&amp;problemSource=</xsl:text>
                    <!-- formulate PG version with included routine -->
                    <!-- form base64 version for URL transmission -->
                    <xsl:variable name="pg-ascii">
                        <xsl:apply-templates select="." mode="pg" />
                    </xsl:variable>
                    <!-- A useful debugging message if WW problems misbehave            -->
                    <!-- Redirect output with 2> if there is too much at the console    -->
                    <!-- <xsl:message><xsl:value-of select="$pg-ascii" /></xsl:message> -->
                    <xsl:call-template name="b64:encode">
                        <xsl:with-param name="urlsafe" select="true()" />
                        <xsl:with-param name="asciiString">
                            <xsl:value-of select="$pg-ascii" />
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>
                <!-- problem not authored, nor pointed at -->
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>MBX:WARNING: A webwork problem requires a source URL or original content</xsl:text>
                        <xsl:apply-templates select="." mode="location-report" />
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>&amp;problemSeed=</xsl:text>
            <xsl:choose>
                <xsl:when test="@seed">
                    <xsl:value-of select="@seed"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>123567890</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>&amp;displayMode=MathJax</xsl:text>
            <xsl:text>&amp;courseID=</xsl:text>
            <xsl:value-of select="$webwork.course"/>
            <xsl:text>&amp;userID=</xsl:text>
            <xsl:value-of select="$webwork.userID"/>
            <xsl:choose>
                <xsl:when test="$webwork.version='2.11'">
                    <xsl:text>&amp;password=</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>&amp;course_password=</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$webwork.password"/>
            <xsl:text>&amp;outputformat=</xsl:text>
            <xsl:choose>
                <xsl:when test="@format"><xsl:value-of select="@format" /></xsl:when>
                <xsl:otherwise><xsl:text>simple</xsl:text></xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <!-- unclear what this does, mimicing Mike's blog post -->
        <xsl:if test="not(. = '')">
            <xsl:attribute name="base64"><xsl:text>1</xsl:text></xsl:attribute>
            <xsl:attribute name="uri"><xsl:text>1</xsl:text></xsl:attribute>
        </xsl:if>
    </xsl:element> <!-- end iframe -->
    <script type="text/javascript">
        <xsl:text>iFrameResize({scrolling:true,minHeight:500,heightCalculationMethod:'max',log:true,inPageLinks:true,resizeFrom:'child',checkOrigin:["</xsl:text> <xsl:value-of select="$webwork-server" /><xsl:text>"]})</xsl:text>
    </script>
</xsl:template>


<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Mathematics authored in LaTeX syntax should be       -->
<!-- independent of output format.  Despite MathJax's     -->
<!-- broad array of capabilities, there are still some    -->
<!-- differences which we need to accomodate via abstract -->
<!-- templates.                                           -->

<!-- Inline Mathematics ("m") -->

<!-- Never labeled, so not ever knowled,        -->
<!-- and so no need for a duplicate template    -->
<!-- Asymmetric LaTeX delimiters \( and \) need -->
<!-- to be part of MathJax configuration, but   -->
<!-- also free up the dollar sign               -->

<!-- These two templates provide the delimiters for -->
<!-- inline math, so we can adjust with overides.   -->
<xsl:template name="begin-inline-math">
    <xsl:text>\(</xsl:text>
</xsl:template>

<xsl:template name="end-inline-math">
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- The general modal template "get-clause-punctuation"      -->
<!-- does exactly what we need here to fix up bad line-breaks -->
<!-- in HTML/MathJax rendering, so there is no override       -->


<!-- Displayed Single-Line Math ("me", "men") -->

<!-- All displayed mathematics is wrapped by a div,    -->
<!-- motivated in part by the need to sometimes put an -->
<!-- HTML id on the first item of an exploded logical  -->
<!-- paragraph into several HTML block level items     -->
<!-- NB: displaymath might have an intertext           -->
<!-- becoming "p", thus the necessity of "copy-of"     -->
<xsl:template match="me|men|md|mdn" mode="display-math-wrapper">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="content" />
    <div class="displaymath">
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:copy-of select="$content" />
    </div>
</xsl:template>

<!-- "men" needs to be handled in the knowl production          -->
<!-- scheme (but just barely), since it can be duplicated,      -->
<!-- and there are minor details with trailing punctuation.     -->
<!-- Then we just add "me" in as well, since it is so similar.  -->
<!-- The necessary modal "body" template is in -common, and     -->
<!-- is called by other conversions with the default variables. -->

<!-- We need a few templates for knowl production, -->
<!-- but generally they do nothing                 -->

<!-- always visible -->
<xsl:template match="me|men" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="me|men" mode="body-element" />
<xsl:template match="me|men" mode="body-css-class" />

<!-- No title; type and number obvious from content -->
<xsl:template match="me|men" mode="heading-xref-knowl" />

<!-- We need this so a % is used only on the LaTeX side -->
<xsl:template name="display-math-visual-blank-line">
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Manual Number Tagging -->
<!-- We do "tag" numbered equations in MathJax output, -->
<!-- because we want to control and duplicate the way  -->
<!-- numbers are generated and assigned by LaTeX       -->
<!-- "me" is never numbered/tagged, "men" always is    -->
<!-- This is the MathJax hard-coded technique          -->
<!-- Local tag preempts a hard-coded number, and we    -->
<!-- need to also take care with the numbering         -->
<!-- \label{} uses author's @xml:id as the logical,    -->
<!-- unique identifier in source and in HTML.  \tag{}  -->
<!-- is what a reader sees, usually the number         -->
<!-- computed in -common, but sometimes symbols        -->
<!-- generated by mrow/@tag                            -->

<xsl:template match="me" mode="tag" />

<xsl:template match="men|mrow" mode="tag">
    <xsl:param name="b-original" />
    <xsl:if test="$b-original and @xml:id">
        <xsl:text>\label{</xsl:text>
        <xsl:apply-templates select="." mode="internal-id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="mrow[@tag]" mode="tag">
    <xsl:param name="b-original" />
    <xsl:if test="$b-original and @xml:id">
        <xsl:text>\label{</xsl:text>
        <xsl:apply-templates select="." mode="internal-id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- \qedhere device is LaTeX only -->
<xsl:template match="me|men|mrow" mode="qed-here" />


<!-- Displayed Multi-Line Math ("md", "mdn") -->

<!-- The default template for the "md" and "mdn" containers   -->
<!-- just calls the modal "body" template needed for the HTML -->
<!-- knowl production scheme.                                 -->

<!-- We need a few templates for knowl production, -->
<!-- but generally they do nothing                 -->

<!-- always visible -->
<xsl:template match="md|mdn" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="md|mdn" mode="body-element" />
<xsl:template match="md|mdn" mode="body-css-class" />

<!-- No title; type and number obvious from content -->
<xsl:template match="md|mdn" mode="heading-xref-knowl" />

<!-- Rows of Displayed Multi-Line Math ("mrow") -->
<!-- Template in -common is sufficient with abstract templates -->
<!--                                                           -->
<!-- (1) "display-page-break"                                  -->
<!-- (2) "qed-here"                                            -->

<xsl:template match="mrow" mode="display-page-break" />

<!-- Intertext -->
<!-- A LaTeX construct really, we just jump out/in of    -->
<!-- the align/gather environment and process the text.  -->
<!-- "md" and "mdn" can only occur in a "p" and          -->
<!-- we break a logical PreTeXt "p" into multiple HTML   -->
<!-- "p" at places where displays occur, such as math    -->
<!-- and lists.  So we can wrap the "intertext" in a     -->
<!-- p.intertext, giving xref knowls a place to open.    -->
<!-- This breaks the alignment, but MathJax has no good  -->
<!-- solution for this.                                  -->
<!-- NB: "displaymath-alignment" needs to be just right  -->
<!-- NB: we check the *parent* for alignment information -->
<!-- NB: the out-of-order LaTeX begin/end pairs mean     -->
<!-- the "p" for intertext are contained in the overall  -->
<!-- "display-math-wrapper".  It might be advisable      -->
<!-- to unpack the whole md/mdn into math bits and       -->
<!-- intertext bits, similar to how paragraphs are       -->
<!-- exploded.  This will make it harder to locate       -->
<!-- the id of an enclosing paragraph onto the first     -->
<!-- component (first in exploded paragraph, first in    -->
<!-- exploded md/intertext).                             -->
<!-- An abstact "intertext-wrapper" would allow all      -->
<!-- this to live in -common.                            -->
<!-- TODO: pass duplication flag, reaction unnecessary?  -->
<xsl:template match="intertext">
    <xsl:param name="b-nonumbers" select="false()" />
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="parent::*" mode="displaymath-alignment">
        <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
    </xsl:apply-templates>
    <xsl:text>}&#xa;</xsl:text>
    <p class="intertext">
        <xsl:apply-templates />
    </p>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="parent::*" mode="displaymath-alignment">
        <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
    </xsl:apply-templates>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="parent::*" mode="alignat-columns" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- ############################# -->
<!-- End: Block Production, Knowls -->
<!-- ############################# -->


<!-- #################### -->
<!-- Components of Blocks -->
<!-- #################### -->

<!-- Introductions and Conclusions -->
<!-- As components of blocks.      -->
<xsl:template match="introduction[not(parent::*[&STRUCTURAL-FILTER;])]|conclusion[not(parent::*[&STRUCTURAL-FILTER;])]">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)" />
        </xsl:attribute>
        <xsl:if test="$b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="title">
            <h6 class="heading">
                <xsl:apply-templates select="." mode="title-full" />
                <span> </span>
            </h6>
        </xsl:if>
        <xsl:apply-templates select="*">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- Prelude, Interlude, Postlude -->
<!-- Very simple containiers, to help with movement, use -->
<xsl:template match="prelude|interlude|postlude">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- ########### -->
<!-- HTML Markup -->
<!-- ########### -->

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Utility templates to translate MBX              -->
<!-- enumeration style to HTML list-style-type       -->
<!-- NB: this is currently inferior to latex version -->
<!-- NB: all pre-, post-formatting is lost           -->
<xsl:template match="ol" mode="html-list-class">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$mbx-format-code = '1'">decimal</xsl:when>
        <xsl:when test="$mbx-format-code = 'a'">lower-alpha</xsl:when>
        <xsl:when test="$mbx-format-code = 'A'">upper-alpha</xsl:when>
        <xsl:when test="$mbx-format-code = 'i'">lower-roman</xsl:when>
        <xsl:when test="$mbx-format-code = 'I'">upper-roman</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad MBX ordered list label format code in HTML conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="ul" mode="html-list-class">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$mbx-format-code = 'disc'">disc</xsl:when>
        <xsl:when test="$mbx-format-code = 'circle'">circle</xsl:when>
        <xsl:when test="$mbx-format-code = 'square'">square</xsl:when>
        <xsl:when test="$mbx-format-code = 'none'">no-marker</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad MBX unordered list label format code in HTML conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Lists themselves -->
<!-- Hard-code the list style, trading -->
<!-- on match in label templates.      -->
<!-- Tunnel duplication flag to list items -->
<xsl:template match="ol|ul">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="{local-name(.)}">
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="html-list-class" />
            <xsl:if test="@cols">
                <xsl:text> </xsl:text>
                <!-- HTML-specific, but in mathbook-common.xsl -->
                <xsl:apply-templates select="." mode="number-cols-CSS-class" />
            </xsl:if>
        </xsl:attribute>
        <xsl:apply-templates select="li">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- We let CSS react to narrow titles for dl -->
<!-- But no support for multiple columns      -->
<!-- tunnel duplication flag to list items -->
<xsl:template match="dl">
    <xsl:param name="b-original" select="true()" />
    <dl>
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="@width = 'narrow'">
                    <xsl:text>description-list-narrow</xsl:text>
                </xsl:when>
                <!-- 'medium', 'wide', and any typo (let DTD check) -->
                <xsl:otherwise>
                    <xsl:text>description-list</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates select="li">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </dl>
</xsl:template>

<!-- ############################# -->
<!-- Widths of Images, Videos, Etc -->
<!-- ############################# -->

<!-- Anyway that an image gets placed in a sidebyside  -->
<!-- panel it should have a relative size filling that -->
<!-- panel, so this is easy, just 100% all the time    -->
<xsl:template match="image[ancestor::sidebyside]" mode="get-width-percentage">
    <xsl:text>100%</xsl:text>
</xsl:template>


<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- With a @source attribute, without an extension, -->
<!--   we presume an SVG has been manufactured       -->
<!-- With a @source attribute, with an extension,    -->
<!--   we write an HTML "img" tag with attributes    -->
<xsl:template match="image[@source]" >
    <!-- condition on file extension -->
    <!-- no period, lowercase'ed     -->
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename" select="@source" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
        <!-- no extension, presume SVG manufactured -->
        <xsl:when test="$extension=''">
            <xsl:call-template name="svg-wrapper">
                <xsl:with-param name="svg-filename">
                    <xsl:value-of select="@source" />
                    <xsl:text>.svg</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="png-fallback-filename" />
                <xsl:with-param name="image-width">
                    <xsl:apply-templates select="." mode="get-width-percentage" />
                </xsl:with-param>
                <xsl:with-param name="image-description">
                    <xsl:apply-templates select="description" />
                </xsl:with-param>
            </xsl:call-template>
            <!-- possibly annotate with archive links -->
            <xsl:apply-templates select="." mode="archive">
                <xsl:with-param name="base-pathname" select="@source" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- with extension, just include it -->
        <xsl:otherwise>
            <xsl:element name="img">
                <xsl:attribute name="width">
                    <xsl:apply-templates select="." mode="get-width-percentage" />
                </xsl:attribute>
                <xsl:attribute name="src">
                    <xsl:value-of select="@source" />
                </xsl:attribute>
                <!-- alt attribute for accessibility -->
                <xsl:attribute name="alt">
                    <xsl:apply-templates select="description" />
                </xsl:attribute>
            </xsl:element>
            <!-- possibly annotate with archive links -->
            <xsl:apply-templates select="." mode="archive">
                <xsl:with-param name="base-pathname">
                    <xsl:call-template name="substring-before-last">
                        <xsl:with-param name="input" select="@source" />
                        <xsl:with-param name="substr" select="'.'" />
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- SVG's produced by mbx script                  -->
<!--   Asymptote graphics language                 -->
<!--   LaTeX source code images                    -->
<!--   Sage graphics plots, w/ PNG fallback for 3D -->
<xsl:template match="image[asymptote]|image[latex-image-code]|image[latex-image]|image[sageplot]">
    <xsl:variable name="base-pathname">
        <xsl:value-of select="$directory.images" />
        <xsl:text>/</xsl:text>
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <xsl:call-template name="svg-wrapper">
        <xsl:with-param name="svg-filename" select="concat($base-pathname, '.svg')" />
        <!-- maybe empty, which is fine -->
        <xsl:with-param name="png-fallback-filename">
            <xsl:if test="sageplot">
                <xsl:value-of select="$base-pathname" />
                <xsl:text>.png</xsl:text>
            </xsl:if>
        </xsl:with-param>
        <xsl:with-param name="image-width">
            <xsl:apply-templates select="." mode="get-width-percentage" />
        </xsl:with-param>
        <xsl:with-param name="image-description">
            <xsl:apply-templates select="description" />
        </xsl:with-param>
    </xsl:call-template>
    <!-- possibly annotate with archive links -->
    <xsl:apply-templates select="." mode="archive">
        <xsl:with-param name="base-pathname" select="$base-pathname" />
    </xsl:apply-templates>
</xsl:template>

<!-- A named template creates the infrastructure for an SVG image -->
<!-- Parameters                                 -->
<!-- svg-filename: required, full relative path -->
<!-- png-fallback-filename: optional            -->
<!-- image-width: required                      -->
<!-- image-description: optional                -->
<xsl:template name="svg-wrapper">
    <xsl:param name="svg-filename" />
    <xsl:param name="png-fallback-filename" select="''" />
    <xsl:param name="image-width" />
    <xsl:param name="image-description" select="''" />
    <xsl:element name="img">
        <!-- source file attribute for img element, the SVG image -->
        <xsl:attribute name="src">
            <xsl:value-of select="$svg-filename" />
        </xsl:attribute>
        <!-- fix width, let browser get aspect ration from SVG viewBox -->
        <!-- attribute (svg/@viewBox) and compute the height           -->
        <!-- https://css-tricks.com/scale-svg/#article-header-id-7     -->
        <xsl:attribute name="width">
            <xsl:value-of select="$image-width" />
        </xsl:attribute>
        <!-- center the image, either in some figure (necessary),    -->
        <!-- or in a side-by-side (redundant).  The 0 is top/bottom, -->
        <!-- and the auto is left/right in concert with width        -->
        <xsl:attribute name="style">
            <xsl:text>display: block; margin: 0 auto;</xsl:text>
        </xsl:attribute>
        <!-- alt attribute for accessibility -->
        <xsl:attribute name="alt">
            <xsl:value-of select="$image-description" />
        </xsl:attribute>
        <!-- PNG fallback, if available                                     -->
        <!-- https://www.envano.com/2014/04/using-svg-images-in-responsive- -->
        <!-- websites-with-a-fallback-for-browsers-not-supporting-svg/      -->
        <xsl:if test="not($png-fallback-filename = '')">
            <xsl:attribute name="onerror">
                <xsl:text>this.src='</xsl:text>
                <xsl:value-of select="$png-fallback-filename" />
                <xsl:text>';this.onerror=null;</xsl:text>
            </xsl:attribute>
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- Image Archives -->
<!-- Under an image provide a set of (download) links              -->
<!-- for archival versions of the image in different formats       -->
<!--                                                               -->
<!-- 1.  @archive is a space-delimited list of file suffixes       -->
<!-- 2.  Author must ensure the versions are next to file employed -->
<!-- 3.  Formatting and case of suffixes is author's choice        -->
<!-- 4.  Order in suffix list is respected in output               -->
<!-- 5.  Per-image, with global spec in "docinfo/images/archive"   -->
<!--                                                               -->
<!-- The originating image template knows/computes the filename,   -->
<!-- so this template accepts the filename, sans period and        -->
<!-- extension, to transmit to the actual link production where    -->
<!-- different extensions are added                                -->
<!--                                                               -->
<xsl:template match="image" mode="archive">
    <xsl:param name="base-pathname" />
    <!-- Determine requested archive links            -->
    <!-- Local request on image overrides global      -->
    <!-- If $formats ends empty, then nothing happens -->
    <xsl:variable name="formats">
        <xsl:choose>
            <!-- local, given on image, including suppression -->
            <xsl:when test="@archive">
                <xsl:value-of select="normalize-space(@archive)" />
            </xsl:when>
            <!-- semi-local, semi-global via subtree specification     -->
            <!-- last in list that contains the image wins             -->
            <!-- Documented heavily as first "mid-range" specification -->
            <!-- A single @from puts us in mid-range mode              -->
            <xsl:when test="$docinfo/images/archive[@from]">
                <!-- context of next "select" filters is "archive" -->
                <!-- so save off the present context, the "image"  -->
                <xsl:variable name="the-image" select="." />
                <!-- Filter all of the "archive" in docinfo with @from      -->
                <!-- Subset occurs in document order                        -->
                <!-- Form two subtrees of all desendant nodes, rooted at    -->
                <!--   (1) the image node                                   -->
                <!--   (2) the node pointed to by @from                     -->
                <!-- The pipe forms a union of the nodes in the subtrees    -->
                <!-- "image" is on the subtree @from iff union is no larger -->
                <xsl:variable name="containing-archives"
                    select="$docinfo/images/archive[@from][count($the-image/descendant-or-self::node()|id(@from)/descendant-or-self::node())=count(id(@from)/descendant-or-self::node())]" />
                <!-- We mimic XSL and the last applicable "archive" is effective -->
                <!-- This way, big subtrees go first, included subtrees refine   -->
                <!-- @from can be an empty string and turn off the behavior      -->
                <!-- We grab the content of the last "archive" to be the formats -->
                <xsl:value-of select="$containing-archives[last()]/." />
            </xsl:when>
            <!-- global, presumes one only, ignores subtree versions -->
            <xsl:when test="$docinfo/images/archive[not(@from)]">
                <xsl:value-of select="normalize-space($docinfo/images/archive)" />
            </xsl:when>
            <!-- nothing begets nothing -->
            <xsl:otherwise />
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="not($formats = '')">
        <!-- Build the links with recursion through formats    -->
        <!-- First wrap resulting links in overall styling div -->
        <xsl:element name="div">
            <xsl:attribute name="class">
                <xsl:text>image-archive</xsl:text>
            </xsl:attribute>
            <!-- Add trailing space as marker for recursion finale -->
            <xsl:call-template name="archive-links">
                <xsl:with-param name="base-pathname" select="$base-pathname" />
                <xsl:with-param name="formats" select="concat($formats, ' ')" />
            </xsl:call-template>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- $base-pathname has no concluding -->
<!-- period, so we add it here        -->
<xsl:template name="archive-links">
    <xsl:param name="base-pathname" />
    <xsl:param name="formats" />
    <!-- stop recursion if empty (note extra space added in initial call) -->
    <xsl:if test="not($formats = '')">
        <xsl:variable name="next-format" select="substring-before($formats, ' ')" />
        <xsl:variable name="remaining-formats" select="substring-after($formats, ' ')" />
        <!-- link to the file, author's responsibility  -->
        <!-- add period, and the suffix to rest of path -->
        <!-- text of link is the format suffix verbatim -->
        <xsl:element name="a">
            <xsl:attribute name="href">
                <xsl:value-of select="$base-pathname" />
                <xsl:text>.</xsl:text>
                <xsl:value-of select="$next-format" />
            </xsl:attribute>
            <xsl:value-of select="$next-format" />
        </xsl:element>
        <!-- recurse through remaining formats -->
        <xsl:call-template name="archive-links">
            <xsl:with-param name="base-pathname" select="$base-pathname" />
            <xsl:with-param name="formats" select="$remaining-formats" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- LaTeX standalone image              -->
<!-- Deprecated when not inside an image -->
<!-- But it gets processed anyway        -->
<xsl:template match="latex-image-code">
    <xsl:message>MBX WARNING: latex-image-code element should be enclosed by an image element</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>


<!-- ################## -->
<!-- SideBySide Layouts -->
<!-- ################## -->

<!-- See xsl/mathbook-common.xsl for descriptions of the  -->
<!-- five modal templates which must be implemented here  -->
<!-- The main templates for "sidebyside" and "sbsgroup"   -->
<!-- are in xsl/mathbook-common.xsl, as befits containers -->

<!-- When we use CSS margins (or padding), then percentage        -->
<!-- widths are relative to the remaining space.  This utility    -->
<!-- takes in a width relative to full-text-width and the margins -->
<!-- (both with "%" attached) and returns the larger percentage   -->
<!-- of the remaining space.                                      -->
<xsl:template name="relative-width">
    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <xsl:value-of select="(100 * substring-before($width, '%')) div (100 - substring-before($left-margin, '%') - substring-before($right-margin, '%'))" />
    <xsl:text>%</xsl:text>
</xsl:template>

<!-- We do no particular setup for the panels -->
<xsl:template match="*" mode="panel-setup" />

<!-- If an object carries a title, we add it to the -->
<!-- row of titles across the top of the table      -->
<!-- else we write an empty div to occupy the space -->
<xsl:template match="*" mode="panel-heading">
    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <xsl:element name="h6">
        <xsl:attribute name="class">
            <xsl:text>sbsheader</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text>
            <xsl:call-template name="relative-width">
                <xsl:with-param name="width" select="$width" />
                <xsl:with-param name="left-margin"  select="$left-margin" />
                <xsl:with-param name="right-margin" select="$right-margin" />
            </xsl:call-template>
            <xsl:text>;</xsl:text>
            <xsl:if test="$sbsdebug">
                <xsl:text>box-sizing: border-box;</xsl:text>
                <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                <xsl:text>border: 2px solid yellow;</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <xsl:if test="title">
            <xsl:apply-templates select="." mode="title-full" />
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- generic "panel-panel" template            -->
<!-- makes a "sbspanel" div of specified width -->
<!-- calls modal "panel-html-box" for contents -->
<!-- fixed-width class is additional           -->
<xsl:template match="*" mode="panel-panel">
    <xsl:param name="b-original" select="true()" />

    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <xsl:param name="valign" />
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>sbspanel</xsl:text>
            <xsl:if test="self::table or self::tabular">
                <xsl:text> fixed-width</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <!-- some structures do not get an id in their panel-html-box  -->
        <!-- TODO: investigate necessity of id incorporation here? -->
        <xsl:if test="self::list and $b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text>
            <xsl:call-template name="relative-width">
                <xsl:with-param name="width" select="$width" />
                <xsl:with-param name="left-margin"  select="$left-margin" />
                <xsl:with-param name="right-margin" select="$right-margin" />
            </xsl:call-template>
            <xsl:text>;</xsl:text>
            <!-- assumes "sbspanel" class set vertical direction -->
            <xsl:text>justify-content:</xsl:text>
            <xsl:choose>
                <xsl:when test="$valign = 'top'">
                    <xsl:text>flex-start</xsl:text>
                </xsl:when>
                <xsl:when test="$valign = 'middle'">
                    <xsl:text>center</xsl:text>
                </xsl:when>
                <xsl:when test="$valign = 'bottom'">
                    <xsl:text>flex-end</xsl:text>
                </xsl:when>
            </xsl:choose>
            <xsl:text>;</xsl:text>
            <xsl:if test="$sbsdebug">
                <xsl:text>box-sizing: border-box;</xsl:text>
                <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                <xsl:text>border: 2px solid black;</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="panel-html-box" >
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="width" select="$width" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- If an object carries a caption, we add it to the    -->
<!-- row of captions across the bottom of the table else -->
<!-- we write an empty figcaption to occupy the space    -->
<!-- See more at utility template immediately following  -->
<xsl:template match="*" mode="panel-caption">
    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />

    <xsl:choose>
        <!-- interior to a figure'd sidebyside        -->
        <!-- width and margins are sentinels from sbs -->
        <xsl:when test="caption and (parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)">
            <xsl:apply-templates select="caption" mode="subcaption">
                <xsl:with-param name="width" select="$width" />
                <xsl:with-param name="left-margin" select="$left-margin" />
                <xsl:with-param name="right-margin" select="$right-margin" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- a caption'ed item, normal numbering      -->
        <!-- width and margins are sentinels from sbs -->
        <xsl:when test="caption">
            <xsl:apply-templates select="caption" >
                <xsl:with-param name="width" select="$width" />
                <xsl:with-param name="left-margin" select="$left-margin" />
                <xsl:with-param name="right-margin" select="$right-margin" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- fill the space (properly) -->
        <xsl:otherwise>
            <figcaption>
                <xsl:call-template name="sbs-caption-attributes">
                    <xsl:with-param name="width" select="$width" />
                    <xsl:with-param name="left-margin" select="$left-margin" />
                    <xsl:with-param name="right-margin" select="$right-margin" />
                </xsl:call-template>
            </figcaption>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- this utility template provides extra class, width   -->
<!-- and degugging information on a "figcaption" element -->
<!-- when employed on a panel of a sidebyside            -->
<!-- It is used above on an empty caption, and by the    -->
<!-- two modal templates for a caption when signaled     -->
<xsl:template name="sbs-caption-attributes">
    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <xsl:attribute name="class">
        <xsl:text>sbscaption</xsl:text>
    </xsl:attribute>
    <xsl:attribute name="style">
        <xsl:text>width:</xsl:text>
        <xsl:call-template name="relative-width">
            <xsl:with-param name="width" select="$width" />
            <xsl:with-param name="left-margin"  select="$left-margin" />
            <xsl:with-param name="right-margin" select="$right-margin" />
        </xsl:call-template>
        <xsl:text>;</xsl:text>
        <xsl:if test="$sbsdebug">
            <xsl:text>box-sizing: border-box;</xsl:text>
            <xsl:text>-moz-box-sizing: border-box;</xsl:text>
            <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
            <xsl:text>border: 2px solid Chocolate;</xsl:text>
        </xsl:if>
    </xsl:attribute>
</xsl:template>

<!-- We take in all three rows and package  -->
<!-- them up inside an overriding "sidebyside" -->
<!-- div containing three "sbsrow" divs -->
<xsl:template match="sidebyside" mode="compose-panels">
    <xsl:param name="b-original" select="true()" />

    <xsl:param name="layout" />
    <xsl:param name="has-headings" />
    <xsl:param name="has-captions" />
    <xsl:param name="headings" />
    <xsl:param name="panels" />
    <xsl:param name="captions" />

    <xsl:variable name="left-margin"  select="$layout/left-margin" />
    <xsl:variable name="right-margin" select="$layout/right-margin" />

    <!-- A "sidebyside" div, to contain headings,  -->
    <!-- panels, captions rows as "sbsrow" divs -->
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>sidebyside</xsl:text>
        </xsl:attribute>
        <xsl:if test="$sbsdebug">
            <xsl:attribute name="style">
                <xsl:text>box-sizing: border-box;</xsl:text>
                <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                <xsl:text>border: 2px solid purple;</xsl:text>
            </xsl:attribute>
        </xsl:if>

        <!-- this will need work to differentiate sbs from sbsrow -->
        <xsl:if test="self::sidebyside and $b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
        </xsl:if>

        <!-- Headings in an "sbsrow" div, if extant -->
        <xsl:if test="$has-headings">
            <xsl:element name="div">
                <xsl:attribute name="class">
                    <xsl:text>sbsrow</xsl:text>
                </xsl:attribute>
                <!-- margins are custom from source -->
                <xsl:attribute name="style">
                    <xsl:text>margin-left:</xsl:text>
                    <xsl:value-of select="$left-margin" />
                    <xsl:text>;</xsl:text>
                    <xsl:text>margin-right:</xsl:text>
                    <xsl:value-of select="$right-margin" />
                    <xsl:text>;</xsl:text>
                    <xsl:if test="$sbsdebug">
                        <xsl:text>box-sizing: border-box;</xsl:text>
                        <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                        <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                        <xsl:text>border: 2px solid green;</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:copy-of select="$headings" />
            </xsl:element>
        </xsl:if>

        <!-- Panels in an "sbsrow" div, always -->
        <xsl:element name="div">
            <xsl:attribute name="class">
                <xsl:text>sbsrow</xsl:text>
            </xsl:attribute>
            <!-- margins are custom from source -->
            <xsl:attribute name="style">
                <xsl:text>margin-left:</xsl:text>
                <xsl:value-of select="$left-margin" />
                <xsl:text>;</xsl:text>
                <xsl:text>margin-right:</xsl:text>
                <xsl:value-of select="$right-margin" />
                <xsl:text>;</xsl:text>
                <xsl:if test="$sbsdebug">
                    <xsl:text>box-sizing: border-box;</xsl:text>
                    <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                    <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                    <xsl:text>border: 2px solid green;</xsl:text>
                    <xsl:text>background: LightGray;</xsl:text>
                    <xsl:text>background-clip: content-box;</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:copy-of select="$panels" />
        </xsl:element>

        <!-- Captions in an "sbsrow" div, if extant -->
        <xsl:if test="$has-captions">
            <xsl:element name="div">
                <xsl:attribute name="class">
                    <xsl:text>sbsrow</xsl:text>
                </xsl:attribute>
                <!-- margins are custom from source -->
                <xsl:attribute name="style">
                    <xsl:text>margin-left:</xsl:text>
                    <xsl:value-of select="$left-margin" />
                    <xsl:text>;</xsl:text>
                    <xsl:text>margin-right:</xsl:text>
                    <xsl:value-of select="$right-margin" />
                    <xsl:text>;</xsl:text>
                    <xsl:if test="$sbsdebug">
                        <xsl:text>box-sizing: border-box;</xsl:text>
                        <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                        <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                        <xsl:text>border: 2px solid green;</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:copy-of select="$captions" />
            </xsl:element>
        </xsl:if>

    </xsl:element>
</xsl:template>

<!-- ########################### -->
<!-- Object by Object HTML Boxes -->
<!-- ########################### -->

<!-- Implement modal "panel-html-box" for various MBX elements -->
<!-- Called in generic -panel                                  -->

<xsl:template match="p|pre" mode="panel-html-box">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select=".">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="paragraphs" mode="panel-html-box">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="p|blockquote">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="ol|ul|dl" mode="panel-html-box">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select=".">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="program|console" mode="panel-html-box">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select=".">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- Process intro, the list, conclusion     -->
<!-- title is killed -->
<xsl:template match="list" mode="panel-html-box">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="introduction|ol|ul|dl|conclusion">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- tabular passes width of containing panel to base width -->
<!-- calculation for paragraph cells                        -->
<xsl:template match="tabular" mode="panel-html-box">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="width" />
    <xsl:apply-templates select="." >
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="ambient-relative-width" select="$width"/>
    </xsl:apply-templates>
</xsl:template>

<!-- This matches the "regular" template, but does not -->
<!-- duplicate the title, which is handled specially   -->
<!-- max-width is at 100%, not 90%                     -->
<xsl:template match="poem" mode="panel-html-box">
    <div class="poem" style="display: table; width: auto; max-width: 100%; margin: 0 auto;">
        <xsl:apply-templates select="stanza"/>
        <xsl:apply-templates select="author"/>
    </div>
</xsl:template>

<!-- An image "knows" how to look outward         -->
<!-- for side-by-side layout, or other width      -->
<!-- specification so we do nothing extraordinary -->
<xsl:template match="image" mode="panel-html-box">
    <xsl:apply-templates select="." />
</xsl:template>

<!-- An video "knows" how to look outward         -->
<!-- for side-by-side layout, or other width      -->
<!-- specification so we do nothing extraordinary -->
<xsl:template match="video" mode="panel-html-box">
    <xsl:apply-templates select="." />
</xsl:template>

<!-- A figure or table is just a container to hold a -->
<!-- title and/or caption, plus perhaps an xml:id,   -->
<!-- so we just pawn off the contents (one only!)    -->
<!-- to the other routines                           -->
<!-- table needs to pass width to tabular in case    -->
<!-- there is a paragraph cell                       -->
<!-- and generically to other contained objects      -->
<xsl:template match="figure" mode="panel-html-box">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="width" select="''" />
    <xsl:apply-templates select="*[not(&METADATA-FILTER;)][1]" mode="panel-html-box">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="width" select="$width" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="table" mode="panel-html-box">
    <xsl:param name="width" />
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*[not(&METADATA-FILTER;)][1]" mode="panel-html-box" >
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="width" select="$width"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="listing" mode="panel-html-box">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*[not(&METADATA-FILTER;)][1]" mode="panel-html-box">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="jsxgraph" mode="panel-html-box">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="." />
</xsl:template>

<!-- Just temporary markers of unimplemented stuff -->
<xsl:template match="*" mode="panel-html-box">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>]</xsl:text>
</xsl:template>


<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="tikz">
    <xsl:message>MBX:WARNING: tikz element superceded by latex-image-code element</xsl:message>
    <xsl:message>MBX:WARNING: tikz package and necessary libraries should be included in docinfo/latex-image-preamble</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:element name="object">
        <xsl:attribute name="type">image/svg+xml</xsl:attribute>
        <xsl:attribute name="style">width:90%; margin:auto;</xsl:attribute>
        <xsl:attribute name="data">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:attribute>
        <p style="margin:auto">&lt;&lt;Your browser is unable to render this SVG image&gt;&gt;</p>
    </xsl:element>
</xsl:template>
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="asymptote">
    <xsl:message>MBX:WARNING: asymptote element must be enclosed by an image element - deprecation (2015/02/08)</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:element name="object">
        <xsl:attribute name="type">image/svg+xml</xsl:attribute>
        <xsl:attribute name="style">width:90%; margin:auto;</xsl:attribute>
        <xsl:attribute name="data">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:attribute>
        <p style="margin:auto">&lt;&lt;Your browser is unable to render this SVG image&gt;&gt;</p>
    </xsl:element>
</xsl:template>
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="sageplot">
    <xsl:message>MBX:WARNING: sageplot element must be enclosed by an image element - deprecation (2015/02/08)</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:element name="object">
        <xsl:attribute name="type">image/svg+xml</xsl:attribute>
        <xsl:attribute name="style">width:90%; margin:auto;</xsl:attribute>
        <xsl:attribute name="data">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:attribute>
        <xsl:element name="img">
            <xsl:attribute name="src">
                <xsl:value-of select="$directory.images" />
                <xsl:text>/</xsl:text>
                <xsl:apply-templates select="." mode="internal-id" />
                <xsl:text>.png</xsl:text>
            </xsl:attribute>
        </xsl:element>
    </xsl:element>
</xsl:template>
<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->


<!-- ##### -->
<!-- Video -->
<!-- ##### -->

<!-- We begin with a general construction of various   -->
<!-- options for embedding, pop-out, and previews.     -->
<!-- An abstract modal method "video-embed" constructs -->
<!-- an HTML object of the correct size and with the   -->
<!-- right autoplay characteristic.                    -->
<!-- Note: autoplay option is internal, not author-set -->

<!-- Two types of video: HTML5, YouTube                   -->
<!-- Three previews: default, generic, author-constructed -->
<!-- Three embeddings: embed, popout, select              -->

<xsl:template match="video">
    <!-- collect and process size information from author -->
    <xsl:variable name="width-percent">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="width-fraction">
        <xsl:value-of select="substring-before($width-percent,'%') div 100" />
    </xsl:variable>
    <xsl:variable name="aspect-ratio">
        <xsl:apply-templates select="." mode="get-aspect-ratio">
            <xsl:with-param name="default-aspect" select="'16:9'" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="width"  select="$design-width * $width-fraction" />
    <xsl:variable name="height" select="$design-width * $width-fraction div $aspect-ratio" />

    <!-- Always build a standalone page, PDF links to these -->
    <xsl:apply-templates select="." mode="video-standalone-page" />

    <!-- standalone page uses internal-id of the video -->
    <xsl:variable name="int-id">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="@play-at = 'popout'">
            <a href="{$int-id}.html" target="_blank">
            <!-- place a thumbnail as clickable for page already extant -->
                <xsl:choose>
                    <!-- generic requested -->
                    <xsl:when test="@preview = 'generic'">
                        <xsl:call-template name="generic-preview-svg">
                            <xsl:with-param name="width" select="$width" />
                            <xsl:with-param name="height" select="$height" />
                        </xsl:call-template>
                    </xsl:when>
                    <!-- author-provided -->
                    <xsl:when test="@preview and not(@preview = 'default')">
                        <img src="{@preview}" width="{$width}" height="{$height}"/>
                    </xsl:when>
                    <!-- this id-device should be replaced by graceful failure  -->
                    <!-- to the generic preview with a console warning          -->
                    <xsl:when test="(@preview = 'default') or not(@preview)">
                        <xsl:variable name="thumbnail-image">
                            <xsl:text>images/</xsl:text>
                            <xsl:value-of select="$int-id" />
                            <xsl:text>.jpg</xsl:text>
                        </xsl:variable>
                        <img src="{$thumbnail-image}" width="{$width}" height="{$height}"/>
                    </xsl:when>
                </xsl:choose>
            </a>
            <!-- until we get an overlay, explain popout -->
            <div style="text-align: center;">
                <xsl:text>Click Above to Play</xsl:text>
            </div>
        </xsl:when>
        <xsl:when test="(@play-at = 'select') or (@play-at = 'embed') or not(@play-at)">
            <xsl:apply-templates select="." mode="video-embed">
                <xsl:with-param name="width"  select="$width" />
                <xsl:with-param name="height" select="$height" />
            </xsl:apply-templates>
            <!-- for the reader-select case, we need a link as a "button" -->
            <!-- if this case is deprecated, we can drop this thing -->
            <xsl:if test="@play-at = 'select'">
                <div style="text-align: center;">
                    <a href="{$int-id}.html" target="_blank">
                        <xsl:text>Click to Pop-Out</xsl:text>
                    </a>
                </div>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<!-- Formerly a "pop-out" page, now a "standalone" page     -->
<!-- Has autoplay on since a reader ahs elected to go there -->
<!-- TODO: override preview, since it just plays, pass 'default -->
<xsl:template match="video" mode="video-standalone-page">
    <xsl:variable name="aspect-ratio">
        <xsl:apply-templates select="." mode="get-aspect-ratio">
            <xsl:with-param name="default-aspect" select="'16:9'" />
        </xsl:apply-templates>
    </xsl:variable>
    <!-- apparent width of content region of HTML page  -->
    <!-- with no sidebar, subtract margins = 900 - 2*30 -->
    <xsl:variable name="ptx-content-width" select="'840'" />
    <xsl:variable name="ptx-content-height" select="$ptx-content-width div $aspect-ratio" />
    <xsl:apply-templates select="." mode="masthead-only-page">
        <xsl:with-param name="content">
            <!-- display preview, and enable autoplay  -->
            <!-- since reader has elected this page    -->
            <xsl:apply-templates select="." mode="video-embed">
                <xsl:with-param name="width"  select="$ptx-content-width" />
                <xsl:with-param name="height" select="$ptx-content-height" />
                <xsl:with-param name="preview" select="'false'" />
                <xsl:with-param name="autoplay" select="'true'" />
            </xsl:apply-templates>
            <div style="text-align: center;">Reloading this page will reset a start location</div>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>


<!-- "Pop-Out Page" -->
<!-- (A bit rough)                  -->
<!-- no extra libraries, no sidebar -->
<!-- 840px available (~900 - 2*30)  -->
<!-- Page name comes from context node -->
<!-- TODO:  one page template, super-parameterized      -->
<!-- TODO:  trash navigation further in masthead        -->
<!-- TODO:  replace libraries by hooks to add some back -->
<xsl:template match="*" mode="masthead-only-page">
    <xsl:param name="content" select="''" />
    <xsl:variable name="int-id">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <exsl:document href="{$int-id}.html" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <xsl:call-template name="converter-blurb-html" />
        <html lang="{$document-language}"> <!-- dir="rtl" here -->
            <head>
                <title>
                    <!-- Leading with initials is useful for small tabs -->
                    <xsl:if test="//docinfo/initialism">
                        <xsl:apply-templates select="//docinfo/initialism" />
                        <xsl:text> </xsl:text>
                    </xsl:if>
                <xsl:apply-templates select="." mode="title-simple" />
                </title>
                <meta name="Keywords" content="Authored in PreTeXt" />
                <!-- http://webdesignerwall.com/tutorials/responsive-design-in-3-steps -->
                <meta name="viewport" content="width=device-width,  initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0" />
                <!-- ########################################## -->
                <!-- A variety of libraries were loaded here    -->
                <!-- Only purpose of this page is YouTube video -->
                <!-- A hook could go here for some extras       -->
                <!-- ########################################## -->
                <xsl:call-template name="knowl" />
                <xsl:call-template name="mathbook-js" />
                <xsl:call-template name="fonts" />
                <xsl:call-template name="css" />
            </head>
            <xsl:element name="body">
                <!-- the first class controls the default icon -->
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="$root/book">mathbook-book</xsl:when>
                        <xsl:when test="$root/article">mathbook-article</xsl:when>
                    </xsl:choose>
                    <!-- ################################################# -->
                    <!-- This is how the left sidebar goes away            -->
                    <!-- <xsl:if test="$b-has-toc">                        -->
                    <!--    <xsl:text> has-toc has-sidebar-left</xsl:text> -->
                    <!-- </xsl:if>                                         -->
                    <!-- ################################################# -->
                </xsl:attribute>
                <!-- assistive "Skip to main content" link    -->
                <!-- this *must* be first for maximum utility -->
                <xsl:call-template name="skip-to-content-link" />
                <xsl:call-template name="latex-macros" />
                 <header id="masthead" class="smallbuttons">
                    <div class="banner">
                        <div class="container">
                            <xsl:call-template name="brand-logo" />
                            <div class="title-container">
                                <h1 class="heading">
                                    <xsl:element name="a">
                                        <xsl:attribute name="href">
                                            <xsl:apply-templates select="$document-root" mode="containing-filename" />
                                        </xsl:attribute>
                                        <span>
                                            <xsl:apply-templates select="." mode="title-attributes" />
                                            <xsl:apply-templates select="$document-root" mode="title-simple" />
                                        </span>
                                        <xsl:if test="normalize-space($document-root/subtitle)">
                                            <span class="subtitle">
                                                <xsl:apply-templates select="$document-root" mode="subtitle" />
                                            </span>
                                        </xsl:if>
                                    </xsl:element>
                                </h1>
                                <!-- Serial list of authors/editors -->
                                <p class="byline">
                                    <xsl:apply-templates select="//frontmatter/titlepage/author" mode="name-list"/>
                                    <xsl:apply-templates select="//frontmatter/titlepage/editor" mode="name-list"/>
                                </p>
                            </div>  <!-- title-container -->
                        </div>  <!-- container -->
                    </div> <!-- banner -->
                    <!-- This seemed to not be enough, until Google Search went away  -->
                    <!-- <xsl:apply-templates select="." mode="primary-navigation" /> -->
                </header> <!-- masthead -->
                <div class="page">
                    <!-- With sidebars killed, this stuff is extraneous     -->
                    <!-- <xsl:apply-templates select="." mode="sidebars" /> -->
                    <main class="main">
                        <div id="content" class="mathbook-content">
                            <!-- This is content passed in as a parameter -->
                            <xsl:copy-of select="$content" />
                          </div>
                    </main>
                </div>
                <xsl:apply-templates select="$docinfo/analytics" />
                <!-- <xsl:call-template name="pytutor-footer" /> -->
            </xsl:element>
        </html>
    </exsl:document>
</xsl:template>

<xsl:template name="generic-preview-svg">
    <xsl:param name="width" select="''" />
    <xsl:param name="height" select="''" />
    <!-- viewbox was square (0,0), 96x96, now clipped 14 above and below                   -->
    <!-- preserveAspectRatio="none" makes it amenable to matching video it hides           -->
    <!-- SVG scaling, comprehensive: https://css-tricks.com/scale-svg/                     -->
    <!-- Accessed: 2017-08-08                                                              -->
    <!-- Page: https://commons.wikimedia.org/wiki/File:YouTube_Play_Button.svg             -->
    <!-- File: https://upload.wikimedia.org/wikipedia/commons/d/d1/YouTube_Play_Button.svg -->
    <!-- License text:  This image only consists of simple geometric shapes or text.       -->
    <!-- It does not meet the threshold of originality needed for copyright protection,    -->
    <!-- and is therefore in the public domain.                                            -->
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 14 96 68" width="{$width}" height="{$height}" style="cursor:pointer;" preserveAspectRatio="none">
        <path fill="#e62117" d="M94.98,28.84c0,0-0.94-6.6-3.81-9.5c-3.64-3.81-7.72-3.83-9.59-4.05c-13.4-0.97-33.52-0.85-33.52-0.85s-20.12-0.12-33.52,0.85c-1.87,0.22-5.95,0.24-9.59,4.05c-2.87,2.9-3.81,9.5-3.81,9.5S0.18,36.58,0,44.33v7.26c0.18,7.75,1.14,15.49,1.14,15.49s0.93,6.6,3.81,9.5c3.64,3.81,8.43,3.69,10.56,4.09c7.53,0.72,31.7,0.89,32.54,0.9c0.01,0,20.14,0.03,33.54-0.94c1.87-0.22,5.95-0.24,9.59-4.05c2.87-2.9,3.81-9.5,3.81-9.5s0.96-7.75,1.02-15.49v-7.26C95.94,36.58,94.98,28.84,94.98,28.84z M38.28,61.41v-27l25.74,13.5L38.28,61.41z"/>
    </svg>
</xsl:template>

<!-- Take <svg> element above, remove width and height attributes  -->
<!-- (not ever needed???), compact to one long string.             -->
<!-- URL encode via: https://meyerweb.com/eric/tools/dencoder/     -->
<!-- Then add a bit of voodoo, and this may be used as the value   -->
<!-- of the HTML5 video/@poster attribute (and other places?)      -->
<xsl:variable name="generic-preview-svg-data-uri">
    <xsl:text>data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%2014%2096%2068%22%20style%3D%22cursor%3Apointer%3B%22%20preserveAspectRatio%3D%22none%22%3E%3Cpath%20fill%3D%22%23e62117%22%20d%3D%22M94.98%2C28.84c0%2C0-0.94-6.6-3.81-9.5c-3.64-3.81-7.72-3.83-9.59-4.05c-13.4-0.97-33.52-0.85-33.52-0.85s-20.12-0.12-33.52%2C0.85c-1.87%2C0.22-5.95%2C0.24-9.59%2C4.05c-2.87%2C2.9-3.81%2C9.5-3.81%2C9.5S0.18%2C36.58%2C0%2C44.33v7.26c0.18%2C7.75%2C1.14%2C15.49%2C1.14%2C15.49s0.93%2C6.6%2C3.81%2C9.5c3.64%2C3.81%2C8.43%2C3.69%2C10.56%2C4.09c7.53%2C0.72%2C31.7%2C0.89%2C32.54%2C0.9c0.01%2C0%2C20.14%2C0.03%2C33.54-0.94c1.87-0.22%2C5.95-0.24%2C9.59-4.05c2.87-2.9%2C3.81-9.5%2C3.81-9.5s0.96-7.75%2C1.02-15.49v-7.26C95.94%2C36.58%2C94.98%2C28.84%2C94.98%2C28.84z%20M38.28%2C61.41v-27l25.74%2C13.5L38.28%2C61.41z%22%2F%3E%3C%2Fsvg%3E</xsl:text>
</xsl:variable>

<!-- create a "video" element for author-hosted   -->
<!-- dimensions and autoplay as parameters        -->
<!-- Normally $preview is true, and not passed in -->
<!-- 'false' is an override for standalone pages  -->
<xsl:template match="video[@source]" mode="video-embed">
    <xsl:param name="width" select="''" />
    <xsl:param name="height" select="''" />
    <xsl:param name="preview" select="'true'" />
    <xsl:param name="autoplay" select="'false'" />

    <!-- start/end times (read both, see 4.1, 4.2.1 at w3.org)    -->
    <!-- Media Fragment URI: https://www.w3.org/TR/media-frags/   -->
    <!-- Javascript: https://stackoverflow.com/questions/11212715 -->
    <!-- variable is possibly empty, so no harm using that later  -->
    <!-- This portion of URL should follow any query string       -->
    <xsl:variable name="temporal-fragment">
        <xsl:if test="@start or @end">
            <xsl:text>#t=</xsl:text>
        </xsl:if>
        <xsl:if test="@start">
            <xsl:value-of select="@start" />
        </xsl:if>
        <!-- can lead with comma, implies 0,xx -->
        <xsl:if test="@end">
            <xsl:text>,</xsl:text>
            <xsl:value-of select="@end" />
        </xsl:if>
    </xsl:variable>
    <!-- we need to build the element, since @autoplay is optional -->
    <xsl:element name="video">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id"/>
        </xsl:attribute>
        <xsl:attribute name="width">
            <xsl:value-of select="$width" />
        </xsl:attribute>
        <xsl:attribute name="height">
            <xsl:value-of select="$height" />
        </xsl:attribute>
        <!-- This CSS allows us to break the aspect-ratio -->
        <!-- https://stackoverflow.com/questions/4000818/ -->
        <xsl:attribute name="style">
            <text>object-fit: fill;</text>
        </xsl:attribute>
        <!-- empty forms work as boolean switches -->
        <xsl:attribute name="controls" />
        <xsl:if test="$autoplay = 'true'">
            <xsl:attribute name="autoplay" />
        </xsl:if>
        <!-- Optionally cover up with HTML5 @poster via PTX @preview -->
        <xsl:if test="($preview = 'true') and @preview and not(@preview = 'default')">
            <xsl:attribute name="poster">
                <xsl:choose>
                    <xsl:when test="@preview = 'generic'">
                        <xsl:value-of select="$generic-preview-svg-data-uri" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@preview" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </xsl:if>
        <!-- Construct the HTML5 source URL(s)                  -->
        <!-- If this gets refactored, it could be best to form  -->
        <!-- base, extension, query, fragment strings/variables -->
        <!-- First, grab extension of source URL in PTX @source -->
        <xsl:variable name="extension">
            <xsl:call-template name="file-extension">
                <xsl:with-param name="filename" select="@source" />
            </xsl:call-template>
        </xsl:variable>
        <!-- "source" elements, children of HTML5 video -->
        <!-- no extension suggests hosting has multiple -->
        <!-- versions for browser to sort through       -->
        <!-- More open formats first!  ;-)              -->
        <xsl:if test="$extension = '' or $extension = 'oog'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="@source"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.ogg</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="$temporal-fragment" />
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/ogg</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'webm'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="@source"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.webm</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="$temporal-fragment" />
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/webm</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'mp4'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="@source"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.mp4</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="$temporal-fragment" />
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/mp4</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <!-- failure to perform -->
        <xsl:text>Your browser does not support the &lt;video&gt; tag.</xsl:text>
    </xsl:element>
</xsl:template>

<!-- You Tube -->
<!-- Better sizing would require CSS classes (16:9, 4:3?)                      -->
<!-- https://css-tricks.com/NetMag/FluidWidthVideo/Article-FluidWidthVideo.php -->

<!-- Configurable options, we are considering academic uses -->
<!-- https://developers.google.com/youtube/player_parameters#Manual_IFrame_Embeds -->
<!-- hl parameter for language seems superfluous, user settings override       -->
<!-- something to do with cross-domain scripting security? -->
<!-- <xsl:text>&amp;origin=http://example.com</xsl:text>   -->
<!-- start/end time parameters -->

<!-- create iframe home for YouTube video         -->
<!-- dimensions and autoplay as parameters        -->
<!-- Normally $preview is true, and not passed in -->
<!-- 'false' is an override for standalone pages  -->
<xsl:template match="video[@youtube]" mode="video-embed">
    <xsl:param name="width" select="''" />
    <xsl:param name="height" select="''" />
    <xsl:param name="preview" select="'true'" />
    <xsl:param name="autoplay" select="'false'" />

    <xsl:variable name="int-id">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <xsl:variable name="source-url">
        <xsl:apply-templates select="." mode="youtube-embed-url">
            <xsl:with-param name="autoplay" select="$autoplay" />
        </xsl:apply-templates>
    </xsl:variable>
    <!-- Following is inaccurate, the @select should be 'true' -->
    <!-- But the YouTube autoplay won't wait for the poster    -->
    <!-- to be withdrawn, so two clicks are needed             -->
    <!-- We have two (equal) URLs to preserve logic, should    -->
    <!-- there be a better way to fake the HTML5 @poster       -->
    <xsl:variable name="source-url-autoplay-on">
        <xsl:apply-templates select="." mode="youtube-embed-url">
            <xsl:with-param name="autoplay" select="'false'" />
        </xsl:apply-templates>
    </xsl:variable>
    <!-- allowfullscreen is an iframe parameter, -->
    <!-- not a YouTube embed parameter, but it's -->
    <!-- use enables the "full screen" button    -->
    <!-- http://w3c.github.io/test-results/html51/implementation-report.html -->
    <xsl:choose>
        <xsl:when test="($preview = 'true') and @preview and not(@preview = 'default')">
            <!-- hide behind a preview image, code from post at -->
            <!-- https://stackoverflow.com/questions/7199624    -->
            <div onclick="this.nextElementSibling.style.display='block'; this.style.display='none'">
                <xsl:choose>
                    <xsl:when test="@preview = 'generic'">
                        <xsl:call-template name="generic-preview-svg">
                            <xsl:with-param name="width" select="$width" />
                            <xsl:with-param name="height" select="$height" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <img width="{$width}" height="{$height}" src="{@preview}" />
                    </xsl:otherwise>
                </xsl:choose>
            </div>
            <div class="hidden-content">
                <!-- Hidden content in here                   -->
                <!-- Turn autoplay on, else two clicks needed -->
                <iframe id="{$int-id}"
                        type="text/html"
                        width="{$width}"
                        height="{$height}"
                        frameborder="0"
                        allowfullscreen=""
                        src="{$source-url-autoplay-on}" />
            </div>
        </xsl:when>
        <xsl:otherwise>
            <iframe id="{$int-id}"
                    type="text/html"
                    width="{$width}"
                    height="{$height}"
                    frameborder="0"
                    allowfullscreen=""
                    src="{$source-url}" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Creates a YouTube URL for embedding, typically in an iframe -->
<!-- autoplay for popout, otherwise not                          -->
<xsl:template match="video[@youtube]" mode="youtube-embed-url">
    <xsl:param name="autoplay" select="'false'" />
    <xsl:text>https://www.youtube.com/embed/</xsl:text>
    <xsl:value-of select="@youtube" />
    <!-- alphabetical, ? separator first -->
    <!-- enables keyboard controls       -->
    <xsl:text>?disablekd=1</xsl:text>
    <!-- use &amp; separator for remainder -->
    <!-- modest branding -->
    <xsl:text>&amp;modestbranding=1</xsl:text>
    <!-- kill related videos at end -->
    <xsl:text>&amp;rel=0</xsl:text>
    <xsl:if test="@start">
        <xsl:text>&amp;start=</xsl:text>
        <xsl:value-of select="@start" />
    </xsl:if>
    <xsl:if test="@end">
        <xsl:text>&amp;end=</xsl:text>
        <xsl:value-of select="@end" />
    </xsl:if>
    <!-- default autoplay is 0, don't -->
    <xsl:if test="$autoplay = 'true'">
        <xsl:text>&amp;autoplay=1</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ############ -->
<!-- Music Scores -->
<!-- ############ -->

<!-- Embed an interactive score from MuseScore                          -->
<!-- Flag: score element has two MuseScore-specific attributes          -->
<!-- https://musescore.org/user/{usernumber}/scores/{scorenumber}/embed -->
<!-- into an iframe with width and height (todo)                        -->
<xsl:template match="score[@musescoreuser and @musescore]">
    <xsl:element name="iframe">
        <xsl:attribute name="width">
            <xsl:text>100%</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="height">
            <xsl:text>500</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="frameborder">
            <xsl:text>0</xsl:text>
        </xsl:attribute>
        <!-- empty attribute, just switch -->
        <xsl:attribute name="allowfullscreen">
            <xsl:text></xsl:text>
        </xsl:attribute>
        <xsl:attribute name="src">
            <xsl:text>https://musescore.com/user/</xsl:text>
            <xsl:value-of select="@musescoreuser" />
            <xsl:text>/scores/</xsl:text>
            <xsl:value-of select="@musescore" />
            <xsl:text>/embed</xsl:text>
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- ####### -->
<!-- Tabular -->
<!-- ####### -->

<!-- Top-down organization -->

<!-- A tabular layout, a naked table -->
<!-- Allowed to be placed various locations, but gets no              -->
<!-- vertical space etc, that is the container's responsibiility      -->
<!-- A sequence of rows, we ignore column group in applying templates -->
<!-- Realized as an HTML table                                        -->
<xsl:template match="tabular">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="ambient-relative-width" select="'100%'" />
    <!-- Abort if tabular's cols have widths summing to over 100% -->
    <xsl:call-template name="cap-width-at-one-hundred-percent">
        <xsl:with-param name="nodeset" select="col/@width" />
    </xsl:call-template>
    <xsl:element name="table">
        <xsl:apply-templates select="row">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width" select="$ambient-relative-width" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- A row of table -->
<xsl:template match="row">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="ambient-relative-width" />
    <!-- Form the HTML table row -->
    <xsl:element name="tr">
        <!-- Walk the cells of the row -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width">
                <xsl:value-of select="$ambient-relative-width" />
            </xsl:with-param>
            <xsl:with-param name="the-cell" select="cell[1]" />
            <xsl:with-param name="left-col" select="ancestor::tabular/col[1]" />  <!-- possibly empty -->
        </xsl:call-template>
    </xsl:element>
</xsl:template>

<xsl:template name="row-cells">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="ambient-relative-width" />
    <xsl:param name="the-cell" />
    <xsl:param name="left-col" />
    <!-- A cell may span several columns, or default to just 1              -->
    <!-- When colspan is not trivial, we identify the col elements          -->
    <!-- for the left and right ends of the span                            -->
    <!-- When colspan is trivial, the left and right versions are identical -->
    <!-- Left is used for left border and for horizontal alignment          -->
    <!-- Right is used for right border                                     -->
    <xsl:variable name="column-span">
        <xsl:choose>
            <xsl:when test="$the-cell/@colspan">
                <xsl:value-of select="$the-cell/@colspan" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- For a "normal" 1-column cell this variable effectively makes a copy -->
    <xsl:variable name="right-col" select="($left-col/self::*|$left-col/following-sibling::col)[position()=$column-span]" />
    <!-- Look ahead one column, anticipating recursion   -->
    <!-- but also probing for end of row (no more cells) -->
    <xsl:variable name="next-cell" select="$the-cell/following-sibling::cell[1]" />
    <xsl:variable name="next-col"  select="$right-col/following-sibling::col[1]" /> <!-- possibly empty -->
    <xsl:if test="$the-cell">
        <!-- build an HTML data cell, with CSS decorations              -->
        <!-- we set properties in various variables,                    -->
        <!-- then write them in a class attribute                       -->
        <!-- we look outward and upward for characteristics of the cell -->
        <!--                                                            -->
        <!-- horizontal alignment -->
        <xsl:variable name="alignment">
            <xsl:choose>
                <!-- cell attribute first -->
                <xsl:when test="$the-cell/@halign">
                    <xsl:value-of select="$the-cell/@halign" />
                </xsl:when>
                <!-- parent row attribute next -->
                <xsl:when test="$the-cell/ancestor::row/@halign">
                    <xsl:value-of select="$the-cell/ancestor::row/@halign" />
                </xsl:when>
                <!-- col attribute next -->
                <xsl:when test="$left-col/@halign">
                    <xsl:value-of select="$left-col/@halign" />
                </xsl:when>
                <!-- table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@halign">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@halign" />
                </xsl:when>
                <!-- HTML default is left, we write it for consistency -->
                <xsl:otherwise>
                    <xsl:text>left</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- vertical alignment -->
        <xsl:variable name="valignment">
            <xsl:choose>
                <!-- parent row attribute first -->
                <xsl:when test="$the-cell/ancestor::row/@valign">
                    <xsl:value-of select="$the-cell/ancestor::row/@valign" />
                </xsl:when>
                <!-- table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@valign">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@valign" />
                </xsl:when>
                <!-- HTML default is "baseline", not supported by MBX           -->
                <!-- Instead we default to "middle" to be consistent with LaTeX -->
                <xsl:otherwise>
                    <xsl:text>middle</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- bottom borders -->
        <xsl:variable name="bottom">
            <xsl:choose>
                <!-- cell attribute first -->
                <xsl:when test="$the-cell/@bottom">
                    <xsl:value-of select="$the-cell/@bottom" />
                </xsl:when>
                <!-- parent row attribute next -->
                <xsl:when test="$the-cell/ancestor::row/@bottom">
                    <xsl:value-of select="$the-cell/ancestor::row/@bottom" />
                </xsl:when>
                <!-- not available on columns, table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@bottom">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@bottom" />
                </xsl:when>
                <!-- default is none -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- right borders -->
        <xsl:variable name="right">
            <xsl:choose>
                <!-- cell attribute first -->
                <xsl:when test="$the-cell/@right">
                    <xsl:value-of select="$the-cell/@right" />
                </xsl:when>
                <!-- not available on rows, col attribute next -->
                <xsl:when test="$right-col/@right">
                    <xsl:value-of select="$right-col/@right" />
                </xsl:when>
                <!-- table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@right">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@right" />
                </xsl:when>
                <!-- default is none -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- left borders -->
        <xsl:variable name="left">
            <xsl:choose>
                <!-- the first cell of the row, so may have left border -->
                <xsl:when test="not($the-cell/preceding-sibling::cell)">
                    <xsl:choose>
                        <!-- row attribute first -->
                        <xsl:when test="$the-cell/ancestor::row/@left">
                            <xsl:value-of select="$the-cell/ancestor::row/@left" />
                        </xsl:when>
                        <!-- table attribute last -->
                        <xsl:when test="$the-cell/ancestor::tabular/@left">
                            <xsl:value-of select="$the-cell/ancestor::tabular/@left" />
                        </xsl:when>
                        <!-- default is none -->
                        <xsl:otherwise>
                            <xsl:text>none</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- not the first cell of the row, so no left border -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- top borders -->
        <xsl:variable name="top">
            <xsl:choose>
                <!-- the first row of the table, so may have top border -->
                <!-- http://ajaxandxml.blogspot.com/2006/11/xsl-detect-first-of-type-element-in.html -->
                <xsl:when test="not($the-cell/ancestor::row/preceding-sibling::row)">
                    <xsl:choose>
                        <!-- col attribute first -->
                        <xsl:when test="$left-col/@top">
                            <xsl:value-of select="$left-col/@top" />
                        </xsl:when>
                        <!-- table attribute last -->
                        <xsl:when test="$the-cell/ancestor::tabular/@top">
                            <xsl:value-of select="$the-cell/ancestor::tabular/@top" />
                        </xsl:when>
                        <!-- default is none -->
                        <xsl:otherwise>
                            <xsl:text>none</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- not the first cell of the row, so no left border -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- the HTML element for the cell -->
        <xsl:element name="td">
            <!-- and the class attribute -->
            <xsl:attribute name="class">
                <!-- always write alignment, so *precede* all subsequent with a space -->
                <xsl:choose>
                    <xsl:when test="$the-cell/p and $alignment='justify'">
                        <xsl:text>j</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="halign-specification">
                            <xsl:with-param name="align" select="$alignment" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- vertical alignment -->
                <xsl:text> </xsl:text>
                <xsl:call-template name="valign-specification">
                    <xsl:with-param name="align" select="$valignment" />
                </xsl:call-template>
                <!-- bottom border -->
                <xsl:text> b</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$bottom" />
                </xsl:call-template>
                <!-- right border -->
                <xsl:text> r</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$right" />
                </xsl:call-template>
                <!-- left border -->
                <xsl:text> l</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$left" />
                </xsl:call-template>
                <!-- top border -->
                <xsl:text> t</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$top" />
                </xsl:call-template>
                <!-- no wrapping unless paragraph cell -->
                <xsl:if test="not($the-cell/p)">
                    <xsl:text> lines</xsl:text>
                </xsl:if>

            </xsl:attribute>
            <xsl:if test="not($column-span = 1)">
                <xsl:attribute name="colspan">
                    <xsl:value-of select="$column-span" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$the-cell/p">
                <xsl:attribute name="style">
                    <xsl:text>max-width:</xsl:text>
                    <xsl:choose>
                        <xsl:when test="$left-col/@width">
                            <xsl:variable name="width">
                                <xsl:call-template name="normalize-percentage">
                                    <xsl:with-param name="percentage" select="$left-col/@width" />
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:value-of select="$design-width * substring-before($width, '%') div 100 * substring-before($ambient-relative-width, '%') div 100" />
                            <xsl:text>px;</xsl:text>
                        </xsl:when>
                        <!-- If there is no $left-col/@width, terminate -->
                        <xsl:otherwise>
                            <xsl:message terminate="yes">MBX:ERROR:   cell with p element has no corresponding col element with width attribute</xsl:message>
                            <xsl:apply-templates select="." mode="location-report" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <!-- process the actual contents -->
            <xsl:apply-templates select="$the-cell">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:element>
        <!-- recurse forward, perhaps to an empty cell -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width" select="$ambient-relative-width" />
            <xsl:with-param name="the-cell" select="$next-cell" />
            <xsl:with-param name="left-col" select="$next-col" />
        </xsl:call-template>
    </xsl:if>
    <!-- Arrive here only when we have no cell so      -->
    <!-- we bail out of recursion with no action taken -->
</xsl:template>

<xsl:template match="tabular//line">
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::line">
        <br />
    </xsl:if>
</xsl:template>


<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- Utilities are defined in xsl/mathbook-common.xsl -->

<!-- "thickness-specification" : param "width"    -->
<!--     none, minor, medium, major -> 0, 1, 2, 3 -->

<!-- "halign-specification" : param "align"       -->
<!--     left, right, center -> l, c, r           -->

<!-- "valign-specification" : param "align"       -->
<!--     top, middle, bottom -> t, m, b           -->

<!-- ######## -->
<!-- Captions -->
<!-- ######## -->

<!-- Caption of a numbered figure, table or listing -->
<!-- All the relevant information is in the parent  -->
<xsl:template match="caption">
    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <figcaption>
        <!-- $width, $left-margin, $right-margin are sentinels -->
        <!-- for sidebyside width control attributes           -->
        <xsl:if test="$width or $left-margin or $right-margin">
            <xsl:call-template name="sbs-caption-attributes">
                <xsl:with-param name="width" select="$width" />
                <xsl:with-param name="left-margin" select="$left-margin" />
                <xsl:with-param name="right-margin" select="$right-margin" />
            </xsl:call-template>
        </xsl:if>
        <span class="type">
            <xsl:apply-templates select="parent::*" mode="type-name"/>
        </span>
        <span class="codenumber">
            <xsl:apply-templates select="parent::*" mode="number"/>
        </span>
        <xsl:apply-templates />
    </figcaption>
</xsl:template>

<!-- sub caption is numbered by the serial number -->
<!-- which is a formatted  (a), (b), (c),...      -->
<xsl:template match="caption" mode="subcaption">
    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <figcaption>
        <!-- $width and $margins are sentinels for -->
        <!-- sidebyside width control attributes   -->
        <xsl:if test="$width or $margins">
            <xsl:call-template name="sbs-caption-attributes">
                <xsl:with-param name="width" select="$width" />
                <xsl:with-param name="left-margin" select="$left-margin" />
                <xsl:with-param name="right-margin" select="$right-margin" />
            </xsl:call-template>
        </xsl:if>
        <!-- no heading info in subcaption -->
        <span class="codenumber">
            <xsl:apply-templates select="parent::*" mode="serial-number"/>
        </span>
        <xsl:apply-templates />
    </figcaption>
</xsl:template>


<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Much of the cross-reference mechanism is -->
<!-- implemented in the common routines,      -->
<!-- here we implement two abstract templates -->
<!-- which are called from those routines     -->

<!-- The "text" of a cross-reference typically   -->
<!-- includes a number and our numbering code is -->
<!-- designed to sync with LaTeX's schemes       -->

<!-- The xref-link template provides one of two types of links      -->
<!--                                                                -->
<!-- (a) a traditional HTML hyperlink, a jump to a new location     -->
<!-- (b) a knowl, aka a transclusion, which appears within the text -->
<!--                                                                -->
<!-- A hyperlink is the default. For conversions to different       -->
<!-- HTML outputs, the choice of targets appearing as knowls        -->
<!-- can be adjusted by overriding the next template                -->

<!-- NB: these items must have their knowl content produced -->
<!-- NB: this is just the behavior of cross-references      -->

<!-- Cross-references as knowls                               -->
<!-- Override to turn off cross-references as knowls          -->
<!-- NB: this device makes it easy to turn off knowlification -->
<!-- entirely, since some renders cannot use knowl JavaScript -->
<xsl:template match="fn|p|blockquote|biblio|biblio/note|&DEFINITION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task|&FIGURE-LIKE;|&THEOREM-LIKE;|proof|case|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|poem|assemblage|paragraphs|objectives|exercise|webwork|hint|answer|solution|exercisegroup|men|mrow|li|contributor" mode="xref-as-knowl">
    <xsl:value-of select="true()" />
</xsl:template>
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- This is the implementation of an abstract template, -->
<!-- to accomodate hard-coded HTML numbers and for       -->
<!-- LaTeX the \ref and \label mechanism                 -->
<!-- NB: we do exactly the same thing in the mathbook-webwork-pg.xsl -->
<xsl:template match="*" mode="xref-number">
    <xsl:param name="xref" select="/.." />
    <xsl:variable name="needs-part-prefix">
        <xsl:apply-templates select="." mode="crosses-part-boundary">
            <xsl:with-param name="xref" select="$xref" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$needs-part-prefix = 'true'">
        <xsl:apply-templates select="ancestor::part" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- One exception is a local tag on an mrow -->
<xsl:template match="mrow[@tag]" mode="xref-number">
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
</xsl:template>

<!-- The second abstract template, we condition   -->
<!-- on if the link is rendered as a knowl or not -->
<!-- and then condition on the location of the    -->
<!-- actual link, which is sensitive to display   -->
<!-- math in particular                           -->
<!-- See xsl/mathbook-common.xsl for more info    -->
<!-- TODO: could match on "xref" once link routines  -->
<!-- are broken into two and other uses are rearranged -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" select="/.." />
    <xsl:param name="content" select="'MISSING LINK CONTENT'"/>
    <xsl:variable name="knowl">
        <xsl:apply-templates select="$target" mode="xref-as-knowl" />
    </xsl:variable>
    <xsl:choose>
        <!-- 1st exceptional case, xref in webwork -->
        <!-- Just parrot the content               -->
        <xsl:when test="ancestor::webwork|ancestor::title|ancestor::subtitle">
            <xsl:value-of select="$content" />
        </xsl:when>
        <!-- 2nd exceptional case, xref in mrow of display math  -->
        <!-- Requires http://aimath.org/mathbook/mathjaxknowl.js -->
        <!-- loaded as a MathJax extension for knowls to render  -->
        <xsl:when test="parent::mrow">
            <!-- MathJax expects similar constructions, variation is here -->
            <xsl:choose>
                <xsl:when test="$knowl='true'">
                    <xsl:text>\knowl{</xsl:text>
                    <xsl:apply-templates select="$target" mode="xref-knowl-filename" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\href{</xsl:text>
                    <xsl:apply-templates select="$target" mode="url" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>}{</xsl:text>
            <xsl:value-of select="$content" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- usual case, always an "a" element (anchor) -->
        <xsl:otherwise>
            <xsl:element name="a">
                <!-- knowl/hyperlink variability here -->
                <xsl:choose>
                    <xsl:when test="$knowl='true'">
                        <!-- build a modern knowl -->
                        <xsl:attribute name="knowl">
                            <xsl:apply-templates select="$target" mode="xref-knowl-filename" />
                        </xsl:attribute>
                        <!-- TODO: check if this "knowl-id" is needed, knowl.js implies it is -->
                        <xsl:attribute name="knowl-id">
                            <xsl:text>xref-</xsl:text>
                            <xsl:apply-templates select="$target" mode="internal-id" />
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- build traditional hyperlink -->
                        <xsl:attribute name="href">
                            <xsl:apply-templates select="$target" mode="url" />
                        </xsl:attribute>
                        <!-- use a class to identify an internal link -->
                        <xsl:attribute name="class">
                            <xsl:text>xref</xsl:text>
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- add HTML title and alt attributes to the link -->
                <xsl:attribute name="alt">
                    <xsl:apply-templates select="$target" mode="tooltip-text" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:apply-templates select="$target" mode="tooltip-text" />
                </xsl:attribute>
                <!-- link content from common template -->
                <xsl:value-of select="$content" />
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Numbers, units, quantities                     -->
<!-- quantity                                       -->
<xsl:template match="quantity">
    <!-- warning if there is no content -->
    <xsl:if test="not(descendant::unit) and not(descendant::per) and not(descendant::mag)">
        <xsl:message terminate="no">
        <xsl:text>MBX:WARNING: magnitude or units needed</xsl:text>
        </xsl:message>
    </xsl:if>
    <!-- print magnitude if there is one -->
    <xsl:if test="descendant::mag">
        <xsl:apply-templates select="mag"/>
        <!-- if the units that follow are fractional, thin space -->
        <xsl:if test="descendant::per">
            <xsl:text>&#8239;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- if there are non-fracitonal units, print them -->
    <xsl:if test="descendant::unit and not(descendant::per)">
        <xsl:apply-templates select="unit" />
    </xsl:if>
    <!-- if there are fracitonal units with a numerator part, print them -->
    <xsl:if test="descendant::unit and descendant::per">
        <sup> <xsl:apply-templates select="unit" /> </sup>
        <xsl:text>&#8260;</xsl:text>
        <sub> <xsl:apply-templates select="per" /> </sub>
    </xsl:if>
    <!-- if there are fracitonal units without a numerator part, print them -->
    <xsl:if test="not(descendant::unit) and descendant::per">
        <sup> <xsl:text>1</xsl:text></sup>
        <xsl:text>&#8260;</xsl:text>
        <sub> <xsl:apply-templates select="per" /> </sub>
    </xsl:if>
</xsl:template>

<!-- Magnitude                                      -->
<xsl:template match="mag">
    <xsl:variable name="mag">
        <xsl:apply-templates />
    </xsl:variable>
    <xsl:variable name="math-pi">
        <xsl:call-template name="begin-inline-math" />
        <xsl:text>\pi</xsl:text>
        <xsl:call-template name="end-inline-math" />
    </xsl:variable>
    <xsl:value-of select="str:replace($mag,'\pi',string($math-pi))"/>
</xsl:template>

<!-- unit and per children of a quantity element    -->
<!-- have a mandatory base attribute                -->
<!-- may have prefix and exp attributes             -->
<!-- base and prefix are not abbreviations          -->

<xsl:key name="prefix-key" match="prefix" use="concat(../@name, @full)"/>
<xsl:key name="base-key" match="base" use="concat(../@name, @full)"/>

<xsl:template match="unit|per">
    <xsl:if test="not(parent::quantity)">
        <xsl:message>MBX:WARNING: unit or per element should have parent quantity element</xsl:message>
    </xsl:if>
    <!-- if the unit is 1st and no mag, no need for thinspace. Otherwise, give thinspace -->
    <xsl:if test="position() != 1 or (local-name(.)='unit' and (preceding-sibling::mag or following-sibling::mag) and not(preceding-sibling::per or following-sibling::per))">
        <xsl:text>&#8239;</xsl:text>
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:variable name="prefix">
            <xsl:value-of select="@prefix" />
        </xsl:variable>
        <xsl:variable name="short">
            <xsl:for-each select="document('mathbook-units.xsl')">
                <xsl:value-of select="key('prefix-key',concat('prefixes',$prefix))/@short"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$short" />
    </xsl:if>
    <!-- base unit is *mandatory* so check to see if it has been provided -->
    <xsl:choose>
        <xsl:when test="@base">
            <xsl:variable name="base">
                <xsl:value-of select="@base" />
            </xsl:variable>
            <xsl:variable name="short">
                <xsl:for-each select="document('mathbook-units.xsl')">
                    <xsl:value-of select="key('base-key',concat('bases',$base))/@short"/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="$short" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="no">
                <xsl:text>MBX:WARNING: base unit needed</xsl:text>
            </xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- exponent is optional -->
    <xsl:if test="@exp">
        <sup><xsl:value-of select="@exp"/></sup>
    </xsl:if>
</xsl:template>

<!-- ############ -->
<!-- Attributions -->
<!-- ############ -->

<!-- At end of: blockquote, preface, foreword       -->
<!-- free-form for one line, or structured as lines -->
<!-- TODO: add CSS for attribution, div flush right         -->
<!-- And go slanted ("oblique"?)                            -->
<!-- Maybe use CSS to right align as a block                -->
<!-- https://github.com/BooksHTML/mathbook-assets/issues/64 -->

<!-- Single line, mixed-content          -->
<!-- Quotation dash if within blockquote -->
<!-- Unicode Character 'HORIZONTAL BAR' aka 'QUOTATION DASH' -->
<xsl:template match="attribution">
    <cite class="attribution">
        <xsl:if test="parent::blockquote">
            <xsl:text>&#x2015;</xsl:text>
        </xsl:if>
        <xsl:apply-templates />
    </cite>
</xsl:template>

<!-- Multiple lines, structured by lines -->
<xsl:template match="attribution[line]">
    <cite class="attribution">
        <xsl:apply-templates select="line" />
    </cite>
</xsl:template>

<!-- General line of an attribution -->
<xsl:template match="attribution/line">
    <xsl:if test="parent::attribution/parent::blockquote and not(preceding-sibling::*)">
        <xsl:text>&#x2015;</xsl:text>
    </xsl:if>
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::*">
        <br />
    </xsl:if>
</xsl:template>

<!-- Defined terms (bold, typically) -->
<xsl:template match="term">
    <dfn class="terminology">
        <xsl:apply-templates />
    </dfn>
</xsl:template>

<!-- Acronyms, Initialisms, Abbreviations -->
<!-- abbreviation: contracted form                                  -->
<!-- acronym: initials, pronounced as a word (eg SCUBA, RADAR)      -->
<!-- initialism: one letter at a time, (eg CIA, FBI)                -->
<!-- All are marked as the HTML "abbr" tag, but classes distinguish -->
<!-- Would a screen reader know the difference?                     -->
<xsl:template match="abbr">
    <abbr class="abbreviation">
        <xsl:apply-templates />
    </abbr>
</xsl:template>

<xsl:template match="acro">
    <abbr class="acronym">
        <xsl:apply-templates />
    </abbr>
</xsl:template>

<xsl:template match="init">
    <abbr class="initialism">
        <xsl:apply-templates />
    </abbr>
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <em class="emphasis">
        <xsl:apply-templates />
    </em>
</xsl:template>

<!-- Alert -->
<xsl:template match="alert">
    <em class="alert">
        <xsl:apply-templates />
    </em>
</xsl:template>

<xsl:template match="q">
    <q>
        <xsl:apply-templates />
    </q>
</xsl:template>

<!-- CSS for ins, del, s -->
<!-- http://html5doctor.com/ins-del-s/           -->
<!-- http://stackoverflow.com/questions/2539207/ -->

<!-- Insert (an edit) -->
<xsl:template match="insert">
    <ins class="insert">
        <xsl:apply-templates />
    </ins>
</xsl:template>

<!-- Delete (an edit) -->
<xsl:template match="delete">
    <del class="delete">
        <xsl:apply-templates />
    </del>
</xsl:template>

<!-- Stale (no longer relevant) -->
<xsl:template match="stale">
    <s class="stale">
        <xsl:apply-templates />
    </s>
</xsl:template>

<!-- Copyright symbol -->
<xsl:template match="copyright">
    <xsl:text>&#169;</xsl:text>
</xsl:template>

<!-- Registered symbol    -->
<!-- "sup" tag will raise -->
<xsl:template match="registered">
    <xsl:text>&#174;</xsl:text>
</xsl:template>

<!-- Trademark symbol -->
<xsl:template match="trademark">
    <xsl:text>&#x2122;</xsl:text>
</xsl:template>

<!-- Fill-in blank -->
<!-- Bringhurst suggests 5/11 em per character                            -->
<!-- A 'span' normally, but a MathJax non-standard \Rule for math         -->
<!-- "\Rule is a MathJax-specific extension with parameters being width,  -->
<!-- height and depth of the rule"                                        -->
<!-- Davide Cervone                                                       -->
<!-- https://groups.google.com/forum/#!topic/mathjax-users/IEivs1D7ntM    -->
<xsl:template match="fillin">
    <xsl:variable name="characters">
        <xsl:choose>
            <xsl:when test="@characters">
                <xsl:value-of select="@characters" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>10</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="parent::m or parent::me or parent::men or parent::mrow">
            <xsl:text>\underline{\hspace{</xsl:text>
            <xsl:value-of select="5 * $characters div 11" />
            <xsl:text>em}}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:attribute name="class">
                    <xsl:text>fillin</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="style">
                    <xsl:text>width: </xsl:text>
                    <xsl:value-of select="5 * $characters div 11" />
                    <xsl:text>em;</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Implication Symbols -->
<!-- TODO: better names! -->
<xsl:template match="imply">
    <xsl:text>&#x21D2;</xsl:text>
</xsl:template>
<xsl:template match="implyreverse">
    <xsl:text>&#x21D0;</xsl:text>
</xsl:template>

<!-- TeX, LaTeX -->
<!-- Corresponding CSS from William Hammond   -->
<!-- attributed to David Carlisle             -->
<!-- "mathjax-users" Google Group, 2015-12-27 -->
<!-- PreTeXt is in -common                    -->

<xsl:template match="latex">
    <span class="latex-logo">L<span class="A">a</span>T<span class="E">e</span>X</span>
</xsl:template>
<xsl:template match="tex">
    <span class="latex-logo">T<span class="E">e</span>X</span>
</xsl:template>

<!-- External URLs, Email        -->
<!-- Open in new window/tab as external reference                        -->
<!-- If content-less, then automatically formatted like code             -->
<!-- Within titles, we just produce (formatted) text, but nothing active -->
<!-- http://stackoverflow.com/questions/9782021/check-for-empty-xml-element-using-xslt -->
<xsl:template match="url">
    <!-- visible portion of HTML is the URL itself,   -->
    <!-- formatted as code, or content of PTX element -->
    <xsl:variable name="visible-text">
        <xsl:choose>
            <xsl:when test="not(*) and not(normalize-space())">
                <code class="code-inline tex2jax_ignore">
                    <xsl:value-of select="@href" />
                </code>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Normally in an active link, except inactive in titles -->
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:copy-of select="$visible-text" />
        </xsl:when>
        <xsl:otherwise>
            <!-- class name identifies an external link -->
            <a class="url" href="{@href}" target="_blank">
                <xsl:copy-of select="$visible-text" />
            </a>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="email">
    <xsl:element name="a">
        <xsl:attribute name="href">
            <xsl:text>mailto:</xsl:text>
            <xsl:value-of select="." />
        </xsl:attribute>
        <xsl:value-of select="." />
    </xsl:element>
</xsl:template>


<!-- ############# -->
<!-- Verbatim Text -->
<!-- ############# -->

<!-- Code, inline -->
<!-- PCDATA only, so drop non-text nodes -->
<!-- NB: "code-block" class otherwise -->
<xsl:template match="c">
    <code class="code-inline tex2jax_ignore">
        <xsl:value-of select="." />
    </code>
</xsl:template>


<!-- 100% analogue of LaTeX's verbatim            -->
<!-- environment or HTML's <pre> element          -->
<!-- TODO: center on page?                        -->

<!-- cd is for use in paragraphs, inline -->
<!-- Unstructured is pure text           -->
<xsl:template match="cd">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="pre">
        <xsl:attribute name="class">
            <xsl:text>code-block tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:value-of select="." />
    </xsl:element>
</xsl:template>

<!-- cline template is in xsl/mathbook-common.xsl -->
<xsl:template match="cd[cline]">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="pre">
        <xsl:attribute name="class">
            <xsl:text>code-block tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:apply-templates select="cline" />
    </xsl:element>
</xsl:template>

<!-- "pre" is analogous to the HTML tag of the same name -->
<!-- The "interior" templates decide between two styles  -->
<!--   (a) clean up raw text, just like for Sage code    -->
<!--   (b) interpret cline as line-by-line structure     -->
<!-- (See templates in xsl/mathbook-common.xsl file)     -->
<!-- Then wrap in a pre element that MathJax ignores     -->
<xsl:template match="pre">
    <xsl:element name="pre">
        <xsl:attribute name="class">
            <xsl:text>code-block tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="interior"/>
    </xsl:element>
</xsl:template>

<!-- ################### -->
<!-- Reserved Characters -->
<!-- ################### -->

<!-- Across all possibilities                     -->
<!-- See mathbook-common.xsl for discussion       -->

<!--           -->
<!-- XML, HTML -->
<!--           -->

<!-- & < > -->

<!-- Ampersand -->
<xsl:template match="ampersand">
    <xsl:text>&amp;</xsl:text>
</xsl:template>

<!-- Less Than -->
<xsl:template match="less">
    <xsl:text>&lt;</xsl:text>
</xsl:template>

<!-- Greater Than -->
<xsl:template match="greater">
    <xsl:text>&gt;</xsl:text>
</xsl:template>

<!--       -->
<!-- LaTeX -->
<!--       -->

<!-- # $ % ^ & _ { } ~ \ -->

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template match="hash">
    <xsl:text>#</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<xsl:template match="dollar">
    <xsl:text>$</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template match="percent">
    <xsl:text>%</xsl:text>
</xsl:template>

<!-- Circumflex  -->
<xsl:template match="circumflex">
    <xsl:text>^</xsl:text>
</xsl:template>

<!-- Ampersand -->
<!-- Handled above -->

<!-- Underscore -->
<xsl:template match="underscore">
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Left Brace -->
<xsl:template match="lbrace">
    <xsl:text>{</xsl:text>
</xsl:template>

<!-- Right  Brace -->
<xsl:template match="rbrace">
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template match="tilde">
    <xsl:text>~</xsl:text>
</xsl:template>

<!-- Backslash -->
<xsl:template match="backslash">
    <xsl:text>\</xsl:text>
</xsl:template>

<!-- Asterisk -->
<!-- Centered as a character, not an exponent                    -->
<!-- Unicode Character 'ASTERISK OPERATOR' (U+2217)              -->
<!-- See raised asterisk for other options:                      -->
<!-- http://www.fileformat.info/info/unicode/char/002a/index.htm -->
<xsl:template match="asterisk">
    <xsl:text>&#x2217;</xsl:text>
</xsl:template>

<!-- Left Single Quote -->
<xsl:template match="lsq">
    <xsl:text>&#x2018;</xsl:text>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template match="rsq">
    <xsl:text>&#x2019;</xsl:text>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template match="lq">
    <xsl:text>&#x201c;</xsl:text>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template match="rq">
    <xsl:text>&#x201d;</xsl:text>
</xsl:template>

<!-- Left Bracket -->
<xsl:template match="lbracket">
    <xsl:text>[</xsl:text>
</xsl:template>

<!-- Right Bracket -->
<xsl:template match="rbracket">
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Left Double Bracket -->
<!-- MATHEMATICAL LEFT WHITE SQUARE BRACKET -->
<xsl:template match="ldblbracket">
    <xsl:text>&#x27e6;</xsl:text>
</xsl:template>

<!-- Right Double Bracket -->
<!-- MATHEMATICAL RIGHT WHITE SQUARE BRACKET -->
<xsl:template match="rdblbracket">
    <xsl:text>&#x27e7;</xsl:text>
</xsl:template>

<!-- Left Angle Bracket -->
<xsl:template match="langle">
    <xsl:text>&#x2329;</xsl:text>
</xsl:template>

<!-- Right Angle Bracket -->
<xsl:template match="rangle">
    <xsl:text>&#x232a;</xsl:text>
</xsl:template>


<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<xsl:template match="midpoint">
    <xsl:text>&#xb7;</xsl:text>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<xsl:template match="swungdash">
    <xsl:text>&#x2053;</xsl:text>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template match="permille">
    <xsl:text>&#x2030;</xsl:text>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template match="pilcrow">
    <xsl:text>&#xb6;</xsl:text>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template match="section-mark">
    <xsl:text>&#xa7;</xsl:text>
</xsl:template>

<!-- Times -->
<!-- A "multiplication sign" symbol for use in text   -->
<!-- Styled to enhance, consensus at Google Group was -->
<!-- font-size: larger; vertical-align: -.2ex;        -->
<xsl:template match="times">
    <xsl:element name="span">
        <xsl:attribute name="class">
            <xsl:text>times-sign</xsl:text>
        </xsl:attribute>
        <xsl:text>&#xd7;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Slash -->
<!-- Forward slash, or virgule (see solidus) -->
<xsl:template match="slash">
    <xsl:text>&#x2f;</xsl:text>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<xsl:template match="solidus">
    <xsl:text>&#x2044;</xsl:text>
</xsl:template>

<!-- Backtick -->
<!-- This is the "accent grave" character.                 -->
<!-- Unicode Character 'GRAVE ACCENT' (U+0060)             -->
<!-- Really it is a modifier.  But as an ASCII character   -->
<!-- on most keyboards it gets used in computer languages. -->
<!-- Normally you would use this in verbatim contexts.     -->
<!-- It is not a left-quote (see <lsq />0, nor is it a     -->
<!-- modifier.  If you really want this character in a     -->
<!-- text context use this empty element.  For example,    -->
<!-- this is a character Markdown uses, so we want to      -->
<!-- provide this safety valve.                            -->
<xsl:template match="backtick">
    <xsl:text>&#x60;</xsl:text>
</xsl:template>

<!-- Foreign words/idioms -->
<!-- Rutter, Web Typography, p.50 advocates a "span" with      -->
<!-- a "lang" attribute for foreign words so screen readers    -->
<!-- and hyphenation react properly.  Elsewhere, italics is    -->
<!-- suggested only for transliterated wods, to avoid          -->
<!-- confusion. However, for now, we are using "i" by default, -->
<!-- with a class that can be used in CSS for distinctions.    -->
<!-- But see also (2018-03-23):                                -->
<!-- https://www.w3.org/TR/html5/text-level-semantics.html#the-i-element -->
<xsl:template match="foreign">
    <i class="foreign">
        <xsl:if test="@xml:lang">
            <xsl:attribute name="lang">
                <xsl:value-of select="@xml:lang" />
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates />
    </i>
</xsl:template>

<!-- Non-breaking space, which "joins" two words as a unit            -->
<!-- Using &nbsp; does not travel well into node-set() in common file -->
<!-- http://stackoverflow.com/questions/31870/using-a-html-entity-in-xslt-e-g-nbsp -->
<xsl:template match="nbsp">
    <xsl:text>&#xa0;</xsl:text>
</xsl:template>

<!-- Dashes, Hyphen -->
<!-- http://www.cs.tut.fi/~jkorpela/dashes.html -->
<!-- NB: global $emdash-space-char could go local to "mdash" template -->
<xsl:variable name="emdash-space-char">
    <xsl:choose>
        <xsl:when test="$emdash-space='none'">
            <xsl:text />
        </xsl:when>
        <xsl:when test="$emdash-space='thin'">
            <xsl:text>&#8201;</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:variable>
<xsl:template match="mdash">
    <xsl:value-of select="$emdash-space-char"/>
    <xsl:text>&#8212;</xsl:text>
    <xsl:value-of select="$emdash-space-char"/>
</xsl:template>
<xsl:template match="ndash">
    <xsl:text>&#8211;</xsl:text>
</xsl:template>
<!-- A "hyphen" element was a bad idea, very cumbersome -->
<xsl:template match="hyphen">
    <xsl:message>MBX:WARNING: the "hyphen" element is deprecated (2017-02-05), use the "hyphen-minus" character instead (aka the "ASCII hyphen")</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:text>&#8208;</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Biological Names -->
<!-- ################ -->

<xsl:template match="taxon[not(genus) and not(species)]">
    <span class="taxon">
        <xsl:apply-templates />
    </span>
</xsl:template>

<xsl:template match="taxon[genus or species]">
    <span class="taxon">
        <xsl:if test="genus">
            <span class="genus">
                <xsl:apply-templates select="genus"/>
            </span>
        </xsl:if>
        <xsl:if test="genus and species">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:if test="species">
            <span class="species">
                <xsl:apply-templates select="species"/>
            </span>
        </xsl:if>
    </span>
</xsl:template>

<!-- Titles of Publications -->
<!-- 2018-02-05: Deprecate "booktitle" in favor of       -->
<!-- "pubtitle".  Will still maintain all for a while.   -->
<!-- CMOS:  When quoted in text or listed in a           -->
<!-- bibliography, titles of books, journals, plays,     -->
<!-- and other freestanding works are italicized; titles -->
<!-- of articles, chapters, and other shorter works      -->
<!-- are set in roman and enclosed in quotation marks.   -->
<xsl:template match="pubtitle|booktitle">
    <span class="booktitle">
        <xsl:apply-templates />
    </span>
</xsl:template>

<xsl:template match="articletitle">
    <span class="articletitle">
        <xsl:apply-templates />
    </span>
</xsl:template>


<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- These are specific instances of abstract templates        -->
<!-- See the similar section of  mathbook-common.xsl  for more -->

<xsl:template match="*" mode="nbsp">
    <xsl:text>&#xa0;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="ndash">
    <xsl:text>&#8211;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="mdash">
    <xsl:text>&#8212;</xsl:text>
</xsl:template>



<!--       -->
<!-- Music -->
<!--       -->

<!--                 -->
<!-- Musical Symbols -->
<!--                 -->

<!-- Accidentals -->

<!-- TODO: If requested, add semi- and sesqui- versions of sharp and flat -->

<!-- Double Sharp -->
<!-- Unicode Character 'MUSICAL SYMBOL DOUBLE SHARP' (U+1D12A)    -->
<!-- http://www.fileformat.info/info/unicode/char/1d12a/index.htm -->
<xsl:template name="doublesharp">
    <xsl:text>&#x1D12A;</xsl:text>
</xsl:template>

<!-- Sharp -->
<!-- Unicode Character 'MUSIC SHARP SIGN' (U+266F)               -->
<!-- http://www.fileformat.info/info/unicode/char/266f/index.htm -->
<xsl:template name="sharp">
    <xsl:text>&#x266F;</xsl:text>
</xsl:template>

<!-- Natural -->
<!-- Unicode Character 'MUSIC NATURAL SIGN' (U+266E)             -->
<!-- http://www.fileformat.info/info/unicode/char/266e/index.htm -->
<xsl:template name="natural">
    <xsl:text>&#x266E;</xsl:text>
</xsl:template>

<!-- Flat -->
<!-- Unicode Character 'MUSIC FLAT SIGN' (U+266D)                -->
<!-- http://www.fileformat.info/info/unicode/char/266d/index.htm -->
<xsl:template name="flat">
    <xsl:text>&#x266D;</xsl:text>
</xsl:template>

<!-- Double Flat -->
<!-- Unicode Character 'MUSICAL SYMBOL DOUBLE FLAT' (U+1D12B)     -->
<!-- http://www.fileformat.info/info/unicode/char/1d12b/index.htm -->
<xsl:template name="doubleflat">
    <xsl:text>&#x1D12B;</xsl:text>
</xsl:template>

<!-- Half Diminished -->
<!-- (MathJax does not support "\o") -->
<!-- Unicode Character 'LATIN SMALL LETTER O WITH STROKE' (U+00F8) -->
<!-- http://www.fileformat.info/info/unicode/char/00F8/index.htm -->
<xsl:template name="halfdiminishedchordsymbol">
    <xsl:text>&#x00F8;</xsl:text>
</xsl:template>

<!-- Raw Bibliographic Entry Formatting              -->
<!-- Markup really, not full-blown data preservation -->

<!-- Title in italics -->
<xsl:template match="biblio[@type='raw']/title">
    <i><xsl:apply-templates /></i>
</xsl:template>

<!-- No treatment for journal -->
<xsl:template match="biblio[@type='raw']/journal">
    <xsl:apply-templates />
</xsl:template>

<!-- Volume in bold -->
<xsl:template match="biblio[@type='raw']/volume">
    <b><xsl:apply-templates /></b>
</xsl:template>

<!-- Year in parentheses -->
<xsl:template match="biblio[@type='raw']/year">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Number -->
<xsl:template match="biblio[@type='raw']/number">
    <xsl:text>no. </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Ibid, nee ibidem, handle TeX period idosyncracy, empty element -->
<!-- A 3em dash is used for identical authors                       -->
<xsl:template match="biblio[@type='raw']/ibid">
    <xsl:text>Ibid.</xsl:text>
</xsl:template>
<!-- Index Entries -->
<!-- Kill on sight, collect later to build index  -->
<xsl:template match="index[not(index-list)]" />
<xsl:template match="idx" />


<!-- Demonstrations -->
<!-- A simple page with no constraints -->
<xsl:template match="demonstration">
    <xsl:variable name="url"><xsl:apply-templates select="." mode="internal-id" />.html</xsl:variable>
    <a href="{$url}" target="_blank" class="link">
        <xsl:apply-templates select="." mode="title-full" />
    </a>
    <xsl:apply-templates select="." mode="simple-file-wrap" >
        <xsl:with-param name="content">
            <xsl:apply-templates />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Sage Cells -->
<!-- TODO: make hidden autoeval cells link against sage-compute cells -->

<!-- Never an @id , so just repeat -->
<xsl:template match="sage" mode="duplicate">
    <xsl:apply-templates select="." />
</xsl:template>

<!-- An abstract named template accepts input text and   -->
<!-- output text, then wraps it for the Sage Cell Server -->
<!-- TODO: consider showing output in green span (?),    -->
<!-- presently output is dropped as computable           -->
<xsl:template name="sage-active-markup">
    <xsl:param name="internal-id" />
    <xsl:param name="language-attribute" />
    <xsl:param name="in" />
    <xsl:param name="out" />
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>sagecell-</xsl:text>
            <xsl:if test="$language-attribute=''">
                <xsl:text>sage</xsl:text>
            </xsl:if>
            <xsl:value-of select="$language-attribute" />
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:value-of select="$internal-id" />
        </xsl:attribute>
        <xsl:element name="script">
            <xsl:attribute name="type">
                <xsl:text>text/x-sage</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="$in" />
        </xsl:element>
    </xsl:element>
</xsl:template>

<!-- An abstract named template accepts input text   -->
<!-- and provides the display class, so untouchable  -->
<xsl:template name="sage-display-markup">
    <xsl:param name="in" />
    <div class="sage-display">
    <script type="text/x-sage">
        <xsl:value-of select="$in" />
    </script>
    </div>
</xsl:template>

<!-- Program Listings -->
<!-- Research:  http://softwaremaniacs.org/blog/2011/05/22/highlighters-comparison/           -->
<!-- From Google: downloadable, auto-detects languages, has hint-handlers                     -->
<!-- http://code.google.com/p/google-code-prettify/                                           -->
<!-- http://code.google.com/p/google-code-prettify/wiki/GettingStarted                        -->
<!-- See common file for more on language handlers, and "language-prettify" template          -->
<!-- Coordinate with disabling in Sage Notebook production                                    -->
<xsl:template match="program">
    <!-- with language, pre.prettyprint activates styling and Prettifier -->
    <!-- with no language, pre.plainprint just yields some styling       -->
    <xsl:variable name="classes">
        <xsl:choose>
            <xsl:when test="@language">
                <xsl:text>prettyprint</xsl:text>
                <xsl:text> lang-</xsl:text>
                <xsl:value-of select="@language" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>plainprint</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <pre class="{$classes}">
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="input" />
    </xsl:call-template>
    </pre>
</xsl:template>

<!-- Interactive Programs -->
<!-- Use the PyTutor embedding to provide a Python program -->
<!-- where a reader can interactively step through the program -->
<xsl:template match="program[@interactive='pythontutor']">
    <!-- check that the language is Python? -->
    <xsl:variable name="internalid">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>pytutorVisualizer</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:value-of select="$internalid" />
            <xsl:text>-div</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="data-tracefile">
            <xsl:text>pytutor/</xsl:text>
            <xsl:value-of select="$internalid" />
            <xsl:text>.json</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="data-params">
            <xsl:text>{</xsl:text>
            <xsl:text>"verticalStack": true, </xsl:text>
            <xsl:text>"embeddedMode": false, </xsl:text>
            <xsl:text>"codeDivWidth": </xsl:text>
            <xsl:value-of select="$design-width" />
            <xsl:text>, </xsl:text>
            <xsl:text>"codeDivHeight": 300</xsl:text>
            <xsl:text>}</xsl:text>
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- Bits of Javascript for the top and bottom of the web page -->
<xsl:template name="pytutor-header">
    <xsl:if test="$document-root//program[@interactive='pythontutor']">
        <script type="text/javascript" src="http://pythontutor.com/build/pytutor-embed.bundle.js?cc25af72af" charset="utf-8"></script>
    </xsl:if>
</xsl:template>

<xsl:template name="pytutor-footer">
    <xsl:if test="$document-root//program[@interactive='pythontutor']">
        <script type="text/javascript">createAllVisualizersFromHtmlAttrs();</script>
    </xsl:if>
</xsl:template>

<!-- Console Session -->
<!-- An interactive command-line session with a prompt, input and output -->
<xsl:template match="console">
    <!-- ignore prompt, and pick it up in trailing input -->
    <xsl:element name="pre">
        <xsl:attribute name="class">console</xsl:attribute>
        <xsl:apply-templates select="input|output" />
    </xsl:element>
</xsl:template>

<!-- do not run through generic text() template -->
<xsl:template match="console/prompt">
    <xsl:element name="span">
        <xsl:attribute name="class">prompt unselectable</xsl:attribute>
        <xsl:value-of select="." />
    </xsl:element>
</xsl:template>

<!-- match immediately preceding, only if a prompt:                   -->
<!-- https://www.oxygenxml.com/archives/xsl-list/199910/msg00541.html -->
<xsl:template match="console/input">
    <xsl:apply-templates select="preceding-sibling::*[1][self::prompt]" />
    <xsl:element name="b">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    </xsl:element>
</xsl:template>

<xsl:template match="console/output">
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
</xsl:template>


<!-- ############ -->
<!-- Interactives -->
<!-- ############ -->

<!-- Interactive goodies to embed, with a general -->
<!-- interface but specific implementations       -->

<!-- TODO: -->
<!-- sizing:  width x aspect-ratio -->
<!-- internal-id:  migrate to iframes -->
<!-- titles:  migrate to iframes -->

<!-- PTX source will include a "static" -->
<!-- element, which we routinely ignore -->

<!-- Geogebra -->
<xsl:template match="interactive[@geogebra]">
    <iframe scrolling="no" src="https://www.geogebra.org/material/iframe/id/{@geogebra}/width/600/height/340/border/888888/smb/false/stb/false/stbh/false/ai/false/asb/false/sri/false/rc/false/ld/false/sdz/false/ctl/false" width="600px" height="340px" />
</xsl:template>

<xsl:template match="interactive[@geogebra and @height and @width]">
    <iframe scrolling="no" src="https://www.geogebra.org/material/iframe/id/{@geogebra}/width/{@width}/height/{@height}/border/888888/smb/false/stb/false/stbh/false/ai/false/asb/false/sri/false/rc/false/ld/false/sdz/false/ctl/false" width="{@width}px" height="{@height}px" />
</xsl:template>

<xsl:template match="interactive[@geogebra and @scale]">
    <iframe scrolling="no" src="https://www.geogebra.org/material/iframe/id/{@geogebra}/width/{@scale*600 div 100}/height/{@scale*340 div 100}/border/888888/smb/false/stb/false/stbh/false/ai/false/asb/false/sri/false/rc/false/ld/false/sdz/false/ctl/false" width="{@scale*600 div 100}px" height="{@scale*340 div 100}px" />
</xsl:template>


<!-- Local source -->
<xsl:template match="interactive[@platform='geogebra']">
    <!-- We need a Javascript identifier to name the applet -->
    <xsl:variable name="applet-name">
        <xsl:apply-templates select="." mode="internal-id-no-dash" />
    </xsl:variable>
    <!-- And a Javascript identifier for the parameters -->
    <xsl:variable name="applet-parameters">
        <xsl:apply-templates select="." mode="internal-id-no-dash" />
        <xsl:text>_params</xsl:text>
    </xsl:variable>
    <!-- And an HTML unique identifier -->
    <xsl:variable name="applet-container">
        <xsl:apply-templates select="." mode="internal-id" />
        <xsl:text>-container</xsl:text>
    </xsl:variable>
    <!-- Javascript API for loading from a base64 string                   -->
    <!-- Crib from page source at second link, with modifications          -->
    <!-- Multiple instances:  https://stackoverflow.com/questions/9434     -->
    <!-- https://learn.jquery.com/using-jquery-core/document-ready/        -->
    <!-- We assume JQuery is loaded, so go that route                      -->
    <!-- https://wiki.geogebra.org/en/Reference:GeoGebra_Apps_API          -->
    <!-- http://dev.geogebra.org/examples/html/example-api-save-state.html -->
    <script type="text/javascript">
<xsl:text>
var </xsl:text><xsl:value-of select="$applet-parameters" /><xsl:text> = {
        "width":550,
        "height":245,
        "showToolBar":true,
        "borderColor":null,
        "showMenuBar":false,
        "showAlgebraInput":false,
        "customToolbar":"0 || 1",
        "showResetIcon":true,
        "enableLabelDrags":false,
        "enableShiftDragZoom":true,
        "enableRightClick":false,
        "capturingThreshold":null,
        "showToolBarHelp":true,
        "errorDialogsActive":true,
        "useBrowserForJS":false,
        "ggbBase64":"</xsl:text>
<xsl:value-of select="normalize-space(code[@language='base64']/text())" />
<xsl:text>"};&#xa;</xsl:text>

<xsl:text>var </xsl:text><xsl:value-of select="$applet-name" /><xsl:text> = new GGBApplet(</xsl:text><xsl:value-of select="$applet-parameters" /><xsl:text>, '5.0');
$( document ).ready(
function() { </xsl:text><xsl:value-of select="$applet-name" /><xsl:text>.inject('</xsl:text><xsl:value-of select="$applet-container" /><xsl:text>'); }
);&#xa;</xsl:text>
    </script>
    <div class="geogebra-applet" id="{$applet-container}"></div>
</xsl:template>

<!-- Desmos -->
<xsl:template match="interactive[@desmos]">
    <iframe src="https://www.desmos.com/calculator/{@desmos}" width="400" height="600" />
</xsl:template>

<!-- CalcPlot3D -->
<xsl:template match="interactive[@platform='calcplot3d']">
    <!-- code/@url is the query string -->
    <xsl:variable name="query-url" select="code" />
    <!-- Use @variant to pick an endpoint/view/infrastructure -->
    <xsl:variable name="cp3d-endpoint">
        <xsl:choose>
            <xsl:when test="@variant='application'">
                <xsl:text>https://www.monroecc.edu/faculty/paulseeburger/calcnsf/CalcPlot3D</xsl:text>
            </xsl:when>
            <xsl:when test="@variant='controls'">
                <xsl:text>https://www.monroecc.edu/faculty/paulseeburger/CalcPlot3D/dynamicFigureWCP</xsl:text>
            </xsl:when>
            <xsl:when test="@variant='minimal'">
                <xsl:text>https://www.monroecc.edu/faculty/paulseeburger/CalcPlot3D/dynamicFigure</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- just a silly domain so something none-too-crazy happens -->
                <xsl:text>http://www.example.com/</xsl:text>
                <xsl:message>MBX:ERROR:  @variant="<xsl:value-of select="@variant" />" is not recognized for a CalcPlot3D &lt;interactive&gt;</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- load 'em up and go -->
    <xsl:variable name="full-url" select="concat($cp3d-endpoint, '/?', $query-url)" />
    <iframe src="{$full-url}" width="600" height="800" />
</xsl:template>

<!-- JSXGraph -->
<xsl:template match="jsxgraph">
    <!-- interpret @width percentage and @aspect ratio -->
    <xsl:variable name="width-percent">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="width-fraction">
        <xsl:value-of select="substring-before($width-percent,'%') div 100" />
    </xsl:variable>
    <xsl:variable name="aspect-ratio">
        <xsl:apply-templates select="." mode="get-aspect-ratio">
            <xsl:with-param name="default-aspect" select="'1:1'" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="width"  select="$design-width * $width-fraction" />
    <xsl:variable name="height" select="$design-width * $width-fraction div $aspect-ratio" />
    <!-- the div to hold the JSX output -->
    <xsl:element name="div">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>jxgbox</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text>
            <xsl:value-of select="$width" />
            <xsl:text>px; height:</xsl:text>
            <xsl:value-of select="$height" />
            <xsl:text>px;</xsl:text>
        </xsl:attribute>
    </xsl:element>
    <!-- the script to hold the code                       -->
    <!-- JSXGraph code must reference the id on the div,   -->
    <!-- so ideally an xml:id specifies this in the source -->
    <xsl:element name="script">
        <xsl:attribute name="type">
            <xsl:text>text/javascript</xsl:text>
        </xsl:attribute>
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="input" />
        </xsl:call-template>
    </xsl:element>
    <xsl:copy-of select="controls" />
</xsl:template>

<!-- Wolfram Computable Document Format -->
<!-- https://www.wolfram.com/cdf/adopting-cdf/deploying-cdf/web-delivery-cloud.html              -->
<!-- More for MMA origination, but discusses "cloud credits"                                     -->
<!-- https://reference.wolfram.com/language/howto/DeployInteractiveContentInTheWolframCloud.html -->
<!-- https://www.wolfram.com/cloud-credits/                                                      -->
<xsl:template match="interactive[@wolfram-cdf]">
    <!-- Query string option: _embed=iframe will provide Wolfram footer -->
    <iframe width="500" height="520" src="https://www.wolframcloud.com/objects/{@wolfram-cdf}?_view=frameless" />
</xsl:template>

<!-- ########################## -->
<!-- WeBWorK Embedded Exercises -->
<!-- ########################## -->

<!-- WeBWorK HTML CSS header -->
<!-- MathView likely necessary for WW widgets          -->
<!-- Incorporated only if "webwork" element is present -->
<xsl:template name="webwork">
    <link href="{$webwork-server}/webwork2_files/js/apps/MathView/mathview.css" rel="stylesheet" />
    <script type="text/javascript" src="{$webwork-server}/webwork2_files/js/vendor/iframe-resizer/js/iframeResizer.min.js"></script>
</xsl:template>

<!-- ############################# -->
<!-- MyOpenMath Embedded Exercises -->
<!-- ############################# -->

<xsl:template match="myopenmath">
    <xsl:element name="iframe">
        <xsl:attribute name="width">
            <xsl:text>100%</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="src">
            <xsl:text>https://www.myopenmath.com/embedq.php?id=</xsl:text>
            <xsl:value-of select="@problem" />
            <!-- can't disable escaping text of an attribute -->
            <xsl:text>&amp;resizer=true</xsl:text>
        </xsl:attribute>
    </xsl:element>
    <!-- not so great -->
    <!-- <script type="text/javascript">iFrameResize({log:true,inPageLinks:true,resizeFrom:'child'})</script> -->
</xsl:template>

<!--                         -->
<!-- Web Page Infrastructure -->
<!--                         -->

<!-- An individual page:                                   -->
<!-- Inputs:                                               -->
<!-- * page content (exclusive of banners, navigation etc) -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="containing-filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
    <xsl:call-template name="converter-blurb-html" />
    <html lang="{$document-language}"> <!-- dir="rtl" here -->
        <head>
            <title>
                <!-- Leading with initials is useful for small tabs -->
                <xsl:if test="//docinfo/initialism">
                    <xsl:apply-templates select="//docinfo/initialism" />
                    <xsl:text> </xsl:text>
                </xsl:if>
            <xsl:apply-templates select="." mode="title-simple" />
            </title>
            <meta name="Keywords" content="Authored in PreTeXt" />
            <!-- http://webdesignerwall.com/tutorials/responsive-design-in-3-steps -->
            <meta name="viewport" content="width=device-width,  initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0" />
            <!-- jquery used by sage, webwork, knowls -->
            <xsl:call-template name="jquery-sagecell" />
            <xsl:call-template name="mathjax" />
            <!-- webwork's iframeResizer needs to come before sage -->
            <xsl:if test="$document-root//webwork[@*|node()]">
                <xsl:call-template name="webwork" />
            </xsl:if>
            <xsl:apply-templates select="." mode="sagecell" />
            <xsl:if test="$document-root//program">
                <xsl:call-template name="goggle-code-prettifier" />
            </xsl:if>
            <xsl:call-template name="google-search-box-js" />
            <xsl:call-template name="knowl" />
            <xsl:call-template name="mathbook-js" />
            <xsl:call-template name="fonts" />
            <xsl:call-template name="hypothesis-annotation" />
            <xsl:call-template name="geogebra" />
            <xsl:call-template name="jsxgraph" />
            <xsl:call-template name="css" />
            <xsl:call-template name="pytutor-header" />
        </head>
        <xsl:element name="body">
            <!-- the first class controls the default icon -->
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="$root/book">mathbook-book</xsl:when>
                    <xsl:when test="$root/article">mathbook-article</xsl:when>
                </xsl:choose>
                <xsl:if test="$b-has-toc">
                    <xsl:text> has-toc has-sidebar-left</xsl:text> <!-- note space, later add right -->
                </xsl:if>
            </xsl:attribute>
            <!-- assistive "Skip to main content" link    -->
            <!-- this *must* be first for maximum utility -->
            <xsl:call-template name="skip-to-content-link" />
            <xsl:call-template name="latex-macros" />
             <header id="masthead" class="smallbuttons">
                <div class="banner">
                    <div class="container">
                        <xsl:call-template name="google-search-box" />
                        <xsl:call-template name="brand-logo" />
                        <div class="title-container">
                            <h1 class="heading">
                                <xsl:element name="a">
                                    <xsl:attribute name="href">
                                        <xsl:apply-templates select="$document-root" mode="containing-filename" />
                                    </xsl:attribute>
                                    <span>
                                        <xsl:apply-templates select="." mode="title-attributes" />
                                        <xsl:apply-templates select="$document-root" mode="title-simple" />
                                    </span>
                                    <xsl:if test="normalize-space($document-root/subtitle)">
                                        <span class="subtitle">
                                            <xsl:apply-templates select="$document-root" mode="subtitle" />
                                        </span>
                                    </xsl:if>
                                </xsl:element>
                            </h1>
                            <!-- Serial list of authors/editors -->
                            <p class="byline">
                                <xsl:apply-templates select="$document-root/frontmatter/titlepage/author" mode="name-list"/>
                                <xsl:apply-templates select="$document-root/frontmatter/titlepage/editor" mode="name-list"/>
                            </p>
                        </div>  <!-- title-container -->
                    </div>  <!-- container -->
                </div> <!-- banner -->
            <xsl:apply-templates select="." mode="primary-navigation" />
            </header> <!-- masthead -->
            <div class="page">
                <xsl:apply-templates select="." mode="sidebars" />
                <main class="main">
                    <div id="content" class="mathbook-content">
                        <xsl:copy-of select="$content" />
                    </div>
                </main>
            </div>
            <xsl:apply-templates select="$docinfo/analytics" />
            <xsl:call-template name="pytutor-footer" />
        </xsl:element>
    </html>
    </exsl:document>
</xsl:template>

<!-- A minimal individual page:                              -->
<!-- Inputs:                                                 -->
<!-- * page content (exclusive of banners, navigation etc)   -->
<!-- Maybe a page title -->
<xsl:template match="*" mode="simple-file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="internal-id" />
        <text>.html</text>
    </xsl:variable>
    <exsl:document href="{$filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
    <xsl:call-template name="converter-blurb-html" />
    <html lang="{$document-language}"> <!-- dir="rtl" here -->
        <head>
            <meta name="Keywords" content="Authored in PreTeXt" />
            <meta name="viewport" content="width=device-width,  initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0" />

            <!-- jquery used by sage, webwork, knowls -->
            <xsl:call-template name="jquery-sagecell" />
            <xsl:call-template name="mathjax" />
            <!-- webwork's iframeResizer needs to come before sage -->
            <xsl:if test="//webwork[@*|node()]">
                <xsl:call-template name="webwork" />
            </xsl:if>
            <xsl:apply-templates select="." mode="sagecell" />
            <xsl:call-template name="knowl" />
            <xsl:call-template name="fonts" />
            <xsl:call-template name="hypothesis-annotation" />
            <xsl:call-template name="geogebra" />
            <xsl:call-template name="jsxgraph" />
            <xsl:call-template name="css" />
        </head>
        <!-- TODO: needs some padding etc -->
        <body>
            <xsl:copy-of select="$content" />
            <xsl:apply-templates select="$docinfo/analytics" />
        </body>
    </html>
    </exsl:document>
</xsl:template>

<!-- ################# -->
<!-- Navigational Aids -->
<!-- ################# -->

<!-- Skip to Main Content link -->
<!-- For accessibilty, a link (hidden off-screen)  -->
<!-- which allows a quick by-pass of all the other -->
<!-- navigational elements, direct to content      -->
<xsl:template name="skip-to-content-link">
    <xsl:element name="a">
        <xsl:attribute name="class">
            <xsl:text>assistive</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="href">
            <xsl:text>#content</xsl:text>
        </xsl:attribute>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'skip-to-content'" />
        </xsl:call-template>
    </xsl:element>
</xsl:template>

<!-- Prev/Up/Next URL's -->
<!-- The "tree" versions are simpler, though less natural for a reader -->
<!-- They often return empty and require the use of the Up button      -->
<!-- The "linear" versions are breadth-first search, and so mimic      -->
<!-- the way a reader would encounter the sections in a (linear) book  -->

<!-- TODO: perhaps isolate logic to return nodes and put into "common" -->

<!-- Check if the XML tree has a preceding/following/parent node -->
<!-- Then check if it is a document node (structural)            -->
<!-- If so, compute the URL for the node                         -->
<!-- NB: tree urls maybe enabled as a processing option          -->
<xsl:template match="*" mode="previous-tree-url">
    <xsl:if test="preceding-sibling::*">
        <xsl:variable name="preceding" select="preceding-sibling::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$preceding" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <xsl:apply-templates select="$preceding" mode="url" />
        </xsl:if>
    </xsl:if>
    <!-- could be empty -->
</xsl:template>

<xsl:template match="*" mode="next-tree-url">
    <xsl:if test="following-sibling::*">
        <xsl:variable name="following" select="following-sibling::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$following" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <xsl:apply-templates select="$following" mode="url" />
        </xsl:if>
    </xsl:if>
    <!-- could be empty -->
</xsl:template>

<!-- Create the URL of the parent document node    -->
<!-- Parent always exists, since the               -->
<!-- structural check fails at <mathbook>          -->
<!-- Identical in tree/linear schemes, up is up    -->
<xsl:template match="*" mode="up-url">
    <xsl:if test="parent::*">
        <xsl:variable name="parent" select="parent::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$parent" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <xsl:apply-templates select="$parent" mode="url" />
        </xsl:if>
    </xsl:if>
    <!-- will be empty precisely at children of <mathbook> -->
</xsl:template>

<!-- Next Linear URL -->
<!-- Breadth-first search, try to descend into first summary link -->
<!-- Else, look sideways for next structural sibling              -->
<!-- Else, go up to parent and look sideways                      -->
<!-- Else done and return empty url                               -->
<xsl:template match="*" mode="next-linear-url">
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true'">
            <!-- Descend once, will always have a child that is structural -->
            <xsl:variable name="first-structural-child" select="*[&STRUCTURAL-FILTER;][1]" />
            <xsl:apply-templates select="$first-structural-child" mode="url" />
            <!-- remainder is a basic check, could be removed -->
            <xsl:variable name="structural">
                <xsl:apply-templates select="$first-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>MBX:ERROR: descending into first node of an intermediate page (<xsl:value-of select="local-name($first-structural-child)" />) that is non-structural; maybe your source has incorrect structure</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <!-- try going sideways, which climbs up the tree recursively -->
            <xsl:apply-templates select="." mode="next-sideways-url" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Recursively look sideways to the right, else up     -->
<!-- <mathbook> is not structural, so halt looking there -->
<xsl:template match="*" mode="next-sideways-url">
    <xsl:variable name="url">
        <xsl:if test="following-sibling::*">
            <xsl:variable name="following" select="following-sibling::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$following" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <!-- A normal sibling following -->
                <xsl:apply-templates select="$following" mode="url" />
            </xsl:if>
        </xsl:if>
        <!-- could be empty here-->
    </xsl:variable>
    <xsl:value-of select="$url" /> <!-- no harm if empty -->
    <xsl:if test="$url=''">
        <!-- Try going up and then sideways                           -->
        <!-- parent always exists, since <mathbook> is non-structural -->
        <xsl:variable name="parent" select="parent::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$parent" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <!-- Up a level, so try looking sideways again -->
            <xsl:apply-templates select="$parent" mode="next-sideways-url" />
        </xsl:if>
        <!-- otherwise we are off the top and quit with an empty url -->
    </xsl:if>
</xsl:template>

<!-- Look sideways to the left                                  -->
<!-- If present, move there and descend right branches          -->
<!-- If nothing there, move up once                             -->
<!-- <mathbook> is not structural, so halt if we go up to there -->
<xsl:template match="*" mode="previous-linear-url">
    <xsl:variable name="url">
        <xsl:if test="preceding-sibling::*">
            <xsl:variable name="preceding" select="preceding-sibling::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$preceding" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <!-- A normal sibling precedin, result is just a sentinel-->
                <xsl:apply-templates select="$preceding" mode="url" />
            </xsl:if>
        </xsl:if>
        <!-- could be empty here -->
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$url=''">
            <!-- Go up to parent and get the URL there (not recursive)    -->
            <!-- parent always exists, since <mathbook> is non-structural -->
            <xsl:variable name="parent" select="parent::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$parent" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <xsl:apply-templates select="$parent" mode="url" />
            </xsl:if>
            <!-- otherwise we are off the top and quit with an empty url -->
        </xsl:when>
        <xsl:otherwise>
            <!-- found a preceding sibling, so descend right branches to a leaf -->
            <xsl:apply-templates select="preceding-sibling::*[1]" mode="previous-descent-url"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Descend recursively through summary pages -->
<!-- to a leaf (content) and get URL           -->
<xsl:template match="*" mode="previous-descent-url" >
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='false'">
            <xsl:apply-templates select="." mode="url" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="last-structural-child" select="*[&STRUCTURAL-FILTER;][last()]" />
            <xsl:apply-templates select="$last-structural-child" mode="previous-descent-url" />
            <!-- remainder is a basic check, could be removed -->
            <xsl:variable name="structural">
                <xsl:apply-templates select="$last-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>MBX:ERROR: descending into last node of an intermediate page (<xsl:value-of select="local-name($last-structural-child)" />) that is non-structural</xsl:message>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!--                     -->
<!-- Navigation Sections -->
<!--                     -->

<!-- Button code, <a href=""> when active   -->
<!-- <span> with "disabled" class otherwise -->
<xsl:template match="*" mode="previous-button">
    <xsl:param name="id-label" select="''" />
    <xsl:variable name="previous-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="previous-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="previous-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$previous-url!=''">
            <xsl:element name="a">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">previous-button toolbar-item button</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$previous-url" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'previous'" />
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:attribute name="alt">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'previous'" />
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'previous-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">previous-button button toolbar-item disabled</xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'previous-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We assume 0 or 1 "index-part" present -->
<xsl:template match="*" mode="index-button">
    <xsl:variable name="indices" select="$document-root//index-part | $document-root//index[index-list]" />
    <xsl:if test="$indices">
        <xsl:variable name="url">
            <xsl:apply-templates select="$indices[1]" mode="url" />
        </xsl:variable>
        <xsl:element name="a">
            <xsl:attribute name="class">
                <xsl:text>index-button toolbar-item button</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="href">
                <xsl:value-of select="$url" />
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'index-part'" />
                </xsl:call-template>
            </xsl:attribute>
            <xsl:attribute name="alt">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'index-part'" />
                </xsl:call-template>
            </xsl:attribute>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'index-part'" />
            </xsl:call-template>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- The "jump to" navigation on a page with the index -->
<xsl:template match="*" mode="index-jump-nav">
    <span class="mininav">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'jump-to'" />
        </xsl:call-template>
    </span>
    <span class="indexnav">
    <a href="#indexletter-a">A </a>
    <a href="#indexletter-b">B </a>
    <a href="#indexletter-c">C </a>
    <a href="#indexletter-d">D </a>
    <a href="#indexletter-e">E </a>
    <a href="#indexletter-f">F </a>
    <a href="#indexletter-g">G </a>
    <a href="#indexletter-h">H </a>
    <a href="#indexletter-i">I </a>
    <a href="#indexletter-j">J </a>
    <a href="#indexletter-k">K </a>
    <a href="#indexletter-l">L </a>
    <a href="#indexletter-m">M </a>
    <br />
    <a href="#indexletter-n">N </a>
    <a href="#indexletter-o">O </a>
    <a href="#indexletter-p">P </a>
    <a href="#indexletter-q">Q </a>
    <a href="#indexletter-r">R </a>
    <a href="#indexletter-s">S </a>
    <a href="#indexletter-t">T </a>
    <a href="#indexletter-u">U </a>
    <a href="#indexletter-v">V </a>
    <a href="#indexletter-w">W </a>
    <a href="#indexletter-x">X </a>
    <a href="#indexletter-y">Y </a>
    <a href="#indexletter-z">Z </a>
    </span>
</xsl:template>

<xsl:template match="*" mode="next-button">
    <xsl:param name="id-label" select="''" />
    <xsl:variable name="next-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="next-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="next-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$next-url!=''">
            <xsl:element name="a">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">next-button button toolbar-item</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$next-url" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'next'" />
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:attribute name="alt">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'next'" />
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'next-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">next-button button toolbar-item disabled</xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'next-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="up-button">
    <xsl:param name="id-label" select="''" />
    <!-- up URL is identical for linear, tree logic -->
    <xsl:variable name="up-url">
        <xsl:apply-templates select="." mode="up-url" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$up-url!=''">
            <xsl:element name="a">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">up-button button toolbar-item</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$up-url" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'up'" />
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:attribute name="alt">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'up'" />
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'up-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">up-button button disabled toolbar-item</xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'up-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Compact Buttons -->
<!-- These get smashed consecutively into a single "tool-bar" -->
<xsl:template match="*" mode="compact-buttons">
    <!-- URL formation, maybe this could be consolidated with above versions -->
    <xsl:variable name="previous-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="previous-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="previous-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="up-url">
        <xsl:apply-templates select="." mode="up-url" />
    </xsl:variable>
    <xsl:variable name="next-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="next-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="next-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <!-- toolbar-item when aligned right, get placed right: first in, first right -->
    <!-- so they apparently seem in the reversed order here and in HTML output    -->
    <!-- Empty URL, then no button                                                -->
    <xsl:if test="not($next-url = '')">
        <div class="toolbar-item">
            <a href="{$next-url}">
                <svg height="50" width="60" viewBox="0 50 110 100" xmlns="https://www.w3.org/2000/svg" >
                    <polygon points="110,100 75,75 0,75 0,125 75,125 " style="fill:darkred;stroke:maroon;stroke-width:1" />
                    <text x="13" y="108" fill="blanchedalmond" font-size="32">next</text>
                </svg>
            </a>
        </div>
    </xsl:if>
    <xsl:if test="not($up-url = '')">
        <div class="toolbar-item">
            <a href="{$up-url}">
                <svg height="50" width="60" viewBox="0 50 80 100" xmlns="https://www.w3.org/2000/svg" >
                    <polygon points="75,75 37,65 0,75 0,125 75,125 " style="fill:blanchedalmond;stroke:burlywood;stroke-width:1" />
                    <text x="13" y="108" fill="maroon" font-size="32">up</text>
                </svg>
            </a>
        </div>
    </xsl:if>
    <xsl:if test="not($previous-url = '')">
        <div class="toolbar-item">
            <a href="{$previous-url}">
                <svg height="50" width="60" viewBox="-10 50 110 100" xmlns="https://www.w3.org/2000/svg" >
                    <polygon points="-10,100 25,75 100,75 100,125 25,125 " style="fill:blanchedalmond;stroke:burlywood;stroke-width:1" />
                    <text x="28" y="108" fill="maroon" font-size="32">prev</text>
                </svg>
            </a>
        </div>
    </xsl:if>
</xsl:template>

<!-- Primary Navigation Panels -->
<!-- ToC, Prev/Up/Next/Annotation buttons  -->
<!-- Also organized for small screen modes -->
<xsl:template match="*" mode="primary-navigation">
    <nav id="primary-navbar" class="navbar">
        <div class="container">
            <!-- Several buttons across the top -->
            <div class="navbar-top-buttons">
                <xsl:element name="button">
                    <xsl:attribute name="class">
                        <xsl:text>sidebar-left-toggle-button button active</xsl:text>
                    </xsl:attribute>
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'toc'" />
                    </xsl:call-template>
                </xsl:element>
                <!-- Prev/Up/Next buttons on top, according to options -->
                <xsl:choose>
                    <xsl:when test="$nav-style = 'full'">
                        <xsl:element name="div">
                            <xsl:attribute name="class">
                                <!-- 3 or 4 buttons, depending on Up Button choice -->
                                <xsl:choose>
                                    <xsl:when test="$nav-upbutton='yes'">
                                        <xsl:text>tree-nav toolbar toolbar-divisor-3</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="$nav-upbutton='no'">
                                        <xsl:text>tree-nav toolbar toolbar-divisor-2</xsl:text>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:attribute>
                            <!-- A page either has an/the index as    -->
                            <!-- a child, and gets the "jump to" bar, -->
                            <!-- or it deserves an index button       -->
                            <xsl:choose>
                                <xsl:when test="index-list">
                                    <xsl:apply-templates select="." mode="index-jump-nav" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="." mode="index-button" />
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Span to encase Prev/Up/Next buttons and float right    -->
                            <!-- Each button gets an id for keypress recognition/action -->
                            <xsl:element name="span">
                                <xsl:attribute name="class">
                                    <xsl:text>threebuttons</xsl:text>
                                </xsl:attribute>
                                <xsl:apply-templates select="." mode="previous-button">
                                    <xsl:with-param name="id-label" select="'previousbutton'" />
                                </xsl:apply-templates>
                                <xsl:if test="$nav-upbutton='yes'">
                                    <xsl:apply-templates select="." mode="up-button">
                                        <xsl:with-param name="id-label" select="'upbutton'" />
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:apply-templates select="." mode="next-button">
                                    <xsl:with-param name="id-label" select="'nextbutton'" />
                                </xsl:apply-templates>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$nav-style = 'compact'">
                        <div class="toolbar toolbar-align-right">
                            <xsl:apply-templates select="." mode="compact-buttons" />
                        </div>
                    </xsl:when>
                </xsl:choose>
                <!-- right sidebar, not used currently -->
                <button class="sidebar-right-toggle-button button active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'annotations'" />
                    </xsl:call-template>
                </button>
            </div>
            <!-- Bottom buttons, for mobile UI -->
            <xsl:element name="div">
                <xsl:attribute name="class">
                    <!-- 3 or 4 buttons, depending on Up Button choice -->
                    <xsl:choose>
                        <xsl:when test="$nav-upbutton='yes'">
                            <xsl:text>navbar-bottom-buttons toolbar toolbar-divisor-4</xsl:text>
                        </xsl:when>
                        <xsl:when test="$nav-upbutton='no'">
                            <xsl:text>navbar-bottom-buttons toolbar toolbar-divisor-3</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
                <!-- "contents" button is uniform across logic -->
                <button class="sidebar-left-toggle-button button toolbar-item active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'toc'" />
                    </xsl:call-template>
                </button>
                <!-- Prev/Up/Next buttons on top, according to options -->
                <!-- in order, for mobile interface on bottom          -->
                <!-- We do not pass an $id-label right now             -->
                <xsl:apply-templates select="." mode="previous-button" />
                <xsl:if test="$nav-upbutton='yes'">
                    <xsl:apply-templates select="." mode="up-button" />
                </xsl:if>
                <xsl:apply-templates select="." mode="next-button" />
                <!-- unused, increment the toolbar-divisor-4/5 above -->
                <!--
                <button class="sidebar-right-toggle-button button toolbar-item active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'annotations'" />
                    </xsl:call-template>
                </button>
                -->
             </xsl:element>
        </div>
    </nav>
</xsl:template>

<!-- Sidebars -->
<!-- Two HTML aside's for ToC (left), Annotations (right)       -->
<!-- Need to pass node down into "toc-items", which is per-page -->
<xsl:template match="*" mode="sidebars">
    <aside id="sidebar-left" class="sidebar">
        <div class="sidebar-content">
            <nav id="toc">
                 <xsl:apply-templates select="." mode="toc-items" />
            </nav>
            <div class="extras">
                <nav>
                    <xsl:if test="$docinfo/feedback">
                        <xsl:call-template name="feedback-link" />
                    </xsl:if>
                    <xsl:call-template name="mathbook-link" />
                    <xsl:call-template name="powered-by-mathjax" />
                </nav>
            </div>
        </div>
    </aside>
    <!-- Content here appears in odd places if turned sidebar is turned off
        <aside id="sidebar-right" class="sidebar">
            <div class="sidebar-content">Mock right sidebar content</div>
        </aside> -->
</xsl:template>

<!-- Table of Contents Contents (Items) -->
<!-- Includes "active" class for enclosing outer node              -->
<!-- Node set equality and subset based on unions of subtrees, see -->
<!-- http://www.xml.com/cookbooks/xsltckbk/solution.csp?day=5      -->
<!-- Displayed text is simple titles                               -->
<!-- TODO: split out inner link formation, outer link formation? -->
<xsl:template match="*" mode="toc-items">
    <xsl:if test="$b-has-toc">
        <!-- Decrement level for books with parts, -->
        <!-- then 0 is exceptional - parts only    -->
        <xsl:variable name="adjusted-toc-level">
            <xsl:choose>
                <xsl:when test="not($parts = 'absent')">
                    <xsl:value-of select="$toc-level - 1" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$toc-level" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Subtree for page this sidebar will adorn -->
        <xsl:variable name="this-page-node" select="descendant-or-self::*" />
        <!-- If a book has parts, we include them as top level -->
        <!-- Note: these include front matter, back matter     -->
        <xsl:for-each select="$root/book/*|$root/book/part/*|$root/article/*">
            <xsl:variable name="structural">
                <xsl:apply-templates select="." mode="is-structural" />
            </xsl:variable>
            <!-- Bypass chapters for compact ToC for book with parts -->
            <xsl:if test="$structural='true' and not(($adjusted-toc-level = 0) and self::chapter)">
                <!-- Subtree represented by this ToC item -->
                <xsl:variable name="outer-node" select="descendant-or-self::*" />
                <xsl:variable name="outer-url">
                    <xsl:apply-templates select="." mode="url"/>
               </xsl:variable>
               <!-- text of anchor's class, active if a match, otherwise plain -->
               <!-- Based on node-set union size                               -->
               <xsl:variable name="class">
                    <xsl:choose>
                        <xsl:when test="count($this-page-node|$outer-node) = count($outer-node)" >
                            <xsl:text>link active</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>link</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="outer-internal">
                    <xsl:apply-templates select="." mode="internal-id" />
                </xsl:variable>
                <!-- The link itself -->
                <h2 class="{$class}">
                    <xsl:element name="a">
                        <xsl:attribute name="href">
                            <xsl:value-of select="$outer-url" />
                        </xsl:attribute>
                        <xsl:attribute name="data-scroll">
                            <xsl:value-of select="$outer-internal" />
                        </xsl:attribute>
                        <xsl:variable name="num"><xsl:apply-templates select="." mode="number" /></xsl:variable>
                        <xsl:if test="$num!=''">
                            <span class="codenumber"><xsl:value-of select="$num" /></span>
                        </xsl:if>
                        <span>
                            <xsl:apply-templates select="." mode="title-attributes" />
                            <xsl:apply-templates select="." mode="title-simple" />
                        </span>
                    </xsl:element>
                </h2>
                <!-- We don't divide parts again, their  -->
                <!-- chapters will be in $sublist anyway -->
                <xsl:if test="not(self::part) and $adjusted-toc-level > 1">
                    <!-- a level 1 ToC entry may not have any structural      -->
                    <!-- descendants, so we build a possible sublist in a     -->
                    <!-- variable and do not use it if it ends up being empty -->
                    <xsl:variable name="sublist">
                        <xsl:for-each select="./*">
                            <xsl:variable name="inner-structural">
                                <xsl:apply-templates select="." mode="is-structural" />
                            </xsl:variable>
                            <xsl:if test="$inner-structural='true'">
                                <!-- Subtree represented by this ToC item -->
                                <xsl:variable name="inner-node" select="descendant-or-self::*" />
                                <xsl:variable name="inner-url">
                                    <xsl:apply-templates select="." mode="url" />
                                </xsl:variable>
                                <xsl:variable name="inner-internal">
                                    <xsl:apply-templates select="." mode="internal-id" />
                                </xsl:variable>
                                <li>
                                    <xsl:element name="a">
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="$inner-url" />
                                        </xsl:attribute>
                                        <xsl:attribute name="data-scroll">
                                            <xsl:value-of select="$inner-internal" />
                                        </xsl:attribute>
                                        <!-- Add if an "active" class if this is where we are -->
                                        <xsl:if test="count($this-page-node|$inner-node) = count($inner-node)">
                                            <xsl:attribute name="class">active</xsl:attribute>
                                        </xsl:if>
                                        <xsl:apply-templates select="." mode="title-simple" />
                                    </xsl:element>
                                </li>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>
                    <!-- not clear why this is the right test         -->
                    <!-- make an unordered list if there is a sublist -->
                    <xsl:if test="not($sublist='')">
                        <ul>
                            <xsl:copy-of select="$sublist" />
                        </ul>
                    </xsl:if>
                </xsl:if>  <!-- end $toc-level > 1 -->
            </xsl:if>  <!-- end structural, level 1 -->
        </xsl:for-each>
    </xsl:if>
</xsl:template>

<!-- Feedback Button goes at the bottom (in "extras") -->
<!-- Text from docinfo, or localized string           -->
<!-- Target URL from docinfo                          -->
<xsl:template name="feedback-link">
    <!-- Possibly an empty URL -->
    <a class="feedback-link" href="{$docinfo/feedback/url}" target="_blank">
        <xsl:choose>
            <xsl:when test="$docinfo/feedback/text">
                <xsl:apply-templates select="$docinfo/feedback/text" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'feedback'" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </a>
</xsl:template>

<!-- Branding in "extras", mostly hard-coded        -->
<!-- HTTPS for authors delivering from secure sites -->
<xsl:template name="mathbook-link">
    <a class="mathbook-link" href="https://mathbook.pugetsound.edu">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'authored'" />
        </xsl:call-template>
        <xsl:text> </xsl:text>
        <xsl:text>PreTeXt</xsl:text>
    </a>
</xsl:template>

<!-- MathJax Logo for bottom of left sidebar -->
<xsl:template name="powered-by-mathjax">
    <a href="https://www.mathjax.org">
        <img title="Powered by MathJax" src="https://www.mathjax.org/badge/badge.gif" border="0" alt="Powered by MathJax" />
    </a>
</xsl:template>

<!-- Tooltip Text -->
<!-- text for an HTML title attribute -->
<!-- TODO: be more careful about extraneous spaces -->
<!-- TODO: captions from figures, tables, sbs? -->
<xsl:template match="*" mode="tooltip-text">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-simple" />
</xsl:template>

<!-- MathJax header                                             -->
<!-- XML manages equation numbers                               -->
<!-- Config MathJax to make anchor names on equations           -->
<!--   these are just the contents of the \label on an equation -->
<!--   which we provide as the xml:id of the equation           -->
<!-- Note: we could set \label with something different         -->
<!-- extpfeil.js provides extensible arrows: \xmapsto, \xtofrom -->
<!--   \xtwoheadrightarrow, \xtwoheadleftarrow, \xlongequal     -->
<!--   equivalent to the LaTeX package of the same name         -->
<!-- Autobold extension is critical for captions (bold'ed) that -->
<!-- have mathematics in them (suggested by P. Krautzberger)    -->
<!-- "useLabelIDs" makes HTML @id "mjx-eqn-foo" from \label{}   -->
<xsl:template name="mathjax">
    <!-- mathjax configuration -->
    <xsl:element name="script">
        <xsl:attribute name="type">
            <xsl:text>text/x-mathjax-config</xsl:text>
        </xsl:attribute>
        <xsl:text>&#xa;</xsl:text>
        <!-- // contrib directory for accessibility menu, moot after v2.6+ -->
        <!-- MathJax.Ajax.config.path["Contrib"] = "<some-url>";           -->
        <xsl:text>MathJax.Hub.Config({&#xa;</xsl:text>
        <xsl:text>    tex2jax: {&#xa;</xsl:text>
        <xsl:text>        inlineMath: [['\\(','\\)']],&#xa;</xsl:text>
        <xsl:text>    },&#xa;</xsl:text>
        <xsl:text>    TeX: {&#xa;</xsl:text>
        <xsl:text>        extensions: ["extpfeil.js", "autobold.js", "https://aimath.org/mathbook/mathjaxknowl.js", ],&#xa;</xsl:text>
        <xsl:text>        // scrolling to fragment identifiers is controlled by other Javascript&#xa;</xsl:text>
        <xsl:text>        positionToHash: false,&#xa;</xsl:text>
        <xsl:text>        equationNumbers: { autoNumber: "none", useLabelIds: true, },&#xa;</xsl:text>
        <xsl:text>        TagSide: "right",&#xa;</xsl:text>
        <xsl:text>        TagIndent: ".8em",&#xa;</xsl:text>
        <xsl:text>    },&#xa;</xsl:text>
        <!-- key needs quotes since it is not a valid identifier by itself-->
        <xsl:text>    // HTML-CSS output Jax to be dropped for MathJax 3.0&#xa;</xsl:text>
        <xsl:text>    "HTML-CSS": {&#xa;</xsl:text>
        <xsl:text>        scale: 88,&#xa;</xsl:text>
        <xsl:text>        mtextFontInherit: true,&#xa;</xsl:text>
        <xsl:text>    },&#xa;</xsl:text>
        <xsl:text>    CommonHTML: {&#xa;</xsl:text>
        <xsl:text>        scale: 88,&#xa;</xsl:text>
        <xsl:text>        mtextFontInherit: true,&#xa;</xsl:text>
        <xsl:text>    },&#xa;</xsl:text>
        <!-- optional presentation mode gets clickable, large math -->
        <xsl:if test="$b-html-presentation">
            <xsl:text>    menuSettings:{&#xa;</xsl:text>
            <xsl:text>      zoom:"Click",&#xa;</xsl:text>
            <xsl:text>      zscale:"300%"&#xa;</xsl:text>
            <xsl:text>    },&#xa;</xsl:text>
        </xsl:if>
        <!-- close of MathJax.Hub.Config -->
        <xsl:text>});&#xa;</xsl:text>
        <!-- optional beveled fraction support -->
        <xsl:if test="//m[contains(text(),'sfrac')] or //md[contains(text(),'sfrac')] or //me[contains(text(),'sfrac')] or //mrow[contains(text(),'sfrac')]">
            <xsl:text>/* support for the sfrac command in MathJax (Beveled fraction) */&#xa;</xsl:text>
            <xsl:text>/* see: https://github.com/mathjax/MathJax-docs/wiki/Beveled-fraction-like-sfrac,-nicefrac-bfrac */&#xa;</xsl:text>
            <xsl:text>MathJax.Hub.Register.StartupHook("TeX Jax Ready",function () {&#xa;</xsl:text>
            <xsl:text>  var MML = MathJax.ElementJax.mml,&#xa;</xsl:text>
            <xsl:text>      TEX = MathJax.InputJax.TeX;&#xa;</xsl:text>
            <xsl:text>  TEX.Definitions.macros.sfrac = "myBevelFraction";&#xa;</xsl:text>
            <xsl:text>  TEX.Parse.Augment({&#xa;</xsl:text>
            <xsl:text>    myBevelFraction: function (name) {&#xa;</xsl:text>
            <xsl:text>      var num = this.ParseArg(name),&#xa;</xsl:text>
            <xsl:text>          den = this.ParseArg(name);&#xa;</xsl:text>
            <xsl:text>      this.Push(MML.mfrac(num,den).With({bevelled: true}));&#xa;</xsl:text>
            <xsl:text>    }&#xa;</xsl:text>
            <xsl:text>  });&#xa;</xsl:text>
            <xsl:text>});&#xa;</xsl:text>
        </xsl:if>
    </xsl:element>
    <!-- mathjax javascript -->
    <xsl:element name="script">
        <xsl:attribute name="type">
            <xsl:text>text/javascript</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="src">
            <xsl:text>https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_CHTML-full</xsl:text>
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- jQuery, SageCell -->
<!-- jQuery used by sage, webwork, knowls, so load always  -->
<!--  * essential to use the version from sagemath.org *   -->
<!-- We never know if a Sage cell might be inside a knowl, -->
<!-- so we load the relevant JavaScript onto every page if -->
<!-- a cell occurs *anywhere* in the entire document       -->

<xsl:template name="jquery-sagecell">
    <script type="text/javascript" src="https://sagecell.sagemath.org/static/jquery.min.js"></script>
    <xsl:if test="$document-root//sage">
        <script type="text/javascript" src="https://sagecell.sagemath.org/embedded_sagecell.js"></script>
    </xsl:if>
</xsl:template>

<!--<xsl:template name="jquery-sagecell">
    <script type="text/javascript" src="https://sagecell.sagemath.org/static/jquery-1.5.min.js"></script>
    <xsl:if test="$document-root//sage">
        <script type="text/javascript" src="https://sagecell.sagemath.org/embedded_sagecell.js"></script>
    </xsl:if>
</xsl:template> -->


<!-- <xsl:template name="jquery-sagecell">
    <script type="text/javascript" src="https://sagecell.sagemath.org/static/jquery.min.js"></script>
    <xsl:if test="$document-root//sage">
        <script type="text/javascript" src="https://sagecell.sagemath.org/embedded_sagecell.js"></script>
    </xsl:if>
</xsl:template> -->


<!-- Sage Cell Setup -->
<!-- TODO: internationalize button labels, strings below -->
<!-- TODO: make an initialization cell which links with the sage-compute cells -->

<!-- A template for a generic makeSageCell script element -->
<!-- Parameters: language, evaluate-button text -->
<xsl:template name="makesagecell">
    <xsl:param name="language-attribute" />
    <xsl:param name="language-text" />
    <xsl:element name="script">
        <xsl:text>$(function () {&#xa;</xsl:text>
        <xsl:text>    // Make *any* div with class 'sagecell-</xsl:text>
            <xsl:value-of select="$language-attribute" />
        <xsl:text>' an executable Sage cell&#xa;</xsl:text>
        <xsl:text>    // Their results will be linked, only within language type&#xa;</xsl:text>
        <xsl:text>    sagecell.makeSagecell({inputLocation: 'div.sagecell-</xsl:text>
            <xsl:value-of select="$language-attribute" />
        <xsl:text>',&#xa;</xsl:text>
        <xsl:text>                           linked: true,&#xa;</xsl:text>
        <xsl:text>                           languages: ['</xsl:text>
            <xsl:value-of select="$language-attribute" />
        <xsl:text>'],&#xa;</xsl:text>
        <xsl:text>                           evalButtonText: '</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'evaluate'" />
            </xsl:call-template>
            <xsl:text> (</xsl:text>
            <xsl:value-of select="$language-text" />
            <xsl:text>)</xsl:text>
        <xsl:text>'});&#xa;</xsl:text>
        <xsl:text>});&#xa;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- template for a "display only" version -->
<xsl:template name="sagecell-display">
    <xsl:element name="script">
        <xsl:text>$(function () {&#xa;</xsl:text>
        <xsl:text>    // Make *any* div with class 'sage-display' a visible, uneditable Sage cell&#xa;</xsl:text>
        <xsl:text>    sagecell.makeSagecell({inputLocation: 'div.sage-display',&#xa;</xsl:text>
        <xsl:text>                           editor: 'codemirror-readonly',&#xa;</xsl:text>
        <xsl:text>                           hide: ['evalButton', 'editorToggle', 'language']});&#xa;</xsl:text>
        <xsl:text>});&#xa;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- All languages, linked only to similar   -->
<!-- Generic button, drop-down for languages -->
<xsl:template name="sagecell-practice">
    <xsl:element name="script">
        <xsl:text>$(function () {&#xa;</xsl:text>
        <xsl:text>    // Make *any* div with class 'sagecell-practice' an executable Sage cell&#xa;</xsl:text>
        <xsl:text>    // Their results will be linked, only within language type&#xa;</xsl:text>
        <xsl:text>    sagecell.makeSagecell({inputLocation: 'div.sagecell-practice',&#xa;</xsl:text>
        <xsl:text>                           linked: true,&#xa;</xsl:text>
        <xsl:text>                           languages: sagecell.allLanguages,&#xa;</xsl:text>
        <xsl:text>                           evalButtonText: '</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'evaluate'" />
            </xsl:call-template>
        <xsl:text>'});&#xa;</xsl:text>
        <xsl:text>});&#xa;</xsl:text>
    </xsl:element>
</xsl:template>


<!-- Make Sage Cell Server headers on a per-language basis -->
<!-- Examine the subtree of the page, which can still be   -->
<!-- excessive for summary pages, so room for improvement  -->
<xsl:template match="*" mode="sagecell">
    <!-- making a Sage version now very liberally, could be more precise -->
    <xsl:if test=".//sage">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">sage</xsl:with-param>
            <xsl:with-param name="language-text">Sage</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@type='display']">
        <xsl:call-template name="sagecell-display" />
    </xsl:if>

    <xsl:if test=".//sage[@type='practice']">
        <xsl:call-template name="sagecell-practice" />
    </xsl:if>

    <!-- 2016-06-13: sage, gap, gp, html, maxima, octave, python, r, and singular -->

    <xsl:if test=".//sage[@language='gap']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>gap</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">GAP</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='gp']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>gp</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">GP</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='html']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>html</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">HTML</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='maxima']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>maxima</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">Maxima</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='octave']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>octave</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">Octave</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='python']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>python</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">Python</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='r']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>r</xsl:text>
                <!-- <xsl:text></xsl:text> -->
            </xsl:with-param>
            <xsl:with-param name="language-text">R</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='singular']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>singular</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">Singular</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

</xsl:template>


<!-- Program Listings from Google -->
<!--   ?skin=sunburst  on end of src URL gives black terminal look -->
<xsl:template name="goggle-code-prettifier">
    <script src="https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js"></script>
</xsl:template>

<!-- JS setup for a Google Custom Search Engine box -->
<!-- Empty if not enabled via presence of cx number -->
<xsl:template name="google-search-box-js">
    <xsl:if test="$b-google-cse">
        <xsl:element name="script">
            <xsl:text>(function() {&#xa;</xsl:text>
            <xsl:text>  var cx = '</xsl:text>
            <xsl:value-of select="$docinfo/search/google/cx" />
            <xsl:text>';&#xa;</xsl:text>
            <xsl:text>  var gcse = document.createElement('script');&#xa;</xsl:text>
            <xsl:text>  gcse.type = 'text/javascript';&#xa;</xsl:text>
            <xsl:text>  gcse.async = true;&#xa;</xsl:text>
            <xsl:text>  gcse.src = 'https://cse.google.com/cse.js?cx=' + cx;&#xa;</xsl:text>
            <xsl:text>  var s = document.getElementsByTagName('script')[0];&#xa;</xsl:text>
            <xsl:text>  s.parentNode.insertBefore(gcse, s);&#xa;</xsl:text>
            <xsl:text>})();&#xa;</xsl:text>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- Div for Google Search -->
<!-- https://developers.google.com/custom-search/docs/element -->
<!-- Empty if not enabled via presence of cx number           -->
<xsl:template name="google-search-box">
    <xsl:if test="$b-google-cse">
        <div class="searchwrapper">
            <div class="gcse-search" />
        </div>
    </xsl:if>
</xsl:template>

<!-- Knowl header -->
<xsl:template name="knowl">
<script type="text/javascript" src="https://aimath.org/knowl.js"></script>
</xsl:template>

<!-- Mathbook Javascript header -->
<xsl:template name="mathbook-js">
    <!-- condition first on toc present? -->
    <script src="{$html.js.server}/mathbook/js/lib/jquery.sticky.js" ></script>
    <script src="{$html.js.server}/mathbook/js/lib/jquery.espy.min.js"></script>
    <script src="{$html.js.server}/mathbook/js/Mathbook.js"></script>
</xsl:template>

<!-- Font header -->
<!-- Google Fonts -->
<!-- Text: Open Sans by default (was: Istok Web font, regular and italic (400), bold (700)) -->
<!-- Code: Inconsolata, regular (400), bold (700) (was: Source Code Pro regular (400))      -->
<!-- (SourceCodePro being removed) -->
<xsl:template name="fonts">
    <link href='https://fonts.googleapis.com/css?family=Open+Sans:400,400italic,600,600italic' rel='stylesheet' type='text/css' />
    <link href='https://fonts.googleapis.com/css?family=Inconsolata:400,700&amp;subset=latin,latin-ext' rel='stylesheet' type='text/css' />
</xsl:template>

<!-- Hypothes.is Annotations -->
<!-- Configurations are the defaults as of 2016-11-04   -->
<!-- async="" is a guessed-hack, docs ahve no attribute -->
<xsl:template name="hypothesis-annotation">
    <xsl:if test="$b-activate-hypothesis">
        <script type="application/json" class="js-hypothesis-config">
        <xsl:text>{&#xa;</xsl:text>
        <xsl:text>    "openLoginForm": false;</xsl:text>
        <xsl:text>    "openSidebar": false;</xsl:text>
        <xsl:text>    "showHighlights": true;</xsl:text>
        <xsl:text>}</xsl:text>
        </script>
        <script src="https://hypothes.is/embed.js" async=""></script>
    </xsl:if>
</xsl:template>

<!-- GeoGebra -->
<!-- The JS necessary to load the "App", which can -->
<!-- then be loaded with base64 or XML versions    -->
<xsl:template name="geogebra">
    <xsl:if test="$b-has-geogebra">
        <script type="text/javascript" src="https://cdn.geogebra.org/apps/deployggb.js"></script>
    </xsl:if>
</xsl:template>

<!-- JSXGraph -->
<xsl:template name="jsxgraph">
    <xsl:if test="$b-has-jsxgraph">
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/0.99.6/jsxgraph.css" />
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/0.99.6/jsxgraphcore.js"></script>
    </xsl:if>
</xsl:template>

<!-- CSS header -->
<xsl:template name="css">
    <link href="{$html.css.server}/mathbook/stylesheets/{$html.css.file}" rel="stylesheet" type="text/css" />
    <link href="https://aimath.org/mathbook/mathbook-add-on.css" rel="stylesheet" type="text/css" />
    <xsl:call-template name="external-css">
        <xsl:with-param name="css-list" select="normalize-space($html.css.extra)" />
    </xsl:call-template>
</xsl:template>

<!-- Recursively unpack the list of URLs for extra CSS                       -->
<!-- Presumes normalized, so no leading/trailing space and single separators -->
<!-- If unspecified, default is empty string and nothing at all happens      -->
<xsl:template name="external-css">
    <xsl:param name="css-list" />
    <xsl:variable name="delimiter" select="' '" />
    <xsl:choose>
        <xsl:when test="$css-list = ''">
            <!-- bail out: done, halt recursion, take no action -->
        </xsl:when>
        <!--
        Unnormalized:
        strip leading space, or leftover from multiple spaces, or trailing
        <xsl:when test="substring($css-list, 1, 1) = ' '">
            <xsl:call-template name="external-css">
                <xsl:with-param name="css-list" select="substring($css-list, 2)" />
            </xsl:call-template>
        </xsl:when>
        -->
        <xsl:when test="contains($css-list, $delimiter)">
            <!-- Form the css inclusion element from front, recurse -->
            <!-- Presumes a single space as separator               -->
            <xsl:element name="link">
                <xsl:attribute name="href">
                    <xsl:value-of select="substring-before($css-list, $delimiter)" />
                </xsl:attribute>
                <xsl:attribute name="rel">stylesheet</xsl:attribute>
                <xsl:attribute name="type">text/css</xsl:attribute>
            </xsl:element>
            <xsl:call-template name="external-css">
                <xsl:with-param name="css-list" select="substring-after($css-list, $delimiter)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <!-- form the css inclusion element from last/only URL -->
            <xsl:element name="link">
                <xsl:attribute name="href">
                    <xsl:value-of select="$css-list" />
                </xsl:attribute>
                <xsl:attribute name="rel">stylesheet</xsl:attribute>
                <xsl:attribute name="type">text/css</xsl:attribute>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############## -->
<!-- LaTeX Preamble -->
<!-- ############## -->

<!-- First a variable to massage the author-supplied -->
<!-- package list to the form MathJax expects        -->
<xsl:variable name="latex-packages-mathjax">
    <xsl:value-of select="str:replace($latex-packages, '\usepackage{', '\require{')" />
</xsl:variable>


<!-- MathJax expects math wrapping, and we place in   -->
<!-- a hidden div so not visible and take up no space -->
<!-- We could rename this properly, since we are      -->
<!-- sneaking in packages, which load first, in       -->
<!-- case authors want to build on these macros       -->
<xsl:template name="latex-macros">
    <div class="hidden-content">
    <xsl:call-template name="begin-inline-math" />
    <xsl:value-of select="$latex-packages-mathjax" />
    <xsl:value-of select="$latex-macros" />
    <xsl:call-template name="end-inline-math" />
    </div>
</xsl:template>

<!-- Brand Logo -->
<!-- Place image in masthead -->
<!-- TODO: separate url and image, now need both or neither -->
<!-- should allow specifying just URL and get default image -->
<xsl:template name="brand-logo">
    <xsl:choose>
        <xsl:when test="$docinfo/brandlogo">
            <a id="logo-link" href="{$docinfo/brandlogo/@url}" target="_blank" >
                <img src="{$docinfo/brandlogo/@source}" alt="Logo image"/>
            </a>
        </xsl:when>
        <xsl:otherwise>
            <a id="logo-link" href="" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Analytics Footers -->

<!-- Google Analytics                     -->
<!-- "Classic", not compared to Universal -->
<xsl:template match="google">
<xsl:comment>Start: Google code</xsl:comment>
<script type="text/javascript">
var _gaq = _gaq || [];
_gaq.push(['_setAccount', '<xsl:value-of select="./tracking" />']);
_gaq.push(['_trackPageview']);

(function() {
var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'https://www') + '.google-analytics.com/ga.js';
var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();
</script>
<xsl:comment>End: Google code</xsl:comment>
</xsl:template>

<xsl:template match="google-universal">
    <xsl:comment>Start: Google Universal code</xsl:comment>
    <script>
        <xsl:text>(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){&#xa;</xsl:text>
        <xsl:text>(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),&#xa;</xsl:text>
        <xsl:text>m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)&#xa;</xsl:text>
        <xsl:text>})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');&#xa;</xsl:text>
        <xsl:text>ga('create', '</xsl:text>
            <xsl:value-of select="@tracking" />
        <xsl:text>', 'auto');&#xa;</xsl:text>
        <xsl:text>ga('send', 'pageview');&#xa;</xsl:text>
    </script>
    <xsl:comment>End: Google Universal code</xsl:comment>
</xsl:template>

<!-- StatCounter                                -->
<!-- Set sc_invisible to 1                      -->
<!-- In noscript URL, final 1 is an edit from 0 -->
<xsl:template match="statcounter">
<xsl:comment>Start: StatCounter code</xsl:comment>
<script type="text/javascript">
var sc_project=<xsl:value-of select="project" />;
var sc_invisible=1;
var sc_security="<xsl:value-of select="security" />";
var scJsHost = (("https:" == document.location.protocol) ? "https://secure." : "https://www.");
<![CDATA[document.write("<sc"+"ript type='text/javascript' src='" + scJsHost+ "statcounter.com/counter/counter.js'></"+"script>");]]>
</script>
<xsl:variable name="noscript_url">
    <xsl:text>https://c.statcounter.com/</xsl:text>
    <xsl:value-of select="project" />
    <xsl:text>/0/</xsl:text>
    <xsl:value-of select="security" />
    <xsl:text>/1/</xsl:text>
</xsl:variable>
<noscript>
<div class="statcounter">
<a title="web analytics" href="https://statcounter.com/" target="_blank">
<img class="statcounter" src="{$noscript_url}" alt="web analytics" /></a>
</div>
</noscript>
<xsl:comment>End: StatCounter code</xsl:comment>
</xsl:template>

<!-- ############# -->
<!-- Serialization -->
<!-- ############# -->

<!-- Convert a node (perhaps the root of a node-set       -->
<!-- built from an RTF) into its string representation.   -->
<!-- Used initially for conversion of PreTeXt markup to   -->
<!-- the JSON format of a Jupyter notebook.  Identical to -->
<!-- https://stackoverflow.com/questions/6696382 at       -->
<!-- comment https://stackoverflow.com/a/15783514         -->

<xsl:template match="*" mode="serialize">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:apply-templates select="@*" mode="serialize" />
    <xsl:choose>
        <xsl:when test="node()">
            <xsl:text>&gt;</xsl:text>
            <xsl:apply-templates mode="serialize" />
            <xsl:text>&lt;/</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>&gt;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text> /&gt;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="@*" mode="serialize">
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template match="text()" mode="serialize">
    <xsl:value-of select="."/>
</xsl:template>

<!-- Miscellaneous -->

<!-- Inline warnings go into text, no matter what -->
<!-- They are colored for an author's report -->
<xsl:template name="inline-warning">
    <xsl:param name="warning" />
    <xsl:element name="span">
        <!-- Color for author tools version -->
        <xsl:if test="$author-tools='yes'" >
            <xsl:attribute name="style">color:red</xsl:attribute>
        </xsl:if>
        <xsl:text>&lt;&lt;</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>&gt;&gt;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Marginal notes are only for author's report                     -->
<!-- and are always colored red.  Marginpar's from                   -->
<!-- http://www.sitepoint.com/web-foundations/floating-clearing-css/ -->
<xsl:template name="margin-warning">
    <xsl:param name="warning" />
    <xsl:if test="$author-tools='yes'" >
        <xsl:element name="span">
            <xsl:attribute name="style">color:red;float:right;width:20em;margin-right:-25em;</xsl:attribute>
            <xsl:value-of select="$warning" />
        </xsl:element>
    </xsl:if>
</xsl:template>


<!-- Uninteresting Code, aka the Bad Bank                    -->
<!-- Deprecated, unmaintained, etc, parked here out of sight -->

<!-- Legacy code: not maintained                  -->
<!-- Banish to common file when removed, as error -->
<!-- 2014/06/25: implemented with xref as link, need to duplicate knowl functionality -->
<!-- 2014/08/14: remove knowl-link-factory at the same time -->
<xsl:template match="cite[@ref]">
    <xsl:message>MBX:WARNING: &lt;cite ref="<xsl:value-of select="@ref" />&gt; is deprecated, convert to &lt;xref ref="<xsl:value-of select="@ref" />"&gt;</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:call-template name="knowl-link-factory">
        <xsl:with-param name="css-class">cite</xsl:with-param>
        <xsl:with-param name="identifier">
            <xsl:apply-templates select="id(@ref)" mode="internal-id" />
        </xsl:with-param>
        <xsl:with-param name="content">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="id(@ref)" mode="number" />
            <xsl:if test="@detail">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="@detail" />
            </xsl:if>
            <xsl:text>]</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Only used by <cite> above, so can be removed at same time -->
<xsl:template name="knowl-link-factory">
    <xsl:param name="css-class"/>
    <xsl:param name="identifier"/>
    <xsl:param name="content"/>
    <xsl:element name ="a">
        <xsl:attribute name="class">
            <xsl:value-of select="$css-class" />
        </xsl:attribute>
        <xsl:attribute name="knowl">
            <xsl:text>./knowl/</xsl:text>
            <xsl:value-of select="$identifier" />
            <xsl:text>.html</xsl:text>
        </xsl:attribute>
        <xsl:value-of select="$content" />
    </xsl:element>
</xsl:template>

<!-- Include last, since template priorities will   -->
<!-- tie even with more specific webwork// versions -->
<!-- Routines specific to converting a "webwork"    -->
<!-- element into a problem in the PGML language    -->
<xsl:include href="./mathbook-webwork-pg.xsl" />

</xsl:stylesheet>
