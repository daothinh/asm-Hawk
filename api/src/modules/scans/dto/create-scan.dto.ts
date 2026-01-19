import { IsEnum, IsUUID } from 'class-validator';
import { ReconToolType } from '@prisma/client';

export class CreateScanDto {
    @IsUUID()
    assetId: string;

    @IsEnum(ReconToolType)
    toolType: ReconToolType;
}
