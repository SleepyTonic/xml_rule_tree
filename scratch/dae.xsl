<?xml version="1.0" standalone="no"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:exsl="http://exslt.org/common"
				xmlns:svg="http://www.w3.org/2000/svg"
				exclude-result-prefixes="exsl"
                version="1.0"><!--xmlns="http://www.w3.org/1999/xhtml"-->

<xsl:key name="seqdaerule" match="rule" use="@seqdaerule"/> 

<xsl:template match="/">
	
	<xsl:variable name="graphTree">
		<graph edgedefault="directed">
			<xsl:apply-templates select="dae/rules/rule" mode='nodelayout'/>
	   		<xsl:apply-templates select="dae/ruleitems/ruleitem" mode='nodelayout2'>
	   			 <xsl:sort select="@seqdaerule" data-type="text" order="ascending"/>
			</xsl:apply-templates>
	   	</graph>
	</xsl:variable>
	
	<!--
	<xsl:value-of select="exsl:node-set($graphTree)//graph"/>
	-->
	
	<!-- Turn XML nodes into SVG image -->
  <xsl:call-template name="layout2svg">
    <xsl:with-param name="graph" select="exsl:node-set($graphTree)"/>
  </xsl:call-template>
	
</xsl:template>

<!-- Convert layout to SVG -->
<xsl:template name="layout2svg">
  <xsl:param name="graph"/>
  <xsl:processing-instruction name="xml-stylesheet">type="text/css" href="default.css"</xsl:processing-instruction>
  	<html xmlns="http://www.w3.org/1999/xhtml">
  		<head>
  			<title>A title</title>
		</head>
	    <body>
			<svg:svg id="svg-image" width="1000" height="800" version="1.1"> <!-- viewBox="-400 -400 1000 1000" -->
		  	<svg:g transform="translate(0, 500) scale(1) rotate(0)" >
		      <!-- defs section for the arrow -->
			   <svg:defs>
		       <svg:marker id="arrow" refX="5" refY="5" markerUnits="userSpaceOnUse" markerWidth="10" markerHeight="10" orient="auto">
		         <svg:path fill="black" d="M0 0 10 5 0 10z"/>
		       </svg:marker>
		     </svg:defs>
		
		      <!-- ... -->
		      <!-- recurse 'node' elements of the graph to find graph root -->
			  <xsl:value-of select="$graph//graph/node"/>
		      <xsl:apply-templates select="$graph/graph/node"/>
			  </svg:g>
			  
		    </svg:svg>
		</body>
	</html>


</xsl:template>

<xsl:template match="ruleitem" mode='nodelayout2'>
	<xsl:apply-templates select="key('seqdaerule', callrule/@seqdaerule)" mode='nodelayout2'>
		
		<xsl:with-param name='source' select="@seqdaerule"  />
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="rule" mode="nodelayout2">
	<xsl:param name="source" select="null"/>
	<xsl:variable name="ruleId" select="@seqdaerule"/>
	<edge source="{$source}" target="{$ruleId}"/>
</xsl:template>

<xsl:template match="rule" mode="nodelayout">
	<xsl:variable name="ruleId" select="@seqdaerule"/>
 	<node id="{$ruleId}"><xsl:value-of select="./name"/></node>
</xsl:template>



 <!--
 
 	SVG TEMPLATES
 
 -->
  <!-- recurse 'node' element to find graph root -->
  <xsl:template match="node">
    <!-- check if the first 'edge' has current 'node' as target -->
    <xsl:apply-templates select="../edge[1]">
       <xsl:with-param name="n" select="."/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- check if a 'node' ($n) is a target of the current 'edge' -->
  <xsl:template match="edge">
    <xsl:param name="n">null</xsl:param>
    <!-- if the 'node' is not a target of the current 'edge' -->
    <xsl:if test="not(@target=$n/@id)">
      <!-- advance to the next edge -->
      <xsl:apply-templates select="following-sibling::edge[position()=1]">
        <xsl:with-param name="n" select="$n"/>
      </xsl:apply-templates>
      <!-- if all edges have been queried  -->
      <xsl:if test="not(following-sibling::edge[position()=1])">
        <!-- the 'node' ($n) is the root, create it -->
        <xsl:call-template name="create-node">
          <xsl:with-param name="n" select="$n"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <!-- transform a 'node' to SVG and recurse trough its children -->
  <xsl:template name="create-node">
    <xsl:param name="n">null</xsl:param>
    <xsl:param name="level">0</xsl:param>
    <xsl:param name="count">0</xsl:param>
    <xsl:param name="edge">null</xsl:param>
    <xsl:param name="x1">0</xsl:param>
    <xsl:param name="y1">0</xsl:param>
    <!-- some helpers -->
    <xsl:variable name="side" select="1-2*($count mod 2)"/>
    <xsl:variable name="x" select="$level*150"/>
    <xsl:variable name="y" select="$y1 - 50+$side*ceiling($count div 2)*150"/>
    <!-- create the 'node' itself and position it -->
    <svg:g class="node">
      <svg:rect x="{$x}" y="{$y}" width="100" height="100" />
      <svg:text text-anchor="middle" x="{$x+50}" y="{$y+55}">
        <xsl:value-of select="$n"/> <!--was $n/@id -->
      </svg:text>
    </svg:g>
    <!-- if there is an 'edge' ($edge) draw it -->
    <xsl:if test="$edge!='null'">
      <!-- the 'edge' position goes from previous 'node' position to $n one -->
      <svg:line class="edge" x1="{$x1}" y1="{$y1}" x2="{$x}" y2="{$y+50}">
        <xsl:attribute name="style">marker-end:url(#arrow)</xsl:attribute>
      </svg:line>
    </xsl:if>
    <!-- now that the 'node' is created, recurse to children through edges -->
    <xsl:call-template name="query-edge">
      <xsl:with-param name="edge" select="$n/../edge[@source=$n/@id][1]"/>
      <xsl:with-param name="x1" select="$x+100"/>
      <xsl:with-param name="y1" select="$y+50"/>
      <xsl:with-param name="n" select="$n"/>
      <!-- going to the upper level, increment level -->
      <xsl:with-param name="level" select="$level+1"/>
      <!-- going to the first child, set counter to 0 -->
      <xsl:with-param name="count" select="0"/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- recurse a 'node' ($n) edges to find 'node' children -->
  <xsl:template name="query-edge">
    <xsl:param name="edge">null</xsl:param>
    <xsl:param name="x1">0</xsl:param>
    <xsl:param name="y1">0</xsl:param>
    <xsl:param name="n">null</xsl:param>
    <xsl:param name="level">0</xsl:param>
    <xsl:param name="count">0</xsl:param>
    <xsl:variable name="target" select="$edge/@target"/>
    <!-- if there is an 'edge' -->
    <xsl:if test="$edge!='null'">
      <!-- go down the tree, create the 'node' of the 'edge' target -->
      <xsl:call-template name="create-node">
        <xsl:with-param name="n" select="$edge/../node[@id=$target]"/>
        <xsl:with-param name="level" select="$level"/>
        <xsl:with-param name="count" select="$count"/>
        <xsl:with-param name="edge" select="$edge"/>
        <xsl:with-param name="x1" select="$x1"/>
        <xsl:with-param name="y1" select="$y1"/>
      </xsl:call-template>
      <!-- go to the next 'edge' that has also the 'node' ($n) has source -->
      <xsl:variable name="next-edge" select="$edge/following-sibling::edge[position()=1][@source=$n/@id]"/>
      <xsl:call-template name="query-edge">
       <xsl:with-param name="edge" select="$next-edge"/>
       <xsl:with-param name="x1" select="$x1"/>
       <xsl:with-param name="y1" select="$y1"/>
       <xsl:with-param name="n" select="$n"/>
       <xsl:with-param name="level" select="$level"/>
       <!-- next 'edge', increment counter -->
       <xsl:with-param name="count" select="$count+1"/>
     </xsl:call-template>
    </xsl:if>
  </xsl:template>



</xsl:stylesheet>


<!--
<xsl:template match="ruleitems">
 <xsl:text>Testing RuleItems</xsl:text>
  <xsl:apply-templates select="ruleitem"/>
</xsl:template>
-->


<!--
<xsl:template match="rules">
 <xsl:text>Testing Rules</xsl:text>
 	<xsl:apply-templates select="rule" mode="display"/>
</xsl:template>
-->

<!--
<xsl:template match="rule" mode="display">
 	<xsl:value-of select="name"/>
</xsl:template>
-->