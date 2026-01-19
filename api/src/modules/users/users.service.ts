import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Role } from '@prisma/client';

interface CreateUserData {
    email: string;
    passwordHash: string;
    fullName?: string;
    role?: Role;
}

@Injectable()
export class UsersService {
    constructor(private prisma: PrismaService) { }

    async create(data: CreateUserData) {
        return this.prisma.user.create({
            data: {
                email: data.email,
                passwordHash: data.passwordHash,
                fullName: data.fullName,
                role: data.role || Role.VIEWER,
            },
        });
    }

    async findAll() {
        return this.prisma.user.findMany({
            select: {
                id: true,
                email: true,
                fullName: true,
                role: true,
                isActive: true,
                lastLoginAt: true,
                createdAt: true,
            },
        });
    }

    async findById(id: string) {
        const user = await this.prisma.user.findUnique({
            where: { id },
        });
        if (!user) {
            throw new NotFoundException('User not found');
        }
        return user;
    }

    async findByEmail(email: string) {
        return this.prisma.user.findUnique({
            where: { email },
        });
    }

    async updateLastLogin(id: string) {
        return this.prisma.user.update({
            where: { id },
            data: { lastLoginAt: new Date() },
        });
    }

    async updateRole(id: string, role: Role) {
        return this.prisma.user.update({
            where: { id },
            data: { role },
        });
    }

    async deactivate(id: string) {
        return this.prisma.user.update({
            where: { id },
            data: { isActive: false },
        });
    }

    async delete(id: string) {
        return this.prisma.user.delete({
            where: { id },
        });
    }
}
