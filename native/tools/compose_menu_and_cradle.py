"""Menu and first-map compositions using the reusable cue renderer."""
from music_cue import Cue

# The six-note identity retains its contour; note lengths now connect and the line lives lower.
theme=[(0,69,.97,58),(1,72,.47,55),(1.5,74,1.48,61),(3,77,1.96,65),
       (5,76,.47,57),(5.5,74,.97,56),(6.5,72,.46,52),(7,69,.67,49)]
answer=[(0,67,1.47,54),(1.5,69,.47,52),(2,72,.97,57),(3,74,1.97,59),
        (5,72,.47,53),(5.5,70,.97,51),(6.5,69,.46,49),(7,67,.67,46)]
rise=[(0,74,1.47,58),(1.5,76,.47,55),(2,77,1.47,63),(3.5,79,.47,60),
      (4,77,.97,60),(5,76,.47,54),(5.5,74,.97,53),(6.5,72,1.16,50)]
closing=[(0,70,1.47,53),(1.5,72,.47,51),(2,74,1.97,58),(4,72,.97,52),
         (5,70,.97,50),(6,69,1.67,46)]
dm=(38,53,57);bb=(34,53,58);gm=(43,55,58);am=(33,52,57);eb=(39,55,58);f=(41,53,57)
menu_h=[dm,dm,bb,bb,gm,am,dm,dm,bb,f,gm,am,gm,gm,eb,am,dm,bb,gm,dm,eb,am,am,am]
menu=Cue('Extinction-Protocol-Embers-of-the-Cradle-Menu-v2',72,24,
    {0:('flute',73,90,66,38),1:('plucks',24,68,43,25),2:('low-strings',42,63,76,39),
     3:('bass',43,72,62,23),4:('horn',60,57,54,41),9:('percussion',0,63,58,16)},
    {'title':'Embers of the Cradle, flowing revision','intent':'Solemn ancient welcome; quiet enough for an idle menu.',
     'borrow':'Elden Ring reference: restrained dark orchestral gravity and spacious phrasing, original melody.',
     'material':{'motif':'A C D F E D C A','stated_in':'A','character':'Connected arch, arriving then releasing'},
     'form':[{'bars':8,'development':'repeat','harmony':'i VI iv v i','harmony_letters':'Dm Bb Gm Am Dm'},
             {'bars':4,'development':'extend','harmony':'VI III iv v','harmony_letters':'Bb F Gm Am'},
             {'bars':4,'development':'fragment','harmony':'iv bII v','harmony_letters':'Gm Eb Am'},
             {'bars':8,'development':'recap','harmony':'i VI iv i bII v','harmony_letters':'Dm Bb Gm Dm Eb Am'}],
     'energy_curve':[.32,.4,.22,.35],
     'mix_intent':'Flute in a lower register with phrase-shaped expression; strings below, a distant horn answering. Percussion quiet. No wind layer.',
     'change_from_v1':'Replaced isolated pan-flute stabs with connected concert-flute phrases and a coherent eight-beat arc; breath only at phrase ends.'})
for start,ph in [(0,theme),(8,answer),(16,theme),(24,closing),(32,rise),(40,answer),
                 (64,theme),(72,rise),(80,closing),(88,answer)]:menu.phrase(0,start,ph,.92 if start>=80 else 1)
for start,ph in [(48,[(0,67,2.9,45),(3,69,1.9,47),(5,70,2.65,48)]),
                 (56,[(0,67,2.9,44),(3,64,1.9,43),(5,69,2.65,45)])]:menu.phrase(4,start,ph)
for bar,(root,a,b) in enumerate(menu_h):
    t=bar*4;quiet=12<=bar<16
    for pos,n,v in [(0,a,43),(1.5,b,38),(3,a+12,34)]:menu.note(1,t+pos+.015,n,.9,v-(6 if quiet else 0))
    menu.note(3,t,root,2.4,40 if quiet else 47)
    menu.note(2,t+.04,a-12,3.88,32);menu.note(2,t+.07,b-12,3.84,27)
    if not quiet:
        for pos,n,v in [(0,41,39),(2.5,45,29),(3.25,76,23)]:menu.note(9,t+pos+.012,n,.13,v+bar%3)
    if bar in (7,19):menu.note(4,t+.1,57,3.5,36)

map_h=([dm,dm,bb,gm,dm,bb,gm,am]*2+[bb,f,gm,am,bb,gm,eb,am]+[gm,dm,eb,am]*2+
       [dm,dm,bb,gm,dm,bb,gm,am]*2+[bb,gm,eb,am,dm,bb,eb,am])
assert len(map_h)==56
mapcue=Cue('Extinction-Protocol-The-Lost-Cradle-Map-v1',112,56,
    {0:('cello-theme',42,91,60,27),1:('pizzicato',45,88,42,20),2:('string-harmony',48,61,77,35),
     3:('bass',43,96,64,18),4:('horn-theme',60,83,72,34),5:('flute-answer',73,74,48,28),
     9:('tribal-percussion',0,100,58,14)},
    {'title':'The Lost Cradle','intent':'Normal first-map survival music: steady momentum, ancient scale, danger without boss intensity.',
     'borrow':'Elden Ring reference: sombre lower orchestral colours; primal drums and rhythmic bass preserve this game\'s identity.',
     'material':{'motif':'D F A G E D','stated_in':'A','character':'Firm rhythmic march with a descending answer'},
     'form':[{'bars':8,'development':'repeat','harmony':'i VI iv v','harmony_letters':'Dm Bb Gm Am'},
             {'bars':8,'development':'vary','harmony':'i VI iv v','harmony_letters':'Dm Bb Gm Am'},
             {'bars':8,'development':'sequence','harmony':'VI III iv v bII','harmony_letters':'Bb F Gm Am Eb'},
             {'bars':8,'development':'fragment','harmony':'iv i bII v','harmony_letters':'Gm Dm Eb Am'},
             {'bars':16,'development':'recap','harmony':'i VI iv v','harmony_letters':'Dm Bb Gm Am'},
             {'bars':8,'development':'contract','harmony':'VI iv bII v i','harmony_letters':'Bb Gm Eb Am Dm'}],
     'energy_curve':[.52,.62,.67,.43,.64,.54],
     'mix_intent':'Toms and bass interlock; cello or horn owns the lead, flute answers in gaps. Strings stay behind percussion. No huge crescendo or boss finale.',
     'subtraction_events':'Bars 25-32 withdraw horn and string ostinato density; drums retain movement.'})
hook=[(0,62,.7,79),(.75,65,.45,69),(1.5,69,1.2,83),(3,67,.7,74),
      (4,64,.45,69),(4.75,62,1.2,77),(6.25,65,.45,69),(7,64,.72,65)]
reply=[(0,60,.7,72),(.75,62,.45,68),(1.5,65,1.2,77),(3,64,.7,70),
       (4,62,.95,70),(5.25,60,.7,65),(6.25,57,1.45,67)]
upper=[(0,65,.7,76),(.75,67,.45,72),(1.5,69,1.2,81),(3,72,.7,78),
       (4,70,.7,75),(5,69,.7,72),(6,67,.45,67),(6.75,65,.95,70)]
for bar in range(0,56,2):
    t=bar*4;quiet=24<=bar<32
    if quiet:
        mapcue.phrase(5,t,[(0,74,1.47,59),(1.5,72,.47,53),(2,70,1.9,55),(4.5,69,1.45,52),(6.25,67,1.4,49)])
    else:
        ph=hook if bar%4==0 else reply
        if 16<=bar<24 or 40<=bar<48:ph=upper if bar%4==0 else reply
        ch=4 if 8<=bar<24 or 40<=bar<48 else 0
        mapcue.phrase(ch,t,ph,.95 if bar>=48 else 1)
        if bar in (6,14,22,38,46,54):
            mapcue.phrase(5,t+4,[(0,77,.7,56),(.75,76,.45,51),(1.25,74,1.0,54),(2.5,72,1.1,49)])
for bar,(root,a,b) in enumerate(map_h):
    t=bar*4;quiet=24<=bar<32
    for j,(pos,n) in enumerate([(0,root),(.75,root),(1.5,root+7),(2.5,root),(3.25,root+7)]):
        mapcue.note(3,t+pos,n,.38 if j!=3 else .62,(71 if j in (0,3) else 56)-(6 if quiet else 0))
    pattern=[(0,a),(.5,b),(1.25,a+12),(2,a),(2.75,b),(3.5,a+12)]
    if quiet:pattern=[(0,a),(2.75,b)]
    for j,(pos,n) in enumerate(pattern):mapcue.note(1,t+pos+.009,n,.32,57+(j%3)*5-(7 if quiet else 0))
    if not quiet:
        mapcue.note(2,t+.045,a,3.82,36);mapcue.note(2,t+.065,b,3.8,31)
    hits=[(0,41,83),(.75,45,54),(1.5,47,61),(2.5,41,75),(3.25,45,55)]
    if quiet:hits=[(0,41,69),(1.5,45,48),(2.5,41,59)]
    for pos,n,v in hits:mapcue.note(9,t+pos+.005*(bar%3),n,.12,v+bar%4)
    for j in range(8 if not quiet else 4):
        pos=j*.5 if not quiet else j
        mapcue.note(9,t+pos+.013,76 if j%2==0 else 77,.09,(31 if j%2==0 else 23)+bar%3)
    if bar in (6,13,21,37,45,53):
        for pos,n,v in [(3,50,51),(3.5,47,55),(3.75,45,49)]:mapcue.note(9,t+pos,n,.1,v)

if __name__=='__main__':
    menu.finish(-20)
    mapcue.finish(-18)
