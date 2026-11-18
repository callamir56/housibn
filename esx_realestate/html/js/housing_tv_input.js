(() => {
  const panel = document.getElementById('housing-tv-input');
  const input = document.getElementById('housing-tv-url');
  const form = panel.querySelector('form');
  const cancel = document.getElementById('housing-tv-cancel');
  let pending = false;
  const post = (name, data = {}) => fetch(`https://${GetParentResourceName()}/housingTV:${name}`, {
    method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data)
  }).then(response => response.json()).catch(() => ({ok:false}));
  function close() { if (!pending) { pending = true; post('close').finally(() => { pending = false; }); } }
  window.addEventListener('message', event => {
    if (!event.data || event.data.action !== 'HousingTVInput') return;
    panel.hidden = !event.data.open;
    if (event.data.open) { input.value = ''; pending = false; setTimeout(() => input.focus(), 0); }
  });
  window.addEventListener('keydown', event => {
    if (!panel.hidden && event.key === 'Escape') {
      event.preventDefault(); event.stopImmediatePropagation(); close();
    }
  }, true);
  cancel.addEventListener('click', close);
  form.addEventListener('submit', event => {
    event.preventDefault();
    const url = input.value.trim();
    if (pending || !url) { input.focus(); return; }
    pending = true;
    post('submit', {url}).then(result => { if (!result.ok) input.focus(); }).finally(() => { pending = false; });
  });
})();
