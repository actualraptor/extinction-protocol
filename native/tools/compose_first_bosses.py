"""First-boss sketches: three distinct identities, not regular-map replacements."""
from music_cue import Cue

def boss(identity,title,bpm,shift,hook,reply,drums,colour):
    name='Extinction-Protocol-'+title+'-Boss-v1'
    cue=Cue(name,bpm,36,
        {0:('low-brass',61,91,61,26),1:('cello-hook',42,93,49,25),
         2:('string-motion',45 if identity=='warden' else 48,82,78,25),
         3:('bass',43,103,64,17),4:('upper-colour',colour,72,74,29),
         9:('heavy-percussion',0,110,57,17)},
        {'title':title.replace('-',' '),'intent':'Immediate boss threat with a distinct recurring melodic and rhythmic identity.',
         'internal_boss_id':identity,
         'boss_name':{'thorn':'Triceratops — The Horn Crown','hunt':'Cryolophosaurus — The Frozen Crest','warden':'Therizinosaurus — The Scythe Claw','basalt':'Tyrannosaurus rex — The Apex Tyrant','aurora':'Yutyrannus — The Feathered King','bloom':'Spinosaurus — The Sailback'}[identity],
         'material':{'motif':[n+shift for _,n,_,_ in hook],'stated_in':'A','character':{'thorn':'Heavy deliberate charge accents','hunt':'Quick rising hunt followed by a falling response','warden':'Asymmetric claw-like three-hit gestures','basalt':'Massive footstep rhythm: boom, boom, boom-boom','aurora':'Broad ascending call answered by the hunting pack','bloom':'Long winding line over rolling percussion'}[identity]},
         'form':[{'bars':8,'development':'repeat'},{'bars':8,'development':'vary'},
                 {'bars':6,'development':'sequence'},{'bars':6,'development':'fragment'},
                 {'bars':8,'development':'recap'}],
         'harmony':'Minor tonic, lowered sixth, minor fourth, Phrygian lowered second and minor dominant; transposed per boss.',
         'harmony_letters':'Dm / Bb / Gm / Eb / Am before transposition',
         'energy_curve':[.75,.85,.8,.58,.86],
         'mix_intent':'Strong percussion and short bass; brass/cello share foreground by section. Strings yield to hook; no cinematic noise or audible breathing.',
         'subtraction_events':'Bars 23-28 withdraw upper colour and reduce accompaniment while pulse remains.',
         'borrow':'Dark orchestral gravity from the user reference; original notes and boss-specific groove.'})
    roots=[(38,53,57),(34,53,58),(43,55,58),(39,55,58),(33,52,57)]
    order=([0,0,1,2,0,1,3,4]*2+[1,2,0,3,2,4]+[2,0,3,4,3,4]+[0,0,1,2,0,1,3,4])
    for bar in range(0,36,2):
        t=bar*4;quiet=22<=bar<28
        ph=reply if bar%4 else hook
        if 16<=bar<22:ph=[(p,n+3,d,v) for p,n,d,v in ph]
        if quiet:
            ph=[(0,62,1.4,69),(1.5,65,.4,65),(2.25,64,1.4,67),(4,60,1.4,65),(6,57,1.4,62)]
        lead=1 if quiet or 8<=bar<16 else 0
        cue.phrase(lead,t,[(p,n+shift,d,v) for p,n,d,v in ph])
        if not quiet and bar in (6,14,20,32):
            cue.phrase(4,t+4,[(0,74+shift,.7,65),(.75,72+shift,.45,60),(1.5,69+shift,.95,62),(3,67+shift,.7,58)])
    for bar,chord_id in enumerate(order):
        root,a,b=roots[chord_id];root+=shift;a+=shift;b+=shift
        t=bar*4;quiet=22<=bar<28
        for idx,(pos,drum,v) in enumerate(drums):
            if quiet and idx%2:continue
            cue.note(9,t+pos+.006*(bar%2),drum,.1,v-(12 if quiet else 0)+bar%3)
            cue.note(3,t+pos,root if idx%2==0 else root+7,min(.43,3.95-pos),83 if idx%2==0 else 64)
        for j in range(8):
            if quiet and j%2:continue
            cue.note(9,t+j*.5+.014,76 if identity=='warden' else 42,.08,32 if j%2==0 else 24)
        for j,pos in enumerate([0,.75,1.5,2.25,3]):
            if quiet and j%2:continue
            n=[a,b,a+12,b,a][j]
            cue.note(2,t+pos+.015,n,.42 if identity=='warden' else .53,55 if j%2==0 else 46)
    return cue

thorn=boss('thorn','The-Horned-Judgment',124,0,
    [(0,62,.7,86),(.75,62,.45,78),(1.5,65,.95,81),(3,69,.7,89),
     (4,67,.7,80),(5,64,.7,76),(6,62,1.6,82)],
    [(0,60,.95,80),(1.25,62,.7,78),(2.25,65,1.1,85),(4,64,.7,76),(5,60,.7,73),(6,57,1.6,78)],
    [(0,41,100),(1.5,45,78),(2.5,41,94),(3.25,47,75)],60)
hunt=boss('hunt','Pursuit-Under-Ice',138,1,
    [(0,62,.4,81),(.5,65,.4,76),(1,67,.4,80),(1.5,69,.9,87),(2.5,67,.4,77),
     (3,65,.7,79),(4,64,.4,76),(4.5,62,.7,81),(5.5,60,.4,71),(6,62,1.6,79)],
    [(0,65,.4,79),(.5,67,.4,77),(1,69,.9,85),(2,72,.7,87),(3,70,.7,80),
     (4,69,.4,76),(4.5,67,.7,77),(5.5,65,.4,72),(6,64,1.6,74)],
    [(0,41,94),(.75,45,67),(1.5,47,74),(2.25,41,88),(3,45,71)],11)
warden=boss('warden','The-Canopy-Reaper',132,-5,
    [(0,62,.4,83),(.75,65,.4,78),(1.5,69,1.1,88),(3,70,.4,80),(3.75,69,.4,77),
     (4.5,67,.65,81),(5.5,64,.65,76),(6.5,62,1.1,78)],
    [(0,60,.4,80),(.75,62,.4,76),(1.5,65,1.1,85),(3,67,.4,80),(3.75,65,.4,76),
     (4.5,64,.65,77),(5.5,60,.65,73),(6.5,57,1.1,75)],
    [(0,41,96),(.75,60,67),(1.5,45,81),(2.75,41,90),(3.5,61,64)],12)

if __name__=='__main__':
    for cue in (thorn,hunt,warden):cue.finish(-17)
