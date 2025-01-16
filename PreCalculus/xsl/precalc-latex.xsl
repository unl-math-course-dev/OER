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
    </xsl:param>


    <xsl:param name="latex.preamble.early"> </xsl:param>


    <!-- Override default frontmatter pages: -->

    <!-- Remove "half-title" leading page with -->
    <!-- title only, at about 1:2 split    -->
    <xsl:template match="book" mode="half-title">
        <xsl:text>%% no half-title&#xa;</xsl:text>
    </xsl:template>

    <!-- Remove Ad card (may contain list of other books        -->
    <!-- Or may be overridden to make title page spread -->
    <!-- Obverse of half-title                          -->
    <xsl:template match="book" mode="ad-card">
        <xsl:text>%% No adcard&#xa;</xsl:text>
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