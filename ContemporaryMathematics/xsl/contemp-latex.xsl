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
        <!-- A long word or URL that cannot be hyphenated used to stick   -->
        <!-- out into the margin; \emergencystretch lets it use a looser  -->
        <!-- line as a last resort.                                      -->
        <xsl:text>\setlength{\emergencystretch}{2em}&#xa;</xsl:text>
    </xsl:param>


    <xsl:param name="latex.preamble.early"> </xsl:param>


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
    <!-- every column 20% of the line, which crushes the cells (copied   -->
    <!-- from the PreCalculus stylesheet).  For the PDF only (this runs in core's "repair" pass of  -->
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
            <xsl:call-template name="contemp-extra-cols">
                <xsl:with-param name="n" select="$ncols - count(col)"/>
                <xsl:with-param name="w" select="$w"/>
            </xsl:call-template>
            <xsl:apply-templates select="node()[not(self::col)]" mode="repair"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="contemp-extra-cols">
        <xsl:param name="n"/>
        <xsl:param name="w"/>
        <xsl:if test="$n &gt; 0">
            <col width="{$w}"/>
            <xsl:call-template name="contemp-extra-cols">
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