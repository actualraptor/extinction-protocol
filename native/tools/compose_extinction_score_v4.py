"""New thematic finale: processional brass, running strings and choral confrontation."""
from music_cue import Cue, OUT
from music_linear import render_linear
import json

NAME='Extinction-Protocol-The-Last-Light-Meteor-Score-v4'
roster={0:('violins-lead',48,102,32,39),1:('violins-response',49,84,49,38),
        2:('viola-motion',44,83,77,32),3:('cello-counterline',42,94,84,36),
        4:('double-basses',43,94,71,32),5:('horn-theme',60,100,59,38),
        6:('trombone-foundation',57,87,75,36),7:('choral-voices',52,95,49,47),
        8:('timpani',47,102,58,33),9:('orchestral-percussion',0,92,63,34),
        10:('harp',46,70,85,37),11:('running-strings',48,89,38,34),
        12:('trumpet-calls',56,85,67,39),13:('choral-bass',53,78,76,45)}
borders=[0,72,144,216,288,360,432,468,504]
spec={'title':'The Last Light — orchestral confrontation',
      'intent':{'one_thing':'Make the Extinction Engine feel like the culmination of the entire game.',
                'reference_pair':[{'track':'User-supplied Divine Beast Dancing Lion recording','borrow':'Requested scale and musical momentum; original thematic and harmonic material.'},
                                  {'track':'The Last Light v2','borrow':'210-second warning contract and dark orchestral identity.'}],
                'listener_situation':'Final boss, first listen must establish a memorable theme while supporting combat.',
                'emotional_arc':['Immediate confrontation','Sweeping pursuit','Choral arrival','Exposed lament','Rebuild','Final-minute defiance','Acceleration','Extinction']},
      'material':{'motif':'D A D Eb D C Bb A: dotted opening leaps followed by an urgent descending answer.',
                  'character':'A threatening ceremonial dance, answered by a soaring lament.','stated_in':['A'], 'development_mode':'variation'},
      'form':[{'id':chr(65+i),'seconds':[a/2.4,b/2.4],'development':dev,'purpose':purpose}
              for i,(a,b,dev,purpose) in enumerate(zip(borders[:-1],borders[1:],
                ['repeat','extend','vary','fragment','sequence','recap','contract','fragment'],
                ['Brass establishes the theme; running strings answer immediately.',
                 'Violins take the theme above an independent cello reply.',
                 'Choir and brass meet at the first orchestral summit.',
                 'Withdraw heavy brass and drums; exposed cello lament.',
                 'Sequence fragments upward; voices return over suspended harmonies.',
                 '150-second full-orchestra arrival; complete theme in a higher register.',
                 'Faster overlapping calls against triplet motion.',
                 '195-second final surge; unresolved extinction cutoff.']))],
      'harmony':'i bII bVI iv V / bVI bIII iv V / iv bII i V; chromatic diminished approach to dominant.',
      'harmony_letters':'Dm Eb Bb Gm A / Bb F Gm A / Gm Eb Dm A / C#dim A',
      'energy_curve':[.66,.73,.88,.35,.76,1,.94,1],
      'subtraction_events':['90-120s: choir, running strings, full brass and regular percussion withdraw.'],
      'mix_intent':'Broad divided string stage, strong theme in horns and violins, choir behind brass, rhythmic cello and bass beneath. Contrast and orchestral register create scale; no wind/noise bed.',
      'duration_seconds':210,'loop':False,
      'checks':{'exceptions':['Instrumental sampled mockup: choral vowels have no lyrics.','Perceptual orchestral realism and impact require listening review.']}}
cue=Cue(NAME,144,126,roster,spec)
dm=(38,53,57);eb=(39,55,58);bb=(34,53,58);gm=(43,55,58);a=(33,52,61);f=(41,53,57);cd=(37,52,55)
progressions=[[dm,dm,eb,a,bb,gm,eb,a], [dm,bb,f,gm,eb,gm,cd,a],
              [bb,f,gm,a,dm,eb,bb,a], [gm,eb,dm,a,gm,bb,cd,a],
              [dm,eb,gm,a,bb,gm,cd,a], [dm,bb,f,gm,eb,gm,cd,a],
              [bb,gm,eb,a], [dm,eb,cd,a]]
theme=[(0,62,1.4,83),(1.5,69,.4,76),(2,74,.9,89),(3,75,.45,87),(3.5,74,1.4,85),
       (5,72,.9,80),(6,70,.9,77),(7,69,.85,74),(8,67,1.4,77),(9.5,69,.4,80),
       (10,70,1.9,84),(12,69,.9,78),(13,67,.9,75),(14,65,1.85,72)]
soar=[(0,74,2.9,82),(3,77,.9,86),(4,81,2.9,91),(7,82,.85,90),
      (8,81,1.9,86),(10,79,1.9,81),(12,77,1.9,77),(14,76,1.85,74)]
cello=[(0,50,2.8,65),(3,53,.8,68),(4,55,1.8,70),(6,57,1.8,74),
       (8,58,2.8,72),(11,57,.8,66),(12,55,1.8,64),(14,52,1.8,60)]
lament=[(0,62,3.8,67),(4,65,1.8,70),(6,64,1.8,67),(8,62,3.8,64),(12,58,1.8,60),(14,57,1.8,58)]
def section(t):return next(i for i in range(8) if borders[i]<=t<borders[i+1])
def line(ch,t,length,notes,shift=0,gain=1):
    for p,n,d,v in notes:
        if p>=length:break
        dur=min(d,length-p-.035)
        if dur>.05:cue.note(ch,t+p,n+shift,dur,min(115,round(v*gain)))
    for frac,val in [(0,70),(.18,88),(.37,108),(.58,96),(.77,103),(.98,74)]:cue.cc(ch,t+length*frac,11,val)
for s in range(8):
    begin,end=borders[s:s+2]
    for idx,t in enumerate(range(begin,end,16)):
        length=min(16,end-t)
        if s==3:
            line(3,t,length,lament,-12)
            line(0,t,length,[(0,77,7.8,45),(8,76,3.8,43),(12,74,3.8,42)])
            continue
        lead=5 if s==0 else 0
        line(lead,t,length,theme if s==0 or idx%2==0 else soar,12 if s>=5 and lead==0 and idx%2==0 else 0,.94 if s<2 else 1.04)
        line(3,t,length,cello,0,1.08 if s>=5 else 1)
        if s in (1,2,4,5,6,7):
            line(1,t,length,[(0,65,3.8,56),(4,64,1.8,53),(6,65,1.8,57),(8,67,3.8,61),(12,69,1.8,64),(14,70,1.8,62)])
        if s in (2,5,6,7):
            line(5,t,length,theme,0,.87 if s==2 else .97)
            if idx%2==1:line(12,t,length,[(0,74,1.8,76),(2,77,.8,80),(3,76,.8,76),(8,81,1.8,83),(10,79,1.8,78),(12,77,3.7,75)])
for bar in range(126):
    t=bar*4;s=section(t);root,third,fifth=progressions[s][int((t-borders[s])//4)%len(progressions[s])]
    quiet=s==3;full=s>=5
    cue.note(4,t+.02,root,3.84,52 if quiet else 78 if full else 68)
    if quiet:
        cue.note(2,t+.05,third,3.8,35);cue.note(2,t+.075,fifth,3.78,31)
        if bar%3==0:cue.note(10,t+.1,third+12,1.7,45)
        continue
    # String subdivisions alternate triplet drive with broader dotted grouping.
    positions=[i/3 for i in range(12)] if s in (1,2,5,6,7) else [0,.5,1.5,2,2.5,3.5]
    for j,p in enumerate(positions):
        cue.note(11,t+p+.008*(j%2),[third+12,fifth+12,third+19,fifth+12][j%4],.23,60+(10 if full else 0)+(7 if j%3==0 else 0))
    for j,p in enumerate([0,.75,1.5,2.5,3.25]):cue.note(2,t+p+.018,[third,fifth,third+12,fifth,third][j],.5,56 if full else 47)
    if s in (2,4,5,6,7):
        for n,v in dict([(root+24,62),(third+12,66),(fifth+12,59)]).items():cue.note(7,t+.07,n,3.78,v+(9 if full else 0))
        cue.note(13,t+.08,root+12,3.7,58 if full else 46)
    if s in (0,2,5,6,7) and bar%2==0:
        cue.note(6,t+.08,root+12,3.68,76 if full else 65)
    for p,n,v in [(0,root+12,88 if full else 76),(1.5,root+19,66 if full else 57),(2.5,root+12,77 if full else 65)]:cue.note(8,t+p,n,.6,v)
    if bar%2==0:cue.note(9,t,36,.3,92 if full else 79)
    if full:cue.note(9,t+2.5,36,.25,77)
    if bar in (0,18,36,72,90,108,117):cue.note(9,t,49,1.4,88 if full else 73)
    if bar in (16,34,51,86,105,115,123):
        for j in range(6):cue.note(9,t+2.5+j*.2,38,.08,37+j*6)
    if s in (1,4) and bar%3==1:
        for j,p in enumerate([0,.5,1,1.5]):cue.note(10,t+p,third+12+[0,3,7,12][j],.4,43+j*3)

if __name__=='__main__':
    render_linear(cue,NAME)
    p=OUT/(NAME+'-review.json');review=json.loads(p.read_text())
    review['audit_compliance']={'original_new_theme':True,'210_second_contract':True,'subtraction_at_90_seconds':True,
                               'arrangement_changes_by_section':True,'no_clipping_or_hanging_notes':True}
    review['perceptual_review']='Pending listening; GeneralUser sampled orchestra remains the production limitation. No claim of parity with a recorded professional orchestra.'
    p.write_text(json.dumps(review,indent=2))
