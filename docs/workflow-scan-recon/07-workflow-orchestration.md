# Auto Scan Workflow Orchestration

Chi tiết về cách workflow auto-scan được điều phối trong ars0n-framework-v2.

---

## Tổng Quan

Auto-scan workflow được quản lý từ **frontend React** và được orchestrate bởi 2 file chính:
- `client/src/utils/wildcardAutoScan.js` - Orchestration và state management
- `client/src/utils/autoScanSteps.js` - Định nghĩa từng bước scan

---

## AUTO_SCAN_STEPS Constants

```javascript
const AUTO_SCAN_STEPS = {
  IDLE: 'idle',                           // Không hoạt động
  AMASS: 'amass',                         // Subdomain enumeration
  SUBLIST3R: 'sublist3r',                 // Subdomain discovery
  ASSETFINDER: 'assetfinder',             // Asset discovery
  GAU: 'gau',                             // URL discovery
  CTL: 'ctl',                             // Certificate Transparency
  SUBFINDER: 'subfinder',                 // Subdomain discovery
  CONSOLIDATE: 'consolidate',             // Merge subdomains (Round 1)
  HTTPX: 'httpx',                         // HTTP probing (Round 1)
  SHUFFLEDNS: 'shuffledns',               // DNS brute-force
  SHUFFLEDNS_CEWL: 'shuffledns_cewl',     // CeWL + ShuffleDNS
  CONSOLIDATE_ROUND2: 'consolidate_round2', // Merge (Round 2)
  HTTPX_ROUND2: 'httpx_round2',           // HTTP probing (Round 2)
  GOSPIDER: 'gospider',                   // Web spidering
  SUBDOMAINIZER: 'subdomainizer',         // JS subdomain extraction
  CONSOLIDATE_ROUND3: 'consolidate_round3', // Merge (Round 3)
  HTTPX_ROUND3: 'httpx_round3',           // HTTP probing (Round 3)
  NUCLEI_SCREENSHOT: 'nuclei-screenshot', // Screenshot capture
  METADATA: 'metadata',                   // Metadata extraction
  COMPLETED: 'completed'                  // Scan completed
};
```

---

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AUTO SCAN WORKFLOW                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Phase 1: Subdomain Enumeration                                          │
│  ─────────────────────────────                                           │
│  ┌─────────┐   ┌───────────┐   ┌─────────────┐   ┌─────┐   ┌─────┐      │
│  │  AMASS  │-->│ SUBLIST3R │-->│ ASSETFINDER │-->│ GAU │-->│ CTL │      │
│  └─────────┘   └───────────┘   └─────────────┘   └─────┘   └─────┘      │
│                                                        │                 │
│                                                        ▼                 │
│                                                   ┌───────────┐          │
│                                                   │ SUBFINDER │          │
│                                                   └───────────┘          │
│                                                        │                 │
│  Phase 2: Consolidation & Probing Round 1              ▼                 │
│  ───────────────────────────────────────────    ┌─────────────┐          │
│                                                 │ CONSOLIDATE │          │
│                                                 └─────────────┘          │
│                                                        │                 │
│                      [Check maxConsolidatedSubdomains] ▼                 │
│                                                   ┌─────────┐            │
│                                                   │  HTTPX  │            │
│                                                   └─────────┘            │
│                                                        │                 │
│                         [Check maxLiveWebServers]      ▼                 │
│  Phase 3: DNS Brute-force                                                │
│  ────────────────────────                                                │
│  ┌────────────┐   ┌─────────────────────┐                                │
│  │ SHUFFLEDNS │-->│ CEWL + SHUFFLEDNS   │                                │
│  └────────────┘   └─────────────────────┘                                │
│                              │                                           │
│  Phase 4: Consolidation Round 2                                          │
│  ──────────────────────────────                                          │
│                              ▼                                           │
│                   ┌───────────────────┐                                  │
│                   │ CONSOLIDATE_ROUND2│                                  │
│                   └───────────────────┘                                  │
│                              │                                           │
│                              ▼                                           │
│                   ┌───────────────────┐                                  │
│                   │   HTTPX_ROUND2    │                                  │
│                   └───────────────────┘                                  │
│                              │                                           │
│  Phase 5: JavaScript Analysis                                            │
│  ────────────────────────────                                            │
│  ┌──────────┐   ┌───────────────┐      │                                 │
│  │ GOSPIDER │-->│ SUBDOMAINIZER │      │                                 │
│  └──────────┘   └───────────────┘      │                                 │
│                              │                                           │
│  Phase 6: Final Consolidation                                            │
│  ────────────────────────────                                            │
│                              ▼                                           │
│                   ┌───────────────────┐                                  │
│                   │ CONSOLIDATE_ROUND3│                                  │
│                   └───────────────────┘                                  │
│                              │                                           │
│                              ▼                                           │
│                   ┌───────────────────┐                                  │
│                   │   HTTPX_ROUND3    │                                  │
│                   └───────────────────┘                                  │
│                              │                                           │
│  Phase 7: Vulnerability Assessment                                       │
│  ─────────────────────────────────                                       │
│  ┌───────────────────┐   ┌──────────┐                                    │
│  │ NUCLEI_SCREENSHOT │-->│ METADATA │                                    │
│  └───────────────────┘   └──────────┘                                    │
│                              │                                           │
│                              ▼                                           │
│                        ┌───────────┐                                     │
│                        │ COMPLETED │                                     │
│                        └───────────┘                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Start Auto Scan

```javascript
const startAutoScan = async (
  activeTarget,
  setIsAutoScanning,
  setAutoScanCurrentStep,
  setAutoScanTargetId,
  getAutoScanSteps,
  consolidatedSubdomains,
  mostRecentHttpxScan,
  autoScanSessionId
) => {
  // 1. Khởi tạo state
  setIsAutoScanning(true);
  setAutoScanTargetId(activeTarget.id);
  
  // 2. Cập nhật trạng thái IDLE trên server
  await updateAutoScanState(activeTarget.id, AUTO_SCAN_STEPS.IDLE);
  
  // 3. Lấy cấu hình auto-scan
  const configResponse = await fetch('/api/api/auto-scan-config');
  const config = await configResponse.json();
  
  // 4. Lấy danh sách các bước scan
  const steps = getAutoScanSteps(/* ... params ... */, config, autoScanSessionId);
  
  // 5. Thực thi từng bước
  for (let i = 0; i < steps.length; i++) {
    // Kiểm tra trạng thái cancel
    const state = await fetch(`/api/api/auto-scan-state/${activeTarget.id}`);
    if (state.is_cancelled) break;
    
    // Cập nhật bước hiện tại
    setAutoScanCurrentStep(steps[i].name);
    await updateAutoScanState(activeTarget.id, steps[i].name);
    
    // Thực thi action
    await steps[i].action();
    
    // Kiểm tra trạng thái pause
    if (state.is_paused) {
      while (isPaused) {
        await sleep(2000);
        // Re-check pause state
      }
    }
  }
  
  // 6. Hoàn thành
  setAutoScanCurrentStep(AUTO_SCAN_STEPS.COMPLETED);
  await updateAutoScanState(activeTarget.id, AUTO_SCAN_STEPS.COMPLETED);
  setIsAutoScanning(false);
};
```

---

## Step Definition Pattern

```javascript
const getAutoScanSteps = (
  activeTarget,
  setAutoScanCurrentStep,
  // ... nhiều state setters khác
  handleConsolidate,
  config,
  autoScanSessionId
) => {
  const steps = [
    {
      name: AUTO_SCAN_STEPS.AMASS,
      action: async () => {
        // Kiểm tra config có enable không
        if (config?.amass === false) return;
        
        // Cập nhật UI state
        setAutoScanCurrentStep(AUTO_SCAN_STEPS.AMASS);
        await updateAutoScanState(activeTarget.id, AUTO_SCAN_STEPS.AMASS);
        
        // Gọi API để khởi tạo scan
        await initiateAmassScan(activeTarget, ...);
        
        // Polling chờ scan hoàn thành
        await waitForScanCompletion('amass', activeTarget.id, ...);
        
        // Fetch kết quả cập nhật UI
        const response = await fetch(`/api/scopetarget/${activeTarget.id}/scans/amass`);
      }
    },
    // ... more steps
  ];
  
  // Filter theo config
  if (config) {
    return steps.filter(step => config[step.name] !== false);
  }
  return steps;
};
```

---

## Wait For Scan Completion

```javascript
const waitForScanCompletion = async (
  scanType, 
  targetId, 
  setIsScanning, 
  setMostRecentScanStatus, 
  setMostRecentScan = null
) => {
  return new Promise((resolve) => {
    const checkStatus = async () => {
      // Fetch scan status từ API
      const response = await fetch(`/api/scopetarget/${targetId}/scans/${scanType}`);
      const scans = await response.json();
      
      // Lấy scan gần nhất
      const mostRecentScan = scans.reduce((latest, scan) => {
        return new Date(scan.created_at) > new Date(latest.created_at) ? scan : latest;
      }, scans[0]);
      
      // Kiểm tra trạng thái
      if (['completed', 'success', 'failed', 'error'].includes(mostRecentScan.status)) {
        setIsScanning(false);
        resolve(mostRecentScan);
      } else {
        // Poll lại sau 5 giây
        setTimeout(checkStatus, 5000);
      }
    };
    checkStatus();
  });
};
```

---

## Update Auto Scan State

```javascript
const updateAutoScanState = async (
  targetId, 
  currentStep, 
  isPaused = false, 
  isCancelled = false, 
  config = null
) => {
  const response = await fetch(
    `/api/api/auto-scan-state/${targetId}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        current_step: currentStep,
        is_paused: isPaused,
        is_cancelled: isCancelled
      }),
    }
  );
  return response.json();
};
```

---

## Auto Scan Configuration

```javascript
const config = {
  // Tool toggles
  amass: true,
  sublist3r: true,
  assetfinder: true,
  gau: true,
  ctl: true,
  subfinder: true,
  consolidate_httpx_round1: true,
  shuffledns: true,
  cewl: true,
  consolidate_httpx_round2: true,
  gospider: true,
  subdomainizer: true,
  consolidate_httpx_round3: true,
  nuclei_screenshot: true,
  metadata: true,
  
  // Limits (auto-pause if exceeded)
  maxConsolidatedSubdomains: 5000,
  maxLiveWebServers: 500
};
```

---

## Limit Check và Auto-Pause

```javascript
// Sau mỗi bước consolidate
const consolidatedCount = consolidatedSubdomains.length;
if (consolidatedCount > config.maxConsolidatedSubdomains) {
  // Tự động pause scan
  await updateAutoScanState(
    activeTarget.id, 
    currentStep, 
    true,  // is_paused = true
    false
  );
  // UI sẽ hiển thị warning và chờ user tiếp tục
}

// Sau mỗi bước HTTPX
const liveWebServers = mostRecentHttpxScan?.result?.split('\n').length || 0;
if (liveWebServers > config.maxLiveWebServers) {
  await updateAutoScanState(
    activeTarget.id,
    currentStep,
    true,  // is_paused = true
    false
  );
}
```

---

## API Endpoints

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/api/auto-scan-config` | Get auto-scan configuration |
| POST | `/api/api/auto-scan-config` | Update configuration |
| GET | `/api/api/auto-scan-state/{target_id}` | Get current scan state |
| POST | `/api/api/auto-scan-state/{target_id}` | Update scan state |
| POST | `/api/api/auto-scan/session/start` | Start new session |
| GET | `/api/api/auto-scan/session/{id}` | Get session info |
| GET | `/api/api/auto-scan/sessions` | List all sessions |
| POST | `/api/api/auto-scan/session/{id}/cancel` | Cancel session |
| POST | `/api/api/auto-scan/session/{id}/final-stats` | Update final stats |
