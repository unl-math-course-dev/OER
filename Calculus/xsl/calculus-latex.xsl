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