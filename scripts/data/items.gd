class_name Items
extends RefCounted


## id -> [name, price]
const HATS := {
	"none": ["NO HAT", 0], "party_hat": ["PARTY HAT", 40], "bow": ["BOW", 40], "beanie": ["BEANIE", 60],
	"cat_ears": ["CAT EARS", 80], "headphones": ["HEADPHONES", 100], "cowboy": ["COWBOY", 120],
	"chef": ["CHEF", 120], "shades": ["SHADES", 150], "pirate": ["PIRATE", 200], "viking": ["VIKING", 250],
	"top_hat": ["TOP HAT", 300], "crown": ["CROWN", 500], "halo": ["HALO", 600], "devil_horns": ["HORNS", 600],
	"angel_wings": ["WINGS", 800], "dragon": ["DRAGON", 1000], "diamond_crown": ["DIAMOND", 2000],
}
const COLORS := {
	"green": ["SLIME", 0.0, 1.0, 1.0, 0], "blue": ["OCEAN", 0.25, 1.1, 1.0, 50], "pink": ["BUBBLEGUM", 0.56, 0.9, 1.1, 80],
	"purple": ["GRAPE", 0.42, 1.0, 1.0, 80], "orange": ["MAGMA", 0.72, 1.2, 1.1, 150], "ghost": ["GHOST", 0.0, 0.1, 1.15, 250],
	"gold": ["GOLDEN", 0.8, 1.2, 1.15, 600], "shadow": ["SHADOW", 0.4, 0.3, 0.5, 900],
}


static func price(kind: String, id: String) -> int:
	return HATS[id][1] if kind == "hat" else COLORS[id][4]


static func name_of(kind: String, id: String) -> String:
	return HATS[id][0] if kind == "hat" else COLORS[id][0]
