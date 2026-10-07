"""Two original regular-map loops, with distinct biome arrangements."""
from music_cue import Cue

def specification(title,emotion,motif,harmony,letters,mix):
    return {'title':title,'intent':emotion,
            'borrow':'Solemn dark-fantasy orchestral colour informed by the user\'s Elden Ring reference; original music with primal gameplay rhythm.',
            'material':{'motif':motif,'stated_in':'A','character':'Memorable arch with a descending reply'},
            'form':[{'bars':8,'development':'repeat','harmony':harmony,'harmony_letters':letters},
                    {'bars':8,'development':'vary','harmony':harmony,'harmony_letters':letters},
                    {'bars':8,'development':'sequence','harmony':'VI iv bII v','harmony_letters':letters},
                    {'bars':8,'development':'fragment','harmony':'iv bII i v','harmony_letters':letters},
                    {'bars':8,'development':'recap','harmony':harmony,'harmony_letters':letters},
                    {'bars':8,'development':'contract','harmony':'VI iv bII v','harmony_letters':letters}],
            'energy_curve':[.55,.66,.61,.4,.66,.53],
            'mix_intent':mix,'subtraction_events':'Bars 25-32 reduce percussion and accompaniment density while bass keeps moving.',
            'vocal':'None; no audible breathing, room recording or noise bed.'}

dm=(38,53,57);bb=(34,53,58);gm=(43,55,58);am=(33,52,57);eb=(39,55,58)
jh=([dm,dm,gm,dm,bb,gm,eb,am]*2+[bb,bb,gm,am,dm,gm,eb,am]+
    [gm,dm,eb,am,gm,dm,eb,am]+[dm,dm,gm,dm,bb,gm,eb,am]+[bb,gm,dm,am,bb,gm,eb,am])
jungle=Cue('Extinction-Protocol-Teeth-in-the-Canopy-Jungle-v1',116,48,
    {0:('marimba-hook',12,90,52,19),1:('pizzicato',45,80,81,20),
     2:('low-strings',42,82,61,27),3:('bass',32,96,63,15),
     4:('oboe-answer',68,76,45,30),5:('dark-harmony',48,57,76,30),
     9:('wood-and-hide-drums',0,100,57,14)},
    specification('Teeth in the Canopy','Restless, predatory jungle movement; drums and a wooden hook start immediately.',
                  'D F A Bb A G E D','i iv VI bII v','Dm Gm Bb Eb Am',
                  'Marimba owns the rhythmic hook; cello and oboe answer rather than doubling throughout. Low drums with bongos, wooden clicks and restrained shaker. Dense rhythm, clear bass, no jungle ambience.'))
jhook=[(0,74,.31,79),(.5,77,.31,72),(1.25,81,.57,83),(2,82,.31,72),
       (2.75,81,.57,80),(3.5,79,.31,70),(4.25,76,.57,72),(5,74,.7,78),
       (6.25,77,.31,66),(6.75,76,.31,62),(7.25,74,.51,69)]
jreply=[(0,67,.72,71),(.75,69,.46,65),(1.25,70,.7,72),(2,74,1.45,78),
        (3.5,72,.46,69),(4,70,.95,67),(5,69,.7,64),(6,67,1.7,61)]
jvar=[(0,77,.31,78),(.5,79,.31,74),(1.25,81,.57,83),(2,84,.31,77),
      (2.75,82,.57,80),(3.5,81,.31,72),(4.25,79,.57,75),(5,77,.7,75),
      (6.25,76,.31,66),(6.75,74,.8,69)]
for bar in range(0,48,2):
    t=bar*4
    if 24<=bar<32:
        jungle.phrase(2,t,[(0,55,1.45,61),(1.5,57,.45,57),(2,58,1.45,64),(3.5,57,.45,58),(4,55,1.45,60),(6,52,1.7,55)])
        jungle.note(0,t+5.5,74,.4,55);jungle.note(0,t+6.25,76,.4,52)
    elif bar%4==0:
        ph=jvar if 16<=bar<24 or 36<=bar<40 else jhook
        for pos,n,d,v in ph:jungle.note(0,t+pos,n,d,v)
        if bar>=32:jungle.phrase(2,t,[(0,62,1.45,63),(1.5,65,.45,59),(2,69,1.45,67),(4,67,.95,61),(5,64,.7,58),(6.25,62,1.45,61)])
    else:
        jungle.phrase(4,t,jreply,.92 if bar>=40 else 1)
        for pos,n in [(0,74),(1.25,77),(3,76),(4.25,74),(6,69)]:jungle.note(0,t+pos,n,.36,54)
for bar,(root,a,b) in enumerate(jh):
    t=bar*4;quiet=24<=bar<32
    for j,(pos,n) in enumerate([(0,root),(.75,root+12),(1.5,root),(2.25,root+7),(3,root)]):
        jungle.note(3,t+pos,n,.35 if j!=0 else .6,72 if j in (0,2) else 56)
    plucks=[(.5,a),(1.75,b),(2.5,a+12),(3.5,b)] if not quiet else [(.5,a),(2.5,b)]
    for pos,n in plucks:jungle.note(1,t+pos+.012,n,.28,51)
    if not quiet:
        jungle.note(5,t+.04,a,3.82,33);jungle.note(5,t+.07,b,3.8,29)
    hits=[(0,41,86),(.75,60,47),(1.5,45,68),(2.25,61,51),(3,41,76),(3.5,47,53)]
    if quiet:hits=[(0,41,69),(1.5,45,47),(3,41,61)]
    for pos,n,v in hits:jungle.note(9,t+pos+.008*(bar%2),n,.12,v+bar%3)
    for j in range(8):
        if quiet and j%2:continue
        jungle.note(9,t+j*.5+.014,69,.09,26 if j%2==0 else 19)
    if not quiet:
        for pos,n in [(.5,76),(1.75,77),(2.5,76),(3.75,77)]:jungle.note(9,t+pos+.01,n,.08,33)
    if bar in (6,13,21,37,45):
        for pos,n in [(3.25,60),(3.5,61),(3.75,50)]:jungle.note(9,t+pos,n,.09,49)

em=(40,55,59);cm=(36,55,60);a=(33,57,60);bm=(35,54,59);ff=(41,57,60);g=(43,55,59)
fh=([em,em,cm,a,em,g,ff,bm]*2+[cm,g,a,bm,cm,a,ff,bm]+
    [a,em,ff,bm,a,em,ff,bm]+[em,em,cm,a,em,g,ff,bm]+[cm,a,em,bm,cm,a,ff,bm])
frost=Cue('Extinction-Protocol-Beneath-the-Frozen-Sun-Frost-v1',96,48,
    {0:('cello-theme',42,94,62,34),1:('vibraphone',11,73,43,30),
     2:('bowed-harmony',48,66,80,39),3:('low-bass',43,95,64,19),
     4:('muted-horn',60,77,72,37),5:('pizzicato-pulse',45,78,47,23),
     9:('hollow-and-metal-percussion',0,99,58,22)},
    specification('Beneath the Frozen Sun','Cold, immense and dangerous; a deliberate walking pulse through hostile frost.',
                  'E G B A Fsharp E','i VI iv bII v','Em C Am F Bm',
                  'Bowed low melody with spaced vibraphone highlights and restrained horns. Deep hollow toms and metallic taps; rhythmic bass maintains urgency during thinner passages. No wind or peaceful snow ambience.'))
fhook=[(0,64,1.22,77),(1.25,67,.72,70),(2,71,1.72,82),(4,69,.97,75),
       (5,66,.72,68),(5.75,64,1.72,72)]
freply=[(0,62,1.22,69),(1.25,64,.72,66),(2,67,1.72,75),(4,66,.97,69),
        (5,64,.72,65),(5.75,59,1.72,67)]
fupper=[(0,67,1.22,74),(1.25,69,.72,71),(2,71,1.22,80),(3.25,74,.72,77),
        (4,72,.97,74),(5,71,.72,71),(5.75,69,1.72,68)]
for bar in range(0,48,2):
    t=bar*4;quiet=24<=bar<32
    if quiet:
        for pos,n,d,v in [(0,76,1.6,57),(2.5,74,.8,52),(4,72,1.4,55),(6,71,1.45,49)]:frost.note(1,t+pos,n,d,v)
        frost.phrase(0,t,[(0,57,2.4,54),(2.5,59,1.4,57),(4.25,60,1.4,55),(6,59,1.5,52)])
    else:
        ph=fhook if bar%4==0 else freply
        if 16<=bar<24 or 36<=bar<40:ph=fupper if bar%4==0 else freply
        frost.phrase(4 if 8<=bar<16 or 32<=bar<40 else 0,t,ph)
        for pos,n in [(0,76),(3,78),(6.25,79)]:frost.note(1,t+pos,n,.65,45 if pos else 53)
for bar,(root,aa,b) in enumerate(fh):
    t=bar*4;quiet=24<=bar<32
    for pos,n,v in [(0,root,77),(1.5,root,57),(2.5,root+7,63),(3.5,root,58)]:frost.note(3,t+pos,n,.46 if pos==3.5 else .7,v-(4 if quiet else 0))
    for pos,n in ([(.75,aa),(2, b),(3.25,aa+12)] if not quiet else [(2,aa)]):frost.note(5,t+pos+.013,n,.42,48)
    frost.note(2,t+.045,aa,3.82,35 if not quiet else 28)
    frost.note(2,t+.07,b,3.78,30 if not quiet else 25)
    hits=[(0,41,84),(1.5,45,53),(2.5,41,72),(3.5,47,54)] if not quiet else [(0,41,68),(2.5,45,52)]
    for pos,n,v in hits:
        if bar in (5,14,22,37,45) and pos==3.5:continue
        frost.note(9,t+pos+.005*(bar%3),n,.15,v)
    for pos,n,v in [(.75,80,29),(2,81,25),(3.25,80,23)]:
        if quiet and pos!=2:continue
        frost.note(9,t+pos+.012,n,.1,v)
    if bar in (5,14,22,37,45):
        for pos,n,v in [(3,50,42),(3.5,47,48),(3.75,45,43)]:frost.note(9,t+pos,n,.12,v)

if __name__=='__main__':
    jungle.finish(-18)
    frost.finish(-18)
