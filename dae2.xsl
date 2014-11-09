<?xml version="1.0" standalone="no"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:exsl="http://exslt.org/common"
				xmlns:xlink="http://www.w3.org/1999/xlink"
				xmlns:svg="http://www.w3.org/2000/svg"
				xmlns:dae-attr="http://dae-attr"
				exclude-result-prefixes="exsl"
                version="1.0"><!--xmlns="http://www.w3.org/1999/xhtml"-->

<xsl:key name="seqdaerule" match="rule" use="@seqdaerule"/> 

<xsl:template match="/">
	
	<xsl:variable name='initialLayout'>
		<xsl:variable name='root' select='dae/rootrule/@seqdaerule'/>
		<xsl:variable name='title' select="key('seqdaerule', $root)/name"/>
		<node label="{$root}" title="{$title}">
			<xsl:apply-templates select="dae/ruleitems/ruleitem[@seqdaerule=$root]"/>
		</node>
	</xsl:variable>
	
	
	<xsl:variable name="layoutTree">
    	<xsl:apply-templates select="exsl:node-set($initialLayout)/node" mode="xml2layout"/>
  	</xsl:variable>
	
	 <!-- Turn XML nodes into SVG image --> 
  	<xsl:call-template name="layout2svg">
    	<xsl:with-param name="layout" select="exsl:node-set($layoutTree)"/>
  	</xsl:call-template>
	
</xsl:template>


<xsl:template match="ruleitem" >
	<xsl:variable name='call' select="callrule/@seqdaerule"/>
	<xsl:variable name='title' select="key('seqdaerule', $call)/name"/>
	<node label="{$call}" title="{$title}">
		<xsl:apply-templates select="../ruleitem[@seqdaerule=$call]"/>	
	</node>
</xsl:template>


<!--
width and height node parsing
-->

<!-- Add layout attributes to non-leaf nodes -->
<xsl:template match="node[node]" mode="xml2layout">
  <xsl:param name="depth" select="1"/>
  <xsl:variable name="subTree">
    <xsl:apply-templates select="node" mode="xml2layout">
      <xsl:with-param name="depth" select="$depth+1"/>
    </xsl:apply-templates>
  </xsl:variable>

  <!-- Add layout attributes to the existing node -->
  <node depth="{$depth}" width="{sum(exsl:node-set($subTree)/node/@width)}">
    <!-- Copy original attributes and content -->
    <xsl:copy-of select="@*"/>
    <xsl:copy-of select="$subTree"/>
  </node>

</xsl:template>

<!-- Add layout attributes to leaf nodes -->
<xsl:template match="node" mode="xml2layout">
  <xsl:param name="depth" select="1"/>
  <node depth="{$depth}" width="1">
    <xsl:copy-of select="@*"/>
  </node>
</xsl:template>        



<!-- 
Layout to SVG 
-->

<!-- Magnifying factor -->
<xsl:param name="hedge.scale" select="10"/>

<!-- Convert layout to SVG -->
<xsl:template name="layout2svg">
  <xsl:param name="layout"/>


	
  <!-- Find depth of the tree -->
  <xsl:variable name="maxDepth">
    <xsl:for-each select="$layout//node">
      <xsl:sort select="@depth" data-type="number" order="descending"/>
      <xsl:if test="position() = 1">
        <xsl:value-of select="@depth"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>
  
	
  <!-- Create SVG wrapper -->
  <!--<xsl:value-of select="$layout/node/@width"/>-->
  <xsl:processing-instruction name="xml-stylesheet">type="text/css" href="node.css"</xsl:processing-instruction>
  
  <!--<xsl:processing-instruction name="xml-stylesheet">type="text/javascript" href="dae2.js"</xsl:processing-instruction>-->
 <!-- <script href="dae2.js" type="text/javascript" />-->
  
  <svg:svg onload="init2(evt)" viewBox="0 0 {sum($layout/node/@width) * 2 * $hedge.scale} {$maxDepth * 2 * $hedge.scale}"  
  	width="{sum($layout/node/@width)*50}mm" height="{$maxDepth*50}mm" preserveAspectRatio="none" > <!--xMidYMid meet-->
	<xsl:attribute name="dae-attr:root">
		<xsl:value-of select="$layout/node/@label"></xsl:value-of>
	</xsl:attribute>
	<svg:script xlink:href="dae2.js" type="text/javascript" />
		<svg:script type="text/javascript"><![CDATA[
function init2(evt) { 
	alert('aa');
    if ( window.svgDocument == null )
        svgDocument = evt.target.ownerDocument;
}
]]></svg:script>
   
	<svg:defs>
		<svg:marker id="arrow" refX="0.0625" refY="0.0625" markerUnits="userSpaceOnUse" markerWidth="0.125" markerHeight="0.125" orient="auto">
			<svg:path fill="black" stroke-width="0.6" d="M0 0 0.125 0.0625 0 0.125z"/>
		</svg:marker>
	</svg:defs>
	
    <svg:g transform="translate(0,-{$hedge.scale div 2}) scale({$hedge.scale})">
      <xsl:apply-templates select="$layout/node" mode="layout2svg"/>
    </svg:g>
  </svg:svg>
</xsl:template>  


<!-- Draw one node --> 
<xsl:template match="node" mode="layout2svg">
  	<!-- Calculate X coordinate -->
  	<xsl:variable name="x" select="(sum(preceding::node[@depth = current()/@depth or (not(node) and @depth &lt;= current()/@depth)]/@width) + (@width div 2)) * 2"/>
  	<!-- Calculate Y coordinate -->
  	<xsl:variable name="y" select="@depth * 2"/>
  
  
  	<!-- Draw label of node -->
  	<svg:g class="node">
  		
  		<xsl:attribute name="dae-attr:ruleid">
  			<xsl:value-of select="../@label"></xsl:value-of>
		</xsl:attribute>
		
  	  <!-- Draw rounded rectangle around label -->
	  	<svg:rect x="{$x - 0.9}" y="{$y - 1}" width="1.8" height="1" onclick="init(evt)"
	    	rx="0.2" ry="0.2"/> <!-- style="fill: none; stroke: black; stroke-width: 0.05;"-->
	
	  	<svg:text x="{$x}"
	        y="{$y - 0.7}"> <!--style="text-anchor: middle; font-size: 0.3px;"-->
	    <xsl:value-of select="@title"/>
	  </svg:text>		
	</svg:g>
	
	  <!-- Draw connector lines to all sub-nodes -->
  <xsl:for-each select="node">
    <svg:line class="edge" x1="{$x}" 
              y1="{$y}" 
              x2="{(sum(preceding::node[@depth = current()/@depth or (not(node) and @depth &lt;= current()/@depth)]/@width) + (@width div 2)) * 2}" 
              y2="{@depth * 2 - 1}"> <!--style="stroke-width: 0.01; stroke: black;"-->
    	<xsl:attribute name="style">marker-end:url(#arrow)</xsl:attribute>
		<xsl:attribute name="dae-attr:target"><xsl:value-of select="@label"></xsl:value-of></xsl:attribute>
		<xsl:attribute name="dae-attr:source"><xsl:value-of select="../@label"></xsl:value-of></xsl:attribute>
	</svg:line>
  </xsl:for-each>
  
  <!-- Draw sub-nodes -->
  <xsl:apply-templates select="node" mode="layout2svg"/>
</xsl:template>	
</xsl:stylesheet>








<!--
<xsl:apply-templates select="key('seqdaerule', callrule/@seqdaerule)" mode='nodelayout2'>
-->


<!--
		<graph edgedefault="directed">
			<xsl:apply-templates select="dae/rules/rule" mode='nodelayout'/>
	   		<xsl:apply-templates select="dae/ruleitems/ruleitem" mode='nodelayout2'>
	   			 <xsl:sort select="@seqdaerule" data-type="text" order="ascending"/>
			</xsl:apply-templates>
	   	</graph>
		-->
	
	
	<!--
	<xsl:value-of select="exsl:node-set($graphTree)//graph"/>
	-->
	
	<!-- Turn XML nodes into SVG image -->
	<!--
  <xsl:call-template name="layout2svg">
    <xsl:with-param name="graph" select="exsl:node-set($graphTree)"/>
  </xsl:call-template>
  -->

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