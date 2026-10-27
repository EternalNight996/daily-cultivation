
/* ============ 基础几何 ============ */
const CX = 195, CY = 400, BOX = 292, R = 152;
const toScreen = (p) => ({ x: CX + (p[0] - .5) * BOX, y: CY + (p[1] - .5) * BOX });

/* ============ 三张符（归一化点列） ============ */
function arc(cx, cy, rx, ry, a0, a1, n = 14) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = a0 + (a1 - a0) * i / n;
    out.push([cx + Math.cos(t) * rx, cy + Math.sin(t) * ry]);
  }
  return out;
}
function quad(p0, p1, p2, n = 12) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = i / n, u = 1 - t;
    out.push([u*u*p0[0] + 2*u*t*p1[0] + t*t*p2[0], u*u*p0[1] + 2*u*t*p1[1] + t*t*p2[1]]);
  }
  return out;
}
const TALISMANS = [
  { name:'清心符', multName:'离火', strokes:[
      [[.50,.10],[.50,.30],[.50,.50],[.49,.68],[.46,.84]],
      [[.26,.32],[.54,.32],[.70,.34],[.76,.39]],
      [[.28,.53],[.52,.53],[.68,.56],[.72,.61]]
  ]},
  { name:'聚灵符', multName:'玄水', strokes:[
      [[.28,.07],[.72,.07],[.72,.11],[.50,.11],[.50,.30]],
      [[.34,.34],[.66,.34],[.66,.56],[.34,.56],[.34,.34]],
      [[.28,.62],[.72,.62],[.72,.66],[.36,.66],[.36,.70],[.64,.70],[.64,.78],[.38,.86]]
  ]},
  { name:'御风符', multName:'青木', strokes:[
      arc(.50,.28,.20,.15,-Math.PI*.9, Math.PI*.2, 16),
      [[.18,.56],[.34,.50],[.50,.58],[.66,.50],[.82,.58]],
      [[.50,.58],[.50,.72],[.46,.82],[.36,.88]]
  ]}
];

/* ============ 重采样 / 归一化 / 打分 ============ */
function resample(pts, n = 32) {
  if (pts.length < 2) return pts.slice();
  const d = [0];
  for (let i = 1; i < pts.length; i++) {
    d.push(d[i-1] + Math.hypot(pts[i].x - pts[i-1].x, pts[i].y - pts[i-1].y));
  }
  const total = d[d.length-1] || 1, step = total / (n - 1);
  const out = [pts[0]]; let j = 0;
  for (let k = 1; k < n - 1; k++) {
    const target = step * k;
    while (j < d.length - 2 && d[j+1] < target) j++;
    const seg = (d[j+1] - d[j]) || 1, t = (target - d[j]) / seg;
    out.push({ x: pts[j].x + (pts[j+1].x - pts[j].x) * t,
               y: pts[j].y + (pts[j+1].y - pts[j].y) * t });
  }
  out.push(pts[pts.length-1]);
  return out;
}
function bbox(pts) {
  let x0=1e9,y0=1e9,x1=-1e9,y1=-1e9;
  for (const p of pts) { x0=Math.min(x0,p.x); y0=Math.min(y0,p.y); x1=Math.max(x1,p.x); y1=Math.max(y1,p.y); }
  return {x0,y0,x1,y1,w:x1-x0,h:y1-y0};
}
function normalize(pts) {
  const b = bbox(pts), s = 1 / Math.max(b.w, b.h, 1e-6);
  const cx = (b.x0+b.x1)/2, cy = (b.y0+b.y1)/2;
  return pts.map(p => ({ x: (p.x-cx)*s + .5, y: (p.y-cy)*s + .5 }));
}
function frechet(P, Q) {
  const n = P.length, m = Q.length;
  let prev = new Float64Array(m).fill(1e9), cur = new Float64Array(m).fill(1e9);
  for (let i = 0; i < n; i++) {
    for (let j = 0; j < m; j++) {
      const d = Math.hypot(P[i].x-Q[j].x, P[i].y-Q[j].y);
      if (i===0 && j===0) cur[j]=d;
      else if (i===0) cur[j]=Math.max(cur[j-1],d);
      else if (j===0) cur[j]=Math.max(prev[j],d);
      else cur[j]=Math.max(Math.min(prev[j],prev[j-1],cur[j-1]),d);
    }
    const t=prev; prev=cur; cur=t; cur.fill(1e9);
  }
  return prev[m-1];
}
function tangents(pts) {
  return pts.map((p,i) => {
    const a = pts[Math.max(0,i-1)], b = pts[Math.min(pts.length-1,i+1)];
    const dx = b.x-a.x, dy = b.y-a.y, L = Math.hypot(dx,dy) || 1;
    return { x: dx/L, y: dy/L };
  });
}
// 用户笔画映射到符的局部坐标系（0..1），与模板同一坐标系比较；
// 不做按单笔包围盒缩放——那样任何一条竖线都会被归一成满分。
function score(userRaw, tmplRaw) {
  const toBox = p => ({ x: (p.x - (CX - BOX/2)) / BOX, y: (p.y - (CY - BOX/2)) / BOX });
  const U = resample(userRaw.map(toBox), 32);
  const T = resample(tmplRaw.map(p=>({x:p[0],y:p[1]})), 32);
  const fr = frechet(U, T);
  const shape = Math.max(0, 1 - fr / 0.22);
  const ut = tangents(U), tt = tangents(T);
  let tan = 0;
  for (let i=0;i<32;i++) tan += Math.max(0, (ut[i].x*tt[i].x + ut[i].y*tt[i].y + 1) / 2);
  tan /= 32;
  const endTol = 40 / BOX;   // 与"起笔容差 40pt"同口径
  const d0 = Math.hypot(U[0].x-T[0].x, U[0].y-T[0].y);
  const d1 = Math.hypot(U[31].x-T[31].x, U[31].y-T[31].y);
  const ends = (Math.max(0,1-d0/endTol) + Math.max(0,1-d1/endTol)) / 2;
  return { total: 0.60*shape + 0.25*tan + 0.15*ends, shape, tan, ends, fr };
}

/* ============ 状态 ============ */
const DEMO = new URLSearchParams(location.search).get('demo') === '1';
const S = {
  talisman: 0, shichen: 0, threshold: 0.72,
  strokes: [], current: null, done: 0,
  today: 0, showScore: true, showGuide: true, startedAt: 0
};
const SHICHEN = [
  { label:'午时 · 离火', mult:1.5, grade:'radial-gradient(circle at 50% 40%, rgba(255,170,90,.30), rgba(120,60,30,.16) 60%, transparent 78%)', dot:'#E8A45C' },
  { label:'子时 · 玄水', mult:1.6, grade:'radial-gradient(circle at 50% 40%, rgba(120,170,255,.26), rgba(30,60,120,.18) 60%, transparent 78%)', dot:'#7FA8E8' },
  { label:'卯时 · 青木', mult:1.3, grade:'radial-gradient(circle at 50% 40%, rgba(140,220,170,.24), rgba(30,100,70,.16) 60%, transparent 78%)', dot:'#7FD0A8' },
  { label:'酉时 · 白金', mult:1.3, grade:'radial-gradient(circle at 50% 40%, rgba(220,220,240,.24), rgba(90,90,120,.16) 60%, transparent 78%)', dot:'#C8C8E0' },
  { label:'无常 · 平', mult:1.0, grade:'radial-gradient(circle at 50% 40%, rgba(200,200,200,.16), rgba(60,60,60,.12) 60%, transparent 78%)', dot:'#9AA0A6' }
];

/* ============ DOM ============ */
const $ = id => document.getElementById(id);
const phone = $('phone'), plate = $('plate'), canvas = $('trail'), ctx = canvas.getContext('2d');
const guide = $('guide'), startdot = $('startdot'), halo = $('halo');
const arcEl = $('scoreArc'), settle = $('settle'), flash = $('flash');
const pet = $('pet'), eyeL = $('eyeL'), eyeR = $('eyeR');
const hint = $('hint');

/* ============ 绘制：符盘 ============ */
function svgPath(points, closed) {
  return points.map((p,i) => {
    const s = toScreen(p);
    return (i ? 'L' : 'M') + s.x.toFixed(1) + ' ' + s.y.toFixed(1);
  }).join(' ') + (closed ? ' Z' : '');
}
function renderGuide() {
  const t = TALISMANS[S.talisman];
  guide.innerHTML = '';
  t.strokes.forEach((st, i) => {
    const el = document.createElementNS('http://www.w3.org/2000/svg','path');
    el.setAttribute('d', svgPath(st));
    if (i < S.done) el.setAttribute('class', 'done');
    else if (i === S.done) { el.setAttribute('class', 'dash'); el.style.opacity = S.showGuide ? 1 : .2; }
    else { el.setAttribute('class', 'faint'); el.style.opacity = S.showGuide ? 1 : .25; }
    guide.appendChild(el);
  });
  const done = S.done >= t.strokes.length;
  if (done) {
    startdot.style.display = 'none';
    halo.style.display = 'none';
  } else {
    const p = toScreen(t.strokes[S.done][0]);
    startdot.style.display = 'block';
    halo.style.display = 'block';
    startdot.style.cssText = 'left:'+p.x+'px;top:'+p.y+'px;' + (S.showGuide?'':'opacity:0');
    halo.style.cssText = 'left:'+p.x+'px;top:'+p.y+'px;' + (S.showGuide?'':'opacity:0');
  }
  $('sProg').textContent = S.done + ' / ' + t.strokes.length;
}

/* ============ 绘制：拖尾 ============ */
function drawTrail() {
  ctx.clearRect(0,0,390,844);
  const pts = S.current ? S.current.pts : [];
  if (pts.length < 2) return;
  ctx.globalCompositeOperation = 'lighter';
  for (let i = 1; i < pts.length; i++) {
    const k = i / pts.length;
    const w = 1.4 + 4.6 * Math.pow(k, 1.15);
    const g = ctx.createLinearGradient(pts[i-1].x, pts[i-1].y, pts[i].x, pts[i].y);
    g.addColorStop(0, 'rgba(201,164,92,' + (0.20 + 0.5*k) + ')');
    g.addColorStop(1, 'rgba(255,244,214,' + (0.30 + 0.6*k) + ')');
    ctx.strokeStyle = g; ctx.lineWidth = w; ctx.lineCap = 'round';
    ctx.shadowColor = 'rgba(255,226,160,.85)'; ctx.shadowBlur = 9 + 7*k;
    ctx.beginPath(); ctx.moveTo(pts[i-1].x, pts[i-1].y); ctx.lineTo(pts[i].x, pts[i].y); ctx.stroke();
  }
  const last = pts[pts.length-1];
  ctx.shadowBlur = 22; ctx.fillStyle = 'rgba(255,248,230,.95)';
  ctx.beginPath(); ctx.arc(last.x, last.y, 4.2, 0, 7); ctx.fill();
  ctx.shadowBlur = 0;
}

/* ============ 契合度环 ============ */
const RING_C = 2 * Math.PI * 158;
function setRing(v, color) {
  const k = Math.max(0, Math.min(1, v));
  arcEl.style.opacity = k <= 0.001 ? '0' : '1';
  arcEl.style.strokeDashoffset = String(RING_C * (1 - k));
  arcEl.style.stroke = color || 'rgba(201,164,92,.55)';
}
// 实时环必须反映"走到哪了"，不能只算"离轨迹近不近"——
// 否则只画前 30% 也会显示 100%，用户会以为已经完成。
function liveMatch(pt) {
  const t = TALISMANS[S.talisman].strokes[S.done];
  const tmpl = t.map(p => toScreen(p));
  const M = 14;
  let hit = 0, progress = 0;
  for (const p of S.current.pts) {
    let localBest = 0;
    for (let i = 1; i < tmpl.length; i++) {
      const a = tmpl[i-1], c = tmpl[i];
      const dx = c.x-a.x, dy = c.y-a.y, L2 = dx*dx+dy*dy || 1;
      let u = ((p.x-a.x)*dx + (p.y-a.y)*dy) / L2; u = Math.max(0, Math.min(1, u));
      const d = Math.hypot(p.x-(a.x+u*dx), p.y-(a.y+u*dy));
      if (d < M) localBest = Math.max(localBest, (i - 1 + u) / (tmpl.length - 1));
    }
    if (localBest > 0) hit++;
    progress = Math.max(progress, localBest);
  }
  const accuracy = hit / Math.max(1, S.current.pts.length);
  const value = progress * (0.6 + 0.4 * accuracy);
  setRing(value, value < .4 ? 'rgba(237,230,214,.28)' : (value < .72 ? 'rgba(111,191,176,.6)' : 'rgba(201,164,92,.7)'));
}

/* ============ 粒子 ============ */
const particles = [];
function burst(x, y) {
  for (let i = 0; i < 90; i++) {
    const a = Math.random() * Math.PI * 2, sp = 60 + Math.random() * 280;
    const r0 = 6 + Math.random() * 22;
    particles.push({
      x: x + Math.cos(a) * r0, y: y + Math.sin(a) * r0,
      vx: Math.cos(a)*sp, vy: Math.sin(a)*sp - 40,
      life: 1, decay: .005 + Math.random()*.008,
      size: .6 + Math.random()*1.8,
      hue: Math.random() < .3 ? '111,191,176' : '255,232,180'
    });
  }
}
function tickParticles(dt) {
  if (!particles.length) return;
  for (let i = particles.length-1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx*dt; p.y += p.vy*dt; p.vy += 120*dt; p.vx *= .985; p.vy *= .985;
    p.life -= p.decay;
    if (p.life <= 0) { particles.splice(i,1); continue; }
    ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = 'rgba('+p.hue+','+(p.life*.9)+')';
    ctx.beginPath(); ctx.arc(p.x, p.y, p.size*p.life, 0, 7); ctx.fill();
  }
}

/* ============ 交互 ============ */
function localPt(e) {
  const r = phone.getBoundingClientRect();
  const sx = 390 / r.width;
  return { x: (e.clientX - r.left) * sx, y: (e.clientY - r.top) * (844 / r.height) };
}
function start(e) {
  if (settle.classList.contains('on')) return;
  const p = localPt(e);
  const t = TALISMANS[S.talisman];
  if (S.done >= t.strokes.length) return;
  const s = toScreen(t.strokes[S.done][0]);
  if (Math.hypot(p.x-s.x, p.y-s.y) > 40) {
    hint.textContent = '从符头的光点起笔'; hint.style.opacity = 1;
    setTimeout(() => hint.style.opacity = .5, 1200);
    return;
  }
  S.current = { pts: [p] };
  S.startedAt = performance.now();
  pet.classList.add('cast');
  hint.style.opacity = 0;
  if (e.pointerId != null) plate.setPointerCapture?.(e.pointerId);
}
function move(e) {
  if (!S.current) return;
  const p = localPt(e), last = S.current.pts[S.current.pts.length-1];
  if (Math.hypot(p.x-last.x, p.y-last.y) < 1.2) return;
  S.current.pts.push(p);
  drawTrail(); liveMatch(p);
  // 眼睛跟随
  const dx = (p.x - 195) / 195, dy = (p.y - 420) / 420;
  eyeL.style.transform = 'translate(' + (dx*3.2) + 'px,' + (dy*2.4) + 'px)';
  eyeR.style.transform = 'translate(' + (dx*3.2) + 'px,' + (dy*2.4) + 'px)';
}
function end() {
  if (!S.current) return;
  const pts = S.current.pts; S.current = null;
  pet.classList.remove('cast');
  const t = TALISMANS[S.talisman].strokes[S.done];
  // 太短：作废
  let len = 0;
  for (let i=1;i<pts.length;i++) len += Math.hypot(pts[i].x-pts[i-1].x, pts[i].y-pts[i-1].y);
  if (len < 64 || pts.length < 8) {
    const s = toScreen(t[0]); startdot.animate([{transform:'translateX(0)'},{transform:'translateX(4px)'},{transform:'translateX(0)'}],{duration:180});
    ctx.clearRect(0,0,390,844); setRing(0); hint.textContent='松手太早，这一笔作废'; hint.style.opacity=.6;
    return;
  }
  const sc = score(pts, t);
  const pass = sc.total >= S.threshold;
  $('sScore').textContent = sc.total.toFixed(3);
  $('sTime').textContent = ((performance.now()-S.startedAt)/1000).toFixed(1) + 's';
  if (!pass) {
    const near = sc.total >= 0.55;
    hint.textContent = near ? '差一点，重画这一笔' : '偏得有点远，再看一眼虚线';
    hint.style.opacity = .75;
    setRing(sc.total, 'rgba(237,230,214,.55)');
    redraw();
    if (!S.showScore) $('sScore').textContent = near ? '接近' : '未过';
    return;
  }
  // 通过：这一笔定格
  S.strokes.push(pts); S.done++;
  redraw();
  setRing(1);
  if (S.done < TALISMANS[S.talisman].strokes.length) {
    hint.textContent = '继续下一笔'; hint.style.opacity = .5;
    renderGuide(); return;
  }
  finish(sc);
}
function drawDoneStroke(pts) {
  ctx.save(); ctx.globalCompositeOperation='lighter';
  ctx.strokeStyle='rgba(201,164,92,.5)'; ctx.lineWidth=2.4; ctx.lineCap='round';
  ctx.shadowColor='rgba(201,164,92,.6)'; ctx.shadowBlur=10;
  ctx.beginPath(); pts.forEach((p,i)=> i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y)); ctx.stroke();
  ctx.restore();
}
function redraw() {
  ctx.clearRect(0, 0, 390, 844);
  S.strokes.forEach(drawDoneStroke);
  drawTrail();
}

function finish(sc) {
  if (DEMO) document.body.classList.add('still');
  renderGuide();                       // 进度与虚线一次性收尾（3/3、隐藏起笔点）
  hint.style.opacity = 0;
  if (DEMO) flash.style.display = 'none';

  const seal = document.getElementById('seal');
  const ink = document.getElementById('ink');
  if (DEMO) {
    // 截图模式：直接定格在"落印完成"的状态
    seal.style.opacity = '.92';
    seal.style.transform = 'rotate(-6deg) scale(1)';
    ink.style.opacity = '.55';
    ink.style.transform = 'scale(1)';
  } else {
    seal.classList.remove('drop');
    void seal.offsetWidth;
    seal.classList.add('drop');
    ink.classList.remove('bloom');
    void ink.offsetWidth;
    ink.classList.add('bloom');
  }

  const sh = SHICHEN[S.shichen];
  const xp = Math.round(80 * sh.mult * 1.05 * 1.10);
  burst(195, 400);
  if (!DEMO) {
    const fx = flash.animate([{opacity:0},{opacity:.5,offset:.35},{opacity:0}], {duration:420, easing:'ease-out'});
    fx.onfinish = () => { flash.style.opacity = '0'; };
  }
  pet.style.bottom = '344px';
  pet.classList.add('bounce');
  setTimeout(()=>pet.classList.remove('bounce'), 600);
  S.today += xp;
  settle.classList.add('on');
  arcEl.style.opacity = '0.14';          // 收尾：成功环淡出，别一直亮着
  $('rMult').textContent = '×' + sh.mult.toFixed(2);
  $('rShichen').textContent = sh.label;
  $('rToday').textContent = S.today;
  $('sToday').textContent = S.today;
  $('sTotal').textContent = sc.total.toFixed(3);
  $('xpNum').textContent = String(xp);   // 先落终值，动画只在真实浏览器里覆盖
  if (DEMO) return;
  const t0 = performance.now();
  const roll = (t) => {
    const k = Math.max(0, Math.min(1, (t - t0) / 500));
    $('xpNum').textContent = Math.round(xp * (1-Math.pow(1-k,3)));
    if (k < 1) requestAnimationFrame(roll);
  };
  requestAnimationFrame(roll);
}
function reset() {
  S.strokes = []; S.current = null; S.done = 0;
  settle.classList.remove('on');
  pet.style.bottom = '206px';
  arcEl.style.opacity = '0';
  const sealEl = document.getElementById('seal');
  sealEl.classList.remove('drop');
  sealEl.style.opacity = '0';
  sealEl.style.transform = 'rotate(-14deg) scale(2.2)';
  const inkEl = document.getElementById('ink');
  inkEl.classList.remove('bloom');
  inkEl.style.opacity = '0';
  ctx.clearRect(0,0,390,844);
  setRing(0); renderGuide(); hint.style.opacity = .5;
  hint.textContent = '从光点起笔，沿虚线画';
  $('sScore').textContent = '—'; $('sTotal').textContent = '—'; $('sTime').textContent = '—';
}

/* ============ 事件绑定 ============ */
plate.addEventListener('pointerdown', start);
window.addEventListener('pointermove', move);
window.addEventListener('pointerup', end);
window.addEventListener('pointercancel', end);

$('segTalisman').addEventListener('click', e => {
  const b = e.target.closest('button'); if (!b) return;
  [...e.currentTarget.children].forEach(x=>x.classList.remove('on'));
  b.classList.add('on'); S.talisman = +b.dataset.i; reset();
  $('plateName').textContent = TALISMANS[S.talisman].name + ' · 三笔';
});
$('segShichen').addEventListener('click', e => {
  const b = e.target.closest('button'); if (!b) return;
  [...e.currentTarget.children].forEach(x=>x.classList.remove('on'));
  b.classList.add('on'); S.shichen = +b.dataset.i; applyShichen();
});
$('thr').addEventListener('input', e => {
  S.threshold = +e.target.value;
  $('thrVal').textContent = S.threshold.toFixed(2);
  $('sThr').textContent = S.threshold.toFixed(2);
});
$('tScore').addEventListener('click', e => { e.currentTarget.classList.toggle('on'); S.showScore = e.currentTarget.classList.contains('on'); });
$('tGuide').addEventListener('click', e => { e.currentTarget.classList.toggle('on'); S.showGuide = e.currentTarget.classList.contains('on'); renderGuide(); });
$('again').addEventListener('click', reset);
$('close').addEventListener('click', () => settle.classList.remove('on'));

function applyShichen() {
  const sh = SHICHEN[S.shichen];
  $('grade').style.background = sh.grade;
  $('pillText').textContent = sh.label;
  $('pillMult').textContent = '×' + sh.mult.toFixed(1);
  document.querySelector('#pill i').style.background = sh.dot;
}

/* ============ 自检：?demo=1 自动画完整符，用于截图验证 ============ */
function simulateStroke() {
  const t = TALISMANS[S.talisman].strokes[S.done];
  if (!t) return;
  S.startedAt = performance.now();
  // 沿模板密集采样，模拟真实指针轨迹
  const dense = [];
  for (let i = 1; i < t.length; i++) {
    const a = toScreen(t[i-1]), b = toScreen(t[i]);
    const n = Math.max(2, Math.round(Math.hypot(b.x-a.x, b.y-a.y) / 5));
    for (let k = 0; k < n; k++) {
      dense.push({ x: a.x + (b.x-a.x)*k/n + (Math.random()-.5)*1.6,
                   y: a.y + (b.y-a.y)*k/n + (Math.random()-.5)*1.6 });
    }
  }
  dense.push({ x: dense.at(-1).x, y: dense.at(-1).y });
  S.current = { pts: dense };
  drawTrail();
  end();
}

/* ============ 启动 ============ */
let lastT = 0;
function loop(t) {
  const dt = Math.min(.05, (t - lastT) / 1000 || .016); lastT = t;
  tickParticles(dt);
  requestAnimationFrame(loop);
}
renderGuide(); applyShichen(); requestAnimationFrame(loop);

const params = new URLSearchParams(location.search);
if (params.get('clean') === '1') document.body.classList.add('clean');
if (params.has('shichen')) {
  S.shichen = Math.max(0, Math.min(4, Number(params.get('shichen')) || 0));
  [...document.querySelectorAll('#segShichen button')].forEach((b, i) => b.classList.toggle('on', i === S.shichen));
  applyShichen();
}

if (params.get('demo') === '1') {
  // 自动画完整符，停在结算态
  const n = TALISMANS[S.talisman].strokes.length;
  for (let i = 0; i < n; i++) setTimeout(simulateStroke, 400 + i * 450);
}

if (params.get('demo') === 'demo') {
  // 画到一半定格：只画第一笔的前 62%，不抬手，用于验收"画符中"的观感
  setTimeout(() => {
    const t = TALISMANS[S.talisman].strokes[0];
    const dense = [];
    for (let i = 1; i < t.length; i++) {
      const a = toScreen(t[i-1]), b = toScreen(t[i]);
      const n = Math.max(2, Math.round(Math.hypot(b.x-a.x, b.y-a.y) / 5));
      for (let k = 0; k < n; k++) {
        dense.push({ x: a.x + (b.x-a.x)*k/n, y: a.y + (b.y-a.y)*k/n });
      }
    }
    const cut = Math.round(dense.length * 0.62);
    S.current = { pts: dense.slice(0, cut) };
    S.startedAt = performance.now();
    document.body.classList.add('still');
    document.getElementById('hint').style.opacity = 0;
    drawTrail();
    liveMatch(dense[cut - 1]);
  }, 500);
}
