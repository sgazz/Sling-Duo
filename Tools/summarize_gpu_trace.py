from pathlib import Path
from xml.etree import ElementTree as ET
from collections import defaultdict
import csv,json,statistics,sys,bisect
from datetime import datetime

class Table:
 def __init__(self,path):
  self.root=ET.parse(path).getroot();self.ids={e.attrib['id']:e for e in self.root.iter() if 'id'in e.attrib}
 def resolve(self,e):
  while 'ref'in e.attrib:e=self.ids[e.attrib['ref']]
  return e
 def value(self,e):
  e=self.resolve(e);return e.text
 def label(self,e):
  e=self.resolve(e);return e.attrib.get('fmt',e.text) or ''
 def rows(self):return self.root.findall('.//row')

def union_ns(intervals):
 if not intervals:return 0
 intervals=sorted(intervals);start,end=intervals[0];total=0
 for a,b in intervals[1:]:
  if a<=end:end=max(end,b)
  else:total+=end-start;start,end=a,b
 return total+end-start

def percentile(values,q):
 if not values:return None
 s=sorted(values);return s[int((len(s)-1)*q)]

if len(sys.argv)!=5:
 raise SystemExit('Usage: summarize_gpu_trace.py VARIANT XML_PREFIX PHASES_CSV OUTPUT_DIRECTORY')

variant=sys.argv[1];prefix=Path(sys.argv[2]);cpu=Path(sys.argv[3]);out=Path(sys.argv[4]);out.mkdir(exist_ok=True,parents=True)
gpu=Table(str(prefix)+'-gpu.xml')
cpu_rows=list(csv.DictReader(cpu.open()))
phase_durations={r['phase']:float(r['wall_seconds']) for r in cpu_rows}
events={}
alignment='signposts'
clock_drift_seconds=0.0
if cpu_rows and 'phase_start_unix_seconds' in cpu_rows[0]:
 alignment='CSV UTC phase clock aligned to trace start-date'
 toc=ET.parse(str(prefix)+'-toc.xml')
 epoch=datetime.fromisoformat(toc.findtext('.//summary/start-date')).timestamp()
 origin_unix=float(cpu_rows[0]['phase_start_unix_seconds'])
 origin_mono=float(cpu_rows[0]['phase_start_monotonic_seconds'])
 for row in cpu_rows:
  unix=float(row['phase_start_unix_seconds']);mono=float(row['phase_start_monotonic_seconds'])
  clock_drift_seconds=max(clock_drift_seconds,abs((unix-origin_unix)-(mono-origin_mono)))
  if row['phase'].startswith('round0-'):
   events[(round((unix-epoch)*1e9),row['phase'])]=1
 if clock_drift_seconds>0.002:
  raise SystemExit(f'Clock instability exceeds 2ms: {clock_drift_seconds}s')
else:
 signposts=Table(str(prefix)+'-signposts.xml')
 for row in signposts.rows():
  if signposts.label(row[6])!='GraphicsPhase':continue
  phase=signposts.label(row[11])
  if phase.startswith('round0-') and phase in phase_durations:events[(int(signposts.value(row[0])),phase)]=1
phases=sorted(events)
if len(phases)!=27:raise SystemExit(f'Expected all 27 first-round phase markers, found {len(phases)}')
starts=[t for t,p in phases]
phase_frames=defaultdict(list);phase_intervals=defaultdict(list);frames=defaultdict(list);app_rows=0
for row in gpu.rows():
 if not gpu.label(row[10]).startswith('Sling Duo (') or gpu.label(row[7])!='Active':continue
 a=int(gpu.value(row[0]));b=a+int(gpu.value(row[1]));app_rows+=1
 i=max(0,bisect.bisect_right(starts,a)-1)
 while i<len(phases) and phases[i][0]<b:
  t,phase=phases[i];end=t+round(phase_durations[phase]*1e9)
  left,right=max(a,t),min(b,end)
  if left<right:phase_intervals[phase].append((left,right))
  i+=1
 # SpriteKit render commands only; exclude compositor and unlabeled uploads.
 frame=gpu.value(row[3])
 if frame is not None and gpu.label(row[6]).startswith('SpriteKit Render:'):
  frames[frame].append((a,b))
for frame,intervals in frames.items():
 a=min(x[0] for x in intervals);b=max(x[1] for x in intervals);i=bisect.bisect_right(starts,a)-1
 if i<0:continue
 t,phase=phases[i];end=t+round(phase_durations[phase]*1e9)
 if b<=end:phase_frames[phase].append(union_ns(intervals)/1e6)
rows=[]
for t,phase in phases:
 samples=phase_frames[phase]
 if len(samples)<10:raise SystemExit(f'Insufficient GPU coverage: {phase}: {len(samples)} frames')
 rows.append(dict(variant=variant,phase=phase,trace_phase_start_seconds=round(t/1e9,6),phase_seconds=phase_durations[phase],spritekit_gpu_frames=len(samples),spritekit_gpu_active_median_ms=round(statistics.median(samples),6),spritekit_gpu_active_p95_ms=round(percentile(samples,.95),6),app_gpu_active_percent=round(union_ns(phase_intervals[phase])/(phase_durations[phase]*1e9)*100,4)))
with (out/(variant+'-gpu-by-phase.csv')).open('w') as f:
 w=csv.DictWriter(f,fieldnames=rows[0],lineterminator="\n");w.writeheader();w.writerows(rows)
summary={}
for kind in ['idle','aim','turbo']:
 sample=[v for phase,values in phase_frames.items() if phase.endswith('-'+kind) for v in values]
 selected=[r for r in rows if r['phase'].endswith('-'+kind)]
 summary[kind]=dict(spritekit_gpu_frames=len(sample),median_active_ms=statistics.median(sample),p95_active_ms=percentile(sample,.95),median_app_gpu_active_percent=statistics.median(r['app_gpu_active_percent'] for r in selected))
result=dict(variant=variant,alignment=alignment,clock_drift_seconds=clock_drift_seconds,caves=9,phases=27,app_gpu_event_rows=app_rows,metric='Union of Active SpriteKit GPU execution intervals per frame; CPU-to-GPU wait/latency excluded; compositor filtered by process',phase_summary=summary)
(out/(variant+'-gpu-summary.json')).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
