// Authenticated backend is the DEFAULT; the isolated local prototype is opt-in.
// This prevents seeded clients, fake payments and role switches being shown as live data.
if(new URLSearchParams(location.search).get('demo')==='1')import('./ui/app.js');
else import('./ui/connected.js');
