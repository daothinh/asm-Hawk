import { IsString, IsOptional, IsEnum, IsObject } from 'class-validator';
import { AssetType } from '@prisma/client';

export class CreateAssetDto {
    @IsString()
    domain: string;

    @IsString()
    @IsOptional()
    ipAddress?: string;

    @IsString()
    @IsOptional()
    ipOwner?: string;

    @IsEnum(AssetType)
    @IsOptional()
    assetType?: AssetType;

    @IsObject()
    @IsOptional()
    metadata?: Record<string, any>;
}
