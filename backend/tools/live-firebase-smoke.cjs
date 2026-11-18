// Opt-in production smoke test. Uses two isolated temporary users and removes
// all their data in finally. Never touches student records or settings trees.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {randomUUID}=require('node:crypto');
const adminApp=require('../functions/node_modules/firebase-admin/app');
const {getAuth}=require('../functions/node_modules/firebase-admin/auth');
const {getFirestore}=require('../functions/node_modules/firebase-admin/firestore');
const {initializeApp,deleteApp}=require('../functions/node_modules/firebase/app');
const {getAuth:clientAuth,signInWithCustomToken,signOut}=require('../functions/node_modules/firebase/auth');
const {getFirestore:clientDb,doc,setDoc,getDocFromServer,updateDoc,deleteDoc,writeBatch,serverTimestamp}=require('../functions/node_modules/firebase/firestore');
const projectId='pharmawhisper-debd2';
const day=ms=>Math.floor((ms+18000000)/86400000);
(async()=>{
 if(process.env.HYZEN_LIVE_FIREBASE_CHECK!=='yes')throw Error('Explicit live-check opt-in is required.');
 const source=fs.readFileSync('hyzen_flutter/lib/core/firebase/firebase_options.dart','utf8').split('FirebaseOptions web = FirebaseOptions(')[1].split(');')[0];
 const config={projectId,apiKey:source.match(/apiKey:\s*'([^']+)'/)[1],appId:source.match(/appId:\s*'([^']+)'/)[1]};
 const admin=adminApp.initializeApp({credential:adminApp.applicationDefault(),projectId});
 const auth=getAuth(admin),db=getFirestore(admin),prefix='hyzen-ci-smoke-'+randomUUID(),uids=[prefix+'-a',prefix+'-b'],apps=[];
 const checks=[];
 const denied=promise=>assert.rejects(promise,e=>e.code==='permission-denied');
 try {
  for(const uid of uids){
   const app=initializeApp(config,uid);apps.push(app);
   await signInWithCustomToken(clientAuth(app),await auth.createCustomToken(uid));
  }
  const a=clientDb(apps[0]),b=clientDb(apps[1]),uid=uids[0];
  const clock=doc(a,`studyUsers/${uid}/state/clock`);
  await setDoc(clock,{at:serverTimestamp()});
  const at=(await getDocFromServer(clock)).data().at,today=day(at.toMillis());
  const wallet=doc(a,`studyUsers/${uid}/state/wallet`);
  await setDoc(wallet,{points:100,lastDay:today,streak:1,best:1,days:[today],badges:[],action:'daily',milestone:0,updatedAt:serverTimestamp()});
  assert.equal((await getDocFromServer(wallet)).data().points,100);checks.push('authenticated daily claim persisted');
  await denied(updateDoc(wallet,{points:200,updatedAt:serverTimestamp()}));checks.push('double credit denied');
  await denied(getDocFromServer(doc(b,`studyUsers/${uid}/state/wallet`)));checks.push('cross-account wallet read denied');
  const event=doc(a,`studyUsers/${uid}/calendar/smoke`);
  const date=new Date(today*86400000).toISOString().slice(0,10);
  await setDoc(event,{title:'Temporary CI check',at:new Date().toISOString(),day:date,color:0xffd46a61,kind:'Test',leadMinutes:30,updatedAt:serverTimestamp()});
  assert.equal((await getDocFromServer(event)).data().title,'Temporary CI check');
  await denied(getDocFromServer(doc(b,`studyUsers/${uid}/calendar/smoke`)));
  await deleteDoc(event);assert.equal((await getDocFromServer(event)).exists(),false);checks.push('calendar round trip and privacy');
  const pulse=doc(a,`studyUsers/${uid}/state/activity`),session=randomUUID().replaceAll('-','');
  await setDoc(pulse,{version:1,session,active:true,closed:false,at:serverTimestamp(),previousAt:serverTimestamp(),previousActive:false,previousSession:session,totalMs:0,sessionMs:0,deltaMs:0,creditDay:0,creditYear:0,completion:0,academicYear:0});
  let old=(await getDocFromServer(pulse)).data();
  await new Promise(r=>setTimeout(r,150));
  await setDoc(pulse,{...old,version:2,at:serverTimestamp(),previousAt:old.at,previousActive:true,creditDay:day(old.at.toMillis())});
  old=(await getDocFromServer(pulse)).data();
  const delta=old.at.toMillis()-old.previousAt.toMillis(),d=day(old.at.toMillis());
  assert.ok(delta>0&&delta<=30000&&d===day(old.previousAt.toMillis()),'Unexpected server interval; do not grant invented credit');
  const batch=writeBatch(a);
  batch.set(pulse,{...old,version:3,active:false,at:serverTimestamp(),previousAt:old.at,totalMs:delta,sessionMs:delta,deltaMs:delta,creditDay:d});
  batch.set(doc(a,`studyUsers/${uid}/verifiedDays/0_${d}`),{day:d,academicYear:0,totalMs:delta,completed:0,bonus:0,lastVersion:3});
  await batch.commit();assert.equal((await getDocFromServer(pulse)).data().totalMs,delta);checks.push('server-timestamp study credit committed');
  await denied(updateDoc(pulse,{totalMs:999999,at:serverTimestamp()}));checks.push('forged study time denied');
 } finally {
  let cleanupError;
  for(const app of apps){await signOut(clientAuth(app)).catch(()=>{});await deleteApp(app);}
  for(const uid of uids){
   try{await db.recursiveDelete(db.doc(`studyUsers/${uid}`));await auth.deleteUser(uid).catch(e=>{if(e.code!=='auth/user-not-found')throw e;});}
   catch(e){cleanupError=e;console.error('QA cleanup incomplete for '+uid);}
  }
  await adminApp.deleteApp(admin);
  if(cleanupError)throw cleanupError;
 }
 console.log(JSON.stringify({projectId,checks,temporaryUsersRemoved:true}));
})().catch(e=>{console.error(e.code||'',e.message);process.exitCode=1;});
