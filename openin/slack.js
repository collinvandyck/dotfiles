(function () {
  // slack subdomain -> team id. add workspaces as you run into them.
  const TEAMS = {
    temporaltechnologies: 'TT31S6VK5',
    temporal: 'TT31S6VK5',
  };

  const url = ctx.url;
  const before = url.href;

  const team = TEAMS[url.hostname.split('.')[0]];
  if (!team) {
    console.log('unknown workspace ' + url.hostname + ', leaving ' + before);
    return;
  }

  // /archives/C123/p1700000000123456 -> ['archives', 'C123', 'p1700000000123456']
  const seg = url.pathname.split('/').filter(Boolean);
  if (seg[0] !== 'archives' || !seg[1]) {
    console.log('not a channel permalink: ' + url.pathname);
    return;
  }

  const q = ['team=' + team, 'id=' + seg[1]];

  const ts = (seg[2] || '').match(/^p(\d{10})(\d{6})$/);
  if (ts) {
    q.push('message=' + ts[1] + '.' + ts[2]);
    // a reply permalink needs the parent ts, or slack lands on the channel instead of the thread
    const thread = url.searchParams.get('thread_ts');
    if (thread) {
      q.push('thread_ts=' + thread);
    }
  }

  // href, not protocol: the protocol setter refuses an https -> slack switch
  url.href = 'slack://channel?' + q.join('&');
  console.log(before + ' -> ' + url.href);
})();
