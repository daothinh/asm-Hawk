import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
    constructor(
        private usersService: UsersService,
        private jwtService: JwtService,
    ) { }

    async register(registerDto: RegisterDto) {
        const existingUser = await this.usersService.findByEmail(registerDto.email);
        if (existingUser) {
            throw new ConflictException('Email already exists');
        }

        const passwordHash = await bcrypt.hash(registerDto.password, 10);
        const user = await this.usersService.create({
            email: registerDto.email,
            passwordHash,
            fullName: registerDto.fullName,
        });

        const token = this.generateToken(user.id, user.email, user.role);

        return {
            user: {
                id: user.id,
                email: user.email,
                fullName: user.fullName,
                role: user.role,
            },
            accessToken: token,
        };
    }

    async login(loginDto: LoginDto) {
        const user = await this.usersService.findByEmail(loginDto.email);
        if (!user) {
            throw new UnauthorizedException('Invalid credentials');
        }

        const isPasswordValid = await bcrypt.compare(loginDto.password, user.passwordHash);
        if (!isPasswordValid) {
            throw new UnauthorizedException('Invalid credentials');
        }

        await this.usersService.updateLastLogin(user.id);

        const token = this.generateToken(user.id, user.email, user.role);

        return {
            user: {
                id: user.id,
                email: user.email,
                fullName: user.fullName,
                role: user.role,
            },
            accessToken: token,
        };
    }

    async validateUser(userId: string) {
        return this.usersService.findById(userId);
    }

    private generateToken(userId: string, email: string, role: string): string {
        const payload = { sub: userId, email, role };
        return this.jwtService.sign(payload);
    }
}
