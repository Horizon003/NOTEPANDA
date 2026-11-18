import {test} from 'node:test';
import assert from 'node:assert/strict';
import {fixture} from './sqlite.js';
import {claimReward,rewardState,rewardPulse,calendarEvents} from '../src/rewards.js';
const at=day=>Date.parse(`2026-11-${String(day).padStart(2,'0')}T08:00:00Z`);
test('daily claims, weekly bonus and milestone are idempotent; missed days reset only current streak',async()=>{
 const {db}=fixture();
 for(let day=1;day<=7;day++){await claimReward(db,'a',{kind:'daily',day:`2026-11-0${day}`},at(day));await claimReward(db,'a',{kind:'daily',day:`2026-11-0${day}`},at(day));}
 let s=await rewardState(db,'a',at(7));assert.equal(s.points,900);assert.equal(s.streak,7);
 await claimReward(db,'a',{kind:'achievement',day:s.today,milestone:5},at(7));
 s=await claimReward(db,'a',{kind:'achievement',day:s.today,milestone:5},at(7));assert.equal(s.points,950);
 await assert.rejects(claimReward(db,'a',{kind:'achievement',day:s.today,milestone:14},at(7)));
 assert.equal((await rewardState(db,'a',at(9))).streak,0);assert.equal((await rewardState(db,'a',at(9))).bestStreak,7);
 assert.equal((await rewardState(db,'b',at(7))).points,0);
 await assert.rejects(claimReward(db,'a',{kind:'daily',day:s.today},at(8)));
});
test('server-timed reward study, paused time and competing devices',async()=>{
 const {db}=fixture(),session='a'.repeat(32), t=at(1);
 await rewardPulse(db,'a',{session,action:'start'},t);
 for(let i=1;i<=240;i++)await rewardPulse(db,'a',{session,action:'heartbeat'},t+i*15000);
 assert.equal((await rewardState(db,'a',t+3600000)).studyPoints,100);
 await assert.rejects(rewardPulse(db,'a',{session:'b'.repeat(32),action:'start'},t+3600001));
 await rewardPulse(db,'a',{session,action:'pause'},t+3600000);
 await rewardPulse(db,'a',{session,action:'start'},t+7200000);
 assert.equal((await rewardState(db,'a',t+7200000)).studyPoints,100);
});
test('calendar is account scoped, upserts and deletes safely',async()=>{
 const {db}=fixture();const event={id:'e1',title:'Pharmacology exam',day:'2026-11-23',at:'2026-11-23T09:00:00+05:00',kind:'Exam',color:0xffd75454,leadMinutes:30};
 await calendarEvents(db,'a',{action:'save',event});assert.equal((await calendarEvents(db,'b',{action:'read'})).events.length,0);
 await calendarEvents(db,'a',{action:'save',event:{...event,title:'Updated'}});
 assert.equal((await calendarEvents(db,'a',{action:'read'})).events[0].title,'Updated');
 await calendarEvents(db,'a',{action:'delete',id:'e1'});assert.equal((await calendarEvents(db,'a',{action:'read'})).events.length,0);
});

test('parallel daily claims credit exactly once and invalid calendar dates are rejected',async()=>{
 const {db}=fixture();
 await Promise.all(Array.from({length:8},()=>claimReward(db,'a',{kind:'daily',day:'2026-11-01'},at(1))));
 assert.equal((await rewardState(db,'a',at(1))).points,100);
 await assert.rejects(calendarEvents(db,'a',{action:'save',event:{id:'bad',title:'Exam',day:'2026-02-31',at:'2026-03-03T09:00:00Z',color:0xffd46a61,kind:'Exam',leadMinutes:30}}));
});
