// API Client for ASM-Hawk

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3100';

interface ApiResponse<T> {
    data?: T;
    error?: string;
}

async function fetchApi<T>(
    endpoint: string,
    options: RequestInit = {}
): Promise<ApiResponse<T>> {
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;

    const headers: HeadersInit = {
        'Content-Type': 'application/json',
        ...options.headers,
    };

    if (token) {
        (headers as Record<string, string>)['Authorization'] = `Bearer ${token}`;
    }

    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers,
        });

        const data = await response.json();

        if (!response.ok) {
            return { error: data.message || 'An error occurred' };
        }

        return { data };
    } catch (error) {
        return { error: error instanceof Error ? error.message : 'Network error' };
    }
}

// Auth API
export const authApi = {
    login: (email: string, password: string) =>
        fetchApi<{ accessToken: string }>('/api/auth/login', {
            method: 'POST',
            body: JSON.stringify({ email, password }),
        }),

    register: (email: string, password: string, fullName?: string) =>
        fetchApi<{ accessToken: string }>('/api/auth/register', {
            method: 'POST',
            body: JSON.stringify({ email, password, fullName }),
        }),

    me: () =>
        fetchApi<{ id: string; email: string; fullName: string; role: string }>('/api/auth/me'),
};

// Assets API
export const assetsApi = {
    list: (page = 1, limit = 10, search?: string) => {
        const params = new URLSearchParams({ page: String(page), limit: String(limit) });
        if (search) params.set('search', search);
        return fetchApi<{ data: Asset[]; total: number; page: number; limit: number }>(
            `/api/assets?${params}`
        );
    },

    get: (id: string) => fetchApi<Asset>(`/api/assets/${id}`),

    create: (asset: CreateAssetDto) =>
        fetchApi<Asset>('/api/assets', {
            method: 'POST',
            body: JSON.stringify(asset),
        }),

    update: (id: string, asset: Partial<CreateAssetDto>) =>
        fetchApi<Asset>(`/api/assets/${id}`, {
            method: 'PATCH',
            body: JSON.stringify(asset),
        }),

    delete: (id: string) =>
        fetchApi<void>(`/api/assets/${id}`, { method: 'DELETE' }),

    stats: () =>
        fetchApi<{ total: number; byType: Record<string, number>; byStatus: Record<string, number> }>(
            '/api/assets/stats'
        ),
};

// Types
export interface Asset {
    id: string;
    domain: string;
    ipAddress?: string;
    ipOwner?: string;
    assetType: 'DOMAIN' | 'SUBDOMAIN' | 'IP' | 'CNAME';
    status: 'ACTIVE' | 'INACTIVE' | 'SUSPICIOUS' | 'CONFIRMED_MALICIOUS';
    riskScore: number;
    firstSeenAt: string;
    lastSeenAt: string;
}

export interface CreateAssetDto {
    domain: string;
    ipAddress?: string;
    ipOwner?: string;
    assetType?: 'DOMAIN' | 'SUBDOMAIN' | 'IP' | 'CNAME';
}
