import { PartialType } from '@nestjs/mapped-types';
import { CreateScanDto } from './create-scan.dto';
import { IsEnum, IsOptional } from 'class-validator';
import { ScanJobStatus } from '@prisma/client';

export class UpdateScanDto extends PartialType(CreateScanDto) {
    @IsOptional()
    @IsEnum(ScanJobStatus)
    status?: ScanJobStatus;
}
