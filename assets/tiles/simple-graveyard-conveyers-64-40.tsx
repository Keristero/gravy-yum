<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.5" tiledversion="1.5.0" name="simple-graveyard-conveyers-64-40" tilewidth="64" tileheight="40" tilecount="6" columns="2">
 <tileoffset x="0" y="8"/>
 <image source="simple-graveyard-conveyers-64-40.png" width="128" height="120"/>
 <tile id="0" type="Conveyor">
  <properties>
   <property name="Direction" value="Up Left"/>
   <property name="Sound Effect" value="/server/assets/sfx/dir_tile.ogg"/>
   <property name="Speed" type="int" value="6"/>
  </properties>
  <animation>
   <frame tileid="0" duration="100"/>
   <frame tileid="2" duration="100"/>
   <frame tileid="4" duration="100"/>
  </animation>
 </tile>
 <tile id="1" type="Conveyor">
  <properties>
   <property name="Direction" value="Down Left"/>
   <property name="Sound Effect" value="/server/assets/sfx/dir_tile.ogg"/>
   <property name="Speed" type="int" value="6"/>
  </properties>
  <animation>
   <frame tileid="1" duration="100"/>
   <frame tileid="3" duration="100"/>
   <frame tileid="5" duration="100"/>
  </animation>
 </tile>
</tileset>
