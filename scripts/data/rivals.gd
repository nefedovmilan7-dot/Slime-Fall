class_name Rivals
extends RefCounted

const ALL := {
	"easy": ["EASY", 20, "party_hat", "blue", "Button"],
	"medium": ["MEDIUM", 40, "cowboy", "purple", "Blue"],
	"hard": ["HARD", 80, "viking", "orange", "Gold"],
	"impossible": ["IMPOSSIBLE", 200, "crown", "shadow", "Red"],
}


static func reward(id: String) -> int:
	return ALL[id][1]


static func hat(id: String) -> String:
	return ALL[id][2]


static func color(id: String) -> String:
	return ALL[id][3]
