extends RefCounted
## Cosmetic names never consume combat RNG: 640 names x 128 titles x 320 epithets.
const STARTS="Ar Bel Cor Dar El Fal Gar Har Is Jar Kel Lor Mor Nar Or Pel Qua Ral Sar Tor Ul Var Vor Wel Xan Yor Zal Bren Drav Grav Krav Mal"
const ENDS="ak an ar ath ek en er eth ik in ir ith ok on or oth ul un ur us"
const ADJECTIVES="Ashen Black Bleak Broken Buried Cold Drowned Empty Fallen Forgotten Hollow Iron Last Lost Pale Quiet Shattered Silent Sunken Withered"
const PLACES="Barrow Bell Cairn Chapel Crypt Crown Gate Grave Keep Marsh Moon Oath Pyre Sepulchre Throne Tomb"
const TITLE_ROOTS="Bone Grave Ash Crypt Dusk Hollow Pale Silent"
const TITLE_WORDS="Bearer Binder Caller Keeper Marshal Reaver Seeker Warden Herald Scribe Seer Votary Sentinel Harrower Speaker Walker"
const ROLES={"warrior":"Blade","guard":"Ward","archer":"Arrow","wraith":"Shade","colossus":"Titan","boss":"Ancient"}
const FIRST_COUNT=640
const TITLE_COUNT=128
const SUFFIX_COUNT=320
const COMBINATIONS=FIRST_COUNT*TITLE_COUNT*SUFFIX_COUNT
static var starts=STARTS.split(" ")
static var ends=ENDS.split(" ")
static var adjectives=ADJECTIVES.split(" ")
static var places=PLACES.split(" ")
static var title_roots=TITLE_ROOTS.split(" ")
static var title_words=TITLE_WORDS.split(" ")
static func generate(run_seed:int,uid:int,role:String)->String:
	# 1000003 is coprime to the pool size and spreads consecutive summons
	# across all components. Reduce inputs first to avoid integer overflow.
	var index=posmod(posmod(run_seed,COMBINATIONS)+posmod(uid,COMBINATIONS)*1000003,COMBINATIONS)
	var first=index%FIRST_COUNT
	var title=int(index/FIRST_COUNT)%TITLE_COUNT
	var epithet=int(index/(FIRST_COUNT*TITLE_COUNT))
	# Shift within each title/epithet group so early summons do not all share
	# the same two given-name stems. This preserves the one-to-one mapping.
	first=posmod(first+title*37+epithet*53,FIRST_COUNT)
	var given=starts[int(first/20)]+ends[first%20]
	var prefix=title_roots[int(title/16)]+" "+title_words[title%16]
	return "%s %s, %s of the %s %s"%[prefix,given,ROLES.get(role,"Shade"),adjectives[int(epithet/16)],places[epithet%16]]

static func display(unit:Dictionary)->String:
	return str(unit.get("name","Unnamed summon"))
