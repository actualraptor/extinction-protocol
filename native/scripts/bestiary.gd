extends RefCounted
## Numeric keys are preserved for existing saves and combat references.
const DATA = [
 {
  "name": "Velociraptor",
  "hp": 24,
  "speed": 85,
  "size": 19,
  "role": "chase",
  "species": "Velociraptor",
  "habitat": "grasslands"
 },
 {
  "name": "Ankylosaurus",
  "hp": 110,
  "speed": 49,
  "size": 26,
  "role": "armor",
  "species": "Ankylosaurus",
  "habitat": "grasslands",
  "knockback": 0.25
 },
 {
  "name": "Pteranodon",
  "hp": 17,
  "speed": 130,
  "size": 19,
  "role": "fly",
  "species": "Pteranodon",
  "habitat": "grasslands"
 },
 {
  "name": "Allosaurus",
  "hp": 65,
  "speed": 112,
  "size": 27,
  "role": "chase",
  "species": "Allosaurus",
  "habitat": "grasslands"
 },
 {
  "name": "Compsognathus",
  "hp": 3,
  "speed": 285,
  "size": 9,
  "role": "stampede",
  "species": "Compsognathus",
  "habitat": "event"
 },
 {
  "name": "Dilophosaurus",
  "hp": 34,
  "speed": 72,
  "size": 21,
  "role": "spit",
  "species": "Dilophosaurus",
  "habitat": "grasslands"
 },
 {
  "name": "Euoplocephalus",
  "hp": 110,
  "speed": 49,
  "size": 26,
  "role": "armor",
  "species": "Euoplocephalus",
  "habitat": "frost",
  "knockback": 0.3
 },
 {
  "name": "Pachyrhinosaurus",
  "hp": 140,
  "speed": 55,
  "size": 32,
  "role": "charge",
  "species": "Pachyrhinosaurus",
  "habitat": "grasslands"
 },
 {
  "name": "Oviraptor",
  "hp": 72,
  "speed": 61,
  "size": 24,
  "role": "brood",
  "species": "Oviraptor",
  "habitat": "jungle"
 },
 {
  "name": "Microraptor",
  "hp": 20,
  "speed": 145,
  "size": 17,
  "role": "fly",
  "species": "Microraptor",
  "habitat": "jungle"
 },
 {
  "name": "Stegosaurus",
  "hp": 145,
  "speed": 40,
  "size": 27,
  "role": "armor",
  "resists": {
   "FIRE": 1.2
  },
  "species": "Stegosaurus",
  "habitat": "jungle"
 },
 {
  "name": "Amargasaurus",
  "hp": 180,
  "speed": 50,
  "size": 32,
  "role": "slam",
  "resists": {
   "FIRE": 0.6,
   "ICE": 1.2
  },
  "species": "Amargasaurus",
  "habitat": "jungle"
 },
 {
  "name": "Utahraptor",
  "hp": 45,
  "speed": 137,
  "size": 20,
  "role": "phase",
  "species": "Utahraptor",
  "habitat": "jungle"
 },
 {
  "name": "Monolophosaurus",
  "hp": 85,
  "speed": 88,
  "size": 25,
  "role": "spit",
  "species": "Monolophosaurus",
  "habitat": "jungle"
 },
 {
  "name": "Dakotaraptor",
  "hp": 40,
  "speed": 107,
  "size": 21,
  "role": "charge",
  "resists": {
   "ICE": 0.8,
   "FIRE": 1.2
  },
  "species": "Dakotaraptor",
  "habitat": "frost"
 },
 {
  "name": "Troodon",
  "hp": 28,
  "speed": 115,
  "size": 23,
  "role": "phase",
  "resists": {
   "ARCANE": 0.8
  },
  "species": "Troodon",
  "habitat": "frost"
 },
 {
  "name": "Nodosaurus",
  "hp": 85,
  "speed": 65,
  "size": 25,
  "role": "armor",
  "species": "Nodosaurus",
  "habitat": "frost",
  "knockback": 0.3
 },
 {
  "name": "Citipati",
  "hp": 60,
  "speed": 66,
  "size": 24,
  "role": "brood",
  "species": "Citipati",
  "habitat": "frost"
 },
 {
  "name": "Sinosauropteryx",
  "species": "Sinosauropteryx",
  "habitat": "frost",
  "hp": 23,
  "speed": 99,
  "size": 17,
  "role": "chase"
 }
]

static func pool(depth,time):
	return preload("res://scripts/expedition_maps.gd").pool("cradle",depth,time)
