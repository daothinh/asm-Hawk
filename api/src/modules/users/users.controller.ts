import { Controller, Get, Param, Delete, Patch, Body, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { UpdateRoleDto } from './dto/update-role.dto';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
    constructor(private usersService: UsersService) { }

    @Get()
    @Roles(Role.ADMIN, Role.ANALYST)
    async findAll() {
        return this.usersService.findAll();
    }

    @Get(':id')
    @Roles(Role.ADMIN)
    async findOne(@Param('id') id: string) {
        const user = await this.usersService.findById(id);
        const { passwordHash, ...result } = user;
        return result;
    }

    @Patch(':id/role')
    @Roles(Role.ADMIN)
    async updateRole(@Param('id') id: string, @Body() updateRoleDto: UpdateRoleDto) {
        return this.usersService.updateRole(id, updateRoleDto.role);
    }

    @Patch(':id/deactivate')
    @Roles(Role.ADMIN)
    async deactivate(@Param('id') id: string) {
        return this.usersService.deactivate(id);
    }

    @Delete(':id')
    @Roles(Role.ADMIN)
    async delete(@Param('id') id: string) {
        await this.usersService.delete(id);
        return { message: 'User deleted successfully' };
    }
}
