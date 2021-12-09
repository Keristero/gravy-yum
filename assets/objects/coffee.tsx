<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.5" tiledversion="1.7.2" name="coffee" tilewidth="33" tileheight="54" tilecount="4" columns="4" objectalignment="bottom">
 <tileoffset x="0" y="8"/>
 <grid orientation="isometric" width="64" height="32"/>
 <properties>
  <property name="Solid" type="bool" value="true"/>
 </properties>
 <image source="coffee.png" width="132" height="54"/>
 <tile id="0">
  <objectgroup draworder="index" id="2">
   <object id="10" x="8.54545" y="25" width="15.5455" height="15.1818"/>
  </objectgroup>
  <animation>
   <frame tileid="0" duration="250"/>
   <frame tileid="1" duration="250"/>
   <frame tileid="2" duration="250"/>
   <frame tileid="3" duration="250"/>
  </animation>
 </tile>
</tileset>
