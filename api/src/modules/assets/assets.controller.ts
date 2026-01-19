import {
    Controller,
    Get,
    Post,
    Body,
    Patch,
    Param,
    Delete,
    UseGuards,
    Query,
    Request,
} from '@nestjs/common';
import { AssetsService } from './assets.service';
import { CreateAssetDto } from './dto/create-asset.dto';
import { UpdateAssetDto } from './dto/update-asset.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('assets')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AssetsController {
    constructor(private assetsService: AssetsService) { }

    @Post()
    @Roles(Role.ADMIN, Role.ANALYST)
    async create(@Body() createAssetDto: CreateAssetDto, @Request() req: any) {
        return this.assetsService.create(createAssetDto, req.user.id);
    }

    @Get()
    async findAll(
        @Query('skip') skip?: string,
        @Query('take') take?: string,
        @Query('search') search?: string,
        @Query('orderBy') orderBy?: 'riskScore' | 'lastSeenAt' | 'createdAt',
        @Query('order') order?: 'asc' | 'desc',
    ) {
        return this.assetsService.findAll({
            skip: skip ? parseInt(skip, 10) : undefined,
            take: take ? parseInt(take, 10) : undefined,
            search,
            orderBy,
            order,
        });
    }

    @Get('stats')
    async getStats() {
        return this.assetsService.getStats();
    }

    @Get(':id')
    async findOne(@Param('id') id: string) {
        return this.assetsService.findOne(id);
    }

    @Patch(':id')
    @Roles(Role.ADMIN, Role.ANALYST)
    async update(@Param('id') id: string, @Body() updateAssetDto: UpdateAssetDto) {
        return this.assetsService.update(id, updateAssetDto);
    }

    @Delete(':id')
    @Roles(Role.ADMIN)
    async delete(@Param('id') id: string) {
        await this.assetsService.delete(id);
        return { message: 'Asset deleted successfully' };
    }
}
