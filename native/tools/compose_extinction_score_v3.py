"""String-led symphonic rewrite of the full extinction countdown."""
from music_cue import Cue
from music_linear import render_linear

NAME='Extinction-Protocol-The-Last-Light-Meteor-Score-v3'
cue=Cue(NAME,120,105,
    {0:('first-violins',48,104,37,39),1:('second-violins',49,77,48,37),
     2:('violas',48,74,68,35),3:('cellos',42,87,82,35),4:('basses',43,90,76,31),
     5:('horns',60,86,64,39),6:('trombones',57,69,73,37),7:('choir',52,69,58,45),
     8:('timpani',47,100,56,33),9:('symphonic-percussion',0,84,63,33),
     10:('harp',46,70,80,37),11:('moving-strings',44,81,40,34),12:('trumpets',56,72,67,40)},
    {'title':'The Last Light — symphonic revision','intent':{'role':'Extinction Engine final boss, 210-second non-looping countdown',
      'emotion':'Dread, grief, defiance and overwhelming scale','focus':'A long, singing string theme with an independent lower reply',
      'borrow':'Elden Ring boss score reference: dark symphonic gravity, lamenting string lines, choral scale and earned orchestral surges; original notes.'},
     'duration_seconds':210,'loop':False,
     'material':{'motif':'D A Bb A G F E','character':'A broad ascent resolving into a descending lament','stated_in':'Opening string statement'},
     'form':[{'seconds':[0,30],'development':'augment','purpose':'Strings establish the lament with sparse timpani; intimate threat'},
             {'seconds':[30,60],'development':'extend','purpose':'Moving strings and independent cello answer'},
             {'seconds':[60,90],'development':'vary','purpose':'Choral confrontation; horns speak only at thematic arrivals'},
             {'seconds':[90,120],'development':'fragment','purpose':'Withdraw choir, brass and drums; exposed cello and divided strings'},
             {'seconds':[120,150],'development':'sequence','purpose':'Rising register and suspended harmony rebuild tension'},
             {'seconds':[150,180],'development':'recap','purpose':'Full string theme with choir and low brass at final-minute warning'},
             {'seconds':[180,195],'development':'contract','purpose':'Compressed lament and urgent moving strings'},
             {'seconds':[195,210],'development':'fragment','purpose':'Highest-register defiance against extinction, unresolved final dominant'}],
     'harmony':'Minor tonic and plagal movement; bII Phrygian tension; dominant major with Csharp only late in the arc.',
     'harmony_letters':'Dm Bb Gm Am / Bb F Gm A / Gm Eb Dm Am / Dm C Bb Eb A',
     'counterpoint':'Violin holds long notes while cello moves; cello rises against descending violin; entries and melodic peaks are staggered.',
     'roster':'Divided first/second violins, violas, cellos, basses; horns and low brass, choir, harp, moving strings and symphonic percussion.',
     'energy_curve':[.37,.57,.76,.27,.64,.91,.87,1],
     'subtraction_events':'90-120 seconds: brass, choir, rhythmic string figure and regular drum pulse withdraw; cello becomes the emotional foreground.',
     'mix_intent':'Strings lead throughout, with brass replying at phrase boundaries. Wider orchestral stage, choir at depth, timpani carries weight. No tribal woodblock, hi-hat grid, wind or breathing noise.',
     'change_from_v2':'Stronger rolling string rhythm, brass call-and-response and broader choir; reference is the user-supplied Dancing Lion recording, used for energy rather than its notes.',
     'change_from_v1':'New long-form melody, divided strings and cello countermelody; replaced repeated small brass gestures and tribal percussion with symphonic phrasing and deliberate entrances.',
     'timing_contract':'Same 210-second game clock; 150-second warning and 195-second final pressure. Pause with simulation; early victory/death cuts to result cue. Preview only.'})

dm=(38,53,57);bb=(34,53,58);gm=(43,55,58);am=(33,52,57);eb=(39,55,58);fm=(41,53,57);cm=(36,52,55);a_major=(33,52,61)
patterns=[[dm,dm,bb,bb,gm,gm,am,am], [dm,dm,bb,fm,gm,gm,am,am],
          [bb,bb,fm,fm,gm,gm,a_major,a_major], [gm,gm,eb,eb,dm,dm,am,am],
          [dm,bb,fm,gm,eb,gm,a_major,a_major], [dm,dm,bb,bb,gm,eb,a_major,a_major],
          [dm,cm,bb,eb], [gm,eb,a_major,a_major]]
borders=[0,60,120,180,240,300,360,390,420]
def sec(t):
    for i in range(8):
        if borders[i]<=t<borders[i+1]:return i
    return 7
def chord(t):
    s=sec(t);return patterns[s][int((t-borders[s])//4)%len(patterns[s])]
lament=[(0,74,3.94,70),(4,81,1.94,77),(6,82,1.94,80),(8,81,3.94,76),
        (12,79,1.94,72),(14,77,1.94,68),(16,76,3.94,67),(20,77,1.94,69),
        (22,79,1.94,74),(24,81,2.94,78),(27,79,.94,73),(28,77,1.94,69),(30,76,1.8,65)]
answer=[(0,72,3.94,67),(4,77,1.94,73),(6,79,1.94,76),(8,77,3.94,71),
        (12,76,1.94,68),(14,74,1.94,64),(16,70,3.94,65),(20,72,1.94,67),
        (22,74,1.94,71),(24,77,2.94,76),(27,76,.94,69),(28,74,1.94,65),(30,73,1.8,63)]
counter=[(0,50,5.88,54),(6,53,1.88,57),(8,55,1.88,59),(10,57,3.88,62),
         (14,58,1.88,64),(16,57,3.88,59),(20,55,1.88,57),(22,53,1.88,55),
         (24,52,3.88,54),(28,50,3.75,52)]

def line(ch,start,length,notes,strength=1,shift=0):
    for p,n,d,v in notes:
        if p>=length:break
        dur=min(d,length-p-.025)
        if dur>.04:cue.note(ch,start+p,n+shift,dur,round(v*strength))
    # Bow-shaped expression progresses over the musical phrase instead of fixed attacks.
    for frac,value in [(0,61),(.18,76),(.35,94),(.54,86),(.72,99),(.88,83),(.99,65)]:
        cue.cc(ch,start+length*frac,11,value)

for section in range(8):
    begin,end=borders[section:section+2]
    for index,start in enumerate(range(begin,end,32)):
        length=min(32,end-start)
        ph=lament if index%2==0 else answer
        if section==3:
            line(3,start,length,ph,.82,-24)
            line(0,start,length,[(0,77,5.8,48),(6,76,1.8,46),(8,74,7.8,49),(16,72,5.8,45),(22,70,1.8,43),(24,69,7.7,46)],.95)
        else:
            line(0,start,length,ph,1.03 if section>=5 else .92 if section==0 else 1)
            line(3,start,length,counter,1.12 if section>=5 else 1)
            if section in (1,2,4,5,6,7):
                lower_reply=[(0,65,7.8,53),(8,64,5.8,50),(14,65,1.8,52),(16,67,5.8,57),
                             (22,69,1.8,59),(24,70,3.8,58),(28,69,3.7,54)]
                line(1,start,length,lower_reply,.95 if section<5 else 1.12)
            if section in (2,5,6,7):
                # Horn arrivals occupy rests and long string notes, not every melody onset.
                horn=[(0,62,5.75,62),(8,65,3.75,65),(16,67,3.75,65),(24,69,5.75,70)]
                line(5,start,length,horn,1.13 if section>=5 else .94)
            if section==7:
                line(12,start,length,[(0,81,3.8,70),(4,82,3.8,75),(8,81,3.8,74),(12,79,3.8,69),
                                      (16,77,3.8,72),(20,76,3.8,70),(24,81,5.7,80)])

for bar in range(105):
    t=bar*4;s=sec(t);root,a,b=chord(t);quiet=s in (0,3);full=s>=5
    cue.note(4,t+.02,root,3.88,47 if quiet else 65 if full else 56)
    cue.note(2,t+.055,a,3.83,38 if quiet else 47)
    cue.note(2,t+.078,b,3.8,33 if quiet else 42)
    if s in (2,4,5,6,7):
        for n,v in [(a+12,45),(b+12,40)]:cue.note(7,t+.06,n,3.81,v+(8 if full else 0))
    if s in (2,5,6,7) and bar%2==0:
        cue.note(6,t+.08,root+12,3.72,57)
    if s in (1,2,4,5,6,7):
        positions=[0,2/3,1,5/3,2,8/3,3,11/3] if s<5 else [i/3 for i in range(12)]
        if s==7:positions=[i*.25 for i in range(16)]
        for j,p in enumerate(positions):
            n=[a+12,b+12,a+19,b+12][j%4]
            cue.note(11,t+p+.01,n,min(.23,3.94-p),47+(7 if full else 0)+(4 if j%4==0 else 0))
    if s in (0,3):
        if bar%4==0:cue.note(10,t+.15,a+12,1.4,44)
        if s==0 and bar in (0,8):cue.note(8,t,root+12,1.2,65)
        continue
    # Timpani and bass-drum punctuation with cymbal rises; no continuous drum kit groove.
    for p,n,v in [(0,root+12,76 if full else 63),(1.5,root+19,53 if full else 44),(2.5,root+12,65 if full else 52)]:
        cue.note(8,t+p,n,.65,v)
    if bar%2==0:cue.note(9,t,36,.3,79 if full else 62)
    if full:cue.note(9,t+2.5,36,.25,65)
    if bar%8==7 or s==7:
        for j in range(6):cue.note(9,t+2.5+j*.2,38,.09,27+j*4)
    if bar in (15,30,60,75,90,98):cue.note(9,t,49,1.3,65 if full else 48)
    if s in (1,4) and bar%2==1:
        for j,p in enumerate([0,.5,1,1.5]):cue.note(10,t+p,a+12+[0,4,7,12][j],.4,41+j*2)

# Countdown cues are exact, including the half-bar final-fifteen-second marker.
cue.note(9,390,49,1.5,76)
cue.note(6,390,45,3.5,65)
cue.note(10,300,86,1.3,62)

if __name__=='__main__':render_linear(cue,NAME)
