import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
    private readonly logger = new Logger(PrismaService.name);

    async onModuleInit() {
        try {
            await this.$connect();
            this.logger.log('Database connected successfully');
        } catch (error) {
            this.logger.error('Failed to connect to database', error);
            // TODO: Prisma 7 requires DATABASE_URL to be set or PostgreSQL running
        }
    }

    async onModuleDestroy() {
        await this.$disconnect();
    }
}
