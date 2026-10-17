extends RefCounted
const DISCOVERIES={"tfk_microphone":"tfk_broadcast","tfk_factbook":"tfk_facts","tfk_toplist":"tfk_list","tfk_telephone":"tfk_phone"}
## Native vector symbols remain editable and distinct at HUD scale.
const SYMBOLS={
	"tfk_phone":"<path d='M30 27 Q64 8 98 27 L94 39 Q64 24 34 39 Z'/><path d='M43 49 L85 49 L98 91 L30 91 Z'/><circle cx='64' cy='70' r='13'/>",
	"tfk_backpack":"<rect x='34' y='35' width='60' height='64' rx='13'/><path d='M49 35 V23 H79 V35 M34 48 H94 M47 71 H81 V89 H47 Z'/>",
	"tfk_list":"<path d='M23 13 H105 V115 H23 Z M43 28 H85 M53 48 H91 M53 73 H83 M53 98 H73'/><path d='M35 42 V54 M31 68 Q43 62 40 71 L31 80 H42 M31 92 H41 L35 97 Q45 102 32 105'/>",
	"tfk_facts":"<path d='M25 13 H83 L105 35 V115 H25 Z M83 13 V35 H105 M39 43 H69 M39 61 H91 M39 77 H91 M39 93 H77'/><circle cx='84' cy='43' r='7'/>",
	"tfk_eyes":"<path d='M18 55 Q37 32 58 55 Q37 75 18 55 Z M70 55 Q91 32 110 55 Q91 75 70 55 Z'/><path d='M38 45 V65 M90 45 V65 M44 90 L64 80 L84 90'/>",
	"tfk_mac":"<path d='M28 27 H100 V76 H28 Z M28 76 L16 97 H112 L100 76 M52 44 L72 44 L59 59 L76 59 L57 71'/>",
	"tfk_scenario":"<path d='M24 39 L64 20 L104 39 V86 L64 108 L24 86 Z M24 39 L64 62 L104 39 M64 62 V108'/><circle cx='43' cy='68' r='3'/><circle cx='85' cy='68' r='3'/><circle cx='85' cy='83' r='3'/>",
	"tfk_broadcast":"<rect x='48' y='17' width='32' height='55' rx='16'/><path d='M37 51 V58 Q37 84 64 84 Q91 84 91 58 V51 M64 84 V105 M46 105 H82 M57 29 H71 M57 41 H71 M57 53 H71'/>",
	"tfk_meltdown":"<path d='M35 70 Q12 43 39 33 Q43 12 63 30 Q86 9 95 34 Q119 49 93 70 L96 94 L64 111 L31 94 Z M64 30 V83 M42 45 L55 55 L42 66 M86 45 L73 55 L86 66'/>",
	"tfk_disaster":"<path d='M21 43 H107 V99 H21 Z M36 26 L47 43 M92 26 L81 43 M57 54 L74 54 L61 71 L77 71 L51 92 L58 75 L45 75 Z'/><circle cx='93' cy='62' r='3'/><circle cx='93' cy='80' r='3'/>"}
const COLORS={"tfk_phone":"#c9a3ff","tfk_backpack":"#cfa577","tfk_list":"#ffd76c","tfk_facts":"#a0e8da","tfk_eyes":"#89d8ed","tfk_mac":"#93caff","tfk_scenario":"#f5b08b","tfk_broadcast":"#ffd76c","tfk_meltdown":"#c9a3ff","tfk_disaster":"#f5b08b"}
static func texture(id):
	var svg="<svg xmlns='http://www.w3.org/2000/svg' width='128' height='128' viewBox='0 0 128 128'><g fill='none' stroke='%s' stroke-width='7' stroke-linecap='round' stroke-linejoin='round'>%s</g></svg>"%[COLORS[id],SYMBOLS[id]]
	var source=Image.new()
	var error=source.load_svg_from_string(svg)
	if error!=OK:push_error("TFK icon SVG could not load: "+id);return null
	return ImageTexture.create_from_image(source)
