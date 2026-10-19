import {seedData} from './seed.js';
import {uuid} from './domain.js';
const KEY='repera-business-console-demo-v2';
const clone=value=>JSON.parse(JSON.stringify(value));
function read(){try{const data=JSON.parse(localStorage.getItem(KEY)||localStorage.getItem('repera-business-console-demo-v1')||'null');if(data?.version===1&&Array.isArray(data.organizations)){data.notifications??=[];data.invites??=[];data.attendance??=[];return data;}}catch{}return seedData();}
export const db={state:read(),listeners:new Set(),subscribe(fn){this.listeners.add(fn);return()=>this.listeners.delete(fn)},notify(){for(const fn of this.listeners)fn()},
 transaction(action,fn){const snapshot=clone(this.state);try{const result=fn(snapshot);snapshot.events.push({id:uuid(),action,at:new Date().toISOString()});snapshot.events=snapshot.events.slice(-200);localStorage.setItem(KEY,JSON.stringify(snapshot));this.state=snapshot;this.notify();return result;}catch(error){throw error;}},
 reset(){this.state=seedData();localStorage.setItem(KEY,JSON.stringify(this.state));this.notify()}};