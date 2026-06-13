<div style="position: relative;">
  <button 
    style="position: absolute; top: 5px; right: 5px; z-index: 1; padding: 4px 8px; font-size: 12px; cursor: pointer;"
    onclick="navigator.clipboard.writeText(document.getElementById('lua-code').textContent.trim()).then(() => { this.textContent = 'Copied!'; setTimeout(() => this.textContent = 'Copy', 2000); })"
  >
    Loader
  </button>
  <pre><code id="lua-code" style="display: block; padding: 16px; background: #f6f8fa; border-radius: 6px; overflow-x: auto;">loadstring(game:HttpGet("https://raw.githubusercontent.com/ImNotWhyLclc/Rendex/refs/heads/main/Loader.luau"))()</code></pre>
</div>   
