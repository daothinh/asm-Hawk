'use client';

import { useEffect, useState } from 'react';
import { assetsApi, Asset } from '@/lib/api';

export default function AssetsPage() {
    const [assets, setAssets] = useState<Asset[]>([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(1);
    const [total, setTotal] = useState(0);
    const limit = 10;

    useEffect(() => {
        loadAssets();
    }, [page, search]);

    const loadAssets = async () => {
        setLoading(true);
        const { data } = await assetsApi.list(page, limit, search || undefined);
        if (data) {
            setAssets(data.data);
            setTotal(data.total);
        }
        setLoading(false);
    };

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        setPage(1);
        loadAssets();
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'ACTIVE':
                return 'bg-green-500/20 text-green-400 border-green-500/30';
            case 'INACTIVE':
                return 'bg-slate-500/20 text-slate-400 border-slate-500/30';
            case 'SUSPICIOUS':
                return 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30';
            case 'CONFIRMED_MALICIOUS':
                return 'bg-red-500/20 text-red-400 border-red-500/30';
            default:
                return 'bg-slate-500/20 text-slate-400 border-slate-500/30';
        }
    };

    const getRiskColor = (score: number) => {
        if (score >= 70) return 'text-red-400';
        if (score >= 40) return 'text-yellow-400';
        return 'text-green-400';
    };

    const totalPages = Math.ceil(total / limit);

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-white">Assets</h1>
                    <p className="text-slate-400 mt-1">Manage your monitored assets</p>
                </div>
                <button className="px-4 py-2 bg-gradient-to-r from-cyan-500 to-blue-600 text-white rounded-lg hover:from-cyan-600 hover:to-blue-700 transition-all">
                    + Add Asset
                </button>
            </div>

            {/* Search */}
            <form onSubmit={handleSearch} className="flex gap-4">
                <input
                    type="text"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    placeholder="Search domains, IPs..."
                    className="flex-1 px-4 py-3 bg-slate-800/50 border border-slate-700 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-transparent"
                />
                <button
                    type="submit"
                    className="px-6 py-3 bg-slate-700 text-white rounded-lg hover:bg-slate-600 transition-colors"
                >
                    Search
                </button>
            </form>

            {/* Table */}
            <div className="bg-slate-800/50 backdrop-blur-lg rounded-xl border border-slate-700 overflow-hidden">
                <table className="w-full">
                    <thead className="bg-slate-900/50">
                        <tr>
                            <th className="px-6 py-4 text-left text-sm font-semibold text-slate-300">Domain</th>
                            <th className="px-6 py-4 text-left text-sm font-semibold text-slate-300">IP Address</th>
                            <th className="px-6 py-4 text-left text-sm font-semibold text-slate-300">Type</th>
                            <th className="px-6 py-4 text-left text-sm font-semibold text-slate-300">Status</th>
                            <th className="px-6 py-4 text-left text-sm font-semibold text-slate-300">Risk Score</th>
                            <th className="px-6 py-4 text-left text-sm font-semibold text-slate-300">Last Seen</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-700">
                        {loading ? (
                            <tr>
                                <td colSpan={6} className="px-6 py-8 text-center text-slate-400">
                                    <div className="flex items-center justify-center gap-2">
                                        <div className="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-cyan-500"></div>
                                        Loading...
                                    </div>
                                </td>
                            </tr>
                        ) : assets.length === 0 ? (
                            <tr>
                                <td colSpan={6} className="px-6 py-8 text-center text-slate-400">
                                    No assets found
                                </td>
                            </tr>
                        ) : (
                            assets.map((asset) => (
                                <tr key={asset.id} className="hover:bg-slate-800/50 transition-colors">
                                    <td className="px-6 py-4 text-white font-medium">{asset.domain}</td>
                                    <td className="px-6 py-4 text-slate-300">{asset.ipAddress || '-'}</td>
                                    <td className="px-6 py-4">
                                        <span className="px-2 py-1 text-xs font-medium bg-slate-700 text-slate-300 rounded">
                                            {asset.assetType}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-2 py-1 text-xs font-medium rounded border ${getStatusColor(asset.status)}`}>
                                            {asset.status}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`font-semibold ${getRiskColor(asset.riskScore)}`}>
                                            {asset.riskScore}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 text-slate-400 text-sm">
                                        {new Date(asset.lastSeenAt).toLocaleDateString()}
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>

                {/* Pagination */}
                {totalPages > 1 && (
                    <div className="flex items-center justify-between px-6 py-4 border-t border-slate-700">
                        <p className="text-sm text-slate-400">
                            Showing {(page - 1) * limit + 1} to {Math.min(page * limit, total)} of {total} assets
                        </p>
                        <div className="flex gap-2">
                            <button
                                onClick={() => setPage(p => Math.max(1, p - 1))}
                                disabled={page === 1}
                                className="px-3 py-1 bg-slate-700 text-slate-300 rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-slate-600 transition-colors"
                            >
                                Previous
                            </button>
                            <button
                                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                                disabled={page === totalPages}
                                className="px-3 py-1 bg-slate-700 text-slate-300 rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-slate-600 transition-colors"
                            >
                                Next
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
