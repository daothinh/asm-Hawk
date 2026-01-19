import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAssetDto } from './dto/create-asset.dto';
import { UpdateAssetDto } from './dto/update-asset.dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class AssetsService {
    constructor(private prisma: PrismaService) { }

    async create(createAssetDto: CreateAssetDto, userId?: string) {
        return this.prisma.asset.create({
            data: {
                domain: createAssetDto.domain,
                ipAddress: createAssetDto.ipAddress,
                ipOwner: createAssetDto.ipOwner,
                assetType: createAssetDto.assetType,
                metadata: createAssetDto.metadata as Prisma.InputJsonValue,
                createdById: userId,
            },
        });
    }

    async findAll(options?: {
        skip?: number;
        take?: number;
        search?: string;
        orderBy?: 'riskScore' | 'lastSeenAt' | 'createdAt';
        order?: 'asc' | 'desc';
    }) {
        const { skip = 0, take = 50, search, orderBy = 'lastSeenAt', order = 'desc' } = options || {};

        const where: Prisma.AssetWhereInput = search
            ? {
                OR: [
                    { domain: { contains: search, mode: 'insensitive' as const } },
                    { ipAddress: { contains: search } },
                    { ipOwner: { contains: search, mode: 'insensitive' as const } },
                ],
            }
            : {};

        const [assets, total] = await Promise.all([
            this.prisma.asset.findMany({
                where,
                skip,
                take,
                orderBy: { [orderBy]: order },
                include: {
                    riskTags: true,
                    _count: {
                        select: {
                            reconResults: true,
                            attackResults: true,
                        },
                    },
                },
            }),
            this.prisma.asset.count({ where }),
        ]);

        return {
            data: assets,
            meta: {
                total,
                skip,
                take,
            },
        };
    }

    async findOne(id: string) {
        const asset = await this.prisma.asset.findUnique({
            where: { id },
            include: {
                riskTags: true,
                reconResults: {
                    take: 10,
                    orderBy: { scannedAt: 'desc' },
                },
                attackResults: {
                    take: 10,
                    orderBy: { executedAt: 'desc' },
                },
                externalIntels: {
                    take: 5,
                    orderBy: { fetchedAt: 'desc' },
                },
            },
        });

        if (!asset) {
            throw new NotFoundException('Asset not found');
        }

        return asset;
    }

    async update(id: string, updateAssetDto: UpdateAssetDto) {
        await this.findOne(id);

        const updateData: Prisma.AssetUpdateInput = {
            lastSeenAt: new Date(),
        };

        if (updateAssetDto.domain !== undefined) updateData.domain = updateAssetDto.domain;
        if (updateAssetDto.ipAddress !== undefined) updateData.ipAddress = updateAssetDto.ipAddress;
        if (updateAssetDto.ipOwner !== undefined) updateData.ipOwner = updateAssetDto.ipOwner;
        if (updateAssetDto.assetType !== undefined) updateData.assetType = updateAssetDto.assetType;
        if (updateAssetDto.status !== undefined) updateData.status = updateAssetDto.status;
        if (updateAssetDto.metadata !== undefined) {
            updateData.metadata = updateAssetDto.metadata as Prisma.InputJsonValue;
        }

        return this.prisma.asset.update({
            where: { id },
            data: updateData,
        });
    }

    async updateRiskScore(id: string, riskScore: number) {
        return this.prisma.asset.update({
            where: { id },
            data: { riskScore },
        });
    }

    async delete(id: string) {
        await this.findOne(id);
        return this.prisma.asset.delete({ where: { id } });
    }

    async getStats() {
        const [total, byStatus, avgRiskScore] = await Promise.all([
            this.prisma.asset.count(),
            this.prisma.asset.groupBy({
                by: ['status'],
                _count: true,
            }),
            this.prisma.asset.aggregate({
                _avg: { riskScore: true },
            }),
        ]);

        return {
            total,
            byStatus: byStatus.reduce(
                (acc, item) => {
                    acc[item.status] = item._count;
                    return acc;
                },
                {} as Record<string, number>,
            ),
            avgRiskScore: avgRiskScore._avg.riskScore || 0,
        };
    }
}
