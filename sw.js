/* EuroTrip offline cache: network first, saved copy when there is no signal. */
var C = 'eurotrip-v1';
var PAGE = './europe_trip_planner.html';
self.addEventListener('install', function(e){
  e.waitUntil(caches.open(C).then(function(c){ return c.add(new Request(PAGE, {cache:'reload'})); }));
  self.skipWaiting();
});
self.addEventListener('activate', function(e){
  e.waitUntil(caches.keys().then(function(ks){
    return Promise.all(ks.filter(function(k){ return k !== C; }).map(function(k){ return caches.delete(k); }));
  }).then(function(){ return self.clients.claim(); }));
});
self.addEventListener('fetch', function(e){
  var req = e.request, u = new URL(req.url);
  if(req.method !== 'GET' || u.origin !== location.origin || !/europe_trip_planner\.html$/.test(u.pathname)) return;
  var saved = function(){ return caches.match(PAGE); };
  var net = fetch(req).then(function(r){
    if(r && r.ok){ var cp = r.clone(); caches.open(C).then(function(c){ c.put(PAGE, cp); }); }
    return r;
  });
  e.respondWith(new Promise(function(resolve){
    var done = false;
    var t = setTimeout(function(){ saved().then(function(m){ if(m && !done){ done = true; resolve(m); } }); }, 4000);
    net.then(function(r){ if(!done){ done = true; clearTimeout(t); resolve(r); } })
       .catch(function(){ clearTimeout(t); saved().then(function(m){ if(!done){ done = true; resolve(m || Response.error()); } }); });
  }));
});
