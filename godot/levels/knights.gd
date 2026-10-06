class_name KnightLevel
extends RefCounted
const DATA := {"name": "Knights", "view": [0,270,980,450], "ammo": {"grenade":4,"rocket":2}, "par":2, "alert_at":90, "hint":"Shields block blasts from the front. Lob over them!", "build":[
["ground",0,190,560], ["ground",190,1000,650], ["barrel",430,650], ["block",600,650,16,50,"wood"], ["enemy",820,650,{"knight":true}], ["enemy",900,650,{"knight":true}]]}
