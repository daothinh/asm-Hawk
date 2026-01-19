'use client';

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { authApi } from '@/lib/api';

interface User {
    id: string;
    email: string;
    fullName: string;
    role: string;
}

interface AuthContextType {
    user: User | null;
    loading: boolean;
    login: (email: string, password: string) => Promise<{ error?: string }>;
    register: (email: string, password: string, fullName?: string) => Promise<{ error?: string }>;
    logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
    const [user, setUser] = useState<User | null>(null);
    const [loading, setLoading] = useState(true);
    const router = useRouter();

    useEffect(() => {
        checkAuth();
    }, []);

    const checkAuth = async () => {
        const token = localStorage.getItem('token');
        if (!token) {
            setLoading(false);
            return;
        }

        const { data, error } = await authApi.me();
        if (data && !error) {
            setUser(data);
        } else {
            localStorage.removeItem('token');
        }
        setLoading(false);
    };

    const login = async (email: string, password: string) => {
        const { data, error } = await authApi.login(email, password);
        if (error) return { error };

        if (data?.access_token) {
            localStorage.setItem('token', data.access_token);
            await checkAuth();
            router.push('/dashboard');
        }
        return {};
    };

    const register = async (email: string, password: string, fullName?: string) => {
        const { data, error } = await authApi.register(email, password, fullName);
        if (error) return { error };

        if (data?.access_token) {
            localStorage.setItem('token', data.access_token);
            await checkAuth();
            router.push('/dashboard');
        }
        return {};
    };

    const logout = () => {
        localStorage.removeItem('token');
        setUser(null);
        router.push('/login');
    };

    return (
        <AuthContext.Provider value={{ user, loading, login, register, logout }}>
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
}
