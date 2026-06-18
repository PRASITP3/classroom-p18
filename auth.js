/* =====================================================================
   auth.js — ระบบ login ด้วยรหัสนักเรียน (ใช้ร่วมทุกหน้า)
   ต้องโหลดหลัง <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
   เปิดให้ใช้:  P18Auth.student , P18Auth.logout() , P18Auth.saveScore(game,mode,score,total)
   ===================================================================== */
(function () {
  const SUPABASE_URL = 'https://qznafcgkzlcfjyyrdqhk.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6bmFmY2dremxjZmp5eXJkcWhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1NTExNDMsImV4cCI6MjA5MTEyNzE0M30.v29uJG7HFjE7G9-wvw0TpovEtwsnXCu9CGFKapV7wT0';
  const LS_KEY = 'p18_student';

  let supa = null;
  function client() {
    if (!supa && window.supabase) supa = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    return supa;
  }

  const Auth = {
    student: null,
    read() { try { return JSON.parse(localStorage.getItem(LS_KEY) || 'null'); } catch (e) { return null; } },
    save(s) { localStorage.setItem(LS_KEY, JSON.stringify(s)); Auth.student = s; },
    logout() { localStorage.removeItem(LS_KEY); Auth.student = null; location.reload(); },
    async saveScore(game, mode, score, total) {
      const c = client(); const s = Auth.student;
      if (!c || !s) return;
      try { await c.from('game_scores').insert({ student_id: s.id, game: game, mode: mode, score: score, total: total }); }
      catch (e) { console.warn('saveScore failed (ตาราง game_scores อาจยังไม่ถูกสร้าง)', e); }
    },
  };
  window.P18Auth = Auth;

  /* ---------- styles ---------- */
  function injectStyles() {
    if (document.getElementById('p18auth-css')) return;
    const css = document.createElement('style');
    css.id = 'p18auth-css';
    css.textContent = `
      #p18gate{position:fixed; inset:0; z-index:99999; display:grid; place-items:center; padding:20px;
        background:radial-gradient(120% 120% at 50% 0%, #FFF4D6 0%, #C7ECFF 60%, #8FD3F4 100%);
        font-family:'Sarabun','Nunito',sans-serif; color:#3A2E14;}
      #p18gate .box{background:#fff; border-radius:28px; box-shadow:0 8px 0 rgba(58,46,20,.10),0 14px 30px rgba(58,46,20,.18);
        border:4px solid #FFE9A8; padding:26px 22px; width:100%; max-width:360px; text-align:center;}
      #p18gate .sun{font-size:2.8rem;}
      #p18gate h2{font-family:'Fredoka',sans-serif; margin:6px 0 2px; font-size:1.5rem;}
      #p18gate p{margin:0 0 16px; color:#7A6B45; font-weight:700; font-size:.95rem;}
      #p18gate input{width:100%; text-align:center; font-size:1.8rem; letter-spacing:6px; font-weight:800;
        padding:12px; border:3px solid #EADFC6; border-radius:16px; font-family:'Fredoka',sans-serif; color:#3A2E14; outline:none;}
      #p18gate input:focus{border-color:#FFC93C;}
      #p18gate button{margin-top:14px; width:100%; border:0; border-radius:16px; padding:14px;
        background:linear-gradient(135deg,#FFB347,#FFC93C); color:#fff; font-family:'Fredoka',sans-serif;
        font-weight:700; font-size:1.2rem; cursor:pointer; box-shadow:0 4px 0 #E0902B;}
      #p18gate button:active{transform:translateY(3px); box-shadow:0 1px 0 #E0902B;}
      #p18gate .err{color:#D64545; font-weight:700; min-height:22px; margin-top:10px; font-size:.95rem;}
      #p18gate .hint{color:#A99668; font-size:.8rem; margin-top:8px;}
      #p18nav{position:fixed; left:14px; bottom:14px; z-index:9990; display:flex; align-items:center; gap:8px;}
      #p18back{display:inline-flex; align-items:center; gap:3px; background:#fff; border-radius:999px;
        padding:8px 15px; cursor:pointer; text-decoration:none; border:2px solid #FFE9A8;
        box-shadow:0 4px 0 rgba(58,46,20,.10),0 8px 20px rgba(58,46,20,.16);
        font-family:'Fredoka','Sarabun',sans-serif; font-weight:700; color:#3A2E14; font-size:.95rem;}
      #p18back:active{transform:translateY(2px);}
      #p18back .a{font-size:1.15rem; line-height:1; margin-top:-1px;}
      #p18chip{display:flex; align-items:center; gap:8px;
        background:#fff; border-radius:999px; padding:7px 12px 7px 13px; cursor:pointer;
        box-shadow:0 4px 0 rgba(58,46,20,.10),0 8px 20px rgba(58,46,20,.16); font-family:'Sarabun',sans-serif;
        font-weight:700; color:#3A2E14; font-size:.9rem; border:2px solid #FFE9A8;}
      #p18chip:active{transform:translateY(2px);}
      #p18chip .x{color:#B8740C; font-weight:800;}
      #p18toast{position:fixed; left:50%; top:18px; transform:translateX(-50%); z-index:99998;
        background:#fff; color:#1E8E6E; font-family:'Fredoka',sans-serif; font-weight:700; padding:10px 18px;
        border-radius:999px; box-shadow:0 6px 18px rgba(0,0,0,.15); opacity:0; transition:opacity .3s; pointer-events:none;}
      #p18toast.show{opacity:1;}
    `;
    document.head.appendChild(css);
  }

  function toast(msg) {
    let t = document.getElementById('p18toast');
    if (!t) { t = document.createElement('div'); t.id = 'p18toast'; document.body.appendChild(t); }
    t.textContent = msg; t.classList.add('show');
    setTimeout(() => t.classList.remove('show'), 2200);
  }

  /* ---------- login gate ---------- */
  function showGate() {
    injectStyles();
    const g = document.createElement('div');
    g.id = 'p18gate';
    g.innerHTML = `
      <div class="box">
        <div class="sun">🌻</div>
        <h2>ห้อง ป.1/8</h2>
        <p>ใส่รหัสนักเรียนเพื่อเข้าใช้งาน</p>
        <input id="p18code" type="text" inputmode="numeric" pattern="[0-9]*" maxlength="6" placeholder="รหัส" autocomplete="off">
        <button id="p18go">เข้าเรียน ✏️</button>
        <div class="err" id="p18err"></div>
        <div class="hint">รหัสนักเรียน 5 หลัก (สอบถามคุณครู)</div>
      </div>`;
    document.body.appendChild(g);
    const input = g.querySelector('#p18code');
    const btn = g.querySelector('#p18go');
    const err = g.querySelector('#p18err');
    setTimeout(() => input.focus(), 150);
    input.addEventListener('input', () => { input.value = input.value.replace(/[^0-9]/g, ''); err.textContent = ''; });
    input.addEventListener('keydown', e => { if (e.key === 'Enter') btn.click(); });
    btn.addEventListener('click', async () => {
      const code = input.value.trim();
      if (code.length < 3) { err.textContent = 'กรุณาใส่รหัสให้ครบ'; return; }
      btn.disabled = true; btn.textContent = 'กำลังตรวจสอบ...';
      const s = await verify(code);
      btn.disabled = false; btn.textContent = 'เข้าเรียน ✏️';
      if (!s) { err.textContent = '❌ ไม่พบรหัสนี้ ลองใหม่อีกครั้ง'; input.value = ''; input.focus(); return; }
      Auth.save(s);
      recordLogin(s);
      g.remove();
      showChip(s);
      toast('สวัสดี ' + (s.nickname || '') + ' 👋');
    });
  }

  async function verify(code) {
    const c = client();
    if (!c) return null;
    try {
      const { data, error } = await c.from('registry_students')
        .select('id,number,nickname,name').eq('code', code).limit(1);
      if (error) throw error;
      if (data && data.length) {
        const r = data[0];
        return { id: r.id, number: r.number, nickname: r.nickname, name: r.name };
      }
      return null;
    } catch (e) { console.warn('verify failed', e); return null; }
  }

  async function recordLogin(s) {
    const c = client(); if (!c) return;
    try { await c.from('student_logins').insert({ student_id: s.id }); }
    catch (e) { console.warn('recordLogin failed (ตาราง student_logins อาจยังไม่ถูกสร้าง)', e); }
  }

  function navBar() {
    let bar = document.getElementById('p18nav');
    if (!bar) { bar = document.createElement('div'); bar.id = 'p18nav'; document.body.appendChild(bar); }
    return bar;
  }

  // ปุ่ม "กลับ" — พากลับหน้าแม่ที่เหมาะสม (เกม→คลังเกม, อื่นๆ→หน้าหลัก, หน้าหลัก→ซ่อน)
  function showBack() {
    injectStyles();
    if (document.getElementById('p18back')) return;
    const p = location.pathname;
    const inPractice = p.includes('/practice/');
    const atPracticeHub = /\/practice\/(index\.html)?$/.test(p);
    const atSiteHome = !inPractice && /(\/|\/index\.html)$/.test(p);
    if (atSiteHome) return;                              // หน้าหลัก: ไม่ต้องมีปุ่มกลับ
    const target = (inPractice && !atPracticeHub) ? 'index.html'        // หน้าเกม → practice/index.html
                 : inPractice ? '../index.html'                          // คลังเกม → หน้าหลัก
                 : 'index.html';                                         // registry/schedule → หน้าหลัก
    const b = document.createElement('a');
    b.id = 'p18back'; b.href = target; b.title = 'กลับ';
    b.innerHTML = `<span class="a">‹</span> กลับ`;
    navBar().appendChild(b);
  }

  function showChip(s) {
    injectStyles();
    showBack();
    if (document.getElementById('p18chip')) return;
    const chip = document.createElement('div');
    chip.id = 'p18chip';
    chip.innerHTML = `🙂 ${s.nickname || s.name || 'นักเรียน'} <span class="x">↩ ออก</span>`;
    chip.title = 'แตะเพื่อออกจากระบบ / สลับผู้ใช้';
    chip.addEventListener('click', () => {
      if (confirm('ออกจากระบบ / สลับผู้ใช้?')) Auth.logout();
    });
    navBar().appendChild(chip);
  }

  /* ---------- init ---------- */
  function init() {
    const s = Auth.read();
    if (s && s.id) { Auth.student = s; showChip(s); }
    else { showGate(); }
  }
  if (document.readyState !== 'loading') init();
  else document.addEventListener('DOMContentLoaded', init);
})();
