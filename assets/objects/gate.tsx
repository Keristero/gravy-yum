<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.5" tiledversion="1.5.0" name="gate" tilewidth="34" tileheight="52" tilecount="5" columns="5" objectalignment="topleft">
 <grid orientation="isometric" width="64" height="32"/>
 <properties>
  <property name="Solid" type="bool" value="true"/>
 </properties>
 <image source="gate.png" width="170" height="52"/>
 <tile id="0">
  <objectgroup draworder="index" id="3">
   <object id="5" x="0" y="40">
    <polygon points="0,0 32,0 40,-8 32,-16 0,-16 -8,-8"/>
   </object>
  </objectgroup>
  <animation>
   <frame tileid="0" duration="50"/>
   <frame tileid="1" duration="50"/>
   <frame tileid="2" duration="50"/>
   <frame tileid="3" duration="50"/>
  </animation>
 </tile>
</tileset>
