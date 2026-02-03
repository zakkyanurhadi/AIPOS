/**
 * AIPOS - Navigation Component
 * Simple JavaScript routing for bottom navigation
 */

// Navigation configuration
const NAV_ITEMS = [
  { id: 'home', icon: 'home', label: 'Home', href: '1home.html' },
  { id: 'produk', icon: 'inventory_2', label: 'Produk', href: '2produk.html' },
  { id: 'transaksi', icon: 'qr_code_scanner', label: '', href: '3riwayat_transaksi.html', isCenter: true },
  { id: 'ringkasan', icon: 'monitoring', label: 'Ringkasan', href: '4ringkasan.html' },
  { id: 'akun', icon: 'person', label: 'Saya', href: '5akun.html' }
];

// Get current page ID from filename
function getCurrentPageId() {
  const path = window.location.pathname;
  const filename = path.substring(path.lastIndexOf('/') + 1);
  
  // Map filenames to nav IDs
  const pageMap = {
    '1home.html': 'home',
    '2produk.html': 'produk',
    '3riwayat_transaksi.html': 'transaksi',
    'buat_transaksi.html': 'transaksi',
    '4ringkasan.html': 'ringkasan',
    '5akun.html': 'akun'
  };
  
  return pageMap[filename] || 'home';
}

// Navigate to page
function navigateTo(href) {
  window.location.href = href;
}

// Render navigation
function renderNavigation(containerId = 'bottomNav') {
  const container = document.getElementById(containerId);
  if (!container) return;
  
  const currentPage = getCurrentPageId();
  
  const navHTML = `
    <nav class="fixed bottom-0 left-0 right-0 z-50 bg-white dark:bg-card-dark border-t border-gray-200 dark:border-gray-700 pb-safe shadow-[0_-4px_10px_rgba(0,0,0,0.03)] transition-all">
      <div class="flex h-20 w-full items-center justify-around px-2">
        ${NAV_ITEMS.map(item => {
          if (item.isCenter) {
            // Center button (Transaksi) - Made larger
            return `
              <div class="relative flex flex-col items-center">
                <button onclick="navigateTo('${item.href}')" class="relative -top-6 flex size-16 items-center justify-center rounded-full bg-primary text-white shadow-lg shadow-primary/40 transition-transform active:scale-95 hover:bg-primary-dark border-[5px] border-white dark:border-card-dark">
                  <span class="material-symbols-outlined text-[32px]">${item.icon}</span>
                </button>
              </div>
            `;
          }
          
          const isActive = currentPage === item.id;
          const iconColor = isActive 
            ? 'text-primary' 
            : 'text-gray-400 dark:text-gray-400 group-hover:text-gray-600 dark:group-hover:text-gray-200';
          const labelColor = isActive 
            ? 'text-primary' 
            : 'text-gray-500 dark:text-gray-400 group-hover:text-gray-700 dark:group-hover:text-gray-200';
          
          return `
            <button onclick="navigateTo('${item.href}')" class="flex flex-col items-center justify-center gap-1.5 p-2 w-16 group transition-all">
              <span class="material-symbols-outlined ${iconColor} text-[28px] transition-colors ${isActive ? 'font-variation-settings-fill-1' : ''}">${item.icon}</span>
              <span class="text-[11px] font-bold ${labelColor} transition-colors uppercase tracking-tight">${item.label}</span>
            </button>
          `;
        }).join('')}
      </div>
    </nav>
    <style>.pb-safe { padding-bottom: env(safe-area-inset-bottom, 0px); }</style>
  `;
  
  container.innerHTML = navHTML;
}

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  // Check if nav container exists
  if (document.getElementById('bottomNav')) {
    renderNavigation();
  }
});

