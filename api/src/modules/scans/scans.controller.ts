import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    Delete,
    UseGuards,
    Query,
} from '@nestjs/common';
import { ScansService } from './scans.service';
import { CreateScanDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Role, ReconToolType, ScanJobStatus } from '@prisma/client';

@Controller('scans')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ScansController {
    constructor(private scansService: ScansService) { }

    @Post()
    @Roles(Role.ADMIN, Role.ANALYST)
    async create(@Body() createScanDto: CreateScanDto) {
        return this.scansService.create(createScanDto);
    }

    @Get()
    async findAll(
        @Query('assetId') assetId?: string,
        @Query('toolType') toolType?: ReconToolType,
        @Query('status') status?: ScanJobStatus,
        @Query('skip') skip?: string,
        @Query('take') take?: string,
    ) {
        return this.scansService.findAll({
            assetId,
            toolType,
            status,
            skip: skip ? parseInt(skip, 10) : undefined,
            take: take ? parseInt(take, 10) : undefined,
        });
    }

    @Get(':id')
    async findOne(@Param('id') id: string) {
        return this.scansService.findOne(id);
    }

    @Get('asset/:assetId')
    async findByAsset(@Param('assetId') assetId: string) {
        return this.scansService.findByAsset(assetId);
    }

    @Post(':id/cancel')
    @Roles(Role.ADMIN, Role.ANALYST)
    async cancel(@Param('id') id: string) {
        return this.scansService.cancel(id);
    }

    @Delete(':id')
    @Roles(Role.ADMIN)
    async delete(@Param('id') id: string) {
        await this.scansService.delete(id);
        return { message: 'Scan deleted successfully' };
    }
}
