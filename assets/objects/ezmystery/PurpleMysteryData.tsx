<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.5" tiledversion="1.5.0" name="PurpleMysteryData" tilewidth="14" tileheight="43" tilecount="8" columns="8" objectalignment="bottom">
 <tileoffset x="0" y="3"/>
 <image source="PurpleMysteryData.png" width="112" height="43"/>
 <tile id="0">
  <properties>
   <property name="Amount" type="int" value="0"/>
   <property name="Description" value="itemdescription"/>
   <property name="Locked" type="bool" value="true"/>
   <property name="Name" value="itemname"/>
   <property name="Next 1" type="object" value="0"/>
   <property name="Next 2" type="object" value="0"/>
   <property name="Next 3" type="object" value="0"/>
   <property name="Once" type="bool" value="true"/>
   <property name="Type" value="keyitem"/>
  </properties>
  <objectgroup draworder="index" id="4">
   <object id="6" x="-1.18582" y="35.7723" width="16.4533" height="9.33835">
    <ellipse/>
   </object>
  </objectgroup>
  <animation>
   <frame tileid="0" duration="100"/>
   <frame tileid="1" duration="100"/>
   <frame tileid="2" duration="100"/>
   <frame tileid="3" duration="100"/>
   <frame tileid="4" duration="100"/>
   <frame tileid="5" duration="100"/>
   <frame tileid="6" duration="100"/>
   <frame tileid="7" duration="100"/>
  </animation>
 </tile>
</tileset>
