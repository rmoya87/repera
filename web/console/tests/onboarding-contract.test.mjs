import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

const source=path=>readFileSync(fileURLToPath(new URL('../../../'+path,import.meta.url)),'utf8');

test('welcome is intentionally dark, while permissions and prices are light',()=>{
 const flow=source('Apps/Repera/Sources/Onboarding/OnboardingFlowView.swift');
 assert.match(flow,/onboarding\.step == \.appleSignIn \? Color\.black : OG\.bg/);
 assert.match(flow,/onboarding\.step == \.appleSignIn \? \.dark : \.light/);
 assert.match(flow,/Text\("Bienvenido a Repera"\)[\s\S]{0,140}\.foregroundStyle\(\.white\)/);
});

test('first-login onboarding presents permission controls BEFORE prices',()=>{
 const flow=source('Apps/Repera/Sources/Onboarding/OnboardingFlowView.swift');
 const store=source('Apps/Repera/Sources/Onboarding/OnboardingStore.swift');
 assert.match(flow,/try await appleAuth\.signIn\(\)[\s\S]*?onboarding\.advance\(to: \.permissions\)/);
 assert.match(flow,/Text\("Continuar"\)/);
 assert.match(flow,/onboarding\.finishPermissions\(\)/);
 assert.match(flow,/onContinueFree: \{\s*onboarding\.finishPrices\(\)/);
 assert.match(flow,/onPurchaseSuccess: \{\s*onboarding\.finishPrices\(\)/);
 assert.match(store,/func finishPermissions\(\) \{\s*advance\(to: priceAlreadySeen \? \.done : \.choosePlan\)/);
 assert.match(store,/func finishPrices\(\) \{[\s\S]*?advance\(to: \.done\)/);
 assert.match(store,/priceAlreadySeen = previous == \.permissions \|\| previous == \.done/);
});

test('inline onboarding paywall never queues a second global paywall',()=>{
 const paywall=source('Apps/Repera/Sources/Monetization/PaywallView.swift');
 assert.doesNotMatch(paywall,/subscriptions\.paywall\.present\(\.onboarding\)/);
 const app=source('Apps/Repera/Sources/ReperaApp.swift');
 assert.match(app,/subscriptions\.paywall\.isPresented && onboarding\.isComplete/);
});
