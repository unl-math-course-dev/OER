<?xml version="1.0" encoding="UTF-8"?>


<!-- This file is part of the book                       -->
<!--                                                     -->
<!--   Coordinated PreCalculus                -->
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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

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
        <xsl:text>%% (precalc-latex.xsl: capped at half the line, may shrink by 3/4)&#xa;</xsl:text>
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

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Images given by web address: link instead in the PDF -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- Two images (SystemsOfLinearEquations, PolynomialsAndFactoring) -->
    <!-- use an https:// address as @source.  HTML loads them from that -->
    <!-- site, but LaTeX cannot, and the build stops.  In the PDF, show -->
    <!-- a framed note with the image description and a link instead.   -->
    <xsl:template match="image[starts-with(@source, 'http://') or starts-with(@source, 'https://')]" mode="image-inclusion" priority="10">
        <xsl:text>\fbox{\parbox{\dimexpr\linewidth-2\fboxsep-2\fboxrule}{\centering\small </xsl:text>
        <xsl:text>Image: </xsl:text>
        <xsl:apply-templates select="description/p[1]/node()"/>
        <xsl:text>\\ \href{</xsl:text>
        <xsl:value-of select="@source"/>
        <xsl:text>}{(view online)}}}&#xa;</xsl:text>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Static WeBWorK: "align" environments inside math       -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- A few UNL library problems (for example piecewiseJustHint.pg)  -->
    <!-- put \begin{align*} inside inline math.  MathJax allows it, but -->
    <!-- LaTeX only allows align* as a display of its own, so the PDF   -->
    <!-- build stops.  "aligned" means the same thing and works inside  -->
    <!-- math, so swap it in.  Only touches math that came back from    -->
    <!-- the WeBWorK server.                                            -->
    <xsl:template match="m[contains(., '\begin{align')]|me[contains(., '\begin{align')]" mode="webwork-rep-to-static">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="webwork-rep-to-static"/>
            <xsl:call-template name="precalc-replace-all">
                <xsl:with-param name="text">
                    <xsl:call-template name="precalc-replace-all">
                        <xsl:with-param name="text">
                            <xsl:call-template name="precalc-replace-all">
                                <xsl:with-param name="text">
                                    <xsl:call-template name="precalc-replace-all">
                                        <xsl:with-param name="text" select="string(.)"/>
                                        <xsl:with-param name="old" select="'\begin{align*}'"/>
                                        <xsl:with-param name="new" select="'\begin{aligned}'"/>
                                    </xsl:call-template>
                                </xsl:with-param>
                                <xsl:with-param name="old" select="'\end{align*}'"/>
                                <xsl:with-param name="new" select="'\end{aligned}'"/>
                            </xsl:call-template>
                        </xsl:with-param>
                        <xsl:with-param name="old" select="'\begin{align}'"/>
                        <xsl:with-param name="new" select="'\begin{aligned}'"/>
                    </xsl:call-template>
                </xsl:with-param>
                <xsl:with-param name="old" select="'\end{align}'"/>
                <xsl:with-param name="new" select="'\end{aligned}'"/>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>

    <!-- Replace every occurrence of $old in $text with $new -->
    <xsl:template name="precalc-replace-all">
        <xsl:param name="text"/>
        <xsl:param name="old"/>
        <xsl:param name="new"/>
        <xsl:choose>
            <xsl:when test="contains($text, $old)">
                <xsl:value-of select="substring-before($text, $old)"/>
                <xsl:value-of select="$new"/>
                <xsl:call-template name="precalc-replace-all">
                    <xsl:with-param name="text" select="substring-after($text, $old)"/>
                    <xsl:with-param name="old" select="$old"/>
                    <xsl:with-param name="new" select="$new"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Static WeBWorK: "\(y)" typo that swallows text         -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- The hint of UNL-Problems/.../boxVolumeJustHint.pg writes "\(y)"  -->
    <!-- instead of "\(y\)", so the server returns one math element that  -->
    <!-- runs on into the next sentence:                                 -->
    <!--   <m>y). Once you ... part a) for \(y</m>                         -->
    <!-- LaTeX stops at the inner "\(".  Split it back into math, text,  -->
    <!-- math: <m>y</m>. Once you ... part a) for <m>y</m>.               -->
    <!-- Remove this once the problem itself is fixed.                    -->
    <xsl:template match="m[contains(., '\(') and contains(substring-before(., '\('), ')')]" mode="webwork-rep-to-static">
        <xsl:variable name="before" select="substring-before(., '\(')"/>
        <m><xsl:value-of select="substring-before($before, ')')"/></m>
        <xsl:value-of select="substring-after($before, ')')"/>
        <m><xsl:value-of select="substring-after(., '\(')"/></m>
    </xsl:template>

    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
    <!--  Static WeBWorK: bare LaTeX displays in text             -->
    <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

    <!-- About 26 UNL library problems (systems_of_linear_equations,     -->
    <!-- exponents, Forms_of_a_Line, ...) write \begin{cases}..., or     -->
    <!-- \begin{aligned}... in their text with no math delimiters.  Live -->
    <!-- WeBWorK renders them, but the static (PDF) version has them as  -->
    <!-- plain text, so the PDF printed the LaTeX code.  Turn each bare  -->
    <!-- \begin{X}...\end{X} in text into a display (md), using aligned  -->
    <!-- for align/align*.  The real fix is in the .pg files.            -->
    <xsl:template match="text()[contains(., '\begin{') and not(ancestor::m or ancestor::me or ancestor::md or ancestor::mrow)]" mode="webwork-rep-to-static">
        <xsl:call-template name="precalc-bare-displays">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="precalc-bare-displays">
        <xsl:param name="text"/>
        <xsl:variable name="rest" select="substring-after($text, '\begin{')"/>
        <xsl:variable name="env" select="substring-before($rest, '}')"/>
        <xsl:variable name="end" select="concat('\end{', $env, '}')"/>
        <xsl:choose>
            <xsl:when test="contains($text, '\begin{') and not($env = '') and contains($rest, $end)">
                <xsl:value-of select="substring-before($text, '\begin{')"/>
                <xsl:variable name="newenv">
                    <xsl:choose>
                        <xsl:when test="$env = 'align' or $env = 'align*'">aligned</xsl:when>
                        <xsl:otherwise><xsl:value-of select="$env"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <md>
                    <xsl:text>\begin{</xsl:text>
                    <xsl:value-of select="$newenv"/>
                    <xsl:text>}</xsl:text>
                    <xsl:value-of select="substring-before(substring-after($rest, '}'), $end)"/>
                    <xsl:text>\end{</xsl:text>
                    <xsl:value-of select="$newenv"/>
                    <xsl:text>}</xsl:text>
                </md>
                <xsl:call-template name="precalc-bare-displays">
                    <xsl:with-param name="text" select="substring-after($rest, $end)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

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