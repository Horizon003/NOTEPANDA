import scoring from '../../backend/functions/scoring.js';
const {dayAt, leaseDelta} = scoring;
export const milestones = [5, 7, 14, 30, 60, 100];
const fail = (message, status=400) => Object.assign(new Error(message), {status});
const previous = day => new Date(Date.parse(day+'T12:00:00Z')-86400000).toISOString().slice(0,10);
export function streakCount(days, today) {
  const set = new Set(days);
  let day = set.has(today) ? today : previous(today), count = 0;
  while (set.has(day)) {count++; day=previous(day);}
  return count;
}
export async function rewardState(db, uid, now=Date.now()) {
  const claims = (await db.prepare('SELECT day FROM reward_claims WHERE uid=? ORDER BY day').bind(uid).all()).results.map(r=>r.day);
  const badges = (await db.prepare("SELECT reward_key FROM reward_ledger WHERE uid=? AND kind='achievement'").bind(uid).all()).results.map(r=>Number(r.reward_key.split(':')[1]));
  const row = await db.prepare('SELECT COALESCE(SUM(points),0) AS points FROM reward_ledger WHERE uid=?').bind(uid).first();
  const time = await db.prepare('SELECT COALESCE(SUM(seconds),0) AS seconds FROM reward_days WHERE uid=?').bind(uid).first();
  // A verified second never gets spent twice; fractional hours carry forward.
  const studyPoints = Math.floor((time?.seconds||0)*100/3600);
  let best=0, count=0, last=null;
  for (const day of claims) {count=last===previous(day)?count+1:1;best=Math.max(best,count);last=day;}
  const today = dayAt(now);
  return {today, updatedAt:now, points: (row?.points||0)+studyPoints, studyPoints, studySeconds:time?.seconds||0,
    claimedDays:claims, claimedMilestones:badges, streak:streakCount(claims,today), bestStreak:best,
    todayClaimed:claims.includes(today), timezone:'Asia/Karachi'};
}
export async function claimReward(db, uid, data, now=Date.now()) {
  const today = dayAt(now);
  if(data.day!==today) throw fail('This claim belongs to another day. Refresh and claim today.',409);
  if(data.kind==='daily') {
    // UNIQUE(uid,day) plus the ledger key make retries and concurrent devices idempotent.
    await db.batch([
      db.prepare('INSERT OR IGNORE INTO reward_claims(uid,day) VALUES(?,?)').bind(uid,today),
      db.prepare("INSERT OR IGNORE INTO reward_ledger(uid,reward_key,kind,points,created_at) VALUES(?,?,'daily',100,?)").bind(uid,`daily:${today}`,now)
    ]);
    const state = await rewardState(db,uid,now);
    // Derive every completed week from immutable claims, including a retry that
    // follows a lost response between daily credit and weekly bonus credit.
    let length=0, last=null;
    const bonuses=[];
    for (const day of state.claimedDays) {
      length=last===previous(day)?length+1:1;last=day;
      if(length%7===0)bonuses.push(db.prepare("INSERT OR IGNORE INTO reward_ledger(uid,reward_key,kind,points,created_at) VALUES(?,?,'weekly',200,?)").bind(uid,`weekly:${day}`,now));
    }
    if(bonuses.length)await db.batch(bonuses);
  } else if(data.kind==='achievement') {
    const days=Number(data.milestone);
    if(!milestones.includes(days))throw fail('Unknown achievement.');
    const state=await rewardState(db,uid,now);
    if(state.bestStreak<days)throw fail('Keep claiming daily to unlock this achievement.',409);
    await db.prepare("INSERT OR IGNORE INTO reward_ledger(uid,reward_key,kind,points,created_at) VALUES(?,?,'achievement',50,?)").bind(uid,`achievement:${days}`,now).run();
  } else throw fail('Unknown claim.');
  return rewardState(db,uid,now);
}
export async function rewardPulse(db,uid,data,now=Date.now()) {
  const {session,action}=data;
  if(!/^[a-f0-9]{32}$/.test(session)||!['start','heartbeat','pause','stop'].includes(action))throw fail('Invalid session action.');
  await db.prepare("INSERT OR IGNORE INTO reward_leases(uid,session,last,active,version,operation) VALUES(?,?,0,0,0,'')").bind(uid,session).run();
  const lease=await db.prepare('SELECT * FROM reward_leases WHERE uid=?').bind(uid).first();
  if(lease.active&&lease.session!==session&&now-lease.last<30000)throw fail('Another device is already tracking study time.',409);
  if(action!=='start'&&lease.session!==session)throw fail('Start this session first.',409);
  const day=dayAt(now);
  const delta=lease.active&&lease.session===session&&dayAt(lease.last)===day?leaseDelta(lease.last,now):0;
  const op=crypto.randomUUID();
  const results=await db.batch([
    db.prepare('UPDATE reward_leases SET session=?,last=?,active=?,version=version+1,operation=? WHERE uid=? AND version=?').bind(session,now,['start','heartbeat'].includes(action)?1:0,op,uid,lease.version),
    db.prepare('INSERT INTO reward_days(uid,day,seconds) SELECT ?,?,? WHERE EXISTS(SELECT 1 FROM reward_leases WHERE uid=? AND operation=?) ON CONFLICT(uid,day) DO UPDATE SET seconds=reward_days.seconds+excluded.seconds').bind(uid,day,delta,uid,op)
  ]);
  if(!results[0].meta.changes)throw fail('Session changed. Retry.',409);
  return rewardState(db,uid,now);
}
export async function calendarEvents(db,uid,data,now=Date.now()) {
  if(data.action==='save') {
    const e=data.event;
    if(!e||!/^[a-zA-Z0-9_-]{1,80}$/.test(e.id)||typeof e.title!=='string'||!e.title.trim()||e.title.length>120||!/^\d{4}-\d{2}-\d{2}$/.test(e.day)||!Number.isFinite(Date.parse(e.day+'T12:00:00Z'))||!Number.isInteger(e.color)||e.color<0||e.color>0xffffffff||!['Test','Exam','Event'].includes(e.kind)||!Number.isFinite(Date.parse(e.at))||!Number.isInteger(e.leadMinutes)||e.leadMinutes<0||e.leadMinutes>10080)throw fail('Invalid calendar event.');
    await db.prepare('INSERT INTO calendar_events(uid,id,payload,updated_at) VALUES(?,?,?,?) ON CONFLICT(uid,id) DO UPDATE SET payload=excluded.payload,updated_at=excluded.updated_at').bind(uid,e.id,JSON.stringify(e),now).run();
  } else if(data.action==='delete') {
    if(typeof data.id!=='string')throw fail('Missing event.');
    await db.prepare('DELETE FROM calendar_events WHERE uid=? AND id=?').bind(uid,data.id).run();
  } else if(data.action!=='read')throw fail('Unknown calendar action.');
  return {events:(await db.prepare('SELECT payload FROM calendar_events WHERE uid=? ORDER BY updated_at DESC LIMIT 1000').bind(uid).all()).results.map(r=>JSON.parse(r.payload))};
}
