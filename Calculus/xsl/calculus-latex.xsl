<?xml version="1.0" encoding="UTF-8"?>


<!-- This file is part of the book                       -->
<!--                                                     -->
<!--   Coordinated Differential Equations                -->
<!--                                                     -->
<!-- Copyright (C) 2024-2025 UNL Mathematics Department  -->
<!-- See the file COPYING for copying conditions.        -->

<!-- Parts of this file were adapted from the author guide at https://github.com/rbeezer/mathbook -->
<!-- and the analagous file at https://github.com/twjudson/aata -->
<!-- and Oscar Levin's DMOI file -->
<!-- Conveniences for classes of similar elements -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pi="http://pretextbook.org/2020/pretext/internal" exclude-result-prefixes="pi" version="1.0">

    <!-- assumes this has been copied to mathbook/user -->
    <xsl:import href="./core/pretext-latex.xsl" />

    <!-- %%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Header/Footer Styling   -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%% -->

    <xsl:template match="book" mode="titleps-style">
        <xsl:text>%% Page style configuration&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Plain pages should have the same font for page numbers&#xa;</xsl:text>
    <xsl:text>\renewpagestyle{plain}{%&#xa;</xsl:text>
    <xsl:text>\setfoot{}{\pagefont\thepage}{}%&#xa;</xsl:text>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:text>
      \renewpagestyle{headings}{%
        \sethead[{\scriptsize \thepage}~~~ \textsc{\scriptsize{\ifthechapter{\thechapter.~}{}\chaptertitle}}][][]
        {}{}{\textsc{\scriptsize{\ifthesection{\thesection.~\sectiontitle}{\chaptertitle}}} ~~~ {\scriptsize \thepage} }
      }
    </xsl:text>
    <xsl:text>\pagestyle{headings}&#xa;</xsl:text>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%  -->
    <!-- End Header/Footer Styling -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%  -->


    <!-- Include a style file at the end of the preamble: -->

    <xsl:param name="latex.preamble.late">
        <xsl:text>%This should load all the style information that ptx does not.&#xa;</xsl:text>
    <xsl:text>\input{external/latex/latex-preamble-styles}&#xa;</xsl:text>
        <!-- Long inline math cannot break, so TeX would rather run a    -->
        <!-- line into the margin than space it out a bit more.          -->
        <!-- \emergencystretch lets it use a looser line as a last       -->
        <!-- resort instead.                                             -->
        <xsl:text>\setlength{\emergencystretch}{2em}&#xa;</xsl:text>
    </xsl:param>


    <xsl:param name="latex.preamble.early"> </xsl:param>


    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Animated GIFs: use a PNG still in the PDF  -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- LaTeX cannot include a GIF, and the build stops if it tries.  -->
    <!-- For any image whose @source ends in ".gif", include the PNG  -->
    <!-- with the same name instead (for example, foo.gif -> foo.png). -->
    <!-- The PNG must exist in assets/ next to the GIF.  HTML still   -->
    <!-- shows the animated GIF.                                      -->
    <xsl:template match="image[@source][substring(@source, string-length(@source) - 3) = '.gif']" mode="image-inclusion" priority="10">
        <xsl:text>\includegraphics[width=\linewidth</xsl:text>
        <xsl:if test="@rotate">
            <xsl:text>,angle=</xsl:text>
            <xsl:value-of select="@rotate"/>
            <xsl:text>,origin=c</xsl:text>
        </xsl:if>
        <xsl:text>]{</xsl:text>
        <xsl:value-of select="$external-directory"/>
        <xsl:value-of select="substring(@source, 1, string-length(@source) - 4)"/>
        <xsl:text>.png}&#xa;</xsl:text>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Fill-in blanks: keep them inside the margin -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- Copy of core "fillin-text" (pretext-latex-common.xsl, 2.55.0) -->
    <!-- with two changes, marked CHANGED.  Static WeBWorK answer      -->
    <!-- blanks are sized by character count (0.5em each), so an       -->
    <!-- 80-character blank is wider than the page allows and runs -->
    <!-- into the margin.  Here a blank is at most half the line wide, -->
    <!-- and may shrink to a quarter of that when a line is crowded    -->
    <!-- (for example "(___, ___, ___)").  If core changes this        -->
    <!-- template, re-copy it and re-apply the changes.                -->
    <xsl:template name="fillin-text">
        <xsl:text>%% Used for fillin answer blank in text&#xa;</xsl:text>
        <xsl:text>%% Relies on calc package, loaded via tcolorbox&#xa;</xsl:text>
        <xsl:text>%% Argument is intended number of characters of blank&#xa;</xsl:text>
        <xsl:text>%% Length may compress for output to fit in one line&#xa;</xsl:text>
        <xsl:text>%% (calculus-latex.xsl: capped at half the line, may shrink by 3/4)&#xa;</xsl:text>
        <xsl:text>\newlength{\ptxfillinmaxwidth}&#xa;</xsl:text>
        <xsl:text>\newlength{\ptxfillincontract}&#xa;</xsl:text>
        <xsl:text>\newlength{\ptxcharmaxwidth}\setlength{\ptxcharmaxwidth}{0.5em}&#xa;</xsl:text>
        <xsl:text>\newlength{\ptxcharminwidth}\setlength{\ptxcharminwidth}{0.1em}&#xa;</xsl:text>
        <xsl:text>\newlength{\ptxfillinheight}&#xa;</xsl:text>
        <xsl:if test="$fillin-text-style = 'shade'">
            <xsl:text>\definecolor{fillintextshade}{gray}{0.9}</xsl:text>
        </xsl:if>
        <xsl:text>\newcommand{\ptxfillintext}[1]{%&#xa;</xsl:text>
        <xsl:text>\setlength{\ptxfillinmaxwidth}{#1\ptxcharmaxwidth}%&#xa;</xsl:text>
        <!-- CHANGED: cap the width at half the line -->
        <xsl:text>\ifdim\ptxfillinmaxwidth>0.5\linewidth\setlength{\ptxfillinmaxwidth}{0.5\linewidth}\fi%&#xa;</xsl:text>
        <!-- CHANGED: allow shrinking by 3/4 (core: #1\ptxcharminwidth) -->
        <xsl:text>\setlength{\ptxfillincontract}{0.75\ptxfillinmaxwidth}%&#xa;</xsl:text>
        <xsl:text>\setlength{\ptxfillinheight}{\baselineskip}\addtolength{\ptxfillinheight}{1.2pt}%&#xa;</xsl:text>
        <xsl:choose>
            <xsl:when test="$fillin-text-style = 'underline'">
                <xsl:text>\strut\nobreak\leaders\vbox{\hrule width 0.3pt height 0.3pt \vskip -1.2pt}\hskip 1\ptxfillinmaxwidth minus \ptxfillincontract\nobreak\strut%&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="$fillin-text-style = 'box'">
                <xsl:text>\rule[-1.2pt]{0.3pt}{\heightof{\strut}+1.8pt}\nobreak\hspace{-0.3pt}\nobreak\leaders\vbox{\hrule width 0.3pt height 0.3pt \vskip \ptxfillinheight \hrule width 0.3pt height 0.3pt \vskip -1.2pt}\hskip 1\ptxfillinmaxwidth minus \ptxfillincontract\nobreak\hspace{-0.3pt}\rule[-1.2pt]{0.3pt}{\heightof{\strut}+1.8pt}%&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="$fillin-text-style = 'shade'">
                <xsl:text>{\color{fillintextshade}\strut\nobreak\leaders\vbox{\hrule width 0.3pt height \ptxfillinheight \vskip -1.2pt}\hskip 1\ptxfillinmaxwidth minus \ptxfillincontract}%&#xa;</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Wide tables: shrink to fit the line         -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- Core (pretext-latex-common.xsl, 2.55.0) shrinks a too-wide      -->
    <!-- table only when it has @width or @margins.  Our tables are      -->
    <!-- natural width, and some run into the margin.  This             -->
    <!-- copies core's "natural width" case and adds the same            -->
    <!-- shrink-but-never-enlarge \resizebox core uses elsewhere.        -->
    <xsl:template match="tabular[not(ancestor::sidebyside)][not(@margins) and not(@width)]" priority="10">
        <xsl:apply-templates select="." mode="newpage"/>
        <xsl:choose>
            <xsl:when test="parent::table">
                <xsl:text>\centering%&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\begin{center}%&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>\resizebox{\ifdim\width > \linewidth\linewidth\else\width\fi}{!}{%&#xa;</xsl:text>
        <xsl:apply-templates select="." mode="tabular-inclusion"/>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:if test="not(parent::table)">
            <xsl:text>\end{center}%&#xa;</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Tables with paragraphs in cells             -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- When a table has a <p> in a cell but no col/@width, core gives   -->
    <!-- every column 20% of the line.  Tables like this (from PreCalculus,-->
    <!-- (two-column "Line 1 / Line 2" checks in Systems of Linear        -->
    <!-- Equations, interest tables, ...) then crush their math, which    -->
    <!-- crossed the cell borders and in one table overlapped the next    -->
    <!-- column.  For the PDF only (this runs in core's "repair" pass of  -->
    <!-- the LaTeX conversion), give such tables equal column widths that -->
    <!-- add up to about 94%.  Existing <col> settings are kept; HTML is   -->
    <!-- unchanged.                                                        -->
    <xsl:template match="tabular[row/cell/p][not(col/@width)]" mode="repair">
        <xsl:variable name="ncols">
            <xsl:for-each select="row">
                <xsl:sort select="count(cell)" data-type="number" order="descending"/>
                <xsl:if test="position() = 1">
                    <xsl:value-of select="count(cell)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="w" select="concat(floor(94 div $ncols), '%')"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="repair"/>
            <xsl:for-each select="col">
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="repair"/>
                    <xsl:attribute name="width"><xsl:value-of select="$w"/></xsl:attribute>
                </xsl:copy>
            </xsl:for-each>
            <xsl:call-template name="precalc-extra-cols">
                <xsl:with-param name="n" select="$ncols - count(col)"/>
                <xsl:with-param name="w" select="$w"/>
            </xsl:call-template>
            <xsl:apply-templates select="node()[not(self::col)]" mode="repair"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="precalc-extra-cols">
        <xsl:param name="n"/>
        <xsl:param name="w"/>
        <xsl:if test="$n &gt; 0">
            <col width="{$w}"/>
            <xsl:call-template name="precalc-extra-cols">
                <xsl:with-param name="n" select="$n - 1"/>
                <xsl:with-param name="w" select="$w"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Very tall images: cap the height            -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- Copy of core's image-inclusion for @source/@pi:generated images -->
    <!-- (pretext-latex-common.xsl, 2.55.0) with one change, marked      -->
    <!-- CHANGED.  A few graphs with no @width (fig-increasing-line,     -->
    <!-- fig-decreasing-line, fig-vertical-line-test3, ...) are set at    -->
    <!-- full width and come out over half a page tall, so they filled a  -->
    <!-- page or ran off its bottom.  Cap the height at 0.55\textheight,  -->
    <!-- keeping the aspect ratio and centering; ordinary images are not  -->
    <!-- affected.                                                       -->
    <xsl:template match="image[@source|@pi:generated]" mode="image-inclusion" priority="5">
        <xsl:variable name="extension">
            <xsl:call-template name="file-extension">
                <xsl:with-param name="filename">
                    <xsl:choose>
                        <xsl:when test="@pi:generated">
                            <xsl:value-of select="@pi:generated" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@source" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <!-- CHANGED: add height cap with keepaspectratio -->
        <xsl:text>\makebox[\linewidth]{\includegraphics[width=\linewidth,height=0.55\textheight,keepaspectratio</xsl:text>
        <xsl:if test="@rotate">
            <xsl:text>,angle=</xsl:text>
            <xsl:value-of select="@rotate"/>
            <xsl:text>,origin=c</xsl:text>
        </xsl:if>
        <xsl:text>]{</xsl:text>
        <xsl:choose>
            <xsl:when test="@pi:generated">
                <xsl:value-of select="$generated-directory"/>
                <xsl:value-of select="@pi:generated"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$extension = ''">
            <xsl:text>.pdf</xsl:text>
        </xsl:if>
        <xsl:text>}}&#xa;</xsl:text>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Images that open an exercise                -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- Core raises an image that is the first thing in an exercise by  -->
    <!-- 1.5\baselineskip, to sit level with a number/title placed in    -->
    <!-- the margin.  Our latex-preamble-styles.tex sets divisional      -->
    <!-- exercises with a run-in title on the first line instead, so the -->
    <!-- raised image covered the title ("Plotti..." for "Plotting Polar -->
    <!-- Points", "Writi..." in Generalized Sinusoidal Functions).  No   -->
    <!-- raise for those images.                                         -->
    <xsl:template match="image[parent::statement or parent::exercise][ancestor::exercises or ancestor::worksheet or ancestor::reading-questions]" mode="vertical-adjustment" priority="10"/>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Static WeBWorK: GIF images from the server              -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- A few WeBWorK problems serve their graphs as GIFs, which core   -->
    <!-- saves as generated-assets/webwork/images/*.gif and LaTeX cannot -->
    <!-- include, so the PDF build stopped.  Use a PNG with the same     -->
    <!-- name when there is one; otherwise print a short note instead of -->
    <!-- failing.  To get the graphs, after generating WeBWorK run (from -->
    <!-- the book folder):                                               -->
    <!--   for f in generated-assets/webwork/images/*.gif; do            -->
    <!--     magick "${f}[0]" "${f%.gif}.png"; done                      -->
    <xsl:template match="image[@pi:generated][substring(@pi:generated, string-length(@pi:generated) - 3) = '.gif']" mode="image-inclusion" priority="10">
        <xsl:variable name="png" select="concat($generated-directory, substring(@pi:generated, 1, string-length(@pi:generated) - 4), '.png')"/>
        <xsl:text>\IfFileExists{</xsl:text>
        <xsl:value-of select="$png"/>
        <xsl:text>}{\makebox[\linewidth]{\includegraphics[width=\linewidth,height=0.55\textheight,keepaspectratio]{</xsl:text>
        <xsl:value-of select="$png"/>
        <xsl:text>}}}{\fbox{\parbox{\dimexpr\linewidth-2\fboxsep-2\fboxrule}{\centering\small (Image: see the online version of this exercise.)}}}&#xa;</xsl:text>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Static WeBWorK: images lost from table cells           -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- Graph-choice problems (graphs_of_linear_equations/*, ...) come -->
    <!-- back with the last image cell as <image/><p/>.  Because of the -->
    <!-- empty p, LaTeX sets the cell as paragraph text and drops the   -->
    <!-- image ("Graph 4" with no graph).  Drop empty p in cells.       -->
    <xsl:template match="cell/p[not(node())]" mode="webwork-rep-to-static"/>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Static WeBWorK: table rows wrapped in paragraphs        -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- The static version of Rogawski 5.5.18 (water draining from a   -->
    <!-- tank, Numerical Integration exercises) comes back with each     -->
    <!-- <row> of its table wrapped in a <p>.  LaTeX then saw a table    -->
    <!-- with no rows and the PDF build stopped.  Unwrap them.           -->
    <xsl:template match="tabular/p" mode="webwork-rep-to-static">
        <xsl:apply-templates select="row" mode="webwork-rep-to-static"/>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Static WeBWorK: empty first choice in a drop-down       -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- A drop-down's blank "pick one" choice usually comes back as "?", -->
    <!-- which core removes.  Some problems (e.g. ez-7-2-WW5, equilibrium -->
    <!-- solutions) send it empty instead; an empty first \item in the     -->
    <!-- inline choice list is a LaTeX error ("Misplaced \item") that      -->
    <!-- stopped the PDF build.  Drop empty choices too.                   -->
    <xsl:template match="statement//var[@form]/li[not(normalize-space(.)) and not(*[not(self::p)]) and not(.//*[normalize-space(.)])]|statement//ul[@form]/li[not(normalize-space(.)) and not(*[not(self::p)]) and not(.//*[normalize-space(.)])]" mode="webwork-rep-to-static" priority="10"/>

    <!-- Override default frontmatter pages: -->

    <!-- Remove the "half-title" leading page (title only, at about -->
    <!-- a 1:2 split) and the ad card on its obverse.  Core renamed  -->
    <!-- this template from "half-title" to "half-title-ad-card"     -->
    <!-- and now produces both pages from it, so this one override   -->
    <!-- drops both.  (An "ad-card" override is no longer needed.)   -->
    <xsl:template match="book" mode="half-title-ad-card">
        <xsl:text>%% no half-title, no adcard&#xa;</xsl:text>
    </xsl:template>


    <!-- Import custom title page -->
    <!-- <xsl:template match="book" mode="title-page"> -->
    <!-- <xsl:text>%% begin: title page&#xa;</xsl:text> -->
    <!-- <xsl:text>%% my custom page.&#xa;</xsl:text> -->
    <!-- <xsl:text>\input{external/frontmatter/title-page}&#xa;</xsl:text> -->
    <!-- <xsl:text>%% end: title page&#xa;</xsl:text> -->
    <!-- </xsl:template> -->

    <!-- Import custom copyright page -->
    <!-- <xsl:template match="book" mode="copyright-page"> -->
    <!-- <xsl:text>%% begin: copyright-page&#xa;</xsl:text> -->
    <!-- <xsl:text>\input{external/frontmatter/copyright-page}&#xa;</xsl:text> -->
    <!-- <xsl:text>%% end:   copyright-page&#xa;</xsl:text> -->
    <!-- </xsl:template> -->

    <!-- Dedication style -->
    <!-- <xsl:template match="dedication/p|dedication/p[1]" priority="1"> -->
    <!-- <xsl:text>\begin{flushright}\large%&#xa;</xsl:text> -->
    <!-- <xsl:apply-templates /> -->
    <!-- <xsl:text>%&#xa;</xsl:text> -->
    <!-- <xsl:text>\end{flushright}&#xa;</xsl:text> -->
    <!-- </xsl:template> -->


</xsl:stylesheet>