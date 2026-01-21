'use client';

import { useState, useEffect, useCallback } from 'react';

// Types
interface Asset {
    id: string;
    domain: string;
}

interface Scan {
    id: string;
    assetId: string;
    toolType: string;
    status: 'PENDING' | 'RUNNING' | 'COMPLETED' | 'FAILED' | 'CANCELLED';
    command?: string;
    stdout?: string;
    stderr?: string;
    executionTime?: string;
    startedAt?: string;
    completedAt?: string;
    createdAt: string;
    asset: Asset;
    _count: {
        scanResults: number;
    };
}

const TOOL_TYPES = [
    { value: 'SUBFINDER', label: 'Subfinder', description: 'Subdomain discovery', icon: '🔍' },
    { value: 'HTTPX', label: 'HTTPX', description: 'HTTP probing', icon: '🌐' },
    { value: 'NUCLEI', label: 'Nuclei', description: 'Vulnerability scanning', icon: '⚠️' },
    { value: 'KATANA', label: 'Katana', description: 'Web crawling', icon: '🕷️' },
    { value: 'DNSX', label: 'DNSX', description: 'DNS toolkit', icon: '📍' },
    { value: 'GOSPIDER', label: 'GoSpider', description: 'JS/Link discovery', icon: '🕸️' },
    { value: 'WAYBACKURLS', label: 'Wayback URLs', description: 'Historical URLs', icon: '⏰' },
    { value: 'ASSETFINDER', label: 'Assetfinder', description: 'Asset discovery', icon: '🎯' },
    { value: 'SUBLIST3R', label: 'Sublist3r', description: 'Subdomain enumeration', icon: '📋' },
];

const STATUS_COLORS: Record<string, string> = {
    PENDING: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/50',
    RUNNING: 'bg-blue-500/20 text-blue-400 border-blue-500/50',
    COMPLETED: 'bg-green-500/20 text-green-400 border-green-500/50',
    FAILED: 'bg-red-500/20 text-red-400 border-red-500/50',
    CANCELLED: 'bg-gray-500/20 text-gray-400 border-gray-500/50',
};

const STATUS_ICONS: Record<string, string> = {
    PENDING: '⏳',
    RUNNING: '🔄',
    COMPLETED: '✅',
    FAILED: '❌',
    CANCELLED: '🚫',
};

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3100';

export default function ScansPage() {
    const [scans, setScans] = useState<Scan[]>([]);
    const [assets, setAssets] = useState<Asset[]>([]);
    const [loading, setLoading] = useState(true);
    const [showNewScan, setShowNewScan] = useState(false);
    const [targetMode, setTargetMode] = useState<'existing' | 'new'>('new');
    const [selectedAsset, setSelectedAsset] = useState<string>('');
    const [customDomain, setCustomDomain] = useState<string>('');
    const [selectedTool, setSelectedTool] = useState<string>('');
    const [creating, setCreating] = useState(false);
    const [selectedScan, setSelectedScan] = useState<Scan | null>(null);
    const [error, setError] = useState('');

    const fetchScans = useCallback(async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${API_BASE}/api/scans`, {
                headers: { Authorization: `Bearer ${token}` },
            });
            const data = await res.json();
            setScans(data.data || []);
        } catch (err) {
            console.error('Error fetching scans:', err);
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchAssets = useCallback(async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${API_BASE}/api/assets?limit=100`, {
                headers: { Authorization: `Bearer ${token}` },
            });
            const data = await res.json();
            setAssets(data.data || []);
        } catch (err) {
            console.error('Error fetching assets:', err);
        }
    }, []);

    useEffect(() => {
        fetchScans();
        fetchAssets();

        // Poll for updates every 5 seconds
        const interval = setInterval(fetchScans, 5000);
        return () => clearInterval(interval);
    }, [fetchScans, fetchAssets]);

    const createOrGetAsset = async (domain: string): Promise<string | null> => {
        const token = localStorage.getItem('token');

        // Check if asset already exists
        const existingAsset = assets.find(a => a.domain.toLowerCase() === domain.toLowerCase());
        if (existingAsset) {
            return existingAsset.id;
        }

        // Create new asset
        const res = await fetch(`${API_BASE}/api/assets`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token}`,
            },
            body: JSON.stringify({
                domain,
                assetType: 'DOMAIN'
            }),
        });

        if (!res.ok) {
            const data = await res.json();
            throw new Error(data.message || 'Failed to create asset');
        }

        const newAsset = await res.json();
        return newAsset.id;
    };

    const createScan = async () => {
        const targetDomain = targetMode === 'new' ? customDomain.trim() :
            assets.find(a => a.id === selectedAsset)?.domain;

        if (!targetDomain) {
            setError('Please enter a domain or select an asset');
            return;
        }

        if (!selectedTool) {
            setError('Please select a scan tool');
            return;
        }

        // Validate domain format
        const domainRegex = /^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/;
        if (!domainRegex.test(targetDomain)) {
            setError('Please enter a valid domain (e.g., example.com)');
            return;
        }

        setCreating(true);
        setError('');

        try {
            // First ensure we have an asset for this domain
            let assetId: string | null;

            if (targetMode === 'existing' && selectedAsset) {
                assetId = selectedAsset;
            } else {
                assetId = await createOrGetAsset(targetDomain);
            }

            if (!assetId) {
                throw new Error('Failed to get or create asset');
            }

            const token = localStorage.getItem('token');
            const res = await fetch(`${API_BASE}/api/scans`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({
                    assetId,
                    toolType: selectedTool,
                }),
            });

            if (!res.ok) {
                const data = await res.json();
                throw new Error(data.message || 'Failed to create scan');
            }

            setShowNewScan(false);
            setSelectedAsset('');
            setCustomDomain('');
            setSelectedTool('');
            fetchScans();
            fetchAssets(); // Refresh assets list
        } catch (err: any) {
            setError(err.message);
        } finally {
            setCreating(false);
        }
    };

    const cancelScan = async (scanId: string) => {
        try {
            const token = localStorage.getItem('token');
            await fetch(`${API_BASE}/api/scans/${scanId}/cancel`, {
                method: 'POST',
                headers: { Authorization: `Bearer ${token}` },
            });
            fetchScans();
        } catch (err) {
            console.error('Error cancelling scan:', err);
        }
    };

    const deleteScan = async (scanId: string) => {
        if (!confirm('Are you sure you want to delete this scan?')) return;

        try {
            const token = localStorage.getItem('token');
            await fetch(`${API_BASE}/api/scans/${scanId}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` },
            });
            fetchScans();
            if (selectedScan?.id === scanId) setSelectedScan(null);
        } catch (err) {
            console.error('Error deleting scan:', err);
        }
    };

    const viewScanDetails = async (scanId: string) => {
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${API_BASE}/api/scans/${scanId}`, {
                headers: { Authorization: `Bearer ${token}` },
            });
            const data = await res.json();
            setSelectedScan(data);
        } catch (err) {
            console.error('Error fetching scan details:', err);
        }
    };

    const formatDate = (dateStr: string) => {
        return new Date(dateStr).toLocaleString('vi-VN');
    };

    const getToolIcon = (toolType: string) => {
        const tool = TOOL_TYPES.find(t => t.value === toolType);
        return tool?.icon || '🔧';
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-cyan-500"></div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-white">Scans</h1>
                    <p className="text-slate-400 mt-1">Run security scans on your assets</p>
                </div>
                <button
                    onClick={() => setShowNewScan(true)}
                    className="px-4 py-2 bg-gradient-to-r from-cyan-500 to-blue-600 text-white rounded-lg font-medium hover:from-cyan-600 hover:to-blue-700 transition-all flex items-center gap-2"
                >
                    <span>+ New Scan</span>
                </button>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-5 gap-4">
                {['PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED'].map((status) => (
                    <div key={status} className="bg-slate-800/50 rounded-xl p-4 border border-slate-700">
                        <div className="flex items-center gap-2">
                            <span className="text-2xl">{STATUS_ICONS[status]}</span>
                            <div>
                                <p className="text-2xl font-bold text-white">
                                    {scans.filter(s => s.status === status).length}
                                </p>
                                <p className="text-xs text-slate-400 capitalize">{status.toLowerCase()}</p>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Main Content */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Scans List */}
                <div className="lg:col-span-2 bg-slate-800/50 rounded-xl border border-slate-700 overflow-hidden">
                    <div className="p-4 border-b border-slate-700">
                        <h2 className="text-lg font-semibold text-white">Recent Scans</h2>
                    </div>

                    {scans.length === 0 ? (
                        <div className="p-8 text-center text-slate-400">
                            <p>No scans yet. Click "New Scan" to get started.</p>
                        </div>
                    ) : (
                        <div className="divide-y divide-slate-700 max-h-[500px] overflow-y-auto">
                            {scans.map((scan) => (
                                <div
                                    key={scan.id}
                                    className={`p-4 hover:bg-slate-700/30 cursor-pointer transition-colors ${selectedScan?.id === scan.id ? 'bg-slate-700/50' : ''
                                        }`}
                                    onClick={() => viewScanDetails(scan.id)}
                                >
                                    <div className="flex items-center justify-between">
                                        <div className="flex items-center gap-3">
                                            <span className="text-2xl">{getToolIcon(scan.toolType)}</span>
                                            <div>
                                                <p className="text-white font-medium">
                                                    {scan.toolType} - {scan.asset?.domain || 'Unknown'}
                                                </p>
                                                <p className="text-sm text-slate-400">
                                                    {formatDate(scan.createdAt)}
                                                    {scan.executionTime && ` • ${scan.executionTime}`}
                                                </p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2">
                                            <span className={`px-3 py-1 rounded-full text-xs font-medium border ${STATUS_COLORS[scan.status]}`}>
                                                {STATUS_ICONS[scan.status]} {scan.status}
                                            </span>
                                            {scan._count?.scanResults > 0 && (
                                                <span className="px-2 py-1 bg-cyan-500/20 text-cyan-400 rounded text-xs">
                                                    {scan._count.scanResults} results
                                                </span>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Scan Details Panel */}
                <div className="bg-slate-800/50 rounded-xl border border-slate-700 overflow-hidden">
                    <div className="p-4 border-b border-slate-700">
                        <h2 className="text-lg font-semibold text-white">Scan Details</h2>
                    </div>

                    {selectedScan ? (
                        <div className="p-4 space-y-4 max-h-[500px] overflow-y-auto">
                            <div className="flex items-center justify-between">
                                <span className="text-2xl">{getToolIcon(selectedScan.toolType)}</span>
                                <span className={`px-3 py-1 rounded-full text-xs font-medium border ${STATUS_COLORS[selectedScan.status]}`}>
                                    {selectedScan.status}
                                </span>
                            </div>

                            <div className="space-y-3">
                                <div>
                                    <p className="text-xs text-slate-400">Tool</p>
                                    <p className="text-white">{selectedScan.toolType}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-slate-400">Target</p>
                                    <p className="text-white">{selectedScan.asset?.domain || 'Unknown'}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-slate-400">Created</p>
                                    <p className="text-white">{formatDate(selectedScan.createdAt)}</p>
                                </div>
                                {selectedScan.executionTime && (
                                    <div>
                                        <p className="text-xs text-slate-400">Duration</p>
                                        <p className="text-white">{selectedScan.executionTime}</p>
                                    </div>
                                )}
                                {selectedScan.command && (
                                    <div>
                                        <p className="text-xs text-slate-400">Command</p>
                                        <p className="text-white font-mono text-xs bg-slate-900 p-2 rounded overflow-x-auto">
                                            {selectedScan.command}
                                        </p>
                                    </div>
                                )}
                            </div>

                            {/* Output */}
                            {selectedScan.stdout && (
                                <div>
                                    <p className="text-xs text-slate-400 mb-2">Output ({selectedScan.stdout.split('\n').length} lines)</p>
                                    <pre className="text-xs text-green-400 bg-slate-900 p-3 rounded-lg max-h-48 overflow-auto font-mono whitespace-pre-wrap break-all">
                                        {selectedScan.stdout}
                                    </pre>
                                </div>
                            )}

                            {selectedScan.stderr && (
                                <div>
                                    <p className="text-xs text-slate-400 mb-2">Errors</p>
                                    <pre className="text-xs text-red-400 bg-slate-900 p-3 rounded-lg max-h-32 overflow-auto font-mono whitespace-pre-wrap break-all">
                                        {selectedScan.stderr}
                                    </pre>
                                </div>
                            )}

                            {/* Actions */}
                            <div className="flex gap-2 pt-4 border-t border-slate-700">
                                {(selectedScan.status === 'PENDING' || selectedScan.status === 'RUNNING') && (
                                    <button
                                        onClick={() => cancelScan(selectedScan.id)}
                                        className="flex-1 py-2 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg text-sm transition-colors"
                                    >
                                        Cancel
                                    </button>
                                )}
                                <button
                                    onClick={() => deleteScan(selectedScan.id)}
                                    className="flex-1 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm transition-colors"
                                >
                                    Delete
                                </button>
                            </div>
                        </div>
                    ) : (
                        <div className="p-8 text-center text-slate-400">
                            <p>Select a scan to view details</p>
                        </div>
                    )}
                </div>
            </div>

            {/* New Scan Modal */}
            {showNewScan && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <div className="bg-slate-800 rounded-2xl border border-slate-700 p-6 w-full max-w-lg shadow-2xl max-h-[90vh] overflow-y-auto">
                        <h2 className="text-xl font-bold text-white mb-4">New Scan</h2>

                        {error && (
                            <div className="mb-4 p-3 bg-red-900/30 border border-red-800 rounded-lg text-red-400 text-sm">
                                {error}
                            </div>
                        )}

                        <div className="space-y-4">
                            {/* Target Mode Selection */}
                            <div>
                                <label className="block text-sm font-medium text-slate-300 mb-2">
                                    Target
                                </label>
                                <div className="flex gap-2 mb-3">
                                    <button
                                        onClick={() => setTargetMode('new')}
                                        className={`flex-1 py-2 px-4 rounded-lg border text-sm font-medium transition-all ${targetMode === 'new'
                                            ? 'bg-cyan-500/20 border-cyan-500 text-cyan-400'
                                            : 'bg-slate-900 border-slate-600 text-slate-400 hover:border-slate-500'
                                            }`}
                                    >
                                        🌐 Enter Domain
                                    </button>
                                    <button
                                        onClick={() => setTargetMode('existing')}
                                        className={`flex-1 py-2 px-4 rounded-lg border text-sm font-medium transition-all ${targetMode === 'existing'
                                            ? 'bg-cyan-500/20 border-cyan-500 text-cyan-400'
                                            : 'bg-slate-900 border-slate-600 text-slate-400 hover:border-slate-500'
                                            }`}
                                    >
                                        📁 Select Asset
                                    </button>
                                </div>

                                {targetMode === 'new' ? (
                                    <input
                                        type="text"
                                        value={customDomain}
                                        onChange={(e) => setCustomDomain(e.target.value)}
                                        placeholder="e.g., example.com"
                                        className="w-full px-4 py-3 bg-slate-900 border border-slate-600 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-cyan-500"
                                    />
                                ) : (
                                    <select
                                        value={selectedAsset}
                                        onChange={(e) => setSelectedAsset(e.target.value)}
                                        className="w-full px-4 py-3 bg-slate-900 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-cyan-500"
                                    >
                                        <option value="">Select an asset...</option>
                                        {assets.map((asset) => (
                                            <option key={asset.id} value={asset.id}>
                                                {asset.domain}
                                            </option>
                                        ))}
                                    </select>
                                )}
                                <p className="text-xs text-slate-500 mt-1">
                                    {targetMode === 'new'
                                        ? 'Enter any domain to scan. An asset will be created automatically.'
                                        : `${assets.length} assets available`
                                    }
                                </p>
                            </div>

                            {/* Tool Selection */}
                            <div>
                                <label className="block text-sm font-medium text-slate-300 mb-2">
                                    Scan Tool
                                </label>
                                <div className="grid grid-cols-3 gap-2">
                                    {TOOL_TYPES.map((tool) => (
                                        <button
                                            key={tool.value}
                                            onClick={() => setSelectedTool(tool.value)}
                                            className={`p-3 rounded-lg border text-left transition-all ${selectedTool === tool.value
                                                ? 'bg-cyan-500/20 border-cyan-500 text-white'
                                                : 'bg-slate-900 border-slate-600 text-slate-300 hover:border-slate-500'
                                                }`}
                                        >
                                            <span className="text-xl">{tool.icon}</span>
                                            <p className="text-sm font-medium mt-1">{tool.label}</p>
                                            <p className="text-xs text-slate-400">{tool.description}</p>
                                        </button>
                                    ))}
                                </div>
                            </div>
                        </div>

                        <div className="flex gap-3 mt-6">
                            <button
                                onClick={() => {
                                    setShowNewScan(false);
                                    setError('');
                                    setCustomDomain('');
                                    setSelectedAsset('');
                                    setSelectedTool('');
                                }}
                                className="flex-1 py-3 bg-slate-700 hover:bg-slate-600 text-white rounded-lg font-medium transition-colors"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={createScan}
                                disabled={creating || (!customDomain && !selectedAsset) || !selectedTool}
                                className="flex-1 py-3 bg-gradient-to-r from-cyan-500 to-blue-600 text-white rounded-lg font-medium hover:from-cyan-600 hover:to-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                            >
                                {creating ? 'Starting...' : 'Start Scan'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
